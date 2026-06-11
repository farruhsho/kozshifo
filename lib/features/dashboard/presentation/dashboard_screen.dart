import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

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
            onPressed: () => ref.invalidate(dashboardSummaryProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AsyncValueWidget<DashboardSummary>(
        value: summary,
        onRetry: () => ref.invalidate(dashboardSummaryProvider),
        builder: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: _KpiGrid(data: data),
          ),
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
    final cards = <Widget>[
      _KpiCard(label: 'Выручка сегодня', value: formatMoney(data.revenueToday),
          icon: Icons.payments_outlined, accent: true),
      _KpiCard(label: 'Выручка за месяц', value: formatMoney(data.revenueMonth),
          icon: Icons.calendar_month_outlined),
      _KpiCard(label: 'Средний чек', value: formatMoney(data.averageCheckToday),
          icon: Icons.receipt_long_outlined),
      _KpiCard(label: 'Оплат сегодня', value: formatInt(data.paymentsToday),
          icon: Icons.point_of_sale_outlined),
      _KpiCard(label: 'Визитов сегодня', value: formatInt(data.visitsToday),
          icon: Icons.event_available_outlined),
      _KpiCard(label: 'Новых пациентов', value: formatInt(data.newPatientsToday),
          icon: Icons.person_add_alt_outlined),
      _KpiCard(label: 'Всего пациентов', value: formatInt(data.patientsTotal),
          icon: Icons.groups_outlined),
      _KpiCard(label: 'В очереди', value: formatInt(data.queueWaiting),
          icon: Icons.queue_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 260).floor().clamp(1, 4);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.9,
          children: cards,
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.icon, this.accent = false});

  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = accent ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = accent ? scheme.onPrimaryContainer : scheme.onSurface;
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: fg.withValues(alpha: 0.8), size: 22),
                const Spacer(),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: fg, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: fg.withValues(alpha: 0.75))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
