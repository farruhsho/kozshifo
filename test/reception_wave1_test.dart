// Reception wave 1: Л-талон привязывается к визиту + выход из «Ожидает
// назначения».
//
// 1) Repository: POST /queue/treatment-ticket несёт visit_id, когда он
//    известен (и не несёт, когда нет); POST /queue/refer-to-doctor несёт
//    visit_id (+ опц. doctor_id) и парсит ticket_number.
// 2) Widget: «В очередь на лечение» передаёт id визита ТОЛЬКО когда открытый
//    визит показан на экране (иначе visit_id не шлётся — бэкенд решает сам);
//    «Направить к врачу» появляется только для flow_status='awaiting_assignment'
//    (оплата registered без талона) и НЕ появляется для доплаты по
//    surgery_scheduled; зовёт referToDoctor (автовыбор → doctor_id не шлётся).
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/core/network/page.dart' as net;
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/patients/data/patients_repository.dart';
import 'package:kozshifo/features/patients/domain/patient.dart';
import 'package:kozshifo/features/reception/data/reception_repository.dart';
import 'package:kozshifo/features/reception/domain/patient_summary.dart';
import 'package:kozshifo/features/reception/domain/payment_result.dart';
import 'package:kozshifo/features/reception/domain/reception_visit.dart';
import 'package:kozshifo/features/reception/domain/service.dart';
import 'package:kozshifo/features/reception/presentation/reception_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Repository: mock transport ───────────────────────────────────────────────

/// Records the last request and replies with a canned body — no sockets.
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.body);

  final String body;
  final int statusCode = 200;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(ReceptionRepository, _MockAdapter) _repoWith(String body) {
  final adapter = _MockAdapter(body);
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;
  return (ReceptionRepository(dio), adapter);
}

// ── Widget: fixtures + provider fakes ────────────────────────────────────────

const _patient = Patient(
  id: 'p1',
  mrn: 'MRN-0001',
  firstName: 'Вали',
  lastName: 'Алиев',
  fullName: 'Алиев Вали',
  phone: '+998901112233',
  branchId: 'br-1',
);

const _service = Service(
  id: 's1',
  code: 'CONS',
  name: 'Консультация офтальмолога',
  price: '150000.00',
);

const _openVisit = ReceptionVisit(
  id: 'v1',
  visitNo: 'V-20260704-0001',
  status: 'open',
  flowStatus: 'registered',
  totalAmount: '150000.00',
  paidAmount: '0.00',
  balance: '150000.00',
);

/// Authenticated front-desk user (queue.manage — Л-талон, queue.admin —
/// «Направить к врачу»).
class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        AuthStatus.authenticated,
        AuthUser(
          id: 'u1',
          email: 'reception@kozshifo.uz',
          fullName: 'Ресепшен',
          branchId: 'br-1',
          permissions: [
            'patients.create',
            'visits.create',
            'visits.update',
            'payments.create',
            'queue.manage',
            'queue.admin',
          ],
        ),
      );
}

class _FakePatientsRepository extends PatientsRepository {
  _FakePatientsRepository() : super(Dio());

  @override
  Future<net.Page<Patient>> list({
    String? q,
    int offset = 0,
    int limit = 50,
  }) async =>
      net.Page(items: const [_patient], total: 1, offset: 0, limit: limit);
}

class _FakeReceptionRepository extends ReceptionRepository {
  _FakeReceptionRepository({
    this.visitToReturn = _openVisit,
  }) : super(Dio());

  final ReceptionVisit visitToReturn;
  String? treatmentPatientId;
  Object? treatmentVisitId = 'unset';
  String? referVisitId;
  Object? referDoctorId = 'unset';

  @override
  Future<List<Service>> services() async => const [_service];

  @override
  Future<ReceptionVisit> createVisit({
    required String patientId,
    required String branchId,
    required List<({String serviceId, int quantity})> items,
    String? doctorId,
  }) async =>
      visitToReturn;

  @override
  Future<PaymentResult> takePayment({
    required String visitId,
    required String amount,
    String method = 'cash',
    String? room,
    String referralIntent = 'diagnostic',
  }) async =>
      PaymentResult.fromJson({
        'payment': {
          'id': 'pay-1',
          'receipt_no': 'R-1',
          'amount': amount,
          'method': method,
          'created_at': '2026-07-04T10:00:00Z',
        },
        'visit_status': 'closed',
        'visit_balance': '0.00',
        'queue_ticket_number': null,
      });

  @override
  Future<Uint8List> receiptPdf(String paymentId) async => Uint8List(0);

  @override
  Future<String> issueTreatmentTicket({
    required String patientId,
    required String branchId,
    String? visitId,
    String? room,
  }) async {
    treatmentPatientId = patientId;
    treatmentVisitId = visitId;
    return 'Л-001';
  }

  @override
  Future<String> referToDoctor({
    required String visitId,
    String? doctorId,
    String? room,
  }) async {
    referVisitId = visitId;
    referDoctorId = doctorId;
    return 'С-001';
  }

  @override
  Future<List<({String id, String fullName, bool isActive})>> doctors() async =>
      const [(id: 'd1', fullName: 'Иванов И.И.', isActive: true)];

  // The reception history panel fetches this when a patient is selected.
  @override
  Future<PatientSummary> patientSummary(String patientId) async =>
      const PatientSummary(
        patientId: 'p1',
        visitCount: 1,
        totalDebt: '0.00',
        isRepeat: false,
      );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeReceptionRepository reception,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        patientsRepositoryProvider.overrideWithValue(_FakePatientsRepository()),
        receptionRepositoryProvider.overrideWithValue(reception),
      ],
      child: const MaterialApp(home: ReceptionScreen()),
    ),
  );
  await tester.pump(); // activeServicesProvider resolves
}

