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
import 'package:kozshifo/features/devices/data/devices_repository.dart';
import 'package:kozshifo/features/devices/domain/device_result.dart';
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

/// Records the last request and replies with a canned body — no sockets.
class _MockAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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
  _FakeAuthController([this._permissions = const ['exams.write']]);

  final List<String> _permissions;

  @override
  AuthState build() => AuthState(
    AuthStatus.authenticated,
    AuthUser(
      id: 'u1',
      email: 'doctor@kozshifo.uz',
      fullName: 'Врач',
      branchId: 'br-1',
      permissions: _permissions,
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
  Future<List<VisitSummary>> visitsForPatient(
    String patientId, {
    DateTime? openedFrom,
    DateTime? openedTo,
    String? status,
    bool owing = false,
  }) async => const [_visit];

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

  bool finishCalled = false;
  String? finishFollowUpDate;

  @override
  Future<void> finishAppointment(String visitId, {String? followUpDate}) async {
    finishCalled = true;
    finishFollowUpDate = followUpDate;
  }
}

/// One scan result linked to v1; records unlinkResult calls — no Dio traffic.
class _FakeDevicesRepository extends DevicesRepository {
  _FakeDevicesRepository() : super(Dio());

  String? unlinkedId;

  @override
  Future<List<DeviceResult>> resultsForVisit(String visitId) async => const [
    DeviceResult(
      id: 'dr1',
      deviceId: 'ab1',
      visitId: 'v1',
      resultType: 'bscan_image',
      payload: {'original_name': 'scan.jpg'},
      filePath: '/files/dr1.jpg',
      measuredAt: '2026-06-13T09:05:00Z',
      source: 'file',
    ),
  ];

  @override
  Future<DeviceResult> unlinkResult(String resultId) async {
    unlinkedId = resultId;
    return const DeviceResult(
      id: 'dr1',
      deviceId: 'ab1',
      resultType: 'bscan_image',
      measuredAt: '2026-06-13T09:05:00Z',
      source: 'file',
    );
  }
}

Widget _harness({
  _FakeDoctorRepository? doctor,
  _FakeDevicesRepository? devices,
  List<String> permissions = const ['exams.write'],
}) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(() => _FakeAuthController(permissions)),
    patientsRepositoryProvider.overrideWithValue(_FakePatientsRepository()),
    doctorRepositoryProvider.overrideWithValue(
      doctor ?? _FakeDoctorRepository(),
    ),
    if (devices != null)
      devicesRepositoryProvider.overrideWithValue(devices),
  ],
  child: const MaterialApp(home: PatientCardScreen(patientId: 'p1')),
);

void main() {
  group('DoctorRepository.finishAppointment', () {
    late _MockAdapter adapter;
    late DoctorRepository repo;

    setUp(() {
      adapter = _MockAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = adapter;
      repo = DoctorRepository(dio);
    });

    test('with a date sends follow_up_date', () async {
      await repo.finishAppointment('v1', followUpDate: '2026-07-11');
      expect(adapter.lastOptions!.path, '/visits/v1/finish-appointment');
      expect(adapter.lastOptions!.method, 'POST');
      expect(adapter.lastOptions!.data, {'follow_up_date': '2026-07-11'});
    });

    test('without a date omits follow_up_date', () async {
      await repo.finishAppointment('v1');
      expect(adapter.lastOptions!.data, isNot(contains('follow_up_date')));
    });
  });

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

  group('follow-up date on finish appointment', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<_FakeDoctorRepository> openScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final doctor = _FakeDoctorRepository();
      await tester.pumpWidget(
        _harness(
          doctor: doctor,
          permissions: const ['exams.write', 'queue.manage'],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      return doctor;
    }

    testWidgets('quick chip sends follow_up_date', (tester) async {
      final doctor = await openScreen(tester);
      await tester.tap(find.text('Завершить приём'));
      await tester.pumpAndSettle();

      // Dialog opened with the quick chips.
      expect(find.text('Повторный приём'), findsOneWidget);
      await tester.tap(find.text('Через 1 нед'));
      await tester.pump();
      await tester.pump();

      expect(doctor.finishCalled, isTrue);
      // A concrete ISO date was propagated (exact day depends on «now»).
      expect(doctor.finishFollowUpDate, matches(r'^\d{4}-\d{2}-\d{2}$'));
    });

    testWidgets('«Без повтора» finishes without a date', (tester) async {
      final doctor = await openScreen(tester);
      await tester.tap(find.text('Завершить приём'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Без повтора'));
      await tester.pump();
      await tester.pump();

      expect(doctor.finishCalled, isTrue);
      expect(doctor.finishFollowUpDate, isNull);
    });

    testWidgets('«Отмена» aborts — finish not called', (tester) async {
      final doctor = await openScreen(tester);
      await tester.tap(find.text('Завершить приём'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отмена'));
      await tester.pump();
      await tester.pump();

      expect(doctor.finishCalled, isFalse);
    });
  });

  group('unlink a mis-linked device result', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<_FakeDevicesRepository> openScreen(
      WidgetTester tester, {
      required List<String> permissions,
    }) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final devices = _FakeDevicesRepository();
      await tester.pumpWidget(
        _harness(devices: devices, permissions: permissions),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      return devices;
    }

    testWidgets('«Отвязать» hidden without device_results.create', (
      tester,
    ) async {
      await openScreen(
        tester,
        permissions: const ['exams.write', 'device_results.read'],
      );
      // The scan row renders (read right) but no unlink action is offered.
      expect(find.text('scan.jpg'), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsNothing);
    });

    testWidgets('«Отвязать» confirms then calls unlinkResult', (tester) async {
      final devices = await openScreen(
        tester,
        permissions: const [
          'exams.write',
          'device_results.read',
          'device_results.create',
        ],
      );

      // The unlink affordance shows on the linked scan.
      expect(find.byIcon(Icons.link_off), findsOneWidget);
      await tester.tap(find.byIcon(Icons.link_off));
      await tester.pumpAndSettle();

      // Confirmation dialog.
      expect(
        find.text(
          'Отвязать результат от визита? Он вернётся в список несвязанных.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Отвязать'));
      await tester.pump();
      await tester.pump();

      expect(devices.unlinkedId, 'dr1');
    });
  });
}
