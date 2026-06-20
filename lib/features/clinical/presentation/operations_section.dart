import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/clinical_repository.dart';
import '../domain/operation.dart';

/// Секция «Операции» карты пациента (TZ Modul 6): врач направляет пациента на
/// операцию (тип + рекомендация, без счёта). Дату/хирурга/цену и выполнение
/// оформляет ресепшен в разделе «Операции».
class OperationsSection extends ConsumerWidget {
  const OperationsSection(
      {super.key, required this.visitId, required this.patientId, this.branchId});

  final String visitId;
  final String patientId;

  /// Филиал визита — склад, с которого perform реально спишет расходники.
  final String? branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(visitOperationsProvider(visitId));
    final user = ref.watch(authControllerProvider).user;
    final canPrescribe = user?.can('operations.prescribe') ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Операции', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            AsyncValueWidget<List<Operation>>(
              value: operations,
              onRetry: () => ref.invalidate(visitOperationsProvider(visitId)),
              builder: (items) {
                if (items.isEmpty) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Операций по этому визиту нет.'),
                  );
                }
                return Column(
                  children: [
                    for (final op in items)
                      _operationTile(context, ref, op, canPrescribe),
                  ],
                );
              },
            ),
            if (canPrescribe) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _refer(context, ref),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Направить на операцию'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _operationTile(
      BuildContext context, WidgetRef ref, Operation op, bool canPrescribe) {
    final statusColor = switch (op.status) {
      'referred' => Colors.blue,
      'scheduled' => Colors.orange,
      'in_progress' => Colors.purple,
      'performed' => Colors.green,
      'completed' => Colors.green,
      _ => Colors.grey,
    };
    final subtitle = [
      if (op.notes != null && op.notes!.isNotEmpty) op.notes!,
      if (op.surgeonName != null) 'Хирург: ${op.surgeonName}',
    ].join(' · ');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.medical_services_outlined),
      title: Text('${op.typeName} · ${op.eyeLabel}'),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (op.isUrgent)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Chip(
                label: const Text('срочная'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.red.withValues(alpha: 0.12),
                labelStyle: const TextStyle(color: Colors.red, fontSize: 12),
                side: BorderSide.none,
              ),
            ),
          Chip(
            label: Text(op.statusLabel),
            backgroundColor: statusColor.withValues(alpha: 0.15),
            labelStyle: TextStyle(color: statusColor),
            side: BorderSide.none,
          ),
          if (canPrescribe && op.isOpen)
            TextButton(
              onPressed: () => _cancel(context, ref, op),
              child: const Text('Отменить'),
            ),
        ],
      ),
    );
  }

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, Operation op) async {
    try {
      await ref.read(clinicalRepositoryProvider).cancelOperation(op.id);
      if (!context.mounted) return;
      ref.invalidate(visitOperationsProvider(visitId));
      _snack(context, 'Направление отменено');
    } catch (e) {
      if (context.mounted) _snack(context, e.toString(), error: true);
    }
  }

  Future<void> _refer(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _ReferOperationDialog(visitId: visitId, branchId: branchId),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(visitOperationsProvider(visitId));
      _snack(context, 'Пациент направлен на операцию — ресепшен оформит детали');
    }
  }

  void _snack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }
}

/// Диалог направления: тип операции (цена — ориентир из каталога), приоритет,
/// глаз, рекомендация + живая проверка наличия расходников по филиалу визита
/// (advisory). Счёт НЕ выставляется — это сделает ресепшен при планировании.
class _ReferOperationDialog extends ConsumerStatefulWidget {
  const _ReferOperationDialog({required this.visitId, this.branchId});

  final String visitId;
  final String? branchId;

  @override
  ConsumerState<_ReferOperationDialog> createState() =>
      _ReferOperationDialogState();
}

