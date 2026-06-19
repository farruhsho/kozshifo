import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../../core/widgets/koz_icons.dart';
import '../../auth/application/auth_controller.dart';
import '../../queue/data/queue_repository.dart';
import '../../queue/domain/queue_ticket.dart';
import '../../scheduling/data/scheduling_repository.dart';
import '../../scheduling/domain/appointment.dart';

/// «Приём сегодня» — рабочий список врача на текущий день.
///
/// Главный источник — ЖИВАЯ ОЧЕРЕДЬ к врачу (V-дорожка): пациенты, пришедшие
/// потоком регистратура → оплата → диагностика, после которой система сама
/// ставит V-талон (TZ §6.2). Врач вызывает следующего, открывает карту и
/// нажимает «Завершить приём» — талон закрывается, визит уходит кассиру
/// (TZ §7.1.6). Ниже — записи на сегодня (Расписание) для плановых пациентов.
class WorklistScreen extends ConsumerStatefulWidget {
  const WorklistScreen({super.key});

  @override
  ConsumerState<WorklistScreen> createState() => _WorklistScreenState();
}

class _WorklistScreenState extends ConsumerState<WorklistScreen> {
  bool _busy = false;
  final _room = TextEditingController(text: '1');
  Timer? _autoRefresh;

  String two(int n) => n.toString().padLeft(2, '0');