/// Search (350 ms debounce) → pick the patient from the results.
Future<void> _selectPatient(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Алиев');
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  await tester.tap(find.text('Алиев Вали'));
  await tester.pump();
}

/// Add the service to the cart and open the visit (fake returns the fixture).
Future<void> _openVisitFlow(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add_circle_outline).first);
  await tester.pump();
  await tester.tap(find.text('Открыть визит'));
  await tester.pump();
  await tester.pump();
}

/// Take a full payment (no talon) — drives visit → «Оплата принята».
Future<void> _payInFull(WidgetTester tester) async {
  await tester.tap(find.text('Принять оплату'));
  await tester.pump();
  await tester.pump();
  await tester.tap(find.text('Оплатить'));
  await tester.pump();
  await tester.pump();
}

/// Snackbar/autosave timers must not leak past the test body.
Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5)); // snackbar auto-dismiss
  await tester.pumpWidget(const SizedBox()); // unmount → cancels autosave
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ReceptionRepository', () {
    test('treatment-ticket несёт visit_id, когда он известен', () async {
      final (repo, adapter) = _repoWith(jsonEncode({'ticket_number': 'Л-001'}));

      final number = await repo.issueTreatmentTicket(
        patientId: 'p1',
        branchId: 'b1',
        visitId: 'v1',
      );

      final options = adapter.lastOptions!;
      expect(number, 'Л-001');
      expect(options.method, 'POST');
      expect(options.path, '/queue/treatment-ticket');
      expect(options.data, {
        'patient_id': 'p1',
        'branch_id': 'b1',
        'visit_id': 'v1',
      });
    });

    test('treatment-ticket без визита не шлёт ключ visit_id', () async {
      final (repo, adapter) = _repoWith(jsonEncode({'ticket_number': 'Л-002'}));

      await repo.issueTreatmentTicket(patientId: 'p1', branchId: 'b1');

      expect(adapter.lastOptions!.data, {'patient_id': 'p1', 'branch_id': 'b1'});
    });

    test('refer-to-doctor шлёт visit_id (+doctor_id) и парсит ticket_number',
        () async {
      final (repo, adapter) = _repoWith(jsonEncode({'ticket_number': 'С-001'}));

      final number = await repo.referToDoctor(visitId: 'v1', doctorId: 'd1');

      expect(number, 'С-001');
      expect(adapter.lastOptions!.path, '/queue/refer-to-doctor');
      expect(adapter.lastOptions!.data, {'visit_id': 'v1', 'doctor_id': 'd1'});
    });
  });

  group('«В очередь на лечение»', () {
    testWidgets('без открытого визита на экране не шлёт visit_id',
        (tester) async {
      final reception = _FakeReceptionRepository();
      await _pumpScreen(tester, reception: reception);
      await _selectPatient(tester);

      await tester.tap(find.text('В очередь на лечение'));
      await tester.pump();
      await tester.pump();

      // Визита на экране нет → visit_id остаётся null (бэкенд подберёт сам),
      // без клиентской эвристики «самый свежий открытый визит».
      expect(reception.treatmentPatientId, 'p1');
      expect(reception.treatmentVisitId, isNull);
      expect(find.text('Номер очереди (лечение): Л-001'), findsOneWidget);
      await _drainTimers(tester);
    });

    testWidgets('с открытым на экране визитом передаёт его id',
        (tester) async {
      final reception = _FakeReceptionRepository();
      await _pumpScreen(tester, reception: reception);
      await _selectPatient(tester);
      await _openVisitFlow(tester);

      // Визит открыт (registered) — «Направить к врачу» не показывается.
      expect(find.text('Направить к врачу'), findsNothing);

      await tester.tap(find.text('В очередь на лечение'));
      await tester.pump();
      await tester.pump();

      expect(reception.treatmentVisitId, 'v1');
      await _drainTimers(tester);
    });
  });

  group('«Направить к врачу» (awaiting_assignment)', () {
    testWidgets('видна после полной оплаты registered-визита без талона',
        (tester) async {
      final reception = _FakeReceptionRepository();
      await _pumpScreen(tester, reception: reception);
      await _selectPatient(tester);
      await _openVisitFlow(tester);
      await _payInFull(tester);

      // Registered-визит оплачен без талона → «Ожидает назначения», кнопка есть.
      final button = find.text('Направить к врачу');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Автовыбор: doctor_id не передаётся — врача подбирает сервер.
      expect(find.text('Автоматически (по услуге)'), findsOneWidget);
      expect(find.text('Иванов И.И.'), findsOneWidget);
      await tester.tap(find.text('Автоматически (по услуге)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(reception.referVisitId, 'v1');
      expect(reception.referDoctorId, isNull);
      expect(find.text('Номер очереди (врач): С-001'), findsOneWidget);
      await _drainTimers(tester);
    });

    testWidgets(
        'НЕ видна для доплаты по surgery_scheduled (нет ложного С-талона)',
        (tester) async {
      // Пациент в surgery_scheduled доплачивает за операцию: полный расчёт без
      // талона НЕ должен подставлять «Ожидает назначения» → кнопки нет.
      final reception = _FakeReceptionRepository(
        visitToReturn:
            _openVisit.copyWith(flowStatus: 'surgery_scheduled'),
      );
      await _pumpScreen(tester, reception: reception);
      await _selectPatient(tester);
      await _openVisitFlow(tester);
      await _payInFull(tester);

      expect(find.text('Оплата принята'), findsOneWidget);
      expect(find.text('Направить к врачу'), findsNothing);
      await _drainTimers(tester);
    });
  });
}
