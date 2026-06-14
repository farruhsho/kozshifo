import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/optics_order.dart';

final opticsRepositoryProvider =
    Provider<OpticsRepository>((ref) => OpticsRepository(ref.watch(dioProvider)));

class OpticsRepository {
  OpticsRepository(this._dio);

  final Dio _dio;

  Future<List<OpticsOrder>> list({required String branchId, String? status}) async {
    try {
      final resp = await _dio.get('/optics', queryParameters: {
        'branch_id': branchId,
        'status': ?status,
      });
      return (resp.data as List<dynamic>)
          .map((e) => OpticsOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<OpticsOrder> create({
    required String branchId,
    required String patientId,
    String? doctorId,
    String kind = 'glasses',
    String? rx,
    String? frame,
    required String price,
  }) async {
    try {
      final resp = await _dio.post('/optics', data: {
        'branch_id': branchId,
        'patient_id': patientId,
        'doctor_id': ?doctorId,
        'kind': kind,
        'rx': ?rx,
        'frame': ?frame,
        'price': price,
      });
      return OpticsOrder.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<OpticsOrder> setStatus(String id, String status) async {
    try {
      final resp = await _dio.post('/optics/$id/status', data: {'status': status});
      return OpticsOrder.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Заказы оптики филиала (новейшие сверху). Фильтрация по статусу — на экране.
final opticsListProvider = FutureProvider.autoDispose
    .family<List<OpticsOrder>, String>((ref, branchId) =>
        ref.watch(opticsRepositoryProvider).list(branchId: branchId));
