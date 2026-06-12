import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/operation.dart';
import '../domain/operation_type.dart';
import '../domain/treatment.dart';

final clinicalRepositoryProvider = Provider<ClinicalRepository>(
    (ref) => ClinicalRepository(ref.watch(dioProvider)));

/// Operations + treatment prescriptions of the clinical loop.
/// Decimals (price, quantity) are strings end-to-end — the server owns the math.
class ClinicalRepository {
  ClinicalRepository(this._dio);

  final Dio _dio;

  // ---- Operations -------------------------------------------------------

  Future<List<OperationType>> operationTypes() async {
    try {
      final resp = await _dio.get('/operation-types');
      return (resp.data as List<dynamic>)
          .map((e) => OperationType.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<Operation>> visitOperations(String visitId) async {
    try {
      final resp = await _dio.get('/visits/$visitId/operations');
      return (resp.data as List<dynamic>)
          .map((e) => Operation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Prescribe an operation; the backend also bills the linked service
  /// onto the visit in the same transaction.
  Future<Operation> prescribeOperation({
    required String visitId,
    required String operationTypeId,
    required String eye,
    String? notes,
  }) async {
    try {
      final resp = await _dio.post('/visits/$visitId/operations', data: {
        'operation_type_id': operationTypeId,
        'eye': eye,
        'notes': ?notes,
      });
      return Operation.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Mark performed; the backend auto-writes-off the consumables and answers
  /// 409 with the missing product in `detail` when stock is insufficient.
  Future<Operation> performOperation(String id) async {
    try {
      final resp = await _dio.post('/operations/$id/perform');
      return Operation.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Operation> cancelOperation(String id) async {
    try {
      final resp = await _dio.post('/operations/$id/cancel');
      return Operation.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ---- Treatments --------------------------------------------------------

  Future<List<Treatment>> visitTreatments(String visitId) async {
    try {
      final resp = await _dio.get('/visits/$visitId/treatments');
      return (resp.data as List<dynamic>)
          .map((e) => Treatment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Treatment> prescribeTreatment({
    required String visitId,
    required String kind,
    required String name,
    String? productId,
    String? quantity,
    String? instructions,
  }) async {
    try {
      final resp = await _dio.post('/visits/$visitId/treatments', data: {
        'kind': kind,
        'name': name,
        'product_id': ?productId,
        'quantity': ?quantity,
        'instructions': ?instructions,
      });
      return Treatment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Dispense a medication (writes stock off; 409 `detail` on shortage).
  Future<Treatment> dispenseTreatment(String id) async {
    try {
      final resp = await _dio.post('/treatments/$id/dispense');
      return Treatment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Mark a procedure as completed.
  Future<Treatment> completeTreatment(String id) async {
    try {
      final resp = await _dio.post('/treatments/$id/complete');
      return Treatment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Treatment> cancelTreatment(String id) async {
    try {
      final resp = await _dio.post('/treatments/$id/cancel');
      return Treatment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final operationTypesProvider = FutureProvider.autoDispose<List<OperationType>>(
    (ref) => ref.watch(clinicalRepositoryProvider).operationTypes());

final visitOperationsProvider = FutureProvider.autoDispose
    .family<List<Operation>, String>((ref, visitId) =>
        ref.watch(clinicalRepositoryProvider).visitOperations(visitId));

final visitTreatmentsProvider = FutureProvider.autoDispose
    .family<List<Treatment>, String>((ref, visitId) =>
        ref.watch(clinicalRepositoryProvider).visitTreatments(visitId));
