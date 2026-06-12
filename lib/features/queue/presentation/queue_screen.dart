import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/url_opener.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/queue_repository.dart';
import '../domain/queue_ticket.dart';

/// Управление живой очередью филиала: вызов следующего, приём, завершение,
/// пропуск. Автообновление каждые 5 секунд; ссылка на TV-табло — в шапке.
class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  final _room = TextEditingController(text: 'Каб. 1');
  Timer? _autoRefresh;
  bool _busy = false;

  String? get _branchId => ref.read(authControllerProvider).user?.branchId;

  @override
  void initState() {
    super.initState();
    _autoRefresh = Timer.periodic(const Duration(seconds: 5), (_) {
      final branchId = _branchId;
      if (branchId != null) ref.invalidate(queueListProvider(branchId));
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _room.dispose();
    super.dispose();
  }

  Future<void> _act(Future<QueueTicket> Function() action) async {
    final branchId = _branchId;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (branchId != null) ref.invalidate(queueListProvider(branchId));
      }
    }
  }

  void _showTvBoardLink(String branchId) {
    final url = '${ApiConstants.baseUrl}/tv/$branchId';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TV-табло'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Откройте эту ссылку в браузере телевизора '
                '(полноэкранный режим). Логин не нужен — табло публичное и '
                'показывает только обезличенные данные.'),
            const SizedBox(height: 12),
            SelectableText(url,
                style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy),
            label: const Text('Копировать'),
          ),
          FilledButton.icon(
            onPressed: () {
              final opened = openInNewTab(url);
              if (!opened) return; // не web: ссылку уже можно скопировать
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Открыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final branchId = user?.branchId;
    final canManage = user?.can('queue.manage') ?? false;

    if (branchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Очередь')),
        body: const Center(
            child: Text('У пользователя не задан филиал — очередь недоступна.')),
      );
    }

    final tickets = ref.watch(queueListProvider(branchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Очередь'),
        actions: [
          IconButton(
            tooltip: 'TV-табло',
            onPressed: () => _showTvBoardLink(branchId),
            icon: const Icon(Icons.connected_tv_outlined),
          ),
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => ref.invalidate(queueListProvider(branchId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _room,
                      decoration: const InputDecoration(
                          labelText: 'Кабинет', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _act(() => ref
                            .read(queueRepositoryProvider)
                            .callNext(branchId: branchId, room: _room.text.trim())),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Вызвать следующего'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: AsyncValueWidget<List<QueueTicket>>(
              value: tickets,
              onRetry: () => ref.invalidate(queueListProvider(branchId)),
              builder: (items) {
                final active = items.where((t) => t.isActive).toList();
                final waiting = items.where((t) => t.isWaiting).toList();
                final wide = MediaQuery.sizeOf(context).width >= 900;
                final panels = [
                  Expanded(
                      child: _panel(context, 'Вызваны / на приёме', active,
                          canManage, _activeActions)),
                  Expanded(
                      child: _panel(context, 'Ожидают (${waiting.length})',
                          waiting, canManage, _waitingActions)),
                ];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: panels)
                      : Column(children: panels),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _activeActions(QueueTicket t) => [
        if (t.status == 'called')
          TextButton(
            onPressed: _busy
                ? null
                : () => _act(() => ref.read(queueRepositoryProvider).serve(t.id)),
            child: const Text('Принят'),
          ),
        TextButton(
          onPressed: _busy
              ? null
              : () => _act(() => ref.read(queueRepositoryProvider).done(t.id)),
          child: const Text('Готово'),
        ),
      ];

  List<Widget> _waitingActions(QueueTicket t) => [
        TextButton(
          onPressed: _busy
              ? null
              : () => _act(() => ref.read(queueRepositoryProvider).skip(t.id)),
          child: const Text('Пропустить'),
        ),
      ];

  Widget _panel(BuildContext context, String title, List<QueueTicket> items,
      bool canManage, List<Widget> Function(QueueTicket) actions) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Список скроллится внутри панели — загруженный филиал легко
            // держит 20+ талонов, колонка без скролла переполнялась бы.
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Пусто'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final t = items[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 22,
                            child: Text(t.ticketNumber,
                                style: const TextStyle(fontSize: 11)),
                          ),
                          title: Text([t.statusLabel, if (t.room != null) t.room!]
                              .join(' · ')),
                          subtitle: Text(
                              'создан ${t.createdAt.replaceFirst('T', ' ').split('.').first}'),
                          trailing: canManage
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: actions(t))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
