import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import '../domain/insight.dart';
import '../domain/lead_source.dart';

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
              ref.invalidate(leadSourcesProvider);
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
            ref.invalidate(leadSourcesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _InsightsPanel(),
                const SizedBox(height: 20),
                _KpiGrid(data: data),
                const _LeadSourcesPanel(),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(insight.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(insight.detail),
        trailing: insight.value == null
            ? null
            : Chip(
                label: Text(insight.value!,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold)),
                side: BorderSide(color: color.withValues(alpha: 0.4)),
              ),
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
      KpiCard(label: 'Выручка за месяц', value: formatMoney(data.revenueMonth),
          iconKey: 'schedule', onTap: () => go('/finance')),
      KpiCard(label: 'Средний чек', value: formatMoney(data.averageCheckToday),
          iconKey: 'analytics'),
      KpiCard(label: 'Оплат сегодня', value: formatInt(data.paymentsToday),
          iconKey: 'finance', onTap: () => go('/finance')),
      KpiCard(label: 'Визитов сегодня', value: formatInt(data.visitsToday),
          iconKey: 'reception'),
      KpiCard(label: 'Новых пациентов', value: formatInt(data.newPatientsToday),
          iconKey: 'patients', onTap: () => go('/patients')),
      KpiCard(label: 'Всего пациентов', value: formatInt(data.patientsTotal),
          iconKey: 'patients', onTap: () => go('/patients')),
      KpiCard(label: 'В очереди', value: formatInt(data.queueWaiting),
          iconKey: 'queue', onTap: () => go('/queue')),
      KpiCard(label: 'Операций сегодня', value: formatInt(data.operationsToday),
          iconKey: 'worklist'),
      KpiCard(label: 'Операций за месяц', value: formatInt(data.operationsMonth),
          iconKey: 'worklist'),
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

// KPI tiles now use the shared KpiCard widget (lib/core/widgets/koz_widgets.dart).
