import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../doctor/data/doctor_repository.dart';
import '../../doctor/domain/timeline_event.dart';

/// «История пациента» — единая карта истории, сгруппированная по 5 разделам
/// (Приёмы · Диагностика · Лечение · Операции · Финансы). Переиспользует
/// авто-таймлайн пациента (`patientTimelineProvider`): тот же бэкенд, но события
/// разложены по смысловым секциям, как требует бизнес-ТЗ.
class PatientHistoryScreen extends ConsumerWidget {
  const PatientHistoryScreen({super.key, required this.patientId});

  final String patientId;

  // Раздел → набор kind'ов событий таймлайна, которые в него попадают.
  static final List<({String label, IconData icon, Set<String> kinds})> _sections =
      [
    (
      label: 'Приёмы',
      icon: Icons.event_note_outlined,
      kinds: {'visit_opened', 'visit_closed', 'visit_cancelled', 'exam', 'seen'},
    ),
    (
      label: 'Диагностика',
      icon: Icons.biotech_outlined,
      kinds: {'device_result', 'attachment'},
    ),
    (
      label: 'Лечение',
      icon: Icons.medication_outlined,
      kinds: {'treatment_prescribed', 'treatment_done'},
    ),
    (
      label: 'Операции',
      icon: Icons.local_hospital_outlined,
      kinds: {
        'operation_referred',
        'operation_scheduled',
        'operation_performed',
        'operation_completed',
        'operation_cancelled',
      },
    ),
    (
      label: 'Финансы',
      icon: Icons.payments_outlined,
      kinds: {'payment', 'refund'},
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(patientTimelineProvider(patientId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('История пациента'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(patientTimelineProvider(patientId)),
          ),
        ],
      ),
      body: AsyncValueWidget<List<TimelineEvent>>(
        value: timeline,
        onRetry: () => ref.invalidate(patientTimelineProvider(patientId)),
        builder: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('История пациента пуста.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final s in _sections)
                _SectionCard(
                  label: s.label,
                  icon: s.icon,
                  events: [for (final e in events) if (s.kinds.contains(e.kind)) e],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.icon,
    required this.events,
  });

  final String label;
  final IconData icon;
  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: events.isNotEmpty,
        leading: Icon(icon, color: scheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(events.isEmpty ? 'Нет записей' : 'Записей: ${events.length}'),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          if (events.isEmpty)
            const ListTile(dense: true, title: Text('—'))
          else
            for (final e in events)
              ListTile(
                dense: true,
                title: Text(e.title),
                subtitle: (e.detail == null || e.detail!.isEmpty)
                    ? null
                    : Text(e.detail!),
                trailing: Text(
                  e.ts.replaceFirst('T', ' ').split('.').first,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
        ],
      ),
    );
  }
}
