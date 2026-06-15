// Reception discount (TZ Modul 2.2): repository call shape + open-visit panel.
//
// 1) Repository: POST /visits/{id}/discount carries percent XOR amount +
//    reason (or {"clear": true}) and parses the recalculated VisitOut;
//    409/422 surface the backend's detail text as ApiException.
// 2) Widget: with a discounted ReceptionVisit fixture (providers overridden),
//    the open-visit panel shows Сумма / Скидка / «К оплате» = payable and
//    the «Скидка» button.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/core/network/api_exception.dart';
import 'package:kozshifo/core/network/page.dart' as net;
import 'package:kozshifo/core/utils/formatters.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/patients/data/patients_repository.dart';
import 'package:kozshifo/features/patients/domain/patient.dart';
import 'package:kozshifo/features/reception/data/reception_repository.dart';
import 'package:kozshifo/features/reception/domain/patient_summary.dart';
import 'package:kozshifo/features/reception/domain/reception_visit.dart';
import 'package:kozshifo/features/reception/domain/service.dart';
import 'package:kozshifo/features/reception/presentation/reception_screen.dart';

// ── Repository: mock transport ───────────────────────────────────────────────

/// Records the last request and replies with a canned body — no sockets.
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
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

/// VisitOut after the server applied «10% Пенсионер» to 150 000.
const _visitJson = <String, dynamic>{
  'id': 'v1',
  'visit_no': 'V-20260612-0001',
  'status': 'open',
  'flow_status': 'registered',
  'total_amount': '150000.00',
  'paid_amount': '0.00',
  'balance': '135000.00',
  'discount_percent': '10',
  'discount_amount': null,
  'discount_reason': 'Пенсионер',
  'discount_value': '15000.00',
  'payable': '135000.00',
  'items': <dynamic>[],
};

(ReceptionRepository, _MockAdapter) _repoWith(
  String body, {
  int statusCode = 200,
}) {
  final adapter = _MockAdapter(body, statusCode: statusCode);
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

const _discountedVisit = ReceptionVisit(
  id: 'v1',
  visitNo: 'V-20260612-0001',
  status: 'open',
  totalAmount: '150000.00',
  paidAmount: '0.00',
  balance: '135000.00',
  discountPercent: '10',
  discountReason: 'Пенсионер',
  discountValue: '15000.00',
  payable: '135000.00',
);

/// Authenticated reception user — no _restore microtask, no network.
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
  _FakeReceptionRepository() : super(Dio());

  @override
  Future<List<Service>> services() async => const [_service];

  @override
  Future<ReceptionVisit> createVisit({
    required String patientId,
    required String branchId,
    required List<({String serviceId, int quantity})> items,
  }) async =>
      _discountedVisit;

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

void main() {
  group('ReceptionRepository.setDiscount', () {
    test('POST /visits/{id}/discount with percent XOR + reason; parses visit',
        () async {
      final (repo, adapter) = _repoWith(jsonEncode(_visitJson));

      final visit = await repo.setDiscount(
        visitId: 'v1',
        percent: '10',
        reason: 'Пенсионер',
      );

      final options = adapter.lastOptions!;
      expect(options.method, 'POST');
      expect(options.path, '/visits/v1/discount');
      expect(options.data, {
        'discount_percent': '10',
        'discount_reason': 'Пенсионер',
      }); // no discount_amount key — XOR is preserved on the wire

      expect(visit.discountPercent, '10');
      expect(visit.discountValue, '15000.00');
      expect(visit.discountReason, 'Пенсионер');
      expect(visit.payable, '135000.00');
      expect(visit.balance, '135000.00');
    });

    test('amount variant sends discount_amount only', () async {
      final (repo, adapter) = _repoWith(jsonEncode(_visitJson));

      await repo.setDiscount(
        visitId: 'v1',
        amount: '50000',
        reason: 'Акция',
      );

      expect(adapter.lastOptions!.data, {
        'discount_amount': '50000',
        'discount_reason': 'Акция',
      });
    });

    test('clear sends {"clear": true}', () async {
      final (repo, adapter) = _repoWith(jsonEncode(_visitJson));

      await repo.setDiscount(visitId: 'v1', clear: true);

      expect(adapter.lastOptions!.data, {'clear': true});
    });

    test('409 maps to ApiException with the backend detail text', () async {
      final (repo, _) = _repoWith(
        jsonEncode({'detail': 'Визит закрыт — скидка недоступна'}),
        statusCode: 409,
      );

      await expectLater(
        repo.setDiscount(visitId: 'v1', percent: '10', reason: 'Акция'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.message, 'message', contains('Визит закрыт')),
        ),
      );
    });
  });

  group('Reception open-visit panel with discount', () {
    testWidgets('shows Сумма / Скидка / «К оплате» = payable + Скидка button',
        (tester) async {
      // Desktop width: the screen uses the two-column layout at ≥1000px (real
      // usage). At the default 800×600 the cards stack and the right-column
      // actions fall below the fold.
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_FakeAuthController.new),
            patientsRepositoryProvider
                .overrideWithValue(_FakePatientsRepository()),
            receptionRepositoryProvider
                .overrideWithValue(_FakeReceptionRepository()),
          ],
          child: const MaterialApp(home: ReceptionScreen()),
        ),
      );
      await tester.pump(); // activeServicesProvider resolves

      // Patient: search (350 ms debounce) → pick from results.
      await tester.enterText(find.byType(TextField).first, 'Алиев');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.tap(find.text('Алиев Вали'));
      await tester.pump();

      // Cart: add the service, open the visit (fake returns the fixture).
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();
      await tester.tap(find.text('Открыть визит'));
      await tester.pump();
      await tester.pump();

      // Due figure is payable, not totalAmount. The service list also shows
      // «150 000 сум», so money rows are scoped to the «3. Оплата» card.
      final paymentCard = find.widgetWithText(Card, '3. Оплата');
      Finder inCard(String text) =>
          find.descendant(of: paymentCard, matching: find.text(text));
      expect(find.text('Сумма:'), findsOneWidget);
      expect(inCard(formatMoney('150000.00')), findsOneWidget);
      expect(find.text('К оплате:'), findsOneWidget);
      expect(inCard(formatMoney('135000.00')), findsOneWidget);
      // Discount line carries value and reason.
      expect(find.text('Скидка:'), findsOneWidget);
      expect(
        find.text('−${formatMoney('15000.00')} (Пенсионер)'),
        findsOneWidget,
      );
      // Remaining amount keeps using balance.
      expect(
        find.textContaining('остаток ${formatMoney('135000.00')}'),
        findsOneWidget,
      );
      // The discount entry point is visible on an open visit.
      expect(find.widgetWithText(OutlinedButton, 'Скидка'), findsOneWidget);
    });
  });
}
