import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/finance_repository.dart';
import '../domain/cash_report.dart';
import 'finance_common.dart';

/// «Касса»: отчёт за день (приход по методам, возвраты, расходы, итог)
/// + сводка за месяц с строкой «Зарплата». CSV — дневной отчёт.
class CashTab extends ConsumerStatefulWidget {
  const CashTab({super.key});

  @override
  ConsumerState<CashTab> createState() => _CashTabState();
}

class _CashTabState extends ConsumerState<CashTab> {
  DateTime _day = DateTime.now();
  late String _month = ym(DateTime.now());
  bool _exporting = false;

  String get _dayKey => ymd(_day);

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _exportDailyCsv() async {
    setState(() => _exporting = true);
    try {
      final bytes =
          await ref.read(financeRepositoryProvider).dailyReportCsv(_dayKey);
      if (mounted) await saveCsv(context, bytes, 'daily-$_dayKey.csv');
    } catch (e) {
      if (mounted) showFinanceSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(dailyReportProvider(_dayKey));
    ref.invalidate(monthlyReportProvider(_month));
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyReportProvider(_dayKey));
    final monthly = ref.watch(monthlyReportProvider(_month));

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Отчёт за день',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              OutlinedButton.icon(
                onPressed: _pickDay,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(ddMMyyyy(_dayKey)),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Скачать CSV за день',
                onPressed: _exporting ? null : _exportDailyCsv,
                icon: _exporting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AsyncValueWidget<DailyReport>(
            value: daily,
            onRetry: () => ref.invalidate(dailyReportProvider(_dayKey)),
            builder: (r) => _ReportCard(
              incomeByMethod: r.incomeByMethod,
              incomeTotal: r.incomeTotal,
              refundTotal: r.refundTotal,
              expenseTotal: r.expenseTotal,
              net: r.net,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Сводка за месяц',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              MonthSelector(
                month: _month,
                onChanged: (m) => setState(() => _month = m),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AsyncValueWidget<MonthlyReport>(
            value: monthly,
            onRetry: () => ref.invalidate(monthlyReportProvider(_month)),
            builder: (r) => _ReportCard(
              incomeByMethod: r.incomeByMethod,
              incomeTotal: r.incomeTotal,
              refundTotal: r.refundTotal,
              expenseTotal: r.expenseTotal,
              net: r.net,
              payrollTotal: r.payrollTotal,
            ),
          ),
        ],
      ),
    );
  }
}

const _methodLabels = <String, String>{
  'cash': 'Наличные',
  'card': 'Карта',
  'qr': 'QR',
  'transfer': 'Перевод',
};

/// Денежная сводка: методы оплаты → приход/возвраты/расходы → итог.
class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.incomeByMethod,
    required this.incomeTotal,
    required this.refundTotal,
    required this.expenseTotal,
    required this.net,
    this.payrollTotal,
  });

  final Map<String, String> incomeByMethod;
  final String incomeTotal;
  final String refundTotal;
  final String expenseTotal;
  final String net;
  final String? payrollTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final netValue = double.tryParse(net) ?? 0;
    final netColor = netValue < 0 ? scheme.error : Colors.green.shade700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Канонические четыре метода — порядок фиксированный.
            for (final entry in _methodLabels.entries)
              _row(context, entry.value, incomeByMethod[entry.key] ?? '0.00'),
            const Divider(),
            _row(context, 'Приход', incomeTotal),
            _row(context, 'Возвраты', refundTotal),
            _row(context, 'Расходы', expenseTotal),
            if (payrollTotal != null)
              _row(context, 'Зарплата (в составе расходов)', payrollTotal!,
                  muted: true),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Итог',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Text(formatMoney(net),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.bold, color: netColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String amount,
      {bool muted = false}) {
    final style = muted
        ? Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).hintColor)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(formatMoney(amount), style: style),
        ],
      ),
    );
  }
}
