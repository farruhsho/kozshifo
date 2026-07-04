import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../doctor/data/doctor_repository.dart';
import '../../doctor/domain/visit_diagnosis.dart';
import '../data/diagnoses_repository.dart';
import '../domain/diagnosis.dart';

/// «Заключение» — lets a diagnostician record a diagnostic conclusion for the
/// current visit by picking from their allowed diagnoses (`GET /diagnoses/mine`).
/// Sits next to the УЗИ-PDF upload on the «Приём» screen. On save it posts the
/// conclusion, then invalidates the patient timeline so the new entry shows.
///
/// Медбезопасность: под списком показываются уже записанные на этом визите
/// заключения; у СВОИХ (записанных текущим пользователем) есть кнопка «Удалить»,
/// чтобы исправить ошибочный выбор, пока визит не завершён.
class DiagnosticConclusionCard extends ConsumerStatefulWidget {
  const DiagnosticConclusionCard({
    super.key,
    required this.patientId,
    required this.visitId,
  });

  final String patientId;
  final String visitId;

  @override
  ConsumerState<DiagnosticConclusionCard> createState() =>
      _DiagnosticConclusionCardState();
}

class _DiagnosticConclusionCardState
    extends ConsumerState<DiagnosticConclusionCard> {
  String? _selectedId;
  bool _saving = false;
  String? _deletingId;

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _record() async {
    final id = _selectedId;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(diagnosesRepositoryProvider).recordConclusion(
            visitId: widget.visitId,
            diagnosisId: id,
          );
      if (!mounted) return;
      ref.invalidate(patientTimelineProvider(widget.patientId));
      ref.invalidate(visitDiagnosesProvider(widget.visitId));
      setState(() => _selectedId = null);
      _snack('Заключение записано');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(VisitDiagnosis conclusion) async {
    setState(() => _deletingId = conclusion.id);
    try {
      await ref.read(diagnosesRepositoryProvider).deleteConclusion(
            visitId: widget.visitId,
            conclusionId: conclusion.id,
          );
      if (!mounted) return;
      ref.invalidate(patientTimelineProvider(widget.patientId));
      ref.invalidate(visitDiagnosesProvider(widget.visitId));
      _snack('Заключение удалено');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diagnoses = ref.watch(myDiagnosesProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_outlined,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Заключение', style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            diagnoses.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Align(
                alignment: Alignment.centerLeft,
                child: Text('$e',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Нет разрешённых заключений',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Выберите заключение',
                        isDense: true,
                      ),
                      items: [
                        for (final Diagnosis d in items)
                          DropdownMenuItem(
                            value: d.id,
                            child: Text(d.label, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _selectedId = v),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: (_selectedId == null || _saving)
                            ? null
                            : _record,
                        icon: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: const Text('Записать'),
                      ),
                    ),
                  ],
                );
              },
            ),
            _RecordedConclusions(
              visitId: widget.visitId,
              deletingId: _deletingId,
              onDelete: _delete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Уже записанные на визите заключения; кнопка «Удалить» — только у СВОИХ
/// (doctorId == текущий пользователь), пока сервер их пропускает.
class _RecordedConclusions extends ConsumerWidget {
  const _RecordedConclusions({
    required this.visitId,
    required this.deletingId,
    required this.onDelete,
  });

  final String visitId;
  final String? deletingId;
  final Future<void> Function(VisitDiagnosis) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(authControllerProvider).user;
    final recorded = ref.watch(visitDiagnosesProvider(visitId));
    return recorded.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 24),
            Text('Записано на визите',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 4),
            for (final VisitDiagnosis d in items)
              _ConclusionRow(
                diagnosis: d,
                mine: me != null && d.doctorId == me.id,
                deleting: deletingId == d.id,
                onDelete: () => onDelete(d),
              ),
          ],
        );
      },
    );
  }
}

class _ConclusionRow extends StatelessWidget {
  const _ConclusionRow({
    required this.diagnosis,
    required this.mine,
    required this.deleting,
    required this.onDelete,
  });

  final VisitDiagnosis diagnosis;
  final bool mine;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              diagnosis.icd10 == null
                  ? diagnosis.diagnosis
                  : '${diagnosis.diagnosis} (${diagnosis.icd10})',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (mine)
            deleting
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Удалить',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: theme.colorScheme.error),
                    onPressed: onDelete,
                  ),
        ],
      ),
    );
  }
}
