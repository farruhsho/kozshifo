import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../data/scheduling_repository.dart';
import '../domain/appointment.dart';

const _slotStartHour = 9;
const _slotEndHour = 18; // exclusive
const _slotStepMin = 30;

List<TimeOfDay> _slots() {
  final out = <TimeOfDay>[];
  for (var m = _slotStartHour * 60; m < _slotEndHour * 60; m += _slotStepMin) {
    out.add(TimeOfDay(hour: m ~/ 60, minute: m % 60));
  }
  return out;
}

String _two(int n) => n.toString().padLeft(2, '0');
String _hm(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';
String _dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

const _months = [
  '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
];

/// Расписание: сетка «время × врачи». Свободный слот — кнопка записи; занятый —
/// карточка с пациентом и статусом. Перетащи запись на свободный слот, чтобы
/// перенести. «Пришёл → Карта» передаёт пациента в работу (как walk-in).
class SchedulingScreen extends ConsumerStatefulWidget {
  const SchedulingScreen({super.key});

  @override
  ConsumerState<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends ConsumerState<SchedulingScreen> {
  DateTime _date = DateTime.now();
  bool _busy = false;

  String? get _branchId => ref.read(authControllerProvider).user?.branchId;
  bool get _canBook => ref.read(authControllerProvider).user?.can('appointments.create') ?? false;

  void _refresh() {
    final b = _branchId;
    if (b != null) ref.invalidate(scheduleProvider((branchId: b, date: _dateKey(_date))));
  }

  Future<void> _act(Future<void> Function() fn, {String? ok}) async {
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
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = _branchId;
    if (branchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Расписание')),
        body: const Center(child: Text('У пользователя не задан филиал.')),
      );
    }
    final isToday = DateUtils.isSameDay(_date, DateTime.now());
    final staffAsync = ref.watch(schedStaffProvider(branchId));
    final apptAsync = ref.watch(scheduleProvider((branchId: branchId, date: _dateKey(_date))));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh), tooltip: 'Обновить'),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DateNav(
                  label: isToday ? 'Сегодня · ${_date.day} ${_months[_date.month]}'
                      : '${_date.day} ${_months[_date.month]} ${_date.year}',
                  onPrev: () => setState(() => _date = _date.subtract(const Duration(days: 1))),
                  onNext: () => setState(() => _date = _date.add(const Duration(days: 1))),
                  onToday: () => setState(() => _date = DateTime.now()),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: staffAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (allStaff) {
                  final doctors = allStaff.where((s) => s.roles.contains('Doctor')).toList();
                  final columns = doctors.isNotEmpty ? doctors : allStaff;
                  if (columns.isEmpty) {
                    return const Center(child: Text('Нет сотрудников в филиале для записи.'));
                  }
                  return apptAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (appts) => _Grid(
                      doctors: columns,
                      appts: appts,
                      date: _date,
                      busy: _busy,
                      canBook: _canBook,
                      onBook: _openBook,
                      onStatus: (a, s) => _act(
                          () async => ref.read(schedulingRepositoryProvider).setStatus(a.id, s),
                          ok: 'Статус: ${_statusOk(s)}'),
                      onReschedule: (a, doctorId, slot) => _act(
                          () async => ref.read(schedulingRepositoryProvider).reschedule(
                                a.id,
                                startsAt: _slotIso(slot),
                                doctorId: doctorId,
                              ),
                          ok: 'Запись перенесена'),
                      onOpenCard: (a) => context.go('/patients/${a.patientId}/card'),
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

  String _slotIso(TimeOfDay slot) =>
      DateTime(_date.year, _date.month, _date.day, slot.hour, slot.minute)
          .toUtc()
          .toIso8601String();

  String _statusOk(String s) => switch (s) {
        'arrived' => 'пришёл', 'done' => 'принят', 'cancelled' => 'отменён', _ => s
      };

  Future<void> _openBook(SchedStaff doctor, TimeOfDay slot) async {
    final branchId = _branchId;
    if (branchId == null) return;
    final res = await showDialog<({String patientId, String service})>(
      context: context,
      builder: (_) => _BookDialog(doctorName: doctor.fullName, time: _hm(slot)),
    );
    if (res == null) return;
    await _act(
      () async => ref.read(schedulingRepositoryProvider).book(
            branchId: branchId,
            patientId: res.patientId,
            doctorId: doctor.id,
            startsAt: _slotIso(slot),
            durationMin: _slotStepMin,
            service: res.service.isEmpty ? null : res.service,
          ),
      ok: 'Пациент записан на ${_hm(slot)}',
    );
  }
}

class _DateNav extends StatelessWidget {
  const _DateNav({required this.label, required this.onPrev, required this.onNext, required this.onToday});
  final String label;
  final VoidCallback onPrev, onNext, onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        const SizedBox(width: 8),
        InkWell(
          onTap: onToday,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.tealBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.doctors,
    required this.appts,
    required this.date,
    required this.busy,
    required this.canBook,
    required this.onBook,
    required this.onStatus,
    required this.onReschedule,
    required this.onOpenCard,
  });

  final List<SchedStaff> doctors;
  final List<Appointment> appts;
  final DateTime date;
  final bool busy;
  final bool canBook;
  final void Function(SchedStaff doctor, TimeOfDay slot) onBook;
  final void Function(Appointment a, String status) onStatus;
  final void Function(Appointment a, String doctorId, TimeOfDay slot) onReschedule;
  final void Function(Appointment a) onOpenCard;

  Appointment? _at(String doctorId, TimeOfDay slot) {
    for (final a in appts) {
      final d = a.start;
      if (a.doctorId == doctorId &&
          d != null &&
          d.hour == slot.hour &&
          d.minute == slot.minute &&
          a.status != 'cancelled' &&
          a.status != 'no_show') {
        return a;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slots();
    const timeW = 72.0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.rCard),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // header
          Container(
            color: const Color(0xFFF7FAF9),
            child: Row(
              children: [
                const SizedBox(width: timeW),
                for (final d in doctors)
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: AppColors.line2))),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          Text(d.roles.contains('Doctor') ? 'Врач' : (d.roles.isNotEmpty ? d.roles.first : '—'),
                              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: slots.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.line2),
              itemBuilder: (context, i) {
                final slot = slots[i];
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: timeW,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          child: Text(_hm(slot),
                              style: const TextStyle(
                                  color: AppColors.sub, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      for (final d in doctors)
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                                border: Border(left: BorderSide(color: AppColors.line2))),
                            padding: const EdgeInsets.all(8),
                            child: _Cell(
                              appt: _at(d.id, slot),
                              doctor: d,
                              slot: slot,
                              busy: busy,
                              canBook: canBook,
                              onBook: onBook,
                              onStatus: onStatus,
                              onReschedule: onReschedule,
                              onOpenCard: onOpenCard,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.appt,
    required this.doctor,
    required this.slot,
    required this.busy,
    required this.canBook,
    required this.onBook,
    required this.onStatus,
    required this.onReschedule,
    required this.onOpenCard,
  });

  final Appointment? appt;
  final SchedStaff doctor;
  final TimeOfDay slot;
  final bool busy;
  final bool canBook;
  final void Function(SchedStaff doctor, TimeOfDay slot) onBook;
  final void Function(Appointment a, String status) onStatus;
  final void Function(Appointment a, String doctorId, TimeOfDay slot) onReschedule;
  final void Function(Appointment a) onOpenCard;

  BadgeKind _kind(String s) => switch (s) {
        'arrived' => BadgeKind.info,
        'done' => BadgeKind.neutral,
        'booked' => BadgeKind.success,
        _ => BadgeKind.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final a = appt;
    if (a == null) {
      // free slot — drop target for reschedule + book button
      return DragTarget<Appointment>(
        onWillAcceptWithDetails: (d) => !busy && d.data.doctorId != null,
        onAcceptWithDetails: (d) => onReschedule(d.data, doctor.id, slot),
        builder: (context, candidate, _) {
          final hot = candidate.isNotEmpty;
          return Material(
            color: hot ? AppColors.tealBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: (canBook && !busy) ? () => onBook(doctor, slot) : null,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: hot ? AppColors.accent : const Color(0xFFEFF3F1),
                      style: BorderStyle.solid),
                ),
                child: canBook
                    ? Text(hot ? 'Перенести сюда' : '＋ свободно',
                        style: TextStyle(
                            color: hot ? AppColors.tealDark : const Color(0xFFA8B6B1),
                            fontWeight: FontWeight.w600, fontSize: 12.5))
                    : const SizedBox.shrink(),
              ),
            ),
          );
        },
      );
    }

    final card = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.line2),
      ),
      padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),
              StatusBadge(a.statusLabel, kind: _kind(a.status)),
            ],
          ),
          if (a.service != null && a.service!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(a.service!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          _actions(a),
        ],
      ),
    );

    // booked/arrived are draggable to reschedule; finished ones are static.
    if (a.status == 'booked' || a.status == 'arrived') {
      return LongPressDraggable<Appointment>(
        data: a,
        feedback: Opacity(
          opacity: 0.9,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(width: 200, child: card),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: card),
        child: card,
      );
    }
    return card;
  }

  Widget _actions(Appointment a) {
    final buttons = <Widget>[];
    if (a.status == 'booked') {
      buttons.add(_mini('Пришёл', () => onStatus(a, 'arrived'), filled: true));
      buttons.add(_mini('✕', () => onStatus(a, 'cancelled')));
    } else if (a.status == 'arrived') {
      buttons.add(_mini('Готово', () => onStatus(a, 'done'), filled: true));
      buttons.add(_mini('→ Карта', () => onOpenCard(a)));
    } else {
      buttons.add(Text(a.statusLabel,
          style: const TextStyle(color: AppColors.muted, fontSize: 12)));
    }
    return Wrap(spacing: 6, runSpacing: 4, children: buttons);
  }

  Widget _mini(String label, VoidCallback onTap, {bool filled = false}) {
    return SizedBox(
      height: 30,
      child: filled
          ? FilledButton(
              onPressed: busy ? null : onTap,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 30),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              child: Text(label))
          : OutlinedButton(
              onPressed: busy ? null : onTap,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 30),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              child: Text(label)),
    );
  }
}

