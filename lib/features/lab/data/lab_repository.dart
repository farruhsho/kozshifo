import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/lab_order.dart';

final labRepositoryProvider =
    Provider<LabRepository>((ref) => LabRepository(ref.watch(dioProvider)));

class LabRepository {
  LabRepository(this._dio);

  final Dio _dio;

  Future<List<LabOrder>> list({required String branchId, String? status}) async {
    try {
      final resp = await _dio.get('/lab', queryParameters: {
        'branch_id': branchId,
        'status': ?status,
      });
      return (resp.data as List<dynamic>)
          .map((e) => LabOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<LabOrder> create({
    required String branchId,
    required String patientId,
    String? doctorId,
    required String testName,
    String? notes,
  }) async {
    try {
      final resp = await _dio.post('/lab', data: {
        'branch_id': branchId,
        'patient_id': patientId,
        'doctor_id': ?doctorId,
        'test_name': testName,
        'notes': ?notes,
      });
      return LabOrder.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Внести результат — сервер заодно переводит направление в `ready`.
  Future<LabOrder> setResult(String id, String result) async {
    try {
      final resp = await _dio.post('/lab/$id/result', data: {'result': result});
      return LabOrder.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<LabOrder> setStatus(String id, String status) async {
    try {
      final resp = await _dio.post('/lab/$id/status', data: {'status': status});
      return LabOrder.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final labListProvider = FutureProvider.autoDispose
    .family<List<LabOrder>, String>((ref, branchId) =>
        ref.watch(labRepositoryProvider).list(branchId: branchId));
