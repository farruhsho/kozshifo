import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../reception/domain/payment_result.dart';
import '../../reception/domain/reception_visit.dart';
import '../data/cashier_repository.dart';
import 'finance_common.dart';

/// «Платежи» — the till / payment queue. Lists open visits that still owe
/// money, lets the cashier take (and split) payments and shows the diagnostic
/// queue ticket on full settlement. Money math stays on the server.
class TillTab extends ConsumerStatefulWidget {
  const TillTab({super.key});

  @override
  ConsumerState<TillTab> createState() => _TillTabState();
}

class _TillTabState extends ConsumerState<TillTab> {
  int _offset = 0;

  /// Only visits with a positive outstanding balance belong on the till.
  static bool _owes(ReceptionVisit v) => (double.tryParse(v.balance) ?? 0) > 0;

  Future<void> _refresh() async {
    ref.invalidate(openVisitsProvider);
  }

  Future<void> _openPayment(ReceptionVisit visit) async {
    final result = await showDialog<PaymentResult>(
      context: context,
      builder: (_) => _TillPaymentDialog(visit: visit),
    );
    if (result == null || !mounted) return;
    // Refresh so the row drops off (paid in full) or shows the smaller balance
    // (split payment — the cashier can re-open it for the remainder).
    ref.invalidate(openVisitsProvider);
    final remaining = double.tryParse(result.visitBalance) ?? 0;
    if (remaining > 0) {
      showFinanceSnack(
        context,
        'Чек ${result.payment.receiptNo}: принято '
        '${formatMoney(result.payment.amount)}. '
        'Остаток: ${formatMoney(result.visitBalance)}',
      );
    } else {
      final ticket = result.queueTicketNumber;
      showFinanceSnack(
        context,
        ticket == null
            ? 'Оплачено полностью. Чек ${result.payment.receiptNo}.'
            : 'Оплачено полностью. Талон диагностики: $ticket',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(openVisitsProvider(_offset));

    return AsyncValueWidget<VisitPage>(
      value: page,
      onRetry: () => ref.invalidate(openVisitsProvider(_offset)),
      builder: (data) {
        final owing = data.items.where(_owes).toList();
        if (owing.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Нет визитов с задолженностью.')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: owing.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _TillRow(
                    visit: owing[i],
                    onPay: () => _openPayment(owing[i]),
                  ),
                ),
              ),
              if (data.total > data.limit)
                _pager(context, data),
            ],
          ),
        );
      },
    );
  }

  Widget _pager(BuildContext context, VisitPage data) {
    final fromN = data.offset + 1;
    final toN = data.offset + data.items.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$fromN–$toN из ${data.total}',
              style: Theme.of(context).textTheme.bodySmall),
          IconButton(
            tooltip: 'Назад',
            onPressed: data.offset == 0
                ? null
                : () => setState(() {
                      final prev = data.offset - data.limit;
                      _offset = prev < 0 ? 0 : prev;
                    }),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Вперёд',
            onPressed: toN >= data.total
                ? null
                : () => setState(() => _offset = data.offset + data.limit),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// One open visit on the till. Resolves the patient name lazily (cached), falls
/// back to the visit number while loading or if the lookup is denied.
class _TillRow extends ConsumerWidget {
  const _TillRow({required this.visit, required this.onPay});

  final ReceptionVisit visit;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = visit.patientId;
    final fallback = 'Визит ${visit.visitNo}';
    final title = patientId == null
        ? fallback
        : ref.watch(patientNameProvider(patientId)).maybeWhen(
            data: (n) => n,
            orElse: () => fallback,
          );
    final payable = visit.payable ?? visit.totalAmount;
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(title),
      subtitle: Text(
        'Визит ${visit.visitNo}  ·  К оплате ${formatMoney(payable)}'
        '  ·  Оплачено ${formatMoney(visit.paidAmount)}',
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Остаток',
              style: Theme.of(context).textTheme.bodySmall),
          Text(
            formatMoney(visit.balance),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      onTap: onPay,
    );
  }
}

const _tillMethods = <(String, String)>[
  ('cash', 'Наличные'),
  ('card', 'Карта'),
  ('qr', 'QR'),
  ('transfer', 'Перечисление'),
];

/// Payment dialog: amount (defaults to the balance) + method chips + Принять.
/// Mirrors reception's tender UX; on a partial payment the till row stays with
/// a smaller balance so the cashier can split across methods.
class _TillPaymentDialog extends ConsumerStatefulWidget {
  const _TillPaymentDialog({required this.visit});

  final ReceptionVisit visit;

  @override
  ConsumerState<_TillPaymentDialog> createState() => _TillPaymentDialogState();
}

class _TillPaymentDialogState extends ConsumerState<_TillPaymentDialog> {
  late final TextEditingController _amount =
      TextEditingController(text: widget.visit.balance);
  String _method = 'cash';
  bool _paying = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
  String get _normalizedAmount => _amount.text.trim().replaceAll(',', '.');

  bool get _canPay {
    if (_paying) return false;
    final amount = double.tryParse(_normalizedAmount);
    return amount != null && amount > 0;
  }

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final result = await ref.read(cashierRepositoryProvider).takePayment(
            visitId: widget.visit.id,
            amount: _normalizedAmount,
            method: _method,
          );
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    return AlertDialog(
      title: Text('Оплата · визит ${v.visitNo}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Остаток к оплате: ${formatMoney(v.balance)}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Сумма'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('Способ оплаты',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final (value, label) in _tillMethods)
                  ChoiceChip(
                    label: Text(label),
                    selected: _method == value,
                    onSelected: (_) => setState(() => _method = value),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _paying ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _canPay ? _pay : null,
          child: _paying
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Принять'),
        ),
      ],
    );
  }
}
