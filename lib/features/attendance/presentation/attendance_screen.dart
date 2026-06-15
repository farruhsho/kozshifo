import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/file_saver.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../admin/data/admin_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_event.dart';
import '../domain/attendance_report.dart';
import '../domain/attendance_status.dart';

/// «Xч Yм» из минут табеля (worked_minutes / total_minutes).
String formatMinutes(int minutes) => '${minutes ~/ 60}ч ${minutes % 60}м';

final _isoDate = DateFormat('yyyy-MM-dd');
final _ruDate = DateFormat('dd.MM.yyyy');
final _ruDateTime = DateFormat('dd.MM.yyyy HH:mm');
final _hhmm = DateFormat('HH:mm');

/// Локальное время `HH:mm` из UTC ISO-метки; «—» если отметки нет.
String _timeLabel(String? iso) {
  if (iso == null) return '—';
  final dt = DateTime.tryParse(iso)?.toLocal();
  return dt == null ? '—' : _hhmm.format(dt);
}

/// `YYYY-MM-DD` → `ДД.ММ.ГГГГ` без парсинга в DateTime.
String _dayLabel(String day) {
  final p = day.split('-');
  return p.length == 3 ? '${p[2]}.${p[1]}.${p[0]}' : day;
}

enum _QuickPeriod { today, week, month }

/// «Сейчас» — живой контроль сотрудников; «Табель» — отчёт за период;
/// «Журнал» — сырые отметки.
enum _View { now, timesheet, journal }

/// Учёт рабочего времени (Face ID): табель посещаемости + сырой журнал
/// отметок + ручные коррекции (attendance.manage) + экспорт CSV.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  _QuickPeriod? _quick = _QuickPeriod.week;
  late DateTimeRange _range = _rangeFor(_QuickPeriod.week);
  _View _view = _View.now;
  bool _exporting = false;
  // Смена ключа пересоздаёт журнал после ручной отметки (он копит страницы).
  int _logTick = 0;

  static DateTimeRange _rangeFor(_QuickPeriod quick) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (quick) {
      _QuickPeriod.today => DateTimeRange(start: today, end: today),
      _QuickPeriod.week => DateTimeRange(
          start: today.subtract(Duration(days: today.weekday - 1)),
          end: today),
      _QuickPeriod.month =>
        DateTimeRange(start: DateTime(today.year, today.month, 1), end: today),
    };
  }

  AttendancePeriod get _period =>
      (from: _isoDate.format(_range.start), to: _isoDate.format(_range.end));

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        _quick = null;
        _range = picked;
      });
    }
  }

  Future<void> _exportCsv() async {
    final period = _period;
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(attendanceRepositoryProvider)
          .reportCsv(dateFrom: period.from, dateTo: period.to);
      final path = await saveBytes(
        bytes,
        'attendance_${period.from}_${period.to}.csv',
        'text/csv',
      );
      if (!mounted) return;
      _snack(path == null ? 'CSV загружен' : 'CSV сохранён: $path');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openManualPunch() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ManualPunchDialog(),
    );
    if (ok == true && mounted) {
      ref.invalidate(attendanceReportProvider);
      ref.invalidate(attendanceStatusProvider);
      setState(() => _logTick++);
      _snack('Отметка добавлена');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final canManage = user?.can('attendance.manage') ?? false;
    final period = _period;

    final showPeriod = _view != _View.now;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сотрудники'),
        actions: [
          if (_view == _View.now)
            IconButton(
              tooltip: 'Обновить',
              onPressed: () => ref.invalidate(attendanceStatusProvider),
              icon: const Icon(Icons.refresh),
            )
          else
            IconButton(
              tooltip: 'Экспорт CSV (Excel)',
              onPressed: _exporting ? null : _exportCsv,
              icon: _exporting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
            ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openManualPunch,
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Отметить вручную'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<_View>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                        value: _View.now,
                        label: Text('Сейчас'),
                        icon: Icon(Icons.groups_outlined)),
                    ButtonSegment(
                        value: _View.timesheet,
                        label: Text('Табель'),
                        icon: Icon(Icons.table_chart_outlined)),
                    ButtonSegment(
                        value: _View.journal,
                        label: Text('Журнал'),
                        icon: Icon(Icons.list_alt_outlined)),
                  ],
                  selected: {_view},
                  onSelectionChanged: (s) => setState(() => _view = s.first),
                ),
                if (showPeriod) ...[
                  ChoiceChip(
                    label: const Text('Сегодня'),
                    selected: _quick == _QuickPeriod.today,
                    onSelected: (_) => setState(() {
                      _quick = _QuickPeriod.today;
                      _range = _rangeFor(_QuickPeriod.today);
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('Неделя'),
                    selected: _quick == _QuickPeriod.week,
                    onSelected: (_) => setState(() {
                      _quick = _QuickPeriod.week;
                      _range = _rangeFor(_QuickPeriod.week);
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('Месяц'),
                    selected: _quick == _QuickPeriod.month,
                    onSelected: (_) => setState(() {
                      _quick = _QuickPeriod.month;
                      _range = _rangeFor(_QuickPeriod.month);
                    }),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text(_quick == null
                        ? '${_ruDate.format(_range.start)} — ${_ruDate.format(_range.end)}'
                        : 'Период…'),
                    onPressed: _pickCustomRange,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: switch (_view) {
              _View.now => const _StaffNowView(),
              _View.timesheet => _TimesheetView(period: period),
              _View.journal => _EventLogView(
                  key: ValueKey('log-${period.from}-${period.to}-$_logTick'),
                  period: period),
            },
          ),
        ],
      ),
    );
  }
}