class _BookDialog extends ConsumerStatefulWidget {
  const _BookDialog({required this.doctorName, required this.time});
  final String doctorName;
  final String time;

  @override
  ConsumerState<_BookDialog> createState() => _BookDialogState();
}

class _BookDialogState extends ConsumerState<_BookDialog> {
  final _search = TextEditingController();
  final _service = TextEditingController(text: 'Первичная консультация');
  String _query = '';
  Timer? _debounce;
  PatientOption? _selected;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(patientSearchProvider(_query));
    return AlertDialog(
      title: const Text('Запись на приём'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${widget.doctorName} · ${widget.time}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 14),
              if (_selected != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline, color: AppColors.accent),
                  title: Text(_selected!.name),
                  subtitle: Text('МРН ${_selected!.mrn}'),
                  trailing: TextButton(
                      onPressed: () => setState(() => _selected = null),
                      child: const Text('Сменить')),
                )
              else ...[
                TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Пациент (ФИО, МРН, телефон)'),
                  onChanged: _onSearch,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 170,
                  child: results.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.red))),
                    data: (items) => items.isEmpty
                        ? const Center(child: Text('Ничего не найдено'))
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final p = items[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.person_outline),
                                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('МРН ${p.mrn}'),
                                onTap: () => setState(() => _selected = p),
                              );
                            },
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _service,
                decoration: const InputDecoration(isDense: true, labelText: 'Услуга / повод'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(
                  (patientId: _selected!.id, service: _service.text.trim())),
          child: const Text('Записать'),
        ),
      ],
    );
  }
}
