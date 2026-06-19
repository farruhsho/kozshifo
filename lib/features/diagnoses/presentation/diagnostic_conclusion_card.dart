import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../doctor/data/doctor_repository.dart';
import '../data/diagnoses_repository.dart';
import '../domain/diagnosis.dart';

/// «Заключение» — lets a diagnostician record a diagnostic conclusion for the
/// current visit by picking from their allowed diagnoses (`GET /diagnoses/mine`).
/// Sits next to the УЗИ-PDF upload on the «Приём» screen. On save it posts the
/// conclusion, then invalidates the patient timeline so the new entry shows.
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
      setState(() => _selectedId = null);
      _snack('Заключение записано');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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
          ],
        ),
      ),
    );
  }
}
