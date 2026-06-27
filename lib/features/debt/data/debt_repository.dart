import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/debtor_row.dart';
import '../domain/patient_debt_detail.dart';

final debtRepositoryProvider =
    Provider<DebtRepository>((ref) => DebtRepository(ref.watch(dioProvider)));

/// «Долги» (debt management) — read the debtors list / a patient's debt detail,
/// and record a (partial) repayment by reusing the existing payments endpoint.
class DebtRepository {
  DebtRepository(this._dio);

  final Dio _dio;

  /// Debtors, highest debt first. [limit] caps the rows; [branchId] filters by
  /// branch when provided.
  Future<List<DebtorRow>> debtors({int limit = 100, String? branchId}) async {
    try {
      final resp = await _dio.get('/debts', queryParameters: {
        'limit': limit,
        'branch_id': ?branchId,
      });
      return (resp.data as List<dynamic>)
          .map((e) => DebtorRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Full debt picture for one patient: owing visits + repayment history.
  Future<PatientDebtDetail> patientDebt(String patientId) async {
    try {
      final resp = await _dio.get('/debts/patient/$patientId');
      return PatientDebtDetail.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Record a (partial) repayment against [visitId]. Reuses POST /payments with
  /// `issue_queue_ticket:false` — a debt repayment never spawns a queue ticket.
  Future<void> repay({
    required String visitId,
    required String amount, // decimal string
    required String method, // cash | card | qr | transfer
    String? note,
  }) async {
    try {
      await _dio.post('/payments', data: {
        'visit_id': visitId,
        'amount': amount,
        'method': method,
        if (note != null && note.isNotEmpty) 'note': note,
        'issue_queue_ticket': false,
      });
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

/// Top 5 debtors for the dashboard «ТОП должников» card.
final topDebtorsProvider = FutureProvider.autoDispose<List<DebtorRow>>(
    (ref) => ref.watch(debtRepositoryProvider).debtors(limit: 5));

/// Full debtors list for the «Долги» screen.
final debtorsProvider = FutureProvider.autoDispose<List<DebtorRow>>(
    (ref) => ref.watch(debtRepositoryProvider).debtors());

/// One patient's debt detail. key = patientId.
final patientDebtProvider =
    FutureProvider.autoDispose.family<PatientDebtDetail, String>(
        (ref, id) => ref.watch(debtRepositoryProvider).patientDebt(id));
