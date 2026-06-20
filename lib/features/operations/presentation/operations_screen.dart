import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../auth/application/auth_controller.dart';
import '../../clinical/data/clinical_repository.dart';
import '../../clinical/domain/operation.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/domain/product.dart';

final _dateTime = DateFormat('dd.MM.yyyy HH:mm');

/// Soft per-day operations capacity. The scheduling board warns (amber/red) when
/// a day reaches this many ops — it never blocks placement, force-majeure days
/// can run over.
const kOpsPerDayCap = 15;

/// Раздел «Операции» (TZ Modul 6) — рабочий список операционного отделения в
/// дизайн-системе Clinic OS. Ресепшен планирует направленные операции
/// (дата/цена), врач-хирург начинает, выполняет (списание расходников) и
/// завершает их.
class OperationsScreen extends ConsumerStatefulWidget {
  const OperationsScreen({super.key});

  @override
  ConsumerState<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends ConsumerState<OperationsScreen> {
  // Worklist tabs map 1:1 to a backend status filter (null = «Все»).
  static const _tabs = <(String, String?)>[
    ('Направленные', 'referred'),
    ('Запланированные', 'scheduled'),
    ('Идут', 'in_progress'),
    ('Выполненные', 'performed'),
    ('Завершённые', 'completed'),
    ('Все', null),
  ];

  String? _status = 'referred';
  // Календарь операций: режим + выбранный день (фильтр scheduled по дате).
  bool _calendar = false;
  DateTime _calDay = DateTime.now();

  void _reload() {
    for (final t in _tabs) {
      ref.invalidate(operationsWorklistProvider(t.$2));
    }
    ref.invalidate(scheduledOperationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final operations = ref.watch(operationsWorklistProvider(_status));
    final user = ref.watch(authControllerProvider).user;
    final canSchedule = user?.can('operations.schedule') ?? false;
    final canPerform = user?.can('operations.perform') ?? false;
    final canCancel =
        canSchedule || (user?.can('operations.prescribe') ?? false);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Операции'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(_calendar ? null : operations.asData?.value.length),
              const SizedBox(height: 16),
              _modeToggle(),
              const SizedBox(height: 16),
              if (_calendar)
                _calendarView()
              else ...[
                _filterChips(),
                const SizedBox(height: 16),
                operations.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => AppCard(
                    child: Center(
                      child: Text(
                        e is ApiException ? e.message : '$e',
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const AppCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: Text('Операций нет')),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final op in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OperationCard(
                              op: op,
                              canSchedule: canSchedule,
                              canPerform: canPerform,
                              canCancel: canCancel,
                              onChanged: _reload,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeToggle() {
    return Wrap(
      spacing: 8,
      children: [
        _FilterChip(
          label: 'Список',
          selected: !_calendar,
          onTap: () => setState(() => _calendar = false),
        ),
        _FilterChip(
          label: 'Календарь',
          selected: _calendar,
          onTap: () => setState(() => _calendar = true),
        ),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Доска планирования операций на день: слева — поставленные на выбранный день
  /// операции (с «Открепить»), справа — пул направленных пациентов (с «Поставить
  /// на <дата>»). Времени дня нет: длительность операций разная, день не сетка по
  /// часам, а список пациентов на дату. На широком экране — две колонки, на узком
  /// пул уходит под список дня.
  Widget _calendarView() {
    // Нормализуем до даты (локальная полночь): ключ семейства — один и тот же
    // для всех пересборок одного календарного дня, иначе каждый кадр плодил бы
    // новый провайдер и сетевой запрос.
    final day = DateTime(_calDay.year, _calDay.month, _calDay.day);
    final scheduled = ref.watch(scheduledOperationsProvider(day));
    final user = ref.watch(authControllerProvider).user;
    final canReadPnl = user?.can('operations.read') ?? false;
    final canSchedule = user?.can('operations.schedule') ?? false;

    // Кол-во операций дня (для счётчика-капа). Берём из уже загруженных данных;
    // пока грузится — null (бейдж капа не показываем).
    final dayCount = scheduled.asData?.value
        .where((o) => o.scheduledAtLocal != null)
        .where((o) => _sameDay(o.scheduledAtLocal!, _calDay))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton.outlined(
              onPressed: () => setState(
                () => _calDay = _calDay.subtract(const Duration(days: 1)),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() => _calDay = DateTime.now()),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tealBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  DateFormat('dd.MM.yyyy').format(_calDay),
                  style: const TextStyle(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: () => setState(
                () => _calDay = _calDay.add(const Duration(days: 1)),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
            const Spacer(),
            if (dayCount != null) _capBadge(dayCount),
          ],
        ),
        if (canReadPnl) ...[
          const SizedBox(height: 16),
          _pnlCard(day),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final dayPane = _scheduledPane(day, scheduled, canSchedule);
            final poolPane = _poolPane(day, canSchedule);
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dayPane),
                  const SizedBox(width: 16),
                  SizedBox(width: 380, child: poolPane),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dayPane,
                const SizedBox(height: 16),
                poolPane,
              ],
            );
          },
        ),
      ],
    );
  }

  /// Счётчик-кап «N / 15 на день» у навигации по датам. Только предупреждение —
  /// планирование сверх капа не блокируется (форс-мажорные перегруженные дни).
  Widget _capBadge(int count) {
    final over = count >= kOpsPerDayCap;
    final color = over ? AppColors.red : AppColors.tealDark;
    final bg = over ? AppColors.redBg : AppColors.tealBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count / $kOpsPerDayCap на день',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Левая колонка доски: операции, поставленные на выбранный день.
  Widget _scheduledPane(
    DateTime day,
    AsyncValue<List<Operation>> scheduled,
    bool canSchedule,
  ) {
    return scheduled.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppCard(
        child: Center(
          child: Text(
            e is ApiException ? e.message : '$e',
            style: const TextStyle(color: AppColors.red),
          ),
        ),
      ),
      data: (items) {
        // Сервер уже отдал ровно этот день (окно scheduled_from/_to). Фильтр
        // _sameDay — страхующий no-op на случай расхождения границ.
        final ops = [
          for (final o in items)
            if (o.scheduledAtLocal != null) (op: o, at: o.scheduledAtLocal!),
        ]..removeWhere((e) => !_sameDay(e.at, _calDay));
        ops.sort((a, b) => a.at.compareTo(b.at));
        if (ops.isEmpty) {
          return const AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('На этот день операций нет')),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final e in ops) _calCard(e.op, day, canSchedule)],
        );
      },
    );
  }

  /// Правая колонка доски: пул «Направлены на операцию» — пациенты, которых врач
  /// направил, но ресепшен ещё не поставил на день. Каждый с «Поставить на
  /// <дата>». Виден под `operations.read`; кнопка — под `operations.schedule`.
  Widget _poolPane(DateTime day, bool canSchedule) {
    final canRead =
        ref.watch(authControllerProvider).user?.can('operations.read') ?? false;
    if (!canRead) return const SizedBox.shrink();
    final pool = ref.watch(referredOperationsProvider);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Направлены на операцию',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              if (pool.asData != null)
                Text(
                  '${pool.asData!.value.length}',
                  style: const TextStyle(
                    color: AppColors.sub,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          pool.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Text(
              e is ApiException ? e.message : '$e',
              style: const TextStyle(color: AppColors.red, fontSize: 12.5),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Пул пуст — нет направленных пациентов',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final op in items) _poolCard(op, day, canSchedule),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Карточка пула: пациент + тип + глаз + хирург и кнопка «Поставить на <дата>».
  Widget _poolCard(Operation op, DateTime day, bool canSchedule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    op.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (op.isUrgent)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.priority_high,
                      color: AppColors.red,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${op.typeName} · ${op.eyeLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.sub, fontSize: 13),
            ),
            if (op.surgeonName != null)
              Text(
                'Хирург: ${op.surgeonName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.sub, fontSize: 12.5),
              ),
            if (canSchedule) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _placeOnDay(op, day),
                  icon: const Icon(Icons.event_available, size: 18),
                  label: Text('Поставить на ${DateFormat('dd.MM').format(day)}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// «Поставить на день»: маленький диалог (хирург + цена), затем планирование на
  /// 09:00 выбранного дня (время — заглушка, доска его не показывает).
  Future<void> _placeOnDay(Operation op, DateTime day) async {
    final res = await showDialog<({String? surgeonId, String? price})>(
      context: context,
      builder: (_) => _PlaceOnDayDialog(op: op, day: day),
    );
    if (res == null || !mounted) return;
    final scheduledAt = DateTime(day.year, day.month, day.day, 9);
    try {
      await ref
          .read(clinicalRepositoryProvider)
          .scheduleOperationAt(
            id: op.id,
            scheduledAt: scheduledAt,
            surgeonId: res.surgeonId,
            price: res.price,
          );
      if (!mounted) return;
      _afterBoardChange(day, 'Пациент поставлен на ${DateFormat('dd.MM').format(day)}');
    } catch (e) {
      if (mounted) {
        _boardSnack(e is ApiException ? e.message : '$e', error: true);
      }
    }
  }

  /// «Открепить»: возвращает операцию в пул (де-биллинг). 409 (уже оплачено)
  /// показываем как ошибку в SnackBar.
  Future<void> _detach(Operation op, DateTime day) async {
    try {
      await ref.read(clinicalRepositoryProvider).unscheduleOperation(op.id);
      if (!mounted) return;
      _afterBoardChange(day, 'Операция откреплена и возвращена в пул');
    } catch (e) {
      if (mounted) {
        _boardSnack(e is ApiException ? e.message : '$e', error: true);
      }
    }
  }

  void _afterBoardChange(DateTime day, String message) {
    ref.invalidate(scheduledOperationsProvider(day));
    ref.invalidate(referredOperationsProvider);
    ref.invalidate(operationDayPnlProvider(day));
    _boardSnack(message);
  }

  void _boardSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.red : null,
      ),
    );
  }

  /// «P&L дня» — итог операций выбранного календарного дня (выручка − COGS −
  /// расходы = прибыль) для филиала пользователя. Сбой сводки не ломает
  /// календарь: рендерим компактную ошибку, список операций живёт отдельно.
  Widget _pnlCard(DateTime day) {
    final pnl = ref.watch(operationDayPnlProvider(day));
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: pnl.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (e, _) => Text(
          'Сводка дня недоступна: ${e is ApiException ? e.message : e}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
        ),
        data: (p) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'P&L дня',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '${p.operationsCount} опер.',
                  style: const TextStyle(
                    color: AppColors.sub,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _pnlRow('Выручка', p.revenue),
            _pnlRow('Себестоимость', p.cogs),
            _pnlRow('Расходы', p.expenses),
            const Divider(height: 18, color: AppColors.line),
            _pnlRow('Прибыль', p.profit, emphasize: true),
          ],
        ),
      ),
    );
  }

  Widget _pnlRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasize ? AppColors.ink : AppColors.sub,
                fontSize: 13.5,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMoney(value),
            textAlign: TextAlign.right,
            style: AppTypography.number(
              emphasize ? 16 : 14,
              color: emphasize ? AppColors.tealDark : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка операции дня. Времени дня НЕТ (по требованию владельца: длительность
  /// операций разная, доска — список пациентов на дату). Тап — медкарта; под
  /// `operations.schedule` есть «Открепить» (форс-мажор → вернуть в пул).
  Widget _calCard(Operation op, DateTime day, bool canSchedule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.go('/patients/${op.patientId}/card'),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          op.patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${op.typeName} · ${op.eyeLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.sub,
                            fontSize: 13,
                          ),
                        ),
                        if (op.surgeonName != null)
                          Text(
                            'Хирург: ${op.surgeonName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.sub,
                              fontSize: 12.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (op.isUrgent)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.priority_high,
                        color: AppColors.red,
                        size: 20,
                      ),
                    ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
            if (canSchedule) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _detach(op, day),
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('Открепить'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hero(int? count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.sidebarGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.healing_outlined,
            size: 34,
            color: AppColors.mintLight,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Операционное отделение',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Направления, планирование и выполнение операций',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mintLight.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: AppTypography.number(22, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value) in _tabs)
          _FilterChip(
            label: label,
            selected: _status == value,
            onTap: () => setState(() => _status = value),
          ),
      ],
    );
  }
}

/// Pill-style filter chip in the brand teal (selected) / hairline (idle).
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.tealDark : AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.tealDark : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.sub,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationCard extends ConsumerWidget {
  const _OperationCard({
    required this.op,
    required this.canSchedule,
    required this.canPerform,
    required this.canCancel,
    required this.onChanged,
  });

  final Operation op;
  final bool canSchedule;
  final bool canPerform;
  final bool canCancel;
  final VoidCallback onChanged;

  static String _initials(String name) {
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

  BadgeKind get _kind => switch (op.status) {
    'referred' => BadgeKind.info,
    'scheduled' => BadgeKind.warning,
    'in_progress' => BadgeKind.info,
    'performed' || 'completed' => BadgeKind.success,
    _ => BadgeKind.neutral,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduled = DateTime.tryParse(op.scheduledAt ?? '')?.toLocal();
    final meta = <String>[
      op.eyeLabel,
      if (scheduled != null) _dateTime.format(scheduled),
      if (op.price != null) formatMoney(op.price),
      if (op.surgeonName != null) 'Хирург: ${op.surgeonName}',
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(_initials(op.patientName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      op.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      op.typeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.sub,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (op.isUrgent) ...[
                const Pill(
                  label: 'срочно',
                  color: AppColors.red,
                  bg: AppColors.redBg,
                ),
                const SizedBox(width: 6),
              ],
              StatusBadge(op.statusLabel, kind: _kind),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            meta.join('  ·  '),
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
          if (op.notes != null && op.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              op.notes!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
          if (_hasActions) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: _actions(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasActions =>
      (canSchedule && (op.isReferred || op.isScheduled)) ||
      (canPerform && (op.isScheduled || op.isInProgress || op.isPerformed)) ||
      (canCancel && op.isOpen);

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    final widgets = <Widget>[];

    // Secondary actions first (left), primary gradient CTA last (right).
    if (canPerform && op.isScheduled) {
      widgets.add(
        _secondary(
          'Начать',
          () => _run(
            context,
            ref,
            (r) => r.startOperation(op.id),
            'Операция начата',
          ),
        ),
      );
    }
    if (canSchedule && op.isScheduled) {
      widgets.add(_secondary('Изменить', () => _schedule(context, ref)));
    }
    if (canCancel && op.isOpen) {
      widgets.add(
        _secondary(
          'Отменить',
          () => _run(
            context,
            ref,
            (r) => r.cancelOperation(op.id),
            'Операция отменена',
          ),
        ),
      );
    }

    // Primary CTA for the current state.
    if (canSchedule && op.isReferred) {
      widgets.add(_primary('Запланировать', () => _schedule(context, ref)));
    } else if (canPerform && (op.isScheduled || op.isInProgress)) {
      widgets.add(_primary('Выполнить', () => _perform(context, ref)));
    } else if (canPerform && op.isPerformed) {
      widgets.add(_primary('Завершить', () => _complete(context, ref)));
    }
    return widgets;
  }

  Widget _primary(String label, VoidCallback onPressed) => SizedBox(
    width: 150,
    child: GradientButton(label: label, height: 40, onPressed: onPressed),
  );

  Widget _secondary(String label, VoidCallback onPressed) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(foregroundColor: AppColors.tealDark),
    child: Text(label),
  );

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<Operation> Function(ClinicalRepository) call,
    String okMessage,
  ) async {
    try {
      await call(ref.read(clinicalRepositoryProvider));
      if (!context.mounted) return;
      onChanged();
      _snack(context, okMessage);
    } catch (e) {
      if (context.mounted) {
        _snack(context, e is ApiException ? e.message : '$e', error: true);
      }
    }
  }

  Future<void> _schedule(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ScheduleDialog(op: op),
    );
    if (ok == true) onChanged();
  }

  Future<void> _perform(BuildContext context, WidgetRef ref) async {
    final adHoc = await showDialog<List<({String productId, String quantity})>>(
      context: context,
      builder: (_) => _PerformDialog(op: op),
    );
    if (adHoc == null || !context.mounted) return; // отмена
    await _run(
      context,
      ref,
      (r) => r.performOperation(op.id, adHocConsumables: adHoc),
      'Операция выполнена, расходники списаны',
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Завершить операцию'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Результат / заключение',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = controller.text.trim();
    await _run(
      context,
      ref,
      (r) => r.completeOperation(op.id, result: result.isEmpty ? null : result),
      'Операция завершена',
    );
  }

  void _snack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.red : null,
      ),
    );
  }
}

/// Диалог «Выполнить»: ресепшен/хирург отмечает галочками фактически
/// использованные (ad-hoc) расходники сверх шаблона типа операции — все
/// списываются одним атомарным действием. Возврат: список {productId, quantity}
/// (пусто = только шаблон); null = отмена.
class _PerformDialog extends ConsumerStatefulWidget {
  const _PerformDialog({required this.op});

  final Operation op;

  @override
  ConsumerState<_PerformDialog> createState() => _PerformDialogState();
}

class _PerformDialogState extends ConsumerState<_PerformDialog> {
  final _search = TextEditingController();
  String _query = '';
  // Отмеченные ad-hoc расходники: id → продукт, и id → количество (по умолч. 1).
  final Map<String, Product> _selected = {};
  final Map<String, double> _qty = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(Product p, bool on) {
    setState(() {
      if (on) {
        _selected[p.id] = p;
        _qty.putIfAbsent(p.id, () => 1);
      } else {
        _selected.remove(p.id);
        _qty.remove(p.id);
      }
    });
  }

  List<({String productId, String quantity})> _result() => [
    for (final p in _selected.values)
      (productId: p.id, quantity: QuantityStepper.format(_qty[p.id] ?? 1)),
  ];

  @override
  Widget build(BuildContext context) {
    final canSearch =
        ref.watch(authControllerProvider).user?.can('inventory.read') ?? false;
    final errStyle = TextStyle(color: Theme.of(context).colorScheme.error);
    return AlertDialog(
      title: Text(widget.op.typeName),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Шаблонные расходники типа спишутся автоматически. Отметьте '
              'галочками дополнительно использованные — спишутся одним действием.',
            ),
            const SizedBox(height: 12),
            if (!canSearch)
              Text(
                'Добавление расходников требует доступа к складу — '
                'спишутся только шаблонные.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Поиск расходника',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: ref.watch(productsProvider).when(
                      data: (all) {
                        final q = _query.trim().toLowerCase();
                        // Инструменты — многоразовые активы, не одноразовые
                        // расходники: прячем из списка списания.
                        final items = all
                            .where((p) => p.productType != 'instrument')
                            .where((p) =>
                                q.isEmpty ||
                                p.name.toLowerCase().contains(q) ||
                                p.sku.toLowerCase().contains(q))
                            .toList();
                        if (items.isEmpty) {
                          return const Center(child: Text('Ничего не найдено'));
                        }
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final p = items[i];
                            final on = _selected.containsKey(p.id);
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: on,
                                  onChanged: (v) => _toggle(p, v ?? false),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _toggle(p, !on),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name),
                                        Text('${p.sku} · ${p.typeLabel}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                  ),
                                ),
                                if (on)
                                  QuantityStepper(
                                    value: _qty[p.id] ?? 1,
                                    unit: p.unit,
                                    onChanged: (v) =>
                                        setState(() => _qty[p.id] = v),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Text('Каталог недоступен: $e', style: errStyle),
                    ),
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Выбрано расходников: ${_selected.length}',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_result()),
          child: const Text('Выполнить'),
        ),
      ],
    );
  }
}

/// Диалог планирования операции ресепшеном: дата/время (обязательно) и цена
/// (необязательно — по умолчанию из каталога). Именно планирование выставляет
/// счёт на визит.
class _ScheduleDialog extends ConsumerStatefulWidget {
  const _ScheduleDialog({required this.op});

