// Ф5 — standalone patient visit-history screen: renders the filter bar + a
// visit card with money rows from canned data; providers overridden, no sockets.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/doctor/data/doctor_repository.dart';
import 'package:kozshifo/features/doctor/domain/visit_summary.dart';
import 'package:kozshifo/features/patients/data/patients_repository.dart';
import 'package:kozshifo/features/patients/domain/patient.dart';
import 'package:kozshifo/features/patients/presentation/patient_visits_screen.dart';

const _patient = Patient(
  id: 'p1',
  mrn: 'MRN-0001',
  firstName: 'Вали',
  lastName: 'Алиев',
  fullName: 'Алиев Вали Каримович',
  phone: '+998901112233',
);

const _visits = <VisitSummary>[
  VisitSummary(
    id: 'v1',
    visitNo: 'V-20260613-0001',
    status: 'open',
    openedAt: '2026-06-13T09:00:00Z',
    totalAmount: '150000.00',
    paidAmount: '100000.00',
    balance: '50000.00',
    items: [VisitItemSummary(serviceName: 'Консультация', total: '150000.00')],
  ),
];

class _FakePatientsRepository extends PatientsRepository {
  _FakePatientsRepository() : super(Dio());

  @override
  Future<Patient> getById(String id) async => _patient;
}

class _FakeDoctorRepository extends DoctorRepository {
  _FakeDoctorRepository() : super(Dio());

  @override
  Future<List<VisitSummary>> visitsForPatient(
    String patientId, {
    DateTime? openedFrom,
    DateTime? openedTo,
    String? status,
    bool owing = false,
  }) async => _visits;
}

void main() {
  testWidgets('PatientVisitsScreen renders header, filters and a visit card', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patientsRepositoryProvider.overrideWithValue(
            _FakePatientsRepository(),
          ),
          doctorRepositoryProvider.overrideWithValue(_FakeDoctorRepository()),
        ],
        child: const MaterialApp(home: PatientVisitsScreen(patientId: 'p1')),
      ),
    );
    await tester.pumpAndSettle();

    // AppBar + patient header (from patientByIdProvider).
    expect(find.text('История визитов'), findsOneWidget);
    expect(find.text('Алиев Вали Каримович'), findsOneWidget);

    // Filter bar: status chips + debt toggle.
    expect(find.text('Все'), findsOneWidget);
    expect(find.text('Открыт'), findsOneWidget);
    expect(find.text('С долгом'), findsOneWidget);

    // The visit card: number, its service line, and the debt money row.
    expect(find.textContaining('V-20260613-0001'), findsOneWidget);
    expect(find.text('Консультация'), findsOneWidget);
    expect(find.text('Итого'), findsOneWidget);
    expect(find.text('Долг'), findsOneWidget);
  });
}
