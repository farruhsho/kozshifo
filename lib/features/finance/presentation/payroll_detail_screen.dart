import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/file_saver.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/finance_repository.dart';
import '../domain/payroll_detail.dart';
import 'finance_common.dart';

/// Детализация зарплаты врача за месяц: по дням и пациентам, секция операций,
/// итоги. Кнопка «Печать» открывает серверный PDF (как чек). Требует
/// `payroll.read` (экран открывается только из мест за этой стеной).
class PayrollDetailScreen extends ConsumerStatefulWidget {
  const PayrollDetailScreen({
    super.key,
    required this.userId,
    required this.fullName,
    required this.month,
  });

  final String userId;
  final String fullName;
  final String month; // YYYY-MM

  @override
  ConsumerState<PayrollDetailScreen> createState() =>
      _PayrollDetailScreenState();
}

class _PayrollDetailScreenState extends ConsumerState<PayrollDetailScreen> {
  bool _printing = false;

  PayrollDetailKey get _key => (userId: widget.userId, month: widget.month);

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      final bytes = await ref
          .read(financeRepositoryProvider)
          .payrollDetailPdf(widget.userId, widget.month);
      await printBytes(
          bytes, 'payroll-${widget.userId}-${widget.month}.pdf', 'application/pdf');
    } catch (e) {
      if (mounted) showFinanceSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(payrollDetailProvider(_key));
    return Scaffold(
      appBar: AppBar(
        title: Text('Зарплата · ${widget.fullName}'),
        actions: [
          IconButton(
            tooltip: 'Печать (PDF)',
            onPressed: _printing ? null : _print,
            icon: _printing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print_outlined),
          ),
        ],
      ),
      body: AsyncValueWidget<PayrollDetail>(
        value: detail,
        onRetry: () => ref.invalidate(payrollDetailProvider(_key)),
        builder: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(context, d),
            const SizedBox(height: 16),
            Text('Приём (по дням)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (d.days.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Платежей за приём в этом месяце нет.'),
              ),
            for (final day in d.days) _dayCard(context, day),
            if (d.operations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Операции', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _operationsCard(context, d),
            ],
            const SizedBox(height: 16),
            _totalsCard(context, d),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, PayrollDetail d) {
    String rule(String? type, String? value, {bool perOp = false}) {
      if (type == null) return '—';
      if (type == 'percent') return '$value%';
      return perOp ? '${formatMoney(value)} / операция' : '${formatMoney(value)} / мес';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(monthLabel(d.month),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _kv(context, 'Оплата за приём',
                rule(d.consultSalaryType, d.consultSalaryValue)),
            _kv(context, 'Оплата за операции',
                rule(d.operationSalaryType, d.operationSalaryValue, perOp: true)),
          ],
        ),
      ),
    );
  }

  Widget _dayCard(BuildContext context, PayrollDetailDay day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(ddMMyyyy(day.date),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text('${formatMoney(day.revenue)} → ${formatMoney(day.share)}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 14),
            for (var i = 0; i < day.patients.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text('${i + 1}. ${day.patients[i].patientName}')),
                    Text(formatMoney(day.patients[i].amount)),
                    if (day.patients[i].share != '0.00') ...[
                      const Text('  →  '),
                      Text(formatMoney(day.patients[i].share),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _operationsCard(BuildContext context, PayrollDetail d) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < d.operations.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${i + 1}. ${ddMMyyyy(d.operations[i].date)} · '
                          '${d.operations[i].patientName} · ${d.operations[i].typeName}'),
                    ),
                    Text('${formatMoney(d.operations[i].price)} → '
                        '${formatMoney(d.operations[i].share)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _totalsCard(BuildContext context, PayrollDetail d) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _kv(context, 'Выручка с приёма', formatMoney(d.consultRevenue)),
            _kv(context, 'Начислено за приём', formatMoney(d.consultPay)),
            _kv(context, 'Выручка с операций',
                '${formatMoney(d.operationRevenue)} (${d.operationCount} шт.)'),
            _kv(context, 'Начислено за операции', formatMoney(d.operationPay)),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Text('ИТОГО К ВЫПЛАТЕ',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Text(formatMoney(d.salary),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodyMedium)),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}
