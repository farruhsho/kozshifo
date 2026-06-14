import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../../core/widgets/koz_icons.dart';
import '../../auth/application/auth_controller.dart';
import '../../scheduling/data/scheduling_repository.dart';
import '../../scheduling/domain/appointment.dart';

/// «Приём сегодня» — рабочий список врача на текущий день. Переиспользует данные
/// расписания (scheduleProvider): показывает только записи этого врача (или все
/// записи дня, если врач не определён). Из строки врач открывает карту пациента
/// и быстро отмечает «пришёл / принят».
class WorklistScreen extends ConsumerStatefulWidget {
  const WorklistScreen({super.key});

  @override
  ConsumerState<WorklistScreen> createState() => _WorklistScreenState();
}

class _WorklistScreenState extends ConsumerState<WorklistScreen> {
  bool _busy = false;

  String two(int n) => n.toString().padLeft(2, '0');

  String get _dateKey {
    final now = DateTime.now();
    return '${now.year}-${two(now.month)}-${two(now.day)}';
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
        ref.invalidate(scheduleProvider((branchId: branchId, date: _dateKey)));
      }
    }
  }

  BadgeKind _kind(String status) => switch (status) {
        'done' => BadgeKind.neutral,
        'arrived' => BadgeKind.info,
        'booked' => BadgeKind.info,
        'cancelled' => BadgeKind.danger,
        'no_show' => BadgeKind.warning,
        _ => BadgeKind.neutral,
      };

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

    if (branchId == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Приём')),
        body: const Center(child: Text('У пользователя не задан филиал.')),
      );
    }

    final apptAsync = ref.watch(scheduleProvider((branchId: branchId, date: _dateKey)));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Приём')),
      body: SafeArea(
        child: apptAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text(e is ApiException ? e.message : e.toString())),
          data: (all) {
            // Только записи этого врача; если врач не определён или своих нет —
            // показываем все записи дня.
            final mine = me == null
                ? const <Appointment>[]
                : all.where((a) => a.doctorId == me).toList();
            final rows = mine.isNotEmpty ? mine : all;

            final inQueue = rows.where((a) => a.status != 'done').length;
            final accepted = rows.where((a) => a.status == 'done').length;

            // Fill the scroll viewport width (tight constraint) — a
            // Center+ConstrainedBox here gives the Column LOOSE width, so a
            // stretch Column shrink-wraps to intrinsic width and every row
            // overflows. Full-width matches the Optics/Lab screens.
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _heroRow(
                    doctorName: user?.fullName ?? 'Врач',
                    inQueue: inQueue,
                    accepted: accepted,
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: rows.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(child: Text('На сегодня записей нет')),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, color: AppColors.line2),
                            itemBuilder: (context, i) => _row(rows[i], branchId),
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

  Widget _heroRow({
    required String doctorName,
    required int inQueue,
    required int accepted,
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

        final inQueueCard = _countCard(inQueue, 'в очереди');
        final acceptedCard = _countCard(accepted, 'принято');

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: inQueueCard),
                  const SizedBox(width: 12),
                  Expanded(child: acceptedCard),
                ],
              ),
            ],
          );
        }
        // Fixed-height row (no IntrinsicHeight + stretch): a speculative
        // intrinsic-width pass over the SVG icon under IntrinsicHeight is
        // fragile, and stretch inside the unbounded scroll view forces an
        // infinite height. A fixed height keeps every tile equal and bounded.
        return SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: hero),
              const SizedBox(width: 12),
              Expanded(child: inQueueCard),
              const SizedBox(width: 12),
              Expanded(child: acceptedCard),
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

  Widget _row(Appointment a, String branchId) {
    final service = a.service ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          InitialsAvatar(_initials(a.patientName)),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
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
          StatusBadge(a.statusLabel, kind: _kind(a.status)),
          const SizedBox(width: 12),
          _rowActions(a, branchId),
        ],
      ),
    );
  }

  Widget _rowActions(Appointment a, String branchId) {
    final children = <Widget>[];

    // Compact secondary action (mark arrived / done) — an icon button keeps the
    // row within its bounded width; the primary CTA stays a full button.
    if (a.status == 'booked') {
      children.add(IconButton(
        tooltip: 'Отметить: пришёл',
        icon: const Icon(Icons.how_to_reg_outlined),
        color: AppColors.tealDark,
        onPressed: _busy
            ? null
            : () => _act(
                  () async =>
                      ref.read(schedulingRepositoryProvider).setStatus(a.id, 'arrived'),
                  branchId: branchId,
                  ok: 'Пациент отмечен: пришёл',
                ),
      ));
      children.add(const SizedBox(width: 4));
    } else if (a.status == 'arrived') {
      children.add(IconButton(
        tooltip: 'Завершить приём',
        icon: const Icon(Icons.task_alt),
        color: AppColors.green,
        onPressed: _busy
            ? null
            : () => _act(
                  () async =>
                      ref.read(schedulingRepositoryProvider).setStatus(a.id, 'done'),
                  branchId: branchId,
                  ok: 'Приём завершён',
                ),
      ));
      children.add(const SizedBox(width: 4));
    }

    children.add(SizedBox(
      width: 190,
      child: GradientButton(
        label: a.status != 'done' ? 'Начать осмотр' : 'Открыть карту',
        height: 40,
        onPressed: () => context.go('/patients/${a.patientId}/card'),
      ),
    ));

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
