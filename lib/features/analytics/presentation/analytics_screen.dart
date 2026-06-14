import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/dashboard_summary.dart';
import '../../dashboard/domain/lead_source.dart';
import '../data/analytics_repository.dart';
import '../domain/top_service.dart';

/// «Аналитика» — read-only KPI-сводка для директора: ключевые метрики дня/месяца,
/// топ услуг по выручке и распределение пациентов по источникам привлечения.
/// Только реальные данные из dashboard/analytics эндпоинтов — без выдуманных
/// конверсий или загрузки кабинетов.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static const _titleStyle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: AppColors.ink,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Аналитика')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kpiRow(ref),
              const SizedBox(height: 24),
              _topServicesCard(ref),
              const SizedBox(height: 24),
              _leadSourcesCard(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiRow(WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return summary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(e is ApiException ? e.message : e.toString())),
      data: (DashboardSummary s) => Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 230,
            height: 130,
            child: KpiCard(
              iconKey: 'finance',
              value: formatMoney(s.averageCheckToday),
              label: 'Средний чек',
              accent: true,
            ),
          ),
          SizedBox(
            width: 230,
            height: 130,
            child: KpiCard(
              iconKey: 'reception',
              value: formatInt(s.visitsToday),
              label: 'Визитов сегодня',
            ),
          ),
          SizedBox(
            width: 230,
            height: 130,
            child: KpiCard(
              iconKey: 'patients',
              value: formatInt(s.patientsTotal),
              label: 'Всего пациентов',
            ),
          ),
          SizedBox(
            width: 230,
            height: 130,
            child: KpiCard(
              iconKey: 'patients',
              value: formatInt(s.newPatientsToday),
              label: 'Новых пациентов',
            ),
          ),
          SizedBox(
            width: 230,
            height: 130,
            child: KpiCard(
              iconKey: 'worklist',
              value: formatInt(s.operationsMonth),
              label: 'Операций за месяц',
            ),
          ),
        ],
      ),
    );
  }

  Widget _topServicesCard(WidgetRef ref) {
    final top = ref.watch(topServicesProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Топ услуг по выручке', style: _titleStyle),
          const SizedBox(height: 16),
          top.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text(e is ApiException ? e.message : e.toString())),
            data: (List<TopService> items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Пока нет данных',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                );
              }
              var maxValue = 0.0;
              for (final s in items) {
                if (s.revenueValue > maxValue) maxValue = s.revenueValue;
              }
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _TopServiceRow(item: items[i], maxValue: maxValue),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _leadSourcesCard(WidgetRef ref) {
    final report = ref.watch(leadSourcesProvider);
    const dotColors = <Color>[
      AppColors.accent,
      AppColors.blue,
      AppColors.amber,
      AppColors.green,
      AppColors.muted,
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Источники пациентов', style: _titleStyle),
          const SizedBox(height: 16),
          report.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text(e is ApiException ? e.message : e.toString())),
            data: (LeadSourceReport r) {
              if (r.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Пока нет данных',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < r.sources.length; i++)
                    _LeadSourceTile(
                      stat: r.sources[i],
                      color: dotColors[i % dotColors.length],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Одна строка топа: услуга + выручка, полоса прогресса (доля от максимума) и
/// серый под-лейбл с количеством услуг.
class _TopServiceRow extends StatelessWidget {
  const _TopServiceRow({required this.item, required this.maxValue});

  final TopService item;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final fraction =
        maxValue <= 0 ? 0.0 : (item.revenueValue / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.service,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatMoney(item.revenue),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.tealDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 9, color: AppColors.line2),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(height: 9, color: AppColors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${formatInt(item.count)} услуг',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

/// Карточка одного канала привлечения: цветная точка, крупное число и метка.
class _LeadSourceTile extends StatelessWidget {
  const _LeadSourceTile({required this.stat, required this.color});

  final LeadSourceStat stat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.line2,
        borderRadius: BorderRadius.circular(AppColors.rField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.sub, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(formatInt(stat.count), style: AppTypography.number(24)),
        ],
      ),
    );
  }
}
