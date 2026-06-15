import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/operation.dart';
import '../domain/operation_type.dart';
import '../domain/treatment.dart';

final clinicalRepositoryProvider = Provider<ClinicalRepository>(
    (ref) => ClinicalRepository(ref.watch(dioProvider)));

/// One consumable-template line vs. usable stock in the branch.
/// `required`/`available` are decimal strings (e.g. "2.000") — never doubles.
typedef ConsumableAvailability = ({
  String productId,
  String name,
  String required,
  String available,
  bool ok,
});

/// Advisory availability verdict for an operation type in a branch.
/// `ok` is true when every template line is coverable (empty template → true).
typedef OperationAvailability = ({
  bool ok,
  List<ConsumableAvailability> items,
});

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

  /// Advisory pre-check: can `branchId` cover the type's consumable template?
  /// Advisory only — performOperation still hard-checks stock atomically.
  Future<OperationAvailability> availability(
      String opTypeId, String branchId) async {
    try {
      final resp = await _dio.get(
        '/operation-types/$opTypeId/availability',
        queryParameters: {'branch_id': branchId},
      );
      final data = resp.data as Map<String, dynamic>;
      return (
        ok: data['ok'] as bool,
        items: [
          for (final raw in data['items'] as List<dynamic>)
            (
              productId: (raw as Map<String, dynamic>)['product_id'] as String,
              name: raw['product_name'] as String,
              required: raw['required'] as String,
              available: raw['available'] as String,
              ok: raw['ok'] as bool,
            ),
        ],
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Operations-department worklist (TZ Modul 6). Filter by [status] (referred,
  /// scheduled, in_progress, performed, completed, cancelled) and/or [branchId].
  Future<List<Operation>> operations({String? status, String? branchId}) async {
    try {
      final resp = await _dio.get('/operations', queryParameters: {
        'status': ?status,
        'branch_id': ?branchId,
      });
      return (resp.data as List<dynamic>)
          .map((e) => Operation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Doctor refers the patient to surgery (TZ: «Operatsiyaga yuborish») —
  /// type + recommendation only. NOT billed; reception schedules it later.
  Future<Operation> referOperation({
    required String visitId,
    required String operationTypeId,
    required String eye,
    String priority = 'normal',
    String? notes,
  }) async {
    try {
      final resp = await _dio.post('/visits/$visitId/operations', data: {
        'operation_type_id': operationTypeId,
        'eye': eye,
        'priority': priority,
        'notes': ?notes,
      });
      return Operation.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Reception schedules a referred operation: date/time, surgeon and price
  /// (override optional). This is what bills the linked service onto the visit.
  Future<Operation> scheduleOperation({
    required String id,
    required String scheduledAt,
    String? surgeonId,
    String? price,
    String? notes,
  }) async {
    try {
      final resp = await _dio.post('/operations/$id/schedule', data: {
        'scheduled_at': scheduledAt,
        'surgeon_id': ?surgeonId,
        'price': ?price,
        'notes': ?notes,
      });
      return Operation.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Mark a scheduled operation as in progress (TZ: «Bajarilmoqda»).
  Future<Operation> startOperation(String id) async {
    try {
      final resp = await _dio.post('/operations/$id/start');
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

  /// Wrap up a performed operation (TZ: «Yakunlandi»); the outcome is written
  /// to the patient card.
  Future<Operation> completeOperation(String id, {String? result}) async {
    try {
      final resp = await _dio.post('/operations/$id/complete', data: {
        'result': ?result,
      });
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

/// Operations-department worklist, filtered by status (null → all statuses).
final operationsWorklistProvider = FutureProvider.autoDispose
    .family<List<Operation>, String?>((ref, status) =>
        ref.watch(clinicalRepositoryProvider).operations(status: status));

final visitTreatmentsProvider = FutureProvider.autoDispose
    .family<List<Treatment>, String>((ref, visitId) =>
        ref.watch(clinicalRepositoryProvider).visitTreatments(visitId));
