import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../../clinical/data/clinical_repository.dart';
import '../../clinical/domain/operation.dart';

final _dateTime = DateFormat('dd.MM.yyyy HH:mm');

/// Раздел «Операции» (TZ Modul 6) — рабочий список операционного отделения.
/// Ресепшен планирует направленные операции (дата/цена), врач-хирург начинает,
/// выполняет (списание расходников) и завершает их.
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 8,
              children: [
                for (final (label, value) in _tabs)
                  ChoiceChip(
                    label: Text(label),
                    selected: _status == value,
                    onSelected: (_) => setState(() => _status = value),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueWidget<List<Operation>>(
              value: operations,
              onRetry: () =>
                  ref.invalidate(operationsWorklistProvider(_status)),
              builder: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Операций нет.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _OperationCard(
                    op: items[i],
                    canSchedule: canSchedule,
                    canPerform: canPerform,
                    canCancel: canCancel,
                    onChanged: _reload,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = switch (op.status) {
      'referred' => Colors.blue,
      'scheduled' => Colors.orange,
      'in_progress' => Colors.purple,
      'performed' || 'completed' => Colors.green,
      _ => Colors.grey,
    };
    final scheduled = DateTime.tryParse(op.scheduledAt ?? '')?.toLocal();

    final meta = <String>[
      op.eyeLabel,
      if (scheduled != null) _dateTime.format(scheduled),
      if (op.price != null) formatMoney(op.price),
      if (op.surgeonName != null) 'Хирург: ${op.surgeonName}',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(op.patientName,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                ),
                if (op.isUrgent)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: const Text('срочная'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                      labelStyle:
                          const TextStyle(color: Colors.red, fontSize: 12),
                      side: BorderSide.none,
                    ),
                  ),
                Chip(
                  label: Text(op.statusLabel),
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: statusColor),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(op.typeName, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(meta.join(' · '), style: theme.textTheme.bodySmall),
            if (op.notes != null && op.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(op.notes!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.end,
              children: _actions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    final widgets = <Widget>[];
    if (canSchedule && (op.isReferred || op.isScheduled)) {
      widgets.add(FilledButton.tonal(
        onPressed: () => _schedule(context, ref),
        child: Text(op.isReferred ? 'Запланировать' : 'Изменить'),
      ));
    }
    if (canPerform && op.isScheduled) {
      widgets.add(TextButton(
        onPressed: () => _act(context, ref,
            (r) => r.startOperation(op.id), 'Операция начата'),
        child: const Text('Начать'),
      ));
    }
    if (canPerform && (op.isScheduled || op.isInProgress)) {
      widgets.add(FilledButton(
        onPressed: () => _perform(context, ref),
        child: const Text('Выполнить'),
      ));
    }
    if (canPerform && op.isPerformed) {
      widgets.add(FilledButton(
        onPressed: () => _complete(context, ref),
        child: const Text('Завершить'),
      ));
    }
    if (canCancel && op.isOpen) {
      widgets.add(TextButton(
        onPressed: () => _act(
            context, ref, (r) => r.cancelOperation(op.id), 'Операция отменена'),
        child: const Text('Отменить'),
      ));
    }
    return widgets;
  }

  Future<void> _act(
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
      if (context.mounted) _snack(context, e.toString(), error: true);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(op.typeName),
        content: const Text('Списать расходники и отметить выполненной?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Выполнить')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _act(context, ref, (r) => r.performOperation(op.id),
        'Операция выполнена, расходники списаны');
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
          decoration:
              const InputDecoration(labelText: 'Результат / заключение'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Завершить')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = controller.text.trim();
    await _act(
      context,
      ref,
      (r) => r.completeOperation(op.id, result: result.isEmpty ? null : result),
      'Операция завершена',
    );
  }

  void _snack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
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
    final dt = DateTime(date.year, date.month, date.day, _time.hour, _time.minute);
    final price = _price.text.trim();
    final notes = _notes.text.trim();
    try {
      await ref.read(clinicalRepositoryProvider).scheduleOperation(
            id: widget.op.id,
            scheduledAt: dt.toUtc().toIso8601String(),
            price: price.isEmpty ? null : price,
            notes: notes.isEmpty ? null : notes,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        _date == null ? 'Выбрать дату' : DateFormat('dd.MM.yyyy').format(_date!);
    return AlertDialog(
      title: Text('Планирование: ${widget.op.typeName}'),
      content: SizedBox(
        width: 420,
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
                labelText: 'Цена',
                helperText: 'Пусто — цена из каталога',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Примечание (необязательно)'),
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
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
