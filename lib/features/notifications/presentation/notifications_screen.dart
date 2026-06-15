import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/koz_icons.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

/// Уведомления — журнал сработавших событий (дефицит склада, инсайты,
/// напоминания, очередь). Серверный журнал доступен только на чтение, поэтому
/// «закрытие» уведомления локальное — прячем id в [_hidden] до обновления.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _hidden = {};
  String _filter = 'all';

  static const _filters = <({String value, String label, NotifKind? kind})>[
    (value: 'all', label: 'Все', kind: null),
    (value: 'stock', label: 'Склад', kind: NotifKind.stock),
    (value: 'reminder', label: 'Напоминания', kind: NotifKind.reminder),
    (value: 'queue', label: 'Очередь', kind: NotifKind.queue),
  ];

  void _refresh() {
    setState(_hidden.clear);
    ref.invalidate(notificationsProvider);
  }

  // KozIcon-ключ для chip по типу события.
  String _iconKey(NotifKind k) => switch (k) {
        NotifKind.stock => 'inventory',
        NotifKind.insight => 'analytics',
        NotifKind.reminder => 'schedule',
        NotifKind.queue => 'queue',
        NotifKind.other => 'notifications',
      };

  // Пара цветов (текст, фон) для Pill по типу события.
  (Color, Color) _pillColors(NotifKind k) => switch (k) {
        NotifKind.stock => (AppColors.amber, AppColors.amberBg),
        NotifKind.reminder => (AppColors.tealDark, AppColors.tealBg),
        NotifKind.queue => (AppColors.blue, AppColors.blueBg),
        NotifKind.insight => (AppColors.green, AppColors.greenBg),
        NotifKind.other => (AppColors.sub, AppColors.line2),
      };

  // ISO-8601 → "HH:MM" в локальном времени; '' если не разобрали.
  String _time(String s) {
    if (s.isEmpty) return '';
    final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s);
    final t = DateTime.tryParse(hasZone ? s : '${s}Z')?.toLocal();
    if (t == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: notifsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(e is ApiException ? e.message : e.toString()),
                  ),
                  data: (all) => _content(all),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(List<AppNotification> all) {
    final selectedKind =
        _filters.firstWhere((f) => f.value == _filter).kind;
    final items = all
        .where((n) => !_hidden.contains(n.id))
        .where((n) => selectedKind == null || n.kind == selectedKind)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in _filters)
              ChoiceChip(
                label: Text(f.label),
                selected: _filter == f.value,
                onSelected: (_) => setState(() => _filter = f.value),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  KozIcon('notifications', size: 40, color: AppColors.muted),
                  SizedBox(height: 12),
                  Text(
                    'Новых уведомлений нет',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.line2),
              itemBuilder: (_, i) => _row(items[i]),
            ),
          ),
      ],
    );
  }

  Widget _row(AppNotification n) {
    final (pillColor, pillBg) = _pillColors(n.kind);
    final time = _time(n.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(AppColors.rField),
            ),
            alignment: Alignment.center,
            child: KozIcon(_iconKey(n.kind), size: 20, color: AppColors.sub),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(label: n.kindLabel, color: pillColor, bg: pillBg),
                    if (time.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  n.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (n.body != null && n.body!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    n.body!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.muted,
            tooltip: 'Скрыть',
            onPressed: () => setState(() => _hidden.add(n.id)),
          ),
        ],
      ),
    );
  }
}
