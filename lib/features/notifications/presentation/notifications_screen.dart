import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/koz_icons.dart';
import '../../dashboard/domain/insight.dart';
import '../data/notifications_repository.dart';

/// Уведомления — ЖИВОЙ список актуальных проблем, который сам себя очищает
/// (owner brief 2026-06-20). Уведомление существует только пока существует
/// проблема: завершён визит / прикреплён результат УЗИ / погашен долг → оно
/// автоматически исчезает. Набор вычисляется на сервере на чтение
/// (GET /notifications/active) — никаких устаревших хранимых записей и никакого
/// «локального скрытия». Тап по карточке ведёт сразу к разделу проблемы.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problems = ref.watch(activeProblemsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(activeProblemsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(activeProblemsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: problems.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(e is ApiException ? e.message : e.toString()),
                  ),
                  data: _content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(List<Insight> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KozIcon('notifications', size: 40, color: AppColors.muted),
              SizedBox(height: 12),
              Text('Всё в порядке — актуальных проблем нет',
                  style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final i in items) _NotificationCard(insight: i)],
    );
  }
}

/// Карточка проблемы — тот же вид, что и панель «Что требует внимания» на
/// дашборде: иконка/цвет по важности, значение-чип и переход к разделу.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.insight});

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
