// Phase-6c: the consolidated patient-history screen groups the auto-timeline
// into the 5 business sections (Приёмы/Диагностика/Лечение/Операции/Финансы).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/doctor/data/doctor_repository.dart';
import 'package:kozshifo/features/doctor/domain/timeline_event.dart';
import 'package:kozshifo/features/patients/presentation/patient_history_screen.dart';

void main() {
  testWidgets('groups timeline events into the 5 sections', (tester) async {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        patientTimelineProvider('p1').overrideWith((ref) async => const [
              TimelineEvent(
                  ts: '2026-06-20T08:00:00', kind: 'visit_opened',
                  title: 'Визит V-1 открыт'),
              TimelineEvent(
                  ts: '2026-06-20T09:00:00', kind: 'attachment',
                  title: 'Файл: УЗИ'),
              TimelineEvent(
                  ts: '2026-06-20T10:00:00', kind: 'operation_performed',
                  title: 'Операция выполнена: Фако'),
              TimelineEvent(
                  ts: '2026-06-20T11:00:00', kind: 'payment',
                  title: 'Оплата 150000 (cash)'),
            ]),
      ],
      child: const MaterialApp(home: PatientHistoryScreen(patientId: 'p1')),
    ));
    await tester.pump();
    await tester.pump();

    // All 5 section headers render.
    for (final s in ['Приёмы', 'Диагностика', 'Лечение', 'Операции', 'Финансы']) {
      expect(find.text(s), findsOneWidget);
    }
    // Events land in their section (expanded since non-empty).
    expect(find.text('Визит V-1 открыт'), findsOneWidget);
    expect(find.text('Файл: УЗИ'), findsOneWidget);
    expect(find.text('Операция выполнена: Фако'), findsOneWidget);
    // The empty section shows its placeholder.
    expect(find.text('Нет записей'), findsOneWidget); // Лечение
  });
}
