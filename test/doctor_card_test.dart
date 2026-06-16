// 3-column doctor workspace (owner spec): ПАЦИЕНТ | ДИАГНОСТИКА | РЕШЕНИЕ ВРАЧА.
//
// 1) Age helper склоняет «год/года/лет» и считает полные годы из birthDate.
// 2) Widget: on a wide layout (≥1280px) the three column headers render, the
//    ПАЦИЕНТ column shows demographics (ФИО / возраст / пол / телефон /
//    источник), ДИАГНОСТИКА shows the exam readings, РЕШЕНИЕ shows the
//    diagnosis/save section — providers overridden, no sockets.
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/doctor/data/doctor_repository.dart';
import 'package:kozshifo/features/doctor/domain/exam_template.dart';
import 'package:kozshifo/features/doctor/domain/eye_exam.dart';
import 'package:kozshifo/features/doctor/domain/frequent_diagnosis.dart';
import 'package:kozshifo/features/doctor/domain/timeline_event.dart';
import 'package:kozshifo/features/doctor/domain/visit_diagnosis.dart';
import 'package:kozshifo/features/doctor/domain/visit_summary.dart';
import 'package:kozshifo/features/doctor/presentation/patient_card_screen.dart';
import 'package:kozshifo/features/doctor/presentation/patient_info_card.dart';
import 'package:kozshifo/features/patients/data/patients_repository.dart';
import 'package:kozshifo/features/patients/domain/patient.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _patient = Patient(
  id: 'p1',
  mrn: 'MRN-0001',
  firstName: 'Вали',
  lastName: 'Алиев',
  fullName: 'Алиев Вали Каримович',
  birthDate: '1990-06-13',
  gender: 'male',
  phone: '+998901112233',
  leadSource: 'instagram',
);

const _visit = VisitSummary(
  id: 'v1',
  visitNo: 'V-20260613-0001',
  status: 'open',
  openedAt: '2026-06-13T09:00:00Z',
  branchId: 'br-1',
  totalAmount: '150000.00',
  paidAmount: '100000.00',
  balance: '50000.00',
  items: [VisitItemSummary(serviceName: 'Консультация', total: '150000.00')],
);

/// Doctor with full clinical permissions; build() is synchronous → no network.
class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    AuthStatus.authenticated,
    AuthUser(
      id: 'u1',
      email: 'doctor@kozshifo.uz',
      fullName: 'Врач',
      branchId: 'br-1',
      permissions: ['exams.write'],
    ),
  );
}

/// Returns canned demographics; no Dio traffic.
class _FakePatientsRepository extends PatientsRepository {
  _FakePatientsRepository() : super(Dio());

  @override
  Future<Patient> getById(String id) async => _patient;
}

/// One open visit, no recorded exam, empty history/timeline/diagnoses.
class _FakeDoctorRepository extends DoctorRepository {
  _FakeDoctorRepository() : super(Dio());

  @override
  Future<List<VisitSummary>> visitsForPatient(String patientId) async =>
      const [_visit];

  @override
  Future<EyeExam?> examForVisit(String visitId) async => null;

  @override
  Future<List<EyeExam>> examHistory(String patientId) async => const [];

  @override
  Future<List<TimelineEvent>> timeline(String patientId) async => const [];

  @override
  Future<List<FrequentDiagnosis>> frequentDiagnoses() async => const [];

  @override
  Future<List<ExamTemplate>> examTemplates() async => const [];

  @override
  Future<List<VisitDiagnosis>> diagnosesForVisit(String visitId) async =>
      const [];

  @override
  Future<Uint8List> cardPdf(String visitId) async => Uint8List(0);
}

Widget _harness() => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_FakeAuthController.new),
    patientsRepositoryProvider.overrideWithValue(_FakePatientsRepository()),
    doctorRepositoryProvider.overrideWithValue(_FakeDoctorRepository()),
  ],
  child: const MaterialApp(home: PatientCardScreen(patientId: 'p1')),
);

void main() {
  group('PatientInfoCard.ageFromBirthDate', () {
    test('full years counted, before/after birthday', () {
      final now = DateTime(2026, 6, 13);
      expect(PatientInfoCard.ageFromBirthDate('1990-06-13', now: now), 36);
      // Birthday not reached yet this year → one less.
      expect(PatientInfoCard.ageFromBirthDate('1990-06-14', now: now), 35);
      // Birthday already passed.
      expect(PatientInfoCard.ageFromBirthDate('1990-06-12', now: now), 36);
    });

    test('null / blank / unparseable → null', () {
      expect(PatientInfoCard.ageFromBirthDate(null), isNull);
      expect(PatientInfoCard.ageFromBirthDate(''), isNull);
      expect(PatientInfoCard.ageFromBirthDate('not-a-date'), isNull);
    });
  });

  group('3-column doctor workspace', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('wide layout renders all three column headers', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_harness());
      // patientVisitsProvider resolves → auto-selects v1 → examForVisit + draft.
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // The three columns are all present and labelled.
      expect(find.text('ПАЦИЕНТ'), findsOneWidget);
      expect(find.text('ДИАГНОСТИКА'), findsOneWidget);
      expect(find.text('РЕШЕНИЕ ВРАЧА'), findsOneWidget);

      // ПАЦИЕНТ column: demographics from the fixture.
      expect(find.text('Алиев Вали Каримович'), findsOneWidget);
      expect(find.text('36 лет'), findsOneWidget); // 1990-06-13 @ 2026-06-13
      expect(find.text('Мужской'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);

      // ПАЦИЕНТ column: structured visit history with the visit's outstanding
      // debt surfaced on the collapsed row.
      expect(find.text('Визиты (1)'), findsOneWidget);
      expect(find.textContaining('долг'), findsOneWidget);

      // ДИАГНОСТИКА column: structured exam readings are reachable.
      expect(find.text('Visus / рефракция'), findsOneWidget);
      expect(find.text('Биомикроскопия (по бланку)'), findsOneWidget);

      // РЕШЕНИЕ ВРАЧА column: conclusion + save.
      expect(find.text('Ташхис / Тавсия (заключение)'), findsOneWidget);
      expect(find.text('Сохранить осмотр'), findsOneWidget);
    });
  });
}
