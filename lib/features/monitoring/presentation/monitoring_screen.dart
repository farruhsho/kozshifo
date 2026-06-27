import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/monitoring_repository.dart';
import '../domain/monitoring.dart';

final _dateTime = DateFormat('dd.MM.yyyy HH:mm');

/// Системный мониторинг (Super Admin): онлайн-пользователи, входы, аптайм,
/// последние ошибки/медленные запросы и журнал сессий.
class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

  static String _uptime(int s) {
    final d = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60;
    if (d > 0) return '$d д $h ч';
    if (h > 0) return '$h ч $m м';
    return '$m м';
  }

  static String _when(String iso) {
    final dt = DateTime.tryParse(iso);
    return dt == null ? iso : _dateTime.format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monitoringStatsProvider);
    final sessions = ref.watch(sessionsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Мониторинг'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(monitoringStatsProvider);
              ref.invalidate(sessionsProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AsyncValueWidget<MonitoringStats>(
              value: stats,
              onRetry: () => ref.invalidate(monitoringStatsProvider),
              builder: _stats,
            ),
            const SizedBox(height: 24),
            Text('Сессии входа',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AsyncValueWidget<List<SessionRow>>(
              value: sessions,
              onRetry: () => ref.invalidate(sessionsProvider),
              builder: _sessions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats(MonitoringStats s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _tile('Онлайн сейчас', '${s.onlineCount}', AppColors.green),
            _tile('Входов сегодня', '${s.loginsToday}', AppColors.blue),
            _tile('Аптайм', _uptime(s.uptimeSeconds), AppColors.tealDark),
            _tile('Всего сессий', '${s.totalSessions}', AppColors.sub),
          ],
        ),
        if (s.onlineUsers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final u in s.onlineUsers)
                Chip(
                  avatar: const Icon(Icons.circle, size: 10, color: AppColors.green),
                  label: Text(u.name),
                ),
            ],
          ),
        ],
        if (s.recentErrors.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Последние ошибки',
              style: TextStyle(fontWeight: FontWeight.bold)),
          for (final e in s.recentErrors)
            _logLine(
              '${e['status']} · ${e['method']} ${e['path']}',
              _when('${e['at']}'),
              AppColors.red,
            ),
        ],
        if (s.recentSlow.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Медленные запросы',
              style: TextStyle(fontWeight: FontWeight.bold)),
          for (final r in s.recentSlow)
            _logLine(
              '${r['duration_ms']} мс · ${r['method']} ${r['path']}',
              _when('${r['at']}'),
              AppColors.amber,
            ),
        ],
      ],
    );
  }

  Widget _tile(String label, String value, Color color) => SizedBox(
        width: 170,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20, color: color)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ],
            ),
          ),
        ),
      );

  Widget _logLine(String text, String at, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(Icons.fiber_manual_record, size: 9, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5)),
            ),
            Text(at, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ],
        ),
      );

  Widget _sessions(List<SessionRow> rows) {
    if (rows.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
              child: Text('Сессий нет', style: TextStyle(color: AppColors.muted))),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final r in rows)
            ListTile(
              dense: true,
              leading: Icon(Icons.circle,
                  size: 10, color: r.online ? AppColors.green : AppColors.line2),
              title: Text(r.userName ?? '—'),
              subtitle: Text(
                [
                  _when(r.startedAt),
                  if (r.ipAddress != null && r.ipAddress!.isNotEmpty) r.ipAddress!,
                  if (r.userAgent != null && r.userAgent!.isNotEmpty) r.userAgent!,
                ].join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: r.online
                  ? const Text('онлайн',
                      style: TextStyle(color: AppColors.green, fontSize: 12))
                  : null,
            ),
        ],
      ),
    );
  }
}
