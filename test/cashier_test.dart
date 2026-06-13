// Cashier till (Касса): repository parsing/route tests against a mocked Dio
// adapter (no network) + widget smoke tests of the Платежи till and the Смена
// summary, with overridden providers and a fake authed cashier.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kozshifo/core/network/api_exception.dart';
import 'package:kozshifo/core/utils/formatters.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/finance/data/cashier_repository.dart';
import 'package:kozshifo/features/finance/data/finance_repository.dart';
import 'package:kozshifo/features/finance/domain/cash_report.dart';
import 'package:kozshifo/features/finance/domain/till_payment.dart';
import 'package:kozshifo/features/finance/presentation/finance_screen.dart';
import 'package:kozshifo/features/finance/presentation/refunds_tab.dart';
import 'package:kozshifo/features/finance/presentation/shift_tab.dart';
import 'package:kozshifo/features/finance/presentation/till_tab.dart';
import 'package:kozshifo/features/reception/domain/reception_visit.dart';

// ─── Mocked Dio adapter ───────────────────────────────────────────────────────

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    lastRequest = options;
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, {int status = 200}) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

(CashierRepository, _FakeAdapter) _repo(
    ResponseBody Function(RequestOptions) handler) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;
  return (CashierRepository(dio), adapter);
}

// ─── Canned payloads (snake_case, money as decimal strings) ───────────────────

Map<String, dynamic> _visitJson({
  String id = 'v-1',
  String visitNo = 'V-0001',
  String status = 'open',
  String total = '300000.00',
  String paid = '0.00',
  String payable = '300000.00',
  String balance = '300000.00',
  String patientId = 'p-1',
}) =>
    {
      'id': id,
      'visit_no': visitNo,
      'patient_id': patientId,
      'branch_id': 'br-1',
      'doctor_id': null,
      'visit_type': 'consultation',
      'status': status,
      'flow_status': 'waiting_diagnostic',
      'total_amount': total,
      'paid_amount': paid,
      'discount_percent': null,
      'discount_amount': null,
      'discount_reason': null,
      'discount_value': '0.00',
      'payable': payable,
      'balance': balance,
      'notes': null,
      'opened_at': '2026-06-12T08:00:00Z',
      'closed_at': null,
      'items': <dynamic>[],
    };

Map<String, dynamic> _paymentJson({
  String id = 'pay-1',
  String receiptNo = 'R-0001',
  String amount = '300000.00',
  String method = 'cash',
  String status = 'completed',
}) =>
    {
      'id': id,
      'receipt_no': receiptNo,
      'visit_id': 'v-1',
      'patient_id': 'p-1',
      'branch_id': 'br-1',
      'cashier_id': 'u-cash',
      'amount': amount,
      'method': method,
      'status': status,
      'note': null,
      'created_at': '2026-06-12T09:30:00Z',
    };

const _dailyJson = <String, dynamic>{
  'date': '2026-06-12',
  'income_by_method': {
    'cash': '500000.00',
    'card': '250000.00',
    'qr': '0.00',
    'transfer': '100000.00',
  },
  'income_total': '850000.00',
  'refund_total': '50000.00',
  'expense_total': '120000.00',
  'net': '680000.00',
};

const _cashier = AuthUser(
  id: 'u-cash',
  email: 'kassa@kozshifo.uz',
  fullName: 'Кассир Каримов',
  branchId: 'br-1',
  permissions: [
    'payments.read',
    'payments.create',
    'payments.refund',
    'expenses.read',
  ],
);

