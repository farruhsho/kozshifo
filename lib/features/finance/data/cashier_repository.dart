import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../../reception/domain/payment_result.dart';
import '../../reception/domain/reception_visit.dart';
import '../domain/till_payment.dart';

final cashierRepositoryProvider = Provider<CashierRepository>(
    (ref) => CashierRepository(ref.watch(dioProvider)));

/// Page size for the open-visits till and the payment history.
const kTillPageSize = 50;

typedef VisitPage = Page<ReceptionVisit>;
typedef TillPaymentPage = Page<TillPayment>;

/// Data access for the cashier till: open visits to bill, take payments,
/// list/refund receipts, and a thin patient-name lookup. All money math stays
/// on the server — the till only POSTs amount/method and re-reads the visit.
class CashierRepository {
  CashierRepository(this._dio);

  final Dio _dio;

  /// Open visits, newest first. Caller filters to balance > 0 (the backend has
  /// no "outstanding only" flag — `status=open` is the closest server filter).
  Future<VisitPage> openVisits({
    int offset = 0,
    int limit = kTillPageSize,
  }) async {
    try {
      final resp = await _dio.get('/visits', queryParameters: {
        'status': 'open',
        'offset': offset,
        'limit': limit,
      });
      return Page.fromJson(
          resp.data as Map<String, dynamic>, ReceptionVisit.fromJson);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Patient full name for a row. Cashier role carries `patients.read`.
  Future<String> patientName(String patientId) async {
    try {
      final resp = await _dio.get('/patients/$patientId');
      return (resp.data as Map<String, dynamic>)['full_name'] as String;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Takes a payment on a visit. SPLIT payments are natural: pay part now with
  /// one method, the visit keeps a smaller balance, pay again later with
  /// another method. On full payment a diagnostic queue ticket is minted and
  /// its number returned (`issue_queue_ticket: true`).
  Future<PaymentResult> takePayment({
    required String visitId,
    required String amount, // decimal string
    String method = 'cash',
  }) async {
    try {
      final resp = await _dio.post('/payments', data: {
        'visit_id': visitId,
        'amount': amount,
        'method': method,
        'issue_queue_ticket': true,
      });
      return PaymentResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Payment history (newest first). [branchId] scopes to the cashier's branch.
  Future<TillPaymentPage> payments({
    String? branchId,
    int offset = 0,
    int limit = kTillPageSize,
  }) async {
    try {
      final resp = await _dio.get('/payments', queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
        'offset': offset,
        'limit': limit,
      });
      return Page.fromJson(
          resp.data as Map<String, dynamic>, TillPayment.fromJson);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Refunds a payment. 409 — already refunded. Sensitive: the UI confirms.
  Future<TillPayment> refund(String paymentId) async {
    try {
      final resp = await _dio.post('/payments/$paymentId/refund');
      return TillPayment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

/// Open visits page; key = offset. Filter to balance > 0 happens in the UI.
final openVisitsProvider =
    FutureProvider.autoDispose.family<VisitPage, int>((ref, offset) =>
        ref.watch(cashierRepositoryProvider).openVisits(offset: offset));

/// Cached patient-name lookup so each till row resolves its name once.
final patientNameProvider =
    FutureProvider.autoDispose.family<String, String>((ref, patientId) =>
        ref.watch(cashierRepositoryProvider).patientName(patientId));

/// Payment history; key = (branchId, offset) for value-equality caching.
typedef TillPaymentQuery = ({String? branchId, int offset});

final tillPaymentsProvider = FutureProvider.autoDispose
    .family<TillPaymentPage, TillPaymentQuery>((ref, q) => ref
        .watch(cashierRepositoryProvider)
        .payments(branchId: q.branchId, offset: q.offset));
