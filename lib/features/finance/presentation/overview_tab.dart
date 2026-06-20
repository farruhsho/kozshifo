import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../../reports/data/reports_repository.dart';
import '../../reports/domain/reports.dart';
import '../data/cashier_repository.dart';
import '../data/finance_repository.dart';
import '../domain/cash_report.dart';
import 'finance_common.dart';
import 'payroll_detail_screen.dart';

/// «Сводка» — финансовый дашборд за месяц: KPI (приход/расход/прибыль/долги),
/// круговая диаграмма приход↔расход, кликабельные срезы (прибыль по врачам,
/// расходы по статьям, должники). Виден при `expenses.read`; срезы директора
/// (прибыль по врачам, расходы по категориям) — при `reports.view`.
class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  late String _month = ym(DateTime.now());

  ReportRange get _range {
    final parts = _month.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return (from: DateTime(y, m, 1), to: DateTime(y, m + 1, 0));
  }

  Future<void> _refresh() async {
    ref.invalidate(monthlyReportProvider(_month));
    ref.invalidate(openVisitsProvider);
    ref.invalidate(financialReportProvider(_range));
    ref.invalidate(byDoctorReportProvider(_range));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final canReports = user?.can('reports.view') ?? false;
    final monthly = ref.watch(monthlyReportProvider(_month));

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Финансовая сводка',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              MonthSelector(
                  month: _month, onChanged: (m) => setState(() => _month = m)),
            ],
          ),
          const SizedBox(height: 12),
          AsyncValueWidget<MonthlyReport>(
            value: monthly,
            onRetry: () => ref.invalidate(monthlyReportProvider(_month)),
            builder: (r) => Column(
              children: [
                _kpiRow(context, r),
                const SizedBox(height: 16),
                _pieCard(context, r),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (canReports) ...[
            _profitByDoctorCard(context),
            const SizedBox(height: 16),
            _expensesByCategoryCard(context),
            const SizedBox(height: 16),
          ],
          _debtorsCard(context),
        ],
      ),
    );
  }

  // ── KPI cards ───────────────────────────────────────────────────────────

  Widget _kpiRow(BuildContext context, MonthlyReport r) {
    final netValue = double.tryParse(r.net) ?? 0;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _kpi(context, 'Приход', formatMoney(r.incomeTotal),
            Icons.south_west, Colors.green.shade700),
        _kpi(context, 'Расход', formatMoney(r.expenseTotal),
            Icons.north_east, Colors.orange.shade800),
        _kpi(context, 'Чистая прибыль', formatMoney(r.net), Icons.savings_outlined,
            netValue < 0 ? Theme.of(context).colorScheme.error : Colors.teal.shade700),
        _debtKpi(context),
      ],
    );
  }

  Widget _kpi(BuildContext context, String label, String value, IconData icon,
      Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _debtKpi(BuildContext context) {
    final debtors = ref.watch(openVisitsProvider(0));
    final value = debtors.maybeWhen(
      data: (page) {
        var sum = 0.0;
        for (final v in page.items) {
          sum += double.tryParse(v.balance) ?? 0;
        }
        final more = page.total > page.items.length ? '+' : '';
        return '${formatMoney(sum.toStringAsFixed(2))}$more';
      },
      orElse: () => '…',
    );
    return _kpi(context, 'Долги (насия)', value, Icons.timer_outlined,
        Colors.red.shade700);
  }

  // ── Pie chart: income vs expense ─────────────────────────────────────────

  Widget _pieCard(BuildContext context, MonthlyReport r) {
    final income = double.tryParse(r.incomeTotal) ?? 0;
    final expense = double.tryParse(r.expenseTotal) ?? 0;
    final hasData = income > 0 || expense > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Приход и расход',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Нет данных за месяц')),
              )
            else
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 48,
                          sections: [
                            PieChartSectionData(
                              value: income,
                              color: Colors.green.shade600,
                              title: '',
                              radius: 46,
                            ),
                            PieChartSectionData(
                              value: expense,
                              color: Colors.orange.shade700,
                              title: '',
                              radius: 46,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legend(context, Colors.green.shade600, 'Приход',
                              formatMoney(r.incomeTotal)),
                          const SizedBox(height: 10),
                          _legend(context, Colors.orange.shade700, 'Расход',
                              formatMoney(r.expenseTotal)),
                          const Divider(height: 20),
                          _legend(context, Colors.teal.shade700,
                              'Чистая прибыль', formatMoney(r.net)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Profit by doctor (reports.view) — clickable → salary detail ──────────

  Widget _profitByDoctorCard(BuildContext context) {
    final rows = ref.watch(byDoctorReportProvider(_range));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Прибыль по врачам',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncValueWidget<List<DoctorReportRow>>(
              value: rows,
              onRetry: () => ref.invalidate(byDoctorReportProvider(_range)),
              builder: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Нет данных за период'),
                  );
                }
                return Column(
                  children: [
                    for (final d in items)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(d.doctorName),
                        subtitle: Text(
                            'Выручка ${formatMoney(d.revenue)} · зарплата ${formatMoney(d.payrollExpense)}'),
                        trailing: Text(formatMoney(d.netProfit),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        // Кликабельно: детализация зарплаты врача за месяц.
                        onTap: d.doctorId == null
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PayrollDetailScreen(
                                      userId: d.doctorId!,
                                      fullName: d.doctorName,
                                      month: _month,
                                    ),
                                  ),
                                ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Expenses by category (reports.view) ──────────────────────────────────

  Widget _expensesByCategoryCard(BuildContext context) {
    final report = ref.watch(financialReportProvider(_range));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Расходы по статьям',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncValueWidget<FinancialReport>(
              value: report,
              onRetry: () => ref.invalidate(financialReportProvider(_range)),
              builder: (r) {
                if (r.byCategory.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Расходов за период нет'),
                  );
                }
                final maxValue = r.byCategory
                    .map((c) => double.tryParse(c.amount) ?? 0)
                    .fold<double>(0, (a, b) => b > a ? b : a);
                return Column(
                  children: [
                    for (final c in r.byCategory)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(c.label)),
                                Text(formatMoney(c.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: maxValue <= 0
                                    ? 0
                                    : (double.tryParse(c.amount) ?? 0) /
                                        maxValue,
                                minHeight: 7,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Debtors (nasiya) — clickable → patient card ──────────────────────────

  Widget _debtorsCard(BuildContext context) {
    final debtors = ref.watch(openVisitsProvider(0));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Должники (насия)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncValueWidget<VisitPage>(
              value: debtors,
              onRetry: () => ref.invalidate(openVisitsProvider(0)),
              builder: (page) {
                if (page.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Нет визитов с задолженностью.'),
                  );
                }
                final items = [...page.items]
                  ..sort((a, b) => (double.tryParse(b.balance) ?? 0)
                      .compareTo(double.tryParse(a.balance) ?? 0));
                final top = items.take(8).toList();
                return Column(
                  children: [
                    for (final v in top)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: _DebtorName(visitNo: v.visitNo, patientId: v.patientId),
                        trailing: Text(formatMoney(v.balance),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.error)),
                        onTap: v.patientId == null
                            ? null
                            : () => context.push('/patients/${v.patientId}/card'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolves and caches the debtor's patient name; falls back to the visit no.
class _DebtorName extends ConsumerWidget {
  const _DebtorName({required this.visitNo, required this.patientId});

  final String visitNo;
  final String? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (patientId == null) return Text(visitNo);
    final name = ref.watch(patientNameProvider(patientId!));
    return Text(name.maybeWhen(data: (n) => n, orElse: () => visitNo));
  }
}
