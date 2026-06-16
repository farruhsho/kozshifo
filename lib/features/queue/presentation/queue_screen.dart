import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/url_opener.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/queue_repository.dart';
import '../domain/queue_ticket.dart';

/// Управление живой очередью филиала по двум дорожкам — «Диагностика (D)» и
/// «К врачу (V)»: вызов следующего в каждой дорожке, приём, завершение,
/// пропуск. Завершение D-талона автоматически рождает V-талон на сервере.
/// Автообновление каждые 5 секунд; ссылка на TV-табло — в шапке.
/// Горячие клавиши: F2 — вызвать следующего на диагностику, F3 — к врачу.
class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  final _room = TextEditingController(text: 'Каб. 1');
  final _hotkeys = FocusNode(debugLabel: 'queue-hotkeys');
  Timer? _autoRefresh;
  bool _busy = false;
  // «Только мои направленные»: вызывать следующего из направленных лично мне
  // (+ общий пул). Выкл = прежнее поведение (любой ожидающий талон дорожки).
  bool _onlyMine = false;

  String? get _branchId => ref.read(authControllerProvider).user?.branchId;

  @override
  void initState() {
    super.initState();
    _autoRefresh = Timer.periodic(const Duration(seconds: 5), (_) {
      final branchId = _branchId;
      if (branchId == null) return;
      // Не складывать запросы: пропускаем тик, пока предыдущая загрузка ещё в
      // полёте (медленный бэкенд) — иначе периодические инвалидации копят GET-ы,
      // а поздний ответ может затереть более свежий список.
      if (ref.read(queueListProvider(branchId)).isLoading) return;
      ref.invalidate(queueListProvider(branchId));
    });
    // Явный requestFocus вместо autofocus: оболочка (AppShell) уже держит
    // фокус, поэтому autofocus здесь игнорировался бы — а без фокуса внутри
    // экрана F2/F3 не доходили бы до CallbackShortcuts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hotkeys.requestFocus();
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _hotkeys.dispose();
    _room.dispose();
    super.dispose();
  }

  /// Вызвать следующего в дорожке — общая точка для кнопок и клавиш F2/F3.
  /// При включённом «только мои» передаём for_user_id текущего пользователя.
  void _callNext(String branchId, String track) {
    final me = ref.read(authControllerProvider).user;
    _act(
      () => ref.read(queueRepositoryProvider).callNext(
        branchId: branchId,
        room: _room.text.trim(),
        track: track,
        forUserId: _onlyMine ? me?.id : null,
      ),
    );
  }

  /// Диалог адресной маршрутизации ожидающего талона: выбрать специалиста или
  /// снять маршрут (вернуть в общий пул). Список специалистов отдаётся под
  /// правом queue.manage — отдельный users.read не нужен.
  Future<void> _showRouteDialog(String branchId, QueueTicket t) async {
    final List<Specialist> specialists;
    try {
      specialists =
          await ref.read(queueRepositoryProvider).specialists(branchId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final choice = await showDialog<_RouteChoice>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Направить талон ${t.ticketNumber}'),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, const _RouteChoice.clear()),
            child: const Text('— Снять маршрут (общий пул)'),
          ),
          const Divider(),
          for (final s in specialists)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, _RouteChoice.user(s.id)),
              child: Text(
                s.roles.isEmpty
                    ? s.fullName
                    : '${s.fullName}  ·  ${s.roles.join(', ')}',
              ),
            ),
        ],
      ),
    );
    if (choice == null) return; // отмена
    await _act(
      () => ref
          .read(queueRepositoryProvider)
          .assign(t.id, assignedUserId: choice.userId),
      successMessage:
          choice.userId == null ? 'Маршрут снят' : 'Талон направлен',
    );
  }

  Future<void> _act(
    Future<QueueTicket> Function() action, {
    String? successMessage,
  }) async {
    final branchId = _branchId;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
            const Text(
              'Откройте эту ссылку в браузере телевизора '
              '(полноэкранный режим). Логин не нужен — табло публичное и '
              'показывает только обезличенные данные.',
            ),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
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
          child: Text('У пользователя не задан филиал — очередь недоступна.'),
        ),
      );
    }

    final tickets = ref.watch(queueListProvider(branchId));
    // Имена специалистов для резолва assigned_user_id на плитках (id → ФИО).
    // valueOrNull: пока список грузится, плитки просто не показывают имя.
    final specialistNames = {
      for (final s
          in ref.watch(queueSpecialistsProvider(branchId)).valueOrNull ??
              const <Specialist>[])
        s.id: s.fullName,
    };

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.f2): () {
          if (canManage && !_busy) _callNext(branchId, 'diagnostic');
        },
        const SingleActivator(LogicalKeyboardKey.f3): () {
          if (canManage && !_busy) _callNext(branchId, 'doctor');
        },
      },
      child: Focus(
        focusNode: _hotkeys,
        child: Scaffold(
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
                            labelText: 'Кабинет',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message:
                            'Вызывать следующего только из направленных мне '
                            '(+ общий пул)',
                        child: FilterChip(
                          selected: _onlyMine,
                          label: const Text('Только мои'),
                          onSelected: _busy
                              ? null
                              : (v) => setState(() => _onlyMine = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'F2/F3 — вызвать следующего',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: AsyncValueWidget<List<QueueTicket>>(
                  value: tickets,
                  onRetry: () => ref.invalidate(queueListProvider(branchId)),
                  builder: (items) {
                    // Одна загрузка на обе дорожки: список делится по t.track.
                    final wide = MediaQuery.sizeOf(context).width >= 900;
                    final tracks = [
                      Expanded(
                        child: _trackSection(
                          context,
                          branchId,
                          title: 'Диагностика (D)',
                          track: 'diagnostic',
                          items: items,
                          canManage: canManage,
                          specialistNames: specialistNames,
                        ),
                      ),
                      Expanded(
                        child: _trackSection(
                          context,
                          branchId,
                          title: 'К врачу (V)',
                          track: 'doctor',
                          items: items,
                          canManage: canManage,
                          specialistNames: specialistNames,
                        ),
                      ),
                    ];
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: tracks,
                            )
                          : Column(children: tracks),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Половина экрана для одной дорожки: заголовок + свой «Вызвать следующего»
  /// + панели «Вызваны / на приёме» и «Ожидают».
  Widget _trackSection(
    BuildContext context,
    String branchId, {
    required String title,
    required String track,
    required List<QueueTicket> items,
    required bool canManage,
    required Map<String, String> specialistNames,
  }) {
    final mine = items.where((t) => t.track == track).toList();
    final active = mine.where((t) => t.isActive).toList();
    final waiting = mine.where((t) => t.isWaiting).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (canManage)
                FilledButton.icon(
                  onPressed: _busy ? null : () => _callNext(branchId, track),
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Вызвать следующего'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _panel(
            context,
            'Вызваны / на приёме',
            active,
            canManage,
            _activeActions,
            specialistNames,
          ),
        ),
        Expanded(
          child: _panel(
            context,
            'Ожидают (${waiting.length})',
            waiting,
            canManage,
            (t) => _waitingActions(t, branchId),
            specialistNames,
          ),
        ),
      ],
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
          // Завершение диагностики автоматически создаёт V-талон на
          // сервере — подсказываем оператору, что пациент не «потерялся».
          : () => _act(
              () => ref.read(queueRepositoryProvider).done(t.id),
              successMessage: t.track == 'diagnostic'
                  ? 'Пациент переведён в очередь к врачу'
                  : null,
            ),
      child: const Text('Готово'),
    ),
  ];

  List<Widget> _waitingActions(QueueTicket t, String branchId) => [
    TextButton(
      onPressed: _busy ? null : () => _showRouteDialog(branchId, t),
      child: const Text('Направить'),
    ),
    TextButton(
      onPressed: _busy
          ? null
          : () => _act(() => ref.read(queueRepositoryProvider).skip(t.id)),
      child: const Text('Пропустить'),
    ),
  ];

  /// Цвет акцента талона из палитры «Clinic OS». Приоритетный (экстренный)
  /// талон всегда красный, иначе цвет по статусу: ожидает → amber,
  /// вызван/на приёме → teal-primary, завершён/пропущен → muted.
  Color _accentColor(QueueTicket t) {
    if (t.priority > 0) return AppColors.red;
    if (t.isActive) return AppColors.accent;
    if (t.isWaiting) return AppColors.amber;
    return AppColors.muted; // done / skipped и прочие терминальные статусы
  }

  Widget _panel(
    BuildContext context,
    String title,
    List<QueueTicket> items,
    bool canManage,
    List<Widget> Function(QueueTicket) actions,
    Map<String, String> specialistNames,
  ) {
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
                        final accent = _accentColor(t);
                        // Левая цветная полоса-акцент по статусу талона:
                        // ожидает → amber, вызван/на приёме → teal,
                        // завершён/пропущен → muted, приоритет → red.
                        // Реализована как Border(left: …), а не отдельным
                        // flex-сиблингом — чтобы не ломать раскладку Row.
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: accent, width: 4),
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 22,
                              // Номер талона (D-001 … V-0999) масштабируется под
                              // кружок: без FittedBox длинный номер переносился на
                              // две строки и обрезался ободом аватара («V-0 / 03»).
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    t.ticketNumber,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              [
                                t.statusLabel,
                                if (t.room != null) t.room!,
                                if (t.assignedUserId != null)
                                  '→ ${specialistNames[t.assignedUserId] ?? 'специалист'}',
                              ].join(' · '),
                            ),
                            subtitle: Text(
                              'создан ${t.createdAt.replaceFirst('T', ' ').split('.').first}',
                            ),
                            trailing: canManage
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: actions(t),
                                  )
                                : null,
                          ),
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

/// Результат диалога маршрутизации. `null` из showDialog = отмена;
/// `_RouteChoice` с `userId == null` = снять маршрут (общий пул).
class _RouteChoice {
  const _RouteChoice.clear() : userId = null;
  const _RouteChoice.user(this.userId);
  final String? userId;
}