class _ReferOperationDialogState
    extends ConsumerState<_ReferOperationDialog> {
  final _notes = TextEditingController();
  String? _typeId;
  String? _surgeonId;
  String _eye = 'od';
  String _priority = 'normal';
  bool _saving = false;

  // Advisory consumables check for the selected type: null → panel hidden
  // (no type yet / no branch / fetch failed). Never blocks prescribing.
  OperationAvailability? _availability;
  bool _checkingAvailability = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  /// Filiал врача — операционный филиал по конвенции проекта (как на
  /// ресепшене). Без филиала проверка молча пропускается; ошибка сети —
  /// просто прячем панель: advisory не должен ломать назначение.
  Future<void> _checkAvailability(String typeId) async {
    // Склад проверяется по филиалу ВИЗИТА (perform списывает именно там);
    // филиал врача — только fallback для старых записей без branch_id.
    final branchId =
        widget.branchId ?? ref.read(authControllerProvider).user?.branchId;
    if (branchId == null) return;
    setState(() {
      _checkingAvailability = true;
      _availability = null;
    });
    try {
      final result = await ref
          .read(clinicalRepositoryProvider)
          .availability(typeId, branchId);
      if (!mounted || _typeId != typeId) return; // тип уже сменили
      setState(() => _availability = result);
    } catch (_) {
      // advisory — скрываем панель, назначение остаётся доступным
    } finally {
      if (mounted && _typeId == typeId) {
        setState(() => _checkingAvailability = false);
      }
    }
  }

  Future<void> _save() async {
    final typeId = _typeId;
    if (typeId == null) return;
    setState(() => _saving = true);
    try {
      final notes = _notes.text.trim();
      await ref.read(clinicalRepositoryProvider).referOperation(
            visitId: widget.visitId,
            operationTypeId: typeId,
            eye: _eye,
            priority: _priority,
            notes: notes.isEmpty ? null : notes,
            surgeonId: _surgeonId,
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
    final types = ref.watch(operationTypesProvider);
    final surgeons = ref.watch(surgeonsProvider);

    return AlertDialog(
      title: const Text('Направить на операцию'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              types.when(
                data: (items) {
                  final active = items.where((t) => t.isActive).toList();
                  return DropdownButtonFormField<String>(
                    initialValue: _typeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Операция'),
                    items: [
                      for (final t in active)
                        DropdownMenuItem(
                          value: t.id,
                          child: Text('${t.name} — ${formatMoney(t.price)}',
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _typeId = v;
                        _availability = null;
                      });
                      if (v != null) _checkAvailability(v);
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Text('$e',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
              if (_checkingAvailability)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                )
              else if (_availability != null)
                _availabilityPanel(context, _availability!),
              const SizedBox(height: 16),
              surgeons.when(
                data: (items) => DropdownButtonFormField<String?>(
                  initialValue: _surgeonId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Хирург'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('— выбрать при планировании —',
                          overflow: TextOverflow.ellipsis),
                    ),
                    for (final s in items)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(
                            s.isExternal
                                ? '${s.fullName} · приезжий'
                                : s.fullName,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _surgeonId = v),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                // Хирург необязателен — ошибку списка не показываем, чтобы
                // не блокировать направление; ресепшен назначит при планировании.
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'normal', label: Text('Обычная')),
                  ButtonSegment(value: 'urgent', label: Text('Срочная')),
                ],
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'od', label: Text('OD')),
                  ButtonSegment(value: 'os', label: Text('OS')),
                  ButtonSegment(value: 'ou', label: Text('OU')),
                ],
                selected: {_eye},
                onSelectionChanged: (s) => setState(() => _eye = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Рекомендация врача (необязательно)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: (_saving || _typeId == null) ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Направить'),
        ),
      ],
    );
  }

  /// Компактная панель наличия расходников: цветной заголовок-светофор
  /// 🟢/🟡/🔴 «Хватит ещё на N операций» (по min_feasibility) + строка на каждый
  /// расходник («название — требуется X, на складе Y, хватит на N»). Дефицит —
  /// назначать МОЖНО, заблокируется лишь выполнение; узкое место подсвечено.
  Widget _availabilityPanel(BuildContext context, OperationAvailability a) {
    if (a.items.isEmpty) return const SizedBox.shrink(); // нет шаблона — нечего показывать
    final textTheme = Theme.of(context).textTheme;
    final errorColor = Theme.of(context).colorScheme.error;

    // Светофор сервера: red / yellow / green → цвет, иконка, эмодзи заголовка.
    final (Color accent, IconData headIcon, String emoji) = switch (a.status) {
      'green' => (Colors.green, Icons.check_circle, '🟢'),
      'yellow' => (Colors.amber, Icons.warning_amber_rounded, '🟡'),
      _ => (errorColor, Icons.error, '🔴'),
    };

    // Русское склонение: «на 1 операцию», «на 2 операции», «на 5 операций».
    String plOps(int n) {
      final m10 = n % 10, m100 = n % 100;
      if (m10 == 1 && m100 != 11) return 'операцию';
      if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'операции';
      return 'операций';
    }

    final headline = a.status == 'red'
        ? 'Расходников не хватает'
        : 'Хватит ещё на ${a.minFeasibility} ${plOps(a.minFeasibility)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок-светофор: цветной бейдж с итоговой ёмкостью склада.
          Row(
            children: [
              Icon(headIcon, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$emoji  $headline',
                  style: textTheme.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Узкое место (что упрётся первым) — только когда не «зелёный».
          if (a.bottleneck != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Узкое место: ${a.bottleneck}',
                style: textTheme.bodySmall?.copyWith(color: accent),
              ),
            ),
          ],
          const Divider(height: 14),
          for (final item in a.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    item.ok ? Icons.check_circle_outline : Icons.cancel_outlined,
                    size: 16,
                    color: item.ok ? Colors.green : errorColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.name} — требуется ${item.required}, '
                      'на складе ${item.available} '
                      '(хватит на ${item.feasibilityCount})',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
