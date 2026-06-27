import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../debt/data/debt_repository.dart';
import '../../debt/domain/debtor_row.dart';
import '../../reception/data/reception_repository.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import '../domain/director_analytics.dart';
import '../domain/finance_by_direction.dart';
import '../domain/hanging_visit.dart';
import '../domain/insight.dart';
import '../domain/lead_source.dart';
import '../domain/period_summary.dart';
import '../domain/region_report.dart';
import '../domain/revenue_trend.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд директора'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(insightsProvider);
              ref.invalidate(revenueTrendProvider);
              ref.invalidate(leadSourcesProvider);
              ref.invalidate(patientsByRegionProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AsyncValueWidget<DashboardSummary>(
        value: summary,
        onRetry: () => ref.invalidate(dashboardSummaryProvider),
        builder: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(insightsProvider);
            ref.invalidate(revenueTrendProvider);
            ref.invalidate(leadSourcesProvider);
            ref.invalidate(patientsByRegionProvider);
            ref.invalidate(revenueByDoctorProvider);
            ref.invalidate(operationsSummaryProvider);
            ref.invalidate(expenseBreakdownProvider);
            ref.invalidate(regionTrendProvider);
            ref.invalidate(patientsByDistrictProvider);
            ref.invalidate(financeByDirectionProvider);
            ref.invalidate(hangingVisitsProvider);
            ref.invalidate(periodSummaryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _InsightsPanel(),
                const _HangingVisitsPanel(),
                const SizedBox(height: 20),
                _KpiGrid(data: data),
                const _PeriodSummaryPanel(),
                const _TopDebtorsPanel(),
                const _FinanceByDirectionPanel(),
                const _RevenueTrendPanel(),
                const _ExpenseBreakdownPanel(),
                const _OperationsFunnelPanel(),
                const _RevenueByDoctorPanel(),
                const _LeadSourcesPanel(),
                const _RegionsPanel(),
                const _RegionTrendPanel(),
                const _DistrictsPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Что требует внимания» — авто-инсайты движка самоконтроля клиники.
/// Пустой список — хороший день: показываем зелёную карточку-успокоение.
class _InsightsPanel extends ConsumerWidget {
  const _InsightsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Что требует внимания',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        AsyncValueWidget<List<Insight>>(
          value: insights,
          onRetry: () => ref.invalidate(insightsProvider),
          builder: (items) {
            if (items.isEmpty) {
              return Card(
                color: AppColors.greenBg,
                child: const ListTile(
                  leading: Icon(Icons.check_circle_outline, color: AppColors.green),
                  title: Text('Всё в порядке — критичных сигналов нет',
                      style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final i in items) _InsightCard(insight: i),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color) = insight.isCritical
        ? (Icons.error_outline, scheme.error)
        : insight.isWarning
            ? (Icons.warning_amber_outlined, AppColors.amber)
            : (Icons.info_outline, AppColors.blue);
    final chip = insight.value == null
        ? null
        : Chip(
            label: Text(insight.value!,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          );
    final clickable = insight.route != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        // Кликабельное уведомление: ведёт сразу к проблемному разделу.
        onTap: clickable ? () => context.go(insight.route!) : null,
        leading: Icon(icon, color: color),
        title: Text(insight.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(insight.detail),
        trailing: !clickable
            ? chip
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?chip,
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
      ),
    );
  }
}

/// «Зависшие визиты» — 5 категорий застрявших случаев с конкретными
/// пациентами (owner brief 2026-06-20). Самоочищается: когда проблема решена,
/// визит пропадает. Панель скрыта, если зависших нет (или пока грузится/ошибка).
class _HangingVisitsPanel extends ConsumerWidget {
  const _HangingVisitsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(hangingVisitsProvider).maybeWhen(
          data: (categories) {
            if (categories.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text('Зависшие визиты',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                for (final c in categories) _HangingCategoryCard(category: c),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _HangingCategoryCard extends ConsumerWidget {
  const _HangingCategoryCard({required this.category});

  final HangingCategory category;

  /// C6 — settle a stale, never-progressed visit (patient registered but left,
  /// no doctor) right from the panel, instead of opening the card. cancel_visit
  /// only allows UNPAID open visits, so a paid one surfaces its 409.
  Future<void> _cancel(
      BuildContext context, WidgetRef ref, HangingVisitRow v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отменить визит?'),
        content: Text('Визит ${v.visitNo} · ${v.patientName} будет отменён. '
            'Это допустимо только для неоплаченного визита.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Нет')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Отменить визит')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(receptionRepositoryProvider).cancelVisit(v.visitId);
      ref.invalidate(hangingVisitsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Визит ${v.visitNo} отменён')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        category.isCritical ? Theme.of(context).colorScheme.error : AppColors.amber;
    final extra = category.count - category.visits.length;
    // Only the «никто не ведёт» (registered/awaiting/diagnostic) cases are safe to
    // abort inline; other categories need real follow-up, not cancellation.
    final canCancel = category.category == 'no_doctor' &&
        (ref.watch(authControllerProvider).user?.can('visits.update') ?? false);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
            category.isCritical
                ? Icons.error_outline
                : Icons.warning_amber_outlined,
            color: color),
        title: Text(category.label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Chip(
          label: Text('${category.count}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        children: [
          for (final v in category.visits)
            ListTile(
              dense: true,
              title: Text(v.patientName),
              subtitle: Text(v.detail),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canCancel)
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, size: 20),
                      tooltip: 'Отменить визит',
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _cancel(context, ref, v),
                    ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              // Тап ведёт прямо в медкарту пациента, чтобы закрыть проблему.
              onTap: () => context.go('/patients/${v.patientId}/card'),
            ),
          if (extra > 0)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('… и ещё $extra',
                  style: const TextStyle(color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

/// «Сводка за период» — единый фильтр периода (owner brief 2026-06-20):
/// Сегодня/Вчера/Неделя/Месяц/Квартал/Год/Произвольный. Метрики (выручка,
/// расход, прибыль, пациенты, визиты, операции, диагностика, лечение)
/// автоматически пересчитываются при смене периода.
class _PeriodSummaryPanel extends ConsumerStatefulWidget {
  const _PeriodSummaryPanel();

  @override
  ConsumerState<_PeriodSummaryPanel> createState() =>
      _PeriodSummaryPanelState();
}

class _PeriodSummaryPanelState extends ConsumerState<_PeriodSummaryPanel> {
  String _period = 'month';
  DateTimeRange? _range;

  static const _presets = <(String, String)>[
    ('today', 'Сегодня'), ('yesterday', 'Вчера'), ('week', 'Неделя'),
    ('month', 'Месяц'), ('quarter', 'Квартал'), ('year', 'Год'),
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
  static String _ru(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

  PeriodQuery get _query => _period == 'custom' && _range != null
      ? (period: 'custom', from: _iso(_range!.start), to: _iso(_range!.end))
      : (period: _period, from: null, to: null);

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _period = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Сводка за период',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _presets)
                ChoiceChip(
                  label: Text(p.$2),
                  selected: _period == p.$1,
                  onSelected: (_) => setState(() => _period = p.$1),
                ),
              ChoiceChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(_period == 'custom' && _range != null
                    ? '${_ru(_range!.start)} — ${_ru(_range!.end)}'
                    : 'Период'),
                selected: _period == 'custom',
                onSelected: (_) => _pickRange(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AsyncValueWidget<PeriodSummary>(
            value: ref.watch(periodSummaryProvider(_query)),
            onRetry: () => ref.invalidate(periodSummaryProvider(_query)),
            builder: _metrics,
          ),
        ],
      ),
    );
  }

  Widget _metrics(PeriodSummary s) {
    final tiles = <(String, String)>[
      ('Выручка', formatMoney(s.revenue)),
      ('Расход', formatMoney(s.expenses)),
      ('Прибыль', formatMoney(s.profit)),
      ('Пациенты', '${s.newPatients}'),
      ('Визиты', '${s.visits}'),
      ('Операции', '${s.operations}'),
      ('Диагностика', '${s.diagnostics}'),
      ('Лечение', '${s.treatments}'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final t in tiles) _PeriodMetricTile(label: t.$1, value: t.$2),
      ],
    );
  }
}

class _PeriodMetricTile extends StatelessWidget {
  const _PeriodMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// «ТОП должников» — топ-5 пациентов с самым крупным долгом. Использует
/// maybeWhen→SizedBox.shrink (без спиннера / AsyncValueWidget), чтобы панель
/// никогда не блокировала pumpAndSettle в виджет-тестах и тихо скрывалась у
/// пользователей без debts.read (провайдер вернёт ошибку → shrink).
class _TopDebtorsPanel extends ConsumerWidget {
  const _TopDebtorsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(topDebtorsProvider).maybeWhen(
          data: (rows) {
            if (rows.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text('ТОП должников',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => context.go('/debts'),
                      child: const Text('Все долги'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Card(
                  child: Column(
                    children: [for (final r in rows) _TopDebtorRow(row: r)],
                  ),
                ),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _TopDebtorRow extends StatelessWidget {
  const _TopDebtorRow({required this.row});

  final DebtorRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      onTap: () => context.go('/debts/${row.patientId}'),
      title: Text(row.patientName, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        formatMoney(row.totalDebt),
        style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// «Финансы по направлениям» — Доход/Расход/Прибыль по 4 направлениям
/// (приём/диагностика/лечение/операции) + итог за день/неделю/месяц/год.
class _FinanceByDirectionPanel extends ConsumerStatefulWidget {
  const _FinanceByDirectionPanel();

  @override
  ConsumerState<_FinanceByDirectionPanel> createState() =>
      _FinanceByDirectionPanelState();
}

class _FinanceByDirectionPanelState
    extends ConsumerState<_FinanceByDirectionPanel> {
  String _period = 'month';
  static const _labels = {
    'day': 'День',
    'week': 'Неделя',
    'month': 'Месяц',
    'year': 'Год',
  };

  Widget _row(String a, String b, String c, String d,
      {bool header = false, bool bold = false}) {
    final style = header
        ? TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).hintColor,
            fontSize: 12)
        : (bold ? const TextStyle(fontWeight: FontWeight.bold) : null);
    Widget cell(String t, {int flex = 3, TextAlign align = TextAlign.right}) =>
        Expanded(flex: flex, child: Text(t, style: style, textAlign: align));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        cell(a, flex: 4, align: TextAlign.left),
        cell(b),
        cell(c),
        cell(d),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(financeByDirectionProvider(_period));
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Финансы по направлениям',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: [
                for (final e in _labels.entries)
                  ButtonSegment(value: e.key, label: Text(e.value)),
              ],
              selected: {_period},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
          ),
          const SizedBox(height: 12),
          AsyncValueWidget<FinanceByDirection>(
            value: report,
            onRetry: () => ref.invalidate(financeByDirectionProvider(_period)),
            builder: (r) => Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    _row('Направление', 'Доход', 'Расход', 'Прибыль',
                        header: true),
                    const Divider(height: 8),
                    for (final d in r.rows)
                      _row(d.label, formatMoney(d.revenue),
                          formatMoney(d.expense), formatMoney(d.profit)),
                    const Divider(height: 8),
                    _row('Итого по клинике', formatMoney(r.totalRevenue),
                        formatMoney(r.totalExpense), formatMoney(r.totalProfit),
                        bold: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final DashboardSummary data;

  @override
  Widget build(BuildContext context) {
    void go(String r) => context.go(r);
    final cards = <Widget>[
      KpiCard(label: 'Выручка сегодня', value: formatMoney(data.revenueToday),
          iconKey: 'finance', accent: true, onTap: () => go('/finance')),
      KpiCard(label: 'Расходы сегодня', value: formatMoney(data.expensesToday),
          iconKey: 'finance', onTap: () => go('/finance')),
      KpiCard(label: 'Прибыль сегодня', value: formatMoney(data.profitToday),
          iconKey: 'analytics', accent: true),
      KpiCard(label: 'Выручка за месяц', value: formatMoney(data.revenueMonth),
          iconKey: 'schedule', onTap: () => go('/finance')),
      KpiCard(label: 'Прибыль за месяц', value: formatMoney(data.profitMonth),
          iconKey: 'analytics'),
      KpiCard(label: 'Средний чек', value: formatMoney(data.averageCheckToday),
          iconKey: 'analytics'),
      KpiCard(label: 'Оплат сегодня', value: formatInt(data.paymentsToday),
          iconKey: 'finance', onTap: () => go('/finance')),
      KpiCard(label: 'Визитов сегодня', value: formatInt(data.visitsToday),
          iconKey: 'reception'),
      KpiCard(label: 'Новых сегодня', value: formatInt(data.newPatientsToday),
          iconKey: 'patients', onTap: () => go('/patients')),
      KpiCard(label: 'Повторных сегодня', value: formatInt(data.returningToday),
          iconKey: 'patients', onTap: () => go('/patients')),
      KpiCard(label: 'Пациентов за неделю', value: formatInt(data.newPatientsWeek),
          iconKey: 'patients', onTap: () => go('/patients')),
      KpiCard(label: 'Пациентов за месяц', value: formatInt(data.newPatientsMonth),
          iconKey: 'patients', onTap: () => go('/patients')),
      KpiCard(label: 'Всего пациентов', value: formatInt(data.patientsTotal),
          iconKey: 'patients', onTap: () => go('/patients')),
      KpiCard(label: 'В очереди', value: formatInt(data.queueWaiting),
          iconKey: 'queue', onTap: () => go('/queue')),
      KpiCard(label: 'Операций назначено', value: formatInt(data.operationsScheduledToday),
          iconKey: 'worklist', onTap: () => go('/operations')),
      KpiCard(label: 'Операций сегодня', value: formatInt(data.operationsToday),
          iconKey: 'worklist', onTap: () => go('/operations')),
      KpiCard(label: 'Операций за месяц', value: formatInt(data.operationsMonth),
          iconKey: 'worklist', onTap: () => go('/operations')),
      KpiCard(label: 'Дефицит склада', value: formatInt(data.lowStockCount),
          iconKey: 'inventory', onTap: () => go('/inventory')),
      KpiCard(label: 'Партии: срок ≤30 дней', value: formatInt(data.expiringSoonCount),
          iconKey: 'inventory', onTap: () => go('/inventory')),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 250).floor().clamp(1, 4);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.55,
          children: cards,
        );
      },
    );
  }
}

/// «Выручка (14 дней)» — тренд завершённой выручки по локальным дням
/// линией fl_chart. Видно только директору (право `dashboard.view`).
class _RevenueTrendPanel extends ConsumerWidget {
  const _RevenueTrendPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (!(user?.can('dashboard.view') ?? false)) {
      return const SizedBox.shrink();
    }
    final trend = ref.watch(revenueTrendProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Text('Выручка (14 дней)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        AsyncValueWidget<RevenueTrend>(
          value: trend,
          onRetry: () => ref.invalidate(revenueTrendProvider),
          builder: (data) => Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: data.isEmpty
                  ? const _RevenueTrendEmpty()
                  : SizedBox(
                      height: 160,
                      child: _RevenueLineChart(points: data.points),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RevenueTrendEmpty extends StatelessWidget {
  const _RevenueTrendEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.show_chart_outlined,
            color: scheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Text('Пока нет выручки',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7))),
      ],
    );
  }
}

/// Линия тренда выручки: x — индекс точки (0..n-1), y — выручка дня.
/// Скрыты сетка/рамка/левые-правые-верхние оси; снизу — каждая ~Nя метка
/// `dd.MM`, чтобы подписи не наезжали друг на друга.
class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({required this.points});

  final List<RevenuePoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = points.length;
    // Показать ~5 подписей по оси X — каждая step-я точка (но не реже 1).
    final step = (n / 5).ceil().clamp(1, n);
    final spots = <FlSpot>[
      for (var i = 0; i < n; i++)
        FlSpot(i.toDouble(), points[i].revenueValue),
    ];
    return LineChart(
      LineChartData(
        minY: 0,
        minX: 0,
        maxX: (n - 1).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                // Только каждая step-я точка (плюс самая последняя).
                if (i < 0 || i >= n) return const SizedBox.shrink();
                if (i % step != 0 && i != n - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[i].dayLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6))),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Источники пациентов» — откуда пришли пациенты за текущий месяц.
/// Видно только директору (право `dashboard.view`). Чистые виджеты —
/// горизонтальные полоски с количеством и долей, без chart-пакетов.
class _LeadSourcesPanel extends ConsumerWidget {
  const _LeadSourcesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (!(user?.can('dashboard.view') ?? false)) {
      return const SizedBox.shrink();
    }
    final report = ref.watch(leadSourcesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Text('Источники пациентов',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        AsyncValueWidget<LeadSourceReport>(
          value: report,
          onRetry: () => ref.invalidate(leadSourcesProvider),
          builder: (data) => Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: data.isEmpty
                  ? const _LeadSourcesEmpty()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final s in data.sources)
                          _LeadSourceBar(stat: s, total: data.total),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeadSourcesEmpty extends StatelessWidget {
  const _LeadSourcesEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.insights_outlined,
            color: scheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Text('Пока нет данных',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7))),
      ],
    );
  }
}

/// Одна полоска канала: метка, доля (заливка), количество и процент.
class _LeadSourceBar extends StatelessWidget {
  const _LeadSourceBar({required this.stat, required this.total});

  final LeadSourceStat stat;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = total <= 0 ? 0.0 : stat.count / total;
    final percent = (fraction * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(width: 8),
              Text('${formatInt(stat.count)} · $percent%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.75))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Пациенты по регионам» — география базы с разбивкой новые/посещавшие,
/// чтобы директор видел, где запускать рекламу. Видно только директору
/// (право `dashboard.view`). Чистые виджеты — сегментированные полоски.
class _RegionsPanel extends ConsumerWidget {
  const _RegionsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (!(user?.can('dashboard.view') ?? false)) {
      return const SizedBox.shrink();
    }
    final report = ref.watch(patientsByRegionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text('Пациенты по регионам',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const _RegionLegend(),
          ],
        ),
        const SizedBox(height: 12),
        AsyncValueWidget<RegionReport>(
          value: report,
          onRetry: () => ref.invalidate(patientsByRegionProvider),
          builder: (data) => Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: data.isEmpty
                  ? const _RegionsEmpty()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final r in data.regions)
                          _RegionBar(stat: r),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Легенда сегментов: «Новые» (акцент) / «Посещавшие» (приглушённый).
class _RegionLegend extends StatelessWidget {
  const _RegionLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 5),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(scheme.primary, 'Новые'),
        const SizedBox(width: 12),
        dot(AppColors.muted, 'Посещавшие'),
      ],
    );
  }
}

class _RegionsEmpty extends StatelessWidget {
  const _RegionsEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.public_outlined,
            color: scheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Text('Пока нет данных',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7))),
      ],
    );
  }
}

/// Одна полоска региона: метка, всего, и сегментированная заливка
/// новые (акцент) | посещавшие (приглушённый).
class _RegionBar extends StatelessWidget {
  const _RegionBar({required this.stat});

  final RegionStat stat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Доли сегментов внутри полоски региона (а не от общего total) — так видно
    // структуру новые/посещавшие даже у небольших регионов.
    final denom = stat.newCount + stat.returningCount;
    final newFlex = denom <= 0 ? 0 : stat.newCount;
    final returningFlex = denom <= 0 ? 0 : stat.returningCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stat.region,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(width: 8),
              Text('${formatInt(stat.total)} '
                  '(${formatInt(stat.newCount)}/${formatInt(stat.returningCount)})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.75))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: denom <= 0
                  ? ColoredBox(color: scheme.surfaceContainerHighest)
                  : Row(
                      children: [
                        Expanded(
                          flex: newFlex,
                          child: ColoredBox(color: scheme.primary),
                        ),
                        Expanded(
                          flex: returningFlex,
                          child: const ColoredBox(color: AppColors.muted),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared building blocks for the director analytics panels below.
// ─────────────────────────────────────────────────────────────────────────────

/// Заголовок секции дашборда (директор-аналитика). Видно только директору.
Widget _sectionHeader(BuildContext context, String title, {Widget? trailing}) {
  final style = Theme.of(context)
      .textTheme
      .titleMedium
      ?.copyWith(fontWeight: FontWeight.bold);
  return Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(title, style: style)),
        ?trailing,
      ],
    ),
  );
}

/// Карточка-обёртка для панели аналитики (одинаковый отступ/радиус).
class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      );
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.insights_outlined,
            color: scheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Text('Пока нет данных',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7))),
      ],
    );
  }
}

/// Горизонтальная полоска «метка — значение — доля от максимума».
class _AnalyticsBar extends StatelessWidget {
  const _AnalyticsBar({
    required this.label,
    required this.valueText,
    required this.fraction,
    this.color,
  });

  final String label;
  final String valueText;
  final double fraction; // 0..1 от максимума
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(width: 8),
              Text(valueText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.78))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor:
                  AlwaysStoppedAnimation<Color>(color ?? scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Базовый каркас панели: проверка права + заголовок + AsyncValueWidget + карточка.
class _AnalyticsPanel<T> extends ConsumerWidget {
  const _AnalyticsPanel({
    required this.title,
    required this.provider,
    required this.isEmpty,
    required this.builder,
    this.trailing,
    super.key,
  });

  final String title;
  final AutoDisposeFutureProvider<T> provider;
  final bool Function(T) isEmpty;
  final Widget Function(BuildContext, T) builder;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (!(user?.can('dashboard.view') ?? false)) return const SizedBox.shrink();
    final value = ref.watch(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(context, title, trailing: trailing),
        AsyncValueWidget<T>(
          value: value,
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _PanelCard(
            child: isEmpty(data) ? const _PanelEmpty() : builder(context, data),
          ),
        ),
      ],
    );
  }
}

/// «Структура расходов (месяц)» — расходы по категориям, крупнейшие сверху.
class _ExpenseBreakdownPanel extends StatelessWidget {
  const _ExpenseBreakdownPanel();
  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel<ExpenseBreakdown>(
      title: 'Структура расходов (месяц)',
      provider: expenseBreakdownProvider,
      isEmpty: (d) => d.isEmpty,
      builder: (context, d) {
        final max = d.categories.fold<double>(
            0, (m, c) => c.amountValue > m ? c.amountValue : m);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in d.categories)
              _AnalyticsBar(
                label: c.category,
                valueText: formatMoney(c.amount),
                fraction: max <= 0 ? 0 : c.amountValue / max,
                color: AppColors.amber,
              ),
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Итого расходы',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(formatMoney(d.total),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// «Операции (месяц)» — воронка назначено/выполнено/отменено + P&L.
class _OperationsFunnelPanel extends StatelessWidget {
  const _OperationsFunnelPanel();
  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel<OperationsSummary>(
      title: 'Операции (месяц)',
      provider: operationsSummaryProvider,
      isEmpty: (d) =>
          d.scheduled == 0 && d.performed == 0 && d.cancelled == 0 &&
          d.revenueValue == 0,
      builder: (context, d) {
        final scheme = Theme.of(context).colorScheme;
        Widget stat(String label, int v, Color c) => Expanded(
              child: Column(
                children: [
                  Text('$v',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold, color: c)),
                  const SizedBox(height: 2),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            );
        Widget pnl(String label, String value, {bool bold = false}) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Text(value,
                      style: TextStyle(
                          fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
                ],
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                stat('Назначено', d.scheduled, AppColors.blue),
                stat('Выполнено', d.performed, AppColors.green),
                stat('Отменено', d.cancelled, scheme.error),
              ],
            ),
            const Divider(height: 22),
            pnl('Выручка', formatMoney(d.revenue)),
            pnl('Себестоимость', '− ${formatMoney(d.cogs)}'),
            pnl('Расходы', '− ${formatMoney(d.expenses)}'),
            const Divider(height: 14),
            pnl('Чистая прибыль', formatMoney(d.profit), bold: true),
          ],
        );
      },
    );
  }
}

/// «Доход по врачам (месяц)» — выручка завершённых оплат по лечащему врачу.
class _RevenueByDoctorPanel extends StatelessWidget {
  const _RevenueByDoctorPanel();
  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel<DoctorRevenueReport>(
      title: 'Доход по врачам (месяц)',
      provider: revenueByDoctorProvider,
      isEmpty: (d) => d.isEmpty,
      builder: (context, d) {
        final max = d.doctors.fold<double>(
            0, (m, r) => r.revenueValue > m ? r.revenueValue : m);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in d.doctors)
              _AnalyticsBar(
                label: r.doctorName,
                valueText: formatMoney(r.revenue),
                fraction: max <= 0 ? 0 : r.revenueValue / max,
              ),
          ],
        );
      },
    );
  }
}

