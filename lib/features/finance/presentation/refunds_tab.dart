import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/cashier_repository.dart';
import '../domain/till_payment.dart';
import 'finance_common.dart';

const _methodLabels = <String, String>{
  'cash': 'Наличные',
  'card': 'Карта',
  'qr': 'QR',
  'transfer': 'Перечисление',
};

/// «Возвраты» — payment history (newest first), each row patient/amount/
/// method/time, with a guarded «Возврат» action (gated `payments.refund`).
/// Refunded rows carry a chip. Refund is sensitive — a confirm dialog gates it.
class RefundsTab extends ConsumerStatefulWidget {
  const RefundsTab({super.key});

  @override
  ConsumerState<RefundsTab> createState() => _RefundsTabState();
}

class _RefundsTabState extends ConsumerState<RefundsTab> {
  int _offset = 0;

  TillPaymentQuery _query(String? branchId) =>
      (branchId: branchId, offset: _offset);

  Future<void> _refund(TillPayment p, String? branchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Оформить возврат?'),
        content: Text(
            'Чек ${p.receiptNo} · ${formatMoney(p.amount)} '
            '(${_methodLabels[p.method] ?? p.method}). '
            'Возврат уменьшит оплату по визиту и не отменяется.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Вернуть'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(cashierRepositoryProvider).refund(p.id);
      ref.invalidate(tillPaymentsProvider);
      // The till balance changes after a refund — keep it in sync.
      ref.invalidate(openVisitsProvider);
      if (mounted) showFinanceSnack(context, 'Возврат по чеку ${p.receiptNo} оформлен');
    } catch (e) {
      if (mounted) showFinanceSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final branchId = user?.branchId;
    final canRefund = user?.can('payments.refund') ?? false;
    final page = ref.watch(tillPaymentsProvider(_query(branchId)));

    return AsyncValueWidget<TillPaymentPage>(
      value: page,
      onRetry: () => ref.invalidate(tillPaymentsProvider(_query(branchId))),
      builder: (data) {
        if (data.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tillPaymentsProvider),
            child: ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Платежей пока нет.')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tillPaymentsProvider),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _PaymentRow(
                    payment: data.items[i],
                    canRefund: canRefund,
                    onRefund: () => _refund(data.items[i], branchId),
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

  Widget _pager(BuildContext context, TillPaymentPage data) {
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

/// One receipt: patient name (lazily resolved), amount/method/local time, a
/// refunded chip or a «Возврат» button.
class _PaymentRow extends ConsumerWidget {
  const _PaymentRow({
    required this.payment,
    required this.canRefund,
    required this.onRefund,
  });

  final TillPayment payment;
  final bool canRefund;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(patientNameProvider(payment.patientId));
    final title = name.maybeWhen(
      data: (n) => n,
      orElse: () => 'Чек ${payment.receiptNo}',
    );
    final method = _methodLabels[payment.method] ?? payment.method;
    return ListTile(
      leading: Icon(
        payment.isRefunded ? Icons.undo : Icons.receipt_long_outlined,
        color: payment.isRefunded
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(
        'Чек ${payment.receiptNo}  ·  $method  ·  '
        '${ddMMHHmmLocal(payment.createdAt)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMoney(payment.amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration:
                      payment.isRefunded ? TextDecoration.lineThrough : null,
                ),
          ),
          const SizedBox(width: 8),
          if (payment.isRefunded)
            Chip(
              visualDensity: VisualDensity.compact,
              label: const Text('Возврат'),
              backgroundColor:
                  Theme.of(context).colorScheme.errorContainer,
            )
          else if (canRefund)
            // Plain TextButton (not .icon, which is a private subtype) so the
            // label sits under the exact TextButton type.
            TextButton(
              onPressed: onRefund,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.undo, size: 18),
                  SizedBox(width: 4),
                  Text('Возврат'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
