import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/payment_result.dart';
import '../domain/reception_visit.dart';
import '../domain/service.dart';

final receptionRepositoryProvider =
    Provider<ReceptionRepository>((ref) => ReceptionRepository(ref.watch(dioProvider)));

class ReceptionRepository {
  ReceptionRepository(this._dio);

  final Dio _dio;

  Future<List<Service>> services() async {
    try {
      final resp = await _dio.get('/services', queryParameters: {'limit': 200});
      return (resp.data['items'] as List<dynamic>)
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .where((s) => s.isActive)
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ReceptionVisit> createVisit({
    required String patientId,
    required String branchId,
    required List<({String serviceId, int quantity})> items,
  }) async {
    try {
      final resp = await _dio.post('/visits', data: {
        'patient_id': patientId,
        'branch_id': branchId,
        'items': [
          for (final it in items)
            {'service_id': it.serviceId, 'quantity': it.quantity},
        ],
      });
      return ReceptionVisit.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Aborts an unpaid open visit (patient declined / wrong services billed).
  Future<void> cancelVisit(String visitId) async {
    try {
      await _dio.post('/visits/$visitId/cancel');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<PaymentResult> takePayment({
    required String visitId,
    required String amount,
    String method = 'cash',
    String? room,
  }) async {
    try {
      final resp = await _dio.post('/payments', data: {
        'visit_id': visitId,
        'amount': amount,
        'method': method,
        'room': ?room,
      });
      return PaymentResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final activeServicesProvider = FutureProvider.autoDispose<List<Service>>(
    (ref) => ref.watch(receptionRepositoryProvider).services());
