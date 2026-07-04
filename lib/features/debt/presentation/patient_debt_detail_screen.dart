import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/debt_repository.dart';
import '../domain/patient_debt_detail.dart';

final _date = DateFormat('dd.MM.yyyy');
final _dateTime = DateFormat('dd.MM.yyyy HH:mm');

String _fmtDate(String iso) {
  final dt = DateTime.tryParse(iso);
  return dt == null ? iso : _date.format(dt.toLocal());
}

String _fmtDateTime(String iso) {
  final dt = DateTime.tryParse(iso);
  return dt == null ? iso : _dateTime.format(dt.toLocal());
}

const _methodLabels = {
  'cash': 'Наличные',
  'card': 'Карта',
  'qr': 'QR',
  'transfer': 'Перевод',
};

/// Детализация долга пациента: шапка с итоговым долгом, долги по визитам
/// (с кнопкой «Погасить») и история оплат.
class PatientDebtDetailScreen extends ConsumerWidget {
  const PatientDebtDetailScreen({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(patientDebtProvider(patientId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Долг пациента'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(patientDebtProvider(patientId)),
          ),
        ],
      ),
      body: AsyncValueWidget<PatientDebtDetail>(
        value: detail,
        onRetry: () => ref.invalidate(patientDebtProvider(patientId)),
        builder: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(detail: data),
            const SizedBox(height: 20),
            Text('Долги по визитам',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (data.visits.isEmpty)
              const _EmptyHint('Нет визитов с долгом')
            else
              for (final v in data.visits)
                _VisitDebtCard(patientId: patientId, visit: v),
            const SizedBox(height: 24),
            Text('История оплат',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (data.payments.isEmpty)
              const _EmptyHint('Оплат пока не было')
            else
              for (final p in data.payments) _PaymentTile(payment: p),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final PatientDebtDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail.patientName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (detail.phone != null && detail.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(detail.phone!,
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Общий долг',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(formatMoney(detail.totalDebt),
                    style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitDebtCard extends ConsumerWidget {
  const _VisitDebtCard({required this.patientId, required this.visit});

  final String patientId;
  final DebtVisitRow visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final canPay =
        ref.watch(authControllerProvider).user?.can('payments.create') ??
            false;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${visit.visitNo}  ·  ${_fmtDate(visit.openedAt)}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(formatMoney(visit.remaining),
                    style: TextStyle(
                        color: scheme.error, fontWeight: FontWeight.bold)),
              ],
            ),
            if (visit.services.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(visit.services,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
            if (canPay) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Погасить'),
                  onPressed: () => _openRepayDialog(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openRepayDialog(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _RepayDialog(visit: visit),
    );
    if (ok != true || !context.mounted) return;
    ref.invalidate(patientDebtProvider(patientId));
    ref.invalidate(debtorsProvider);
    ref.invalidate(topDebtorsProvider);
  }
}

/// Диалог частичного погашения: сумма (предзаполнена остатком, >0 и ≤ остаток),
/// способ оплаты, комментарий. На успехе закрывается с `true`.
class _RepayDialog extends ConsumerStatefulWidget {
  const _RepayDialog({required this.visit});

  final DebtVisitRow visit;

  @override
  ConsumerState<_RepayDialog> createState() => _RepayDialogState();
}

class _RepayDialogState extends ConsumerState<_RepayDialog> {
  late final TextEditingController _amount =
      TextEditingController(text: widget.visit.remaining);
  final _note = TextEditingController();
  String _method = 'cash';
  bool _busy = false;

  late final double _remaining =
      double.tryParse(widget.visit.remaining) ?? 0;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _validate() {
    final v = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return 'Введите сумму больше 0';
    if (v > _remaining + 0.0001) {
      return 'Сумма не больше остатка ${formatMoney(widget.visit.remaining)}';
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _busy = true);
    final amount = _amount.text.trim().replaceAll(',', '.');
    try {
      await ref.read(debtRepositoryProvider).repay(
            visitId: widget.visit.visitId,
            amount: amount,
            method: _method,
            note: _note.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Оплата принята')));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Погасить ${widget.visit.visitNo}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Остаток: ${formatMoney(widget.visit.remaining)}',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Сумма',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(
              labelText: 'Способ оплаты',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final e in _methodLabels.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: _busy
                ? null
                : (v) => setState(() => _method = v ?? 'cash'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Комментарий (необязательно)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Принять оплату'),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final DebtPaymentRow payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final refunded = payment.status == 'refunded';
    final method = _methodLabels[payment.method] ?? payment.method;
    final subtitle = <String>[
      method,
      if (payment.cashierName != null && payment.cashierName!.isNotEmpty)
        payment.cashierName!,
      if (payment.note != null && payment.note!.isNotEmpty) payment.note!,
    ].join('  ·  ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(
          refunded ? Icons.undo : Icons.check_circle_outline,
          color: refunded ? scheme.error : AppColors.green,
        ),
        title: Text(_fmtDateTime(payment.paidAt)),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(payment.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: refunded ? scheme.error : null,
                decoration: refunded ? TextDecoration.lineThrough : null,
              ),
            ),
            if (refunded)
              Text('возврат',
                  style: TextStyle(color: scheme.error, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(text, style: const TextStyle(color: AppColors.muted)),
        ),
      ),
    );
  }
}