  String get _dateKey {
    final now = DateTime.now();
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  @override
  void initState() {
    super.initState();
    // Near-real-time queue (TZ §12.1): mirror the queue screen's 5s poll so a
    // patient finishing diagnostics surfaces here without a manual refresh.
    _autoRefresh = Timer.periodic(const Duration(seconds: 5), (_) {
      final branchId = ref.read(authControllerProvider).user?.branchId;
      if (branchId != null) {
        ref.invalidate(queueListProvider(branchId));
        ref.invalidate(doctorServedTodayProvider(branchId));
      }
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _room.dispose();
    super.dispose();
  }

  void _refresh(String branchId) {
    ref.invalidate(queueListProvider(branchId));
    ref.invalidate(doctorServedTodayProvider(branchId));
    ref.invalidate(scheduleProvider((branchId: branchId, date: _dateKey)));
  }

  Future<void> _act(Future<void> Function() fn,
      {required String branchId, String? ok}) async {
    setState(() => _busy = true);
    try {
      await fn();
      if (ok != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : '$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refresh(branchId);
      }
    }
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '—';
    final buf = StringBuffer();
    for (final w in words.take(2)) {
      buf.write(w.characters.first);
    }
    return buf.toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final branchId = user?.branchId;
    final me = user?.id;
    final canManageQueue = user?.can('queue.manage') ?? false;

    if (branchId == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Приём')),
        body: const Center(child: Text('У пользователя не задан филиал.')),
      );
    }

    final queueAsync = ref.watch(queueListProvider(branchId));
    final apptAsync = ref.watch(scheduleProvider((branchId: branchId, date: _dateKey)));
    final servedToday = ref.watch(doctorServedTodayProvider(branchId)).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Приём'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : () => _refresh(branchId),
          ),
        ],
      ),
      body: SafeArea(
        child: queueAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text(e is ApiException ? e.message : e.toString())),
          data: (allTickets) {
            // Только V-дорожка (вызов к врачу), сегодняшняя и активная — список
            // приходит уже day-scoped/active с бэкенда.
            final doctorQ = allTickets.where((t) => t.track == 'doctor').toList()
              ..sort((a, b) {
                // Экстренные вперёд, затем по времени создания.
                final p = b.priority.compareTo(a.priority);
                return p != 0 ? p : a.createdAt.compareTo(b.createdAt);
              });
            final serving = doctorQ.where((t) => t.isActive).toList();
            final waiting = doctorQ.where((t) => t.isWaiting).toList();

            // Записи на сегодня (Расписание): только живые (не done/cancelled),
            // и, если врач определён, только его.
            final appts = (apptAsync.valueOrNull ?? const <Appointment>[])
                .where((a) => a.status == 'booked' || a.status == 'arrived')
                .where((a) => me == null || a.doctorId == null || a.doctorId == me)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _heroRow(
                    doctorName: user?.fullName ?? 'Врач',
                    waiting: waiting.length,
                    onCall: serving.length,
                    served: servedToday,
                  ),
                  const SizedBox(height: 16),
                  if (canManageQueue) ...[
                    _callNextBar(branchId, me, waiting.isEmpty),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle('На приёме сейчас'),
                  const SizedBox(height: 8),
                  AppCard(
                    child: serving.isEmpty
                        ? const _Empty('Никто не вызван')
                        : Column(
                            children: [
                              for (final t in serving)
                                _queueRow(t, branchId,
                                    canManage: canManageQueue, current: true),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Очередь к врачу (${waiting.length})'),
                  const SizedBox(height: 8),
                  AppCard(
                    child: waiting.isEmpty
                        ? const _Empty('Очередь пуста')
                        : Column(
                            children: [
                              for (var i = 0; i < waiting.length; i++) ...[
                                if (i > 0)
                                  const Divider(height: 1, color: AppColors.line2),
                                _queueRow(waiting[i], branchId,
                                    canManage: canManageQueue,
                                    current: false,
                                    position: i + 1),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Записи на сегодня (${appts.length})'),
                  const SizedBox(height: 8),
                  AppCard(
                    child: appts.isEmpty
                        ? const _Empty('Плановых записей на сегодня нет')
                        : Column(
                            children: [
                              for (var i = 0; i < appts.length; i++) ...[
                                if (i > 0)
                                  const Divider(height: 1, color: AppColors.line2),
                                _apptRow(appts[i]),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Hero + stats ──────────────────────────────────────────────────────────
  Widget _heroRow({
    required String doctorName,
    required int waiting,
    required int onCall,
    required int served,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final stack = c.maxWidth < 760;
        final hero = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.sidebarGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const KozIcon('worklist', size: 34, color: AppColors.mintLight),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('Приём сегодня',
                        style: TextStyle(
                            color: AppColors.mintLight.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5)),
                  ],
                ),
              ),
            ],
          ),
        );

        final waitingCard = _countCard(waiting, 'в очереди');
        final onCallCard = _countCard(onCall, 'на приёме');
        final servedCard = _countCard(served, 'принято');

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: waitingCard),
                  const SizedBox(width: 12),
                  Expanded(child: onCallCard),
                  const SizedBox(width: 12),
                  Expanded(child: servedCard),
                ],
              ),
            ],
          );
        }
        return SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: hero),
              const SizedBox(width: 12),
              Expanded(child: waitingCard),
              const SizedBox(width: 12),
              Expanded(child: onCallCard),
              const SizedBox(width: 12),
              Expanded(child: servedCard),
            ],
          ),
        );
      },
    );
  }

  Widget _countCard(int value, String label) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value.toString(), style: AppTypography.number(28)),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.sub,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  // ── «Вызвать следующего» ────────────────────────────────────────────────
  Widget _callNextBar(String branchId, String? me, bool queueEmpty) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.meeting_room_outlined,
              size: 20, color: AppColors.sub),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: TextField(
              controller: _room,
              decoration: const InputDecoration(
                labelText: 'Кабинет',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GradientButton(
              label: 'Вызвать следующего',
              height: 44,
              onPressed: (_busy || queueEmpty)
                  ? null
                  : () => _act(
                        () async {
                          final room = _room.text.trim();
                          await ref.read(queueRepositoryProvider).callNext(
                                branchId: branchId,
                                room: room.isEmpty ? '1' : room,
                                track: 'doctor',
                                forUserId: me,
                              );
                        },
                        branchId: branchId,
                        ok: 'Следующий пациент вызван',
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Строка очереди ────────────────────────────────────────────────────────
  Widget _queueRow(QueueTicket t, String branchId,
      {required bool canManage, required bool current, int? position}) {
    final name = t.patientName.isEmpty ? '—' : t.patientName;
    final emergency = t.priority > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          InitialsAvatar(_initials(name)),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              position != null ? '№$position' : t.ticketNumber,
              style: const TextStyle(
                  color: AppColors.sub,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14.5)),
                    ),
                    if (emergency) ...[
                      const SizedBox(width: 8),
                      const StatusBadge('⚠ Экстренный', kind: BadgeKind.danger),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('Талон ${t.ticketNumber} · ${t.statusLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (current && canManage) ...[
            IconButton(
              tooltip: 'Завершить приём',
              icon: const Icon(Icons.task_alt),
              color: AppColors.green,
              onPressed: _busy
                  ? null
                  : () => _act(
                        () async =>
                            ref.read(queueRepositoryProvider).done(t.id),
                        branchId: branchId,
                        ok: 'Приём завершён — визит передан кассиру',
                      ),
            ),
            const SizedBox(width: 4),
          ],
          SizedBox(
            width: 190,
            child: GradientButton(
              label: current ? 'Открыть карту' : 'Начать осмотр',
              height: 40,
              onPressed: () => context.go('/patients/${t.patientId}/card'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Строка записи (Расписание) ──────────────────────────────────────────
  Widget _apptRow(Appointment a) {
    final service = a.service ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          InitialsAvatar(_initials(a.patientName)),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(a.timeLabel,
                style: const TextStyle(
                    color: AppColors.sub,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.patientName.isEmpty ? '—' : a.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                if (service.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(service,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusBadge(a.statusLabel,
              kind: a.status == 'arrived' ? BadgeKind.info : BadgeKind.neutral),
          const SizedBox(width: 12),
          SizedBox(
            width: 190,
            child: GradientButton(
              label: 'Открыть карту',
              height: 40,
              onPressed: () => context.go('/patients/${a.patientId}/card'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.ink)),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text(text,
              style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
        ),
      );
}