// ═══ Сейчас (живой контроль) ═════════════════════════════════════════════════

/// Контроль-центр директора: кто на работе прямо сейчас, опоздания, часы за
/// сегодня и состояние Face ID-интеграции.
class _StaffNowView extends ConsumerWidget {
  const _StaffNowView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(attendanceStatusProvider);
    final scheme = Theme.of(context).colorScheme;

    return AsyncValueWidget<AttendanceStatus>(
      value: status,
      onRetry: () => ref.invalidate(attendanceStatusProvider),
      builder: (s) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(attendanceStatusProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
            children: [
              _faceIdBanner(context, s.integrationEnabled),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _countChip(context, 'На работе', s.presentCount, Colors.green),
                  _countChip(context, 'Ушли', s.leftCount, scheme.outline),
                  _countChip(context, 'Отсутствуют', s.absentCount,
                      s.absentCount > 0 ? scheme.error : scheme.outline),
                  _countChip(context, 'Опоздали', s.lateCount,
                      s.lateCount > 0 ? Colors.orange : scheme.outline),
                  Chip(
                    avatar: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text('Начало дня: ${s.workDayStart}'),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (s.staff.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Сотрудников нет.')),
                )
              else
                for (final m in s.staff) _StaffNowTile(member: m),
            ],
          ),
        );
      },
    );
  }

  Widget _faceIdBanner(BuildContext context, bool enabled) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: enabled ? scheme.secondaryContainer : scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(enabled ? Icons.verified_user_outlined : Icons.report_gmailerrorred_outlined,
                color: enabled ? scheme.onSecondaryContainer : scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                enabled
                    ? 'Face ID подключён — терминал отмечает приход/уход автоматически.'
                    : 'Face ID не настроен — отметки только вручную. '
                        'Подключите терминал (ключ HIKVISION_EVENT_TOKEN).',
                style: TextStyle(
                  color: enabled
                      ? scheme.onSecondaryContainer
                      : scheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countChip(BuildContext context, String label, int n, Color color) {
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      label: Text('$label: $n',
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StaffNowTile extends StatelessWidget {
  const _StaffNowTile({required this.member});

  final StaffNow member;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color, icon) = switch (member.status) {
      'present' => ('на работе', Colors.green, Icons.login),
      'left' => ('ушёл', scheme.outline, Icons.logout),
      _ => ('отсутствует', scheme.error, Icons.remove_circle_outline),
    };
    final subtitle = StringBuffer();
    if (member.firstIn != null) subtitle.write('приход ${_timeLabel(member.firstIn)}');
    if (member.workedMinutes > 0) {
      if (subtitle.isNotEmpty) subtitle.write(' · ');
      subtitle.write(formatMinutes(member.workedMinutes));
    }
    if (subtitle.isEmpty) subtitle.write('нет отметок сегодня');

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(member.fullName),
        subtitle: Text(
          member.role == null ? subtitle.toString() : '${member.role} · $subtitle',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (member.late)
              Chip(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                side: BorderSide.none,
                label: const Text('опоздание',
                    style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            Chip(
              visualDensity: VisualDensity.compact,
              backgroundColor: color.withValues(alpha: 0.12),
              side: BorderSide.none,
              label: Text(label, style: TextStyle(color: color, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══ Табель ══════════════════════════════════════════════════════════════════

class _TimesheetView extends ConsumerWidget {
  const _TimesheetView({required this.period});

  final AttendancePeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(attendanceReportProvider(period));

    return AsyncValueWidget<AttendanceReport>(
      value: report,
      onRetry: () => ref.invalidate(attendanceReportProvider(period)),
      builder: (r) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Период: ${_dayLabel(r.dateFrom)} — ${_dayLabel(r.dateTo)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Chip(
                    avatar: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text('Начало дня: ${r.workDayStart}'),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                ],
              ),
            ),
            Expanded(
              child: r.users.isEmpty
                  ? const Center(child: Text('Нет данных за период.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: r.users.length,
                      itemBuilder: (context, i) =>
                          _UserTimesheetCard(user: r.users[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _UserTimesheetCard extends StatelessWidget {
  const _UserTimesheetCard({required this.user});

  final AttendanceUserReport user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    const lateColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('Итого: ${formatMinutes(user.totalMinutes)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Дней: ${user.daysPresent}'),
              Text(
                'Пропусков: ${user.daysAbsent}',
                style: user.daysAbsent > 0
                    ? TextStyle(
                        color: errorColor, fontWeight: FontWeight.bold)
                    : null,
              ),
              Text(
                'Опозданий: ${user.lateCount}',
                style: user.lateCount > 0
                    ? const TextStyle(
                        color: lateColor, fontWeight: FontWeight.bold)
                    : null,
              ),
            ],
          ),
        ),
        children: [
          if (user.days.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Нет отметок за период.'),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _DaysTable(days: user.days),
            ),
        ],
      ),
    );
  }
}

class _DaysTable extends StatelessWidget {
  const _DaysTable({required this.days});

  final List<AttendanceDay> days;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontWeight: FontWeight.bold);

    Widget cell(String text, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(text, style: style),
        );

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [
          cell('Дата', style: headerStyle),
          cell('Приход', style: headerStyle),
          cell('Уход', style: headerStyle),
          cell('Часы', style: headerStyle),
          const SizedBox.shrink(),
        ]),
        for (final d in days)
          TableRow(children: [
            cell(_dayLabel(d.day)),
            cell(_timeLabel(d.firstIn)),
            cell(_timeLabel(d.lastOut)),
            cell(formatMinutes(d.workedMinutes)),
            d.late
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: _LateBadge(),
                  )
                : const SizedBox.shrink(),
          ]),
      ],
    );
  }
}

class _LateBadge extends StatelessWidget {
  const _LateBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'опоздание',
        style: TextStyle(
            color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ═══ Журнал отметок ══════════════════════════════════════════════════════════

class _EventLogView extends ConsumerStatefulWidget {
  const _EventLogView({super.key, required this.period});

  final AttendancePeriod period;

  @override
  ConsumerState<_EventLogView> createState() => _EventLogViewState();
}

class _EventLogViewState extends ConsumerState<_EventLogView> {
  static const _pageSize = 50;

  final _items = <AttendanceEvent>[];
  int _total = 0;
  bool _loading = false;
  // Ошибка первой страницы — полноэкранная с «Повторить»; ошибка догрузки —
  // SnackBar, уже показанные строки не теряем.
  Object? _firstPageError;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  bool get _hasMore => _items.length < _total;

  Future<void> _loadMore() async {
    setState(() {
      _loading = true;
      _firstPageError = null;
    });
    try {
      final page = await ref.read(attendanceRepositoryProvider).events(
            dateFrom: widget.period.from,
            dateTo: widget.period.to,
            offset: _items.length,
            limit: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_items.isEmpty) {
        setState(() => _firstPageError = e);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firstPageError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 40, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text('$_firstPageError', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(
                  onPressed: _loadMore, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Отметок за период нет.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == _items.length) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: _loadMore,
                      child: Text(
                          'Загрузить ещё (${_total - _items.length})'),
                    ),
            ),
          );
        }
        return _EventTile(event: _items[i]);
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final AttendanceEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inColor = Colors.green.shade700;
    final outColor = theme.colorScheme.outline;
    final dt = DateTime.tryParse(event.occurredAt)?.toLocal();
    final when = dt == null ? event.occurredAt : _ruDateTime.format(dt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            (event.isIn ? inColor : outColor).withValues(alpha: 0.12),
        child: Icon(event.isIn ? Icons.login : Icons.logout,
            color: event.isIn ? inColor : outColor),
      ),
      title: Text(event.userFullName ?? 'Сотрудник'),
      subtitle: Text([when, if (event.note != null) event.note!].join(' · ')),
      trailing: Wrap(
        spacing: 4,
        children: [
          Chip(
            label: Text(event.isIn ? 'приход' : 'уход'),
            labelStyle:
                TextStyle(color: event.isIn ? inColor : outColor),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
            backgroundColor:
                (event.isIn ? inColor : outColor).withValues(alpha: 0.1),
          ),
          Chip(
            label: Text(event.source == 'manual' ? 'вручную' : 'Face ID'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ═══ Ручная отметка ══════════════════════════════════════════════════════════

class _ManualPunchDialog extends ConsumerStatefulWidget {
  const _ManualPunchDialog();

  @override
  ConsumerState<_ManualPunchDialog> createState() =>
      _ManualPunchDialogState();
}

class _ManualPunchDialogState extends ConsumerState<_ManualPunchDialog> {
  final _note = TextEditingController();
  String? _userId;
  String _direction = 'in';
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _canSave => !_saving && _userId != null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(attendanceRepositoryProvider).createEvent(
            userId: _userId!,
            direction: _direction,
            occurredAt: DateTime(
                _date.year, _date.month, _date.day, _time.hour, _time.minute),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);

    return AlertDialog(
      title: const Text('Ручная отметка'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            users.when(
              data: (items) => DropdownButtonFormField<String>(
                initialValue: _userId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Сотрудник'),
                items: [
                  for (final u in items.where((u) => u.isActive))
                    DropdownMenuItem(
                        value: u.id,
                        child:
                            Text(u.fullName, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _userId = v),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text('Сотрудники недоступны: $e',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: 'in',
                    label: Text('Приход'),
                    icon: Icon(Icons.login)),
                ButtonSegment(
                    value: 'out',
                    label: Text('Уход'),
                    icon: Icon(Icons.logout)),
              ],
              selected: {_direction},
              onSelectionChanged: (s) =>
                  setState(() => _direction = s.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_ruDate.format(_date)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 255,
              decoration: const InputDecoration(
                  labelText: 'Примечание (необязательно)',
                  hintText: 'забыл отметиться'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
