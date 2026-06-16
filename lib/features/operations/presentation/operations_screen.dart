import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../clinical/data/clinical_repository.dart';
import '../../clinical/domain/operation.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/domain/product.dart';

final _dateTime = DateFormat('dd.MM.yyyy HH:mm');

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

  void _reload() {
    for (final t in _tabs) {
      ref.invalidate(operationsWorklistProvider(t.$2));
    }
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
              _hero(operations.asData?.value.length),
              const SizedBox(height: 16),
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
          ),
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

/// Диалог «Выполнить»: ресепшен/хирург добавляет фактически использованные
/// (ad-hoc) расходники сверх шаблона типа операции. Возврат: список
/// {productId, quantity} (пусто = только шаблон); null = отмена.
class _PerformDialog extends ConsumerStatefulWidget {
  const _PerformDialog({required this.op});

  final Operation op;

  @override
  ConsumerState<_PerformDialog> createState() => _PerformDialogState();
}

class _PerformDialogState extends ConsumerState<_PerformDialog> {
  final _search = TextEditingController();
  String _query = '';
  Timer? _debounce;
  // Выбранные ad-hoc расходники: продукт → контроллер количества.
  final Map<Product, TextEditingController> _adHoc = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    for (final c in _adHoc.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Строка ad-hoc валидна = количество положительное число.
  bool _qtyValid(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return v != null && v > 0;
  }

  bool get _allQtysValid => _adHoc.values.every(_qtyValid);

  void _add(Product p) {
    if (_adHoc.containsKey(p)) return;
    setState(() {
      _adHoc[p] = TextEditingController(text: '1');
      _search.clear();
      _query = '';
    });
  }

  void _remove(Product p) {
    setState(() => _adHoc.remove(p)?.dispose());
  }

  List<({String productId, String quantity})> _result() => [
    for (final e in _adHoc.entries)
      (productId: e.key.id, quantity: e.value.text.trim().replaceAll(',', '.')),
  ];

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final canSearch =
        ref.watch(authControllerProvider).user?.can('inventory.read') ?? false;
    final results = q.isEmpty
        ? const AsyncValue<List<Product>>.data(<Product>[])
        : ref.watch(productSearchProvider(q));
    final errStyle = TextStyle(color: Theme.of(context).colorScheme.error);
    return AlertDialog(
      title: Text(widget.op.typeName),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Шаблонные расходники типа спишутся автоматически. Ниже — '
                'дополнительные, фактически использованные.',
              ),
              const SizedBox(height: 12),
              if (canSearch) ...[
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    labelText: 'Добавить расходник',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  // Debounce: не дёргать GET на каждое нажатие.
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => _query = v);
                    });
                  },
                ),
                if (q.isNotEmpty)
                  results.when(
                    data: (items) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Инструменты — многоразовые активы, не списываются как
                        // одноразовые расходники: прячем из пикера.
                        for (final p
                            in items
                                .where((p) => p.productType != 'instrument')
                                .take(8))
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(p.name),
                            subtitle: Text('${p.sku} · ${p.typeLabel}'),
                            trailing: const Icon(Icons.add),
                            onTap: () => _add(p),
                          ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) =>
                        Text('Поиск недоступен: $e', style: errStyle),
                  ),
              ] else
                Text(
                  'Добавление расходников требует доступа к складу — '
                  'спишутся только шаблонные.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              for (final e in _adHoc.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('${e.key.name} (${e.key.unit})')),
                      SizedBox(
                        width: 84,
                        child: TextField(
                          controller: e.value,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Кол-во',
                            isDense: true,
                            errorText: _qtyValid(e.value) ? null : '> 0',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Убрать',
                        icon: const Icon(Icons.close),
                        onPressed: () => _remove(e.key),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _allQtysValid
              ? () => Navigator.of(context).pop(_result())
              : null,
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