void main() {
  // ─── Repository: route + parse + request shape ──────────────────────────────

  test('openVisits: GET /visits?status=open, parses Page<ReceptionVisit>',
      () async {
    final (repo, adapter) = _repo((_) => _json({
          'items': [
            _visitJson(),
            _visitJson(id: 'v-2', visitNo: 'V-0002', balance: '0.00'),
          ],
          'total': 2,
          'offset': 0,
          'limit': 50,
        }));
    final page = await repo.openVisits();
    expect(adapter.lastRequest!.uri.path, endsWith('/visits'));
    expect(adapter.lastRequest!.uri.queryParameters['status'], 'open');
    expect(adapter.lastRequest!.uri.queryParameters['offset'], '0');
    expect(page.total, 2);
    expect(page.items.first.visitNo, 'V-0001');
    // Money stays a String on the wire.
    expect(page.items.first.balance, '300000.00');
    expect(page.items.first.balance, isA<String>());
  });

  test('patientName: GET /patients/{id} returns full_name', () async {
    final (repo, adapter) = _repo((_) => _json({
          'id': 'p-1',
          'mrn': 'MRN-1',
          'first_name': 'Дилноза',
          'last_name': 'Иванова',
          'full_name': 'Иванова Дилноза',
        }));
    final name = await repo.patientName('p-1');
    expect(adapter.lastRequest!.uri.path, endsWith('/patients/p-1'));
    expect(name, 'Иванова Дилноза');
  });

  test('takePayment: POST /payments body has split-friendly fields', () async {
    final (repo, adapter) = _repo((_) => _json({
          'payment': _paymentJson(amount: '100000.00'),
          'visit_status': 'open',
          'visit_balance': '200000.00',
          'queue_ticket_number': null,
        }, status: 201));
    final result = await repo.takePayment(
        visitId: 'v-1', amount: '100000.00', method: 'card');
    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.uri.path, endsWith('/payments'));
    final body = adapter.lastRequest!.data as Map<String, dynamic>;
    expect(body['visit_id'], 'v-1');
    expect(body['amount'], '100000.00');
    expect(body['method'], 'card');
    expect(body['issue_queue_ticket'], true);
    // A partial payment leaves a smaller balance — the split case.
    expect(result.visitBalance, '200000.00');
    expect(result.queueTicketNumber, isNull);
  });

  test('takePayment full: returns the diagnostic queue ticket number', () async {
    final (repo, _) = _repo((_) => _json({
          'payment': _paymentJson(),
          'visit_status': 'open',
          'visit_balance': '0.00',
          'queue_ticket_number': 'D-007',
        }, status: 201));
    final result = await repo.takePayment(visitId: 'v-1', amount: '300000.00');
    expect(result.visitBalance, '0.00');
    expect(result.queueTicketNumber, 'D-007');
  });

  test('payments: GET /payments?branch_id passes branch + parses TillPayment',
      () async {
    final (repo, adapter) = _repo((_) => _json({
          'items': [
            _paymentJson(),
            _paymentJson(
                id: 'pay-2', receiptNo: 'R-0002', status: 'refunded'),
          ],
          'total': 2,
          'offset': 0,
          'limit': 50,
        }));
    final page = await repo.payments(branchId: 'br-1');
    expect(adapter.lastRequest!.uri.queryParameters['branch_id'], 'br-1');
    expect(page.items.first.isRefunded, isFalse);
    expect(page.items.last.isRefunded, isTrue);
    expect(page.items.first.amount, isA<String>());
    expect(page.items.first.receiptNo, 'R-0001');
  });

  test('refund: POST /payments/{id}/refund returns the refunded row', () async {
    final (repo, adapter) =
        _repo((_) => _json(_paymentJson(status: 'refunded')));
    final p = await repo.refund('pay-1');
    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.uri.path, endsWith('/payments/pay-1/refund'));
    expect(p.isRefunded, isTrue);
  });

  test('refund: 409 (already refunded) surfaces backend detail', () async {
    final (repo, _) = _repo((_) =>
        _json({'detail': 'Payment already refunded'}, status: 409));
    await expectLater(
      repo.refund('pay-1'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 409)
          .having((e) => e.message, 'message', contains('refunded'))),
    );
  });

  // ─── TillPayment parsing ─────────────────────────────────────────────────────

  test('TillPayment.fromJson: parses snake_case, money as String', () {
    final p = TillPayment.fromJson(_paymentJson(amount: '12345.00'));
    expect(p.receiptNo, 'R-0001');
    expect(p.amount, '12345.00');
    expect(p.method, 'cash');
    expect(p.isRefunded, isFalse);
    expect(p.createdAt, '2026-06-12T09:30:00Z');
  });

  // ─── Widget: Платежи (till) ─────────────────────────────────────────────────

  testWidgets('TillTab: renders the owing visits the server returns',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(_cashier)),
        // The till requests owing=true, so the page IS the debtor set — the
        // server filters out fully-paid visits, the client just renders them.
        openVisitsProvider.overrideWith((ref, offset) async => VisitPage(
              items: [ReceptionVisit.fromJson(_visitJson(balance: '300000.00'))],
              total: 1,
              offset: 0,
              limit: 50,
            )),
        patientNameProvider
            .overrideWith((ref, id) async => 'Иванова Дилноза'),
      ],
      child: const MaterialApp(home: Scaffold(body: TillTab())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Иванова Дилноза'), findsOneWidget);
    expect(find.textContaining('V-0001'), findsOneWidget);
    expect(find.text(formatMoney('300000.00')), findsOneWidget);
  });

  testWidgets('TillTab: empty state when nobody owes', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(_cashier)),
        // Server returns an empty owing set.
        openVisitsProvider.overrideWith((ref, offset) async => VisitPage(
              items: const [], total: 0, offset: 0, limit: 50,
            )),
        patientNameProvider.overrideWith((ref, id) async => 'Имя'),
      ],
      child: const MaterialApp(home: Scaffold(body: TillTab())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Нет визитов с задолженностью.'), findsOneWidget);
  });

  // ─── Widget: Возвраты (refund history) ──────────────────────────────────────

  testWidgets('RefundsTab: refund button for completed, chip for refunded',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(_cashier)),
        tillPaymentsProvider.overrideWith((ref, q) async => TillPaymentPage(
              items: [
                TillPayment.fromJson(_paymentJson()),
                TillPayment.fromJson(_paymentJson(
                    id: 'pay-2', receiptNo: 'R-0002', status: 'refunded')),
              ],
              total: 2,
              offset: 0,
              limit: 50,
            )),
        patientNameProvider.overrideWith((ref, id) async => 'Иванова Дилноза'),
      ],
      child: const MaterialApp(home: Scaffold(body: RefundsTab())),
    ));
    await tester.pumpAndSettle();

    // Completed receipt offers a refund action; refunded one shows a chip.
    expect(find.widgetWithText(TextButton, 'Возврат'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Возврат'), findsOneWidget);
  });

  // ─── Widget: Смена (shift summary) ──────────────────────────────────────────

  testWidgets('ShiftTab: renders the daily summary + close-shift action',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(_cashier)),
        dailyReportProvider
            .overrideWith((ref, d) async => DailyReport.fromJson(_dailyJson)),
      ],
      child: const MaterialApp(home: Scaffold(body: ShiftTab())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Наличные'), findsOneWidget);
    expect(find.text('Приход'), findsOneWidget);
    expect(find.text('Итог по смене'), findsOneWidget);
    expect(find.text('Закрыть смену'), findsOneWidget);
    expect(find.text(formatMoney('680000.00')), findsOneWidget);
  });

  // ─── Widget: FinanceScreen tab gating for a cashier ─────────────────────────

  testWidgets('FinanceScreen: cashier sees till tabs (Платежи/Возвраты/Смена)',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(_cashier)),
        openVisitsProvider.overrideWith((ref, offset) async => VisitPage(
            items: const [], total: 0, offset: 0, limit: 50)),
        tillPaymentsProvider.overrideWith((ref, q) async => TillPaymentPage(
            items: const [], total: 0, offset: 0, limit: 50)),
        dailyReportProvider
            .overrideWith((ref, d) async => DailyReport.fromJson(_dailyJson)),
        patientNameProvider.overrideWith((ref, id) async => 'Имя'),
      ],
      child: const MaterialApp(home: FinanceScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Tab, 'Платежи'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Возвраты'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Смена'), findsOneWidget);
    // No payroll.read → no «Зарплата».
    expect(find.widgetWithText(Tab, 'Зарплата'), findsNothing);
  });

  testWidgets('FinanceScreen: no payments.create hides Платежи',
      (tester) async {
    const reception = AuthUser(
      id: 'u-rec',
      email: 'rec@kozshifo.uz',
      fullName: 'Регистратор',
      branchId: 'br-1',
      // Reception can read payments but not refund; no expenses.read.
      permissions: ['payments.read'],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(reception)),
        tillPaymentsProvider.overrideWith((ref, q) async => TillPaymentPage(
            items: const [], total: 0, offset: 0, limit: 50)),
      ],
      child: const MaterialApp(home: FinanceScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Tab, 'Платежи'), findsNothing);
    expect(find.widgetWithText(Tab, 'Возвраты'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Смена'), findsNothing);
  });
}

/// Подменяет AuthController: сразу аутентифицирован с заданным пользователем.
class _FakeAuth extends AuthController {
  _FakeAuth(this._user);

  final AuthUser _user;

  @override
  AuthState build() => AuthState(AuthStatus.authenticated, _user);
}