/// «Динамика регионов» — новые пациенты этот месяц vs прошлый (рост/падение).
class _RegionTrendPanel extends StatelessWidget {
  const _RegionTrendPanel();
  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel<RegionTrendReport>(
      title: 'Динамика регионов (новые vs прошлый месяц)',
      provider: regionTrendProvider,
      isEmpty: (d) => d.isEmpty,
      builder: (context, d) {
        final scheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in d.regions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(r.region,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    Text('${r.currentNew}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text('(пр. ${r.previousNew})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.55))),
                    const SizedBox(width: 10),
                    _DeltaChip(delta: r.delta),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Чип-дельта: ▲ зелёный рост, ▼ красный спад, «—» без изменений.
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});
  final int delta;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color, String text) = delta > 0
        ? (Icons.arrow_upward, AppColors.green, '+$delta')
        : delta < 0
            ? (Icons.arrow_downward, scheme.error, '$delta')
            : (Icons.remove, AppColors.muted, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

/// «Пациенты по районам (Ферганская)» — детализация домашнего региона
/// с разбивкой новые/посещавшие.
class _DistrictsPanel extends StatelessWidget {
  const _DistrictsPanel();
  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel<DistrictReport>(
      key: const ValueKey('districts-home'),
      title: 'Пациенты по районам (Ферганская)',
      provider: patientsByDistrictProvider(null),
      isEmpty: (d) => d.isEmpty,
      builder: (context, d) {
        final scheme = Theme.of(context).colorScheme;
        final max = d.districts.fold<int>(
            0, (m, c) => c.total > m ? c.total : m);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in d.districts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.district,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        Text('${c.total} (${c.newCount}/${c.returningCount})',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface.withValues(alpha: 0.75))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 8,
                        child: max <= 0
                            ? ColoredBox(color: scheme.surfaceContainerHighest)
                            : Row(
                                children: [
                                  Expanded(
                                    flex: c.newCount,
                                    child: ColoredBox(color: scheme.primary),
                                  ),
                                  Expanded(
                                    flex: c.returningCount,
                                    child: const ColoredBox(color: AppColors.muted),
                                  ),
                                  // спейсер до доли от максимума района
                                  Expanded(
                                    flex: (max - c.total).clamp(0, max),
                                    child: ColoredBox(
                                        color: scheme.surfaceContainerHighest),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// KPI tiles now use the shared KpiCard widget (lib/core/widgets/koz_widgets.dart).