  final Operation op;

  @override
  ConsumerState<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends ConsumerState<_ScheduleDialog> {
  final _price = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = DateTime.tryParse(widget.op.scheduledAt ?? '')?.toLocal();
    if (existing != null) {
      _date = DateTime(existing.year, existing.month, existing.day);
      _time = TimeOfDay(hour: existing.hour, minute: existing.minute);
    }
    if (widget.op.price != null) _price.text = widget.op.price!;
    if (widget.op.notes != null) _notes.text = widget.op.notes!;
  }

  @override
  void dispose() {
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final date = _date;
    if (date == null) return;
    setState(() => _saving = true);
    // Local wall-clock -> UTC ISO so the server stores an absolute instant.
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      _time.hour,
      _time.minute,
    );
    final price = _price.text.trim();
    final notes = _notes.text.trim();
    try {
      await ref
          .read(clinicalRepositoryProvider)
          .scheduleOperation(
            id: widget.op.id,
            scheduledAt: dt.toUtc().toIso8601String(),
            price: price.isEmpty ? null : price,
            notes: notes.isEmpty ? null : notes,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : '$e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null
        ? 'Выбрать дату'
        : DateFormat('dd.MM.yyyy').format(_date!);
    return AlertDialog(
      title: Text('Планирование: ${widget.op.typeName}'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(dateLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Цена',
                helperText: 'Пусто — цена из каталога',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Примечание (необязательно)',
              ),
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
          onPressed: (_saving || _date == null) ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}

/// Лёгкий диалог доски «Поставить на день»: необязательный хирург (включая
/// приезжих) + необязательная цена. День и время (заглушка 09:00) задаёт доска —
/// здесь их нет. Возврат: `(surgeonId, price)` (оба могут быть null); null — отмена.
class _PlaceOnDayDialog extends ConsumerStatefulWidget {
  const _PlaceOnDayDialog({required this.op, required this.day});

  final Operation op;
  final DateTime day;

  @override
  ConsumerState<_PlaceOnDayDialog> createState() => _PlaceOnDayDialogState();
}

class _PlaceOnDayDialogState extends ConsumerState<_PlaceOnDayDialog> {
  final _price = TextEditingController();
  String? _surgeonId;

  @override
  void initState() {
    super.initState();
    _surgeonId = widget.op.surgeonId;
    if (widget.op.price != null) _price.text = widget.op.price!;
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surgeons = ref.watch(surgeonsProvider);
    final dayLabel = DateFormat('dd.MM.yyyy').format(widget.day);
    return AlertDialog(
      title: Text('На $dayLabel: ${widget.op.typeName}'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.op.patientName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.op.typeName} · ${widget.op.eyeLabel}',
              style: const TextStyle(color: AppColors.sub, fontSize: 13),
            ),
            const SizedBox(height: 16),
            surgeons.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'Хирурги недоступны: ${e is ApiException ? e.message : e}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
              data: (list) => DropdownButtonFormField<String?>(
                initialValue: list.any((s) => s.id == _surgeonId)
                    ? _surgeonId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Хирург (необязательно)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— не назначен —'),
                  ),
                  for (final s in list)
                    DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(
                        s.isExternal ? '${s.fullName} · приезжий' : s.fullName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _surgeonId = v),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Цена',
                hintText: 'по умолчанию — цена услуги',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final price = _price.text.trim();
            Navigator.of(context).pop((
              surgeonId: _surgeonId,
              price: price.isEmpty ? null : price,
            ));
          },
          child: const Text('Поставить'),
        ),
      ],
    );
  }
}
