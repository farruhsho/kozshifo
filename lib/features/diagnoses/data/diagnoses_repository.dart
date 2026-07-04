import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/diagnosis.dart';

final diagnosesRepositoryProvider = Provider<DiagnosesRepository>(
    (ref) => DiagnosesRepository(ref.watch(dioProvider)));

class DiagnosesRepository {
  DiagnosesRepository(this._dio);

  final Dio _dio;

  /// The diagnoses the current user is permitted to record (for a
  /// diagnostician, scoped to what the director allowed). `GET /diagnoses/mine`.
  Future<List<Diagnosis>> myDiagnoses() async {
    try {
      final resp = await _dio.get('/diagnoses/mine');
      return (resp.data as List<dynamic>)
          .map((e) => Diagnosis.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Records a diagnostic conclusion (заключение) onto a visit from the user's
  /// allowed diagnoses. `POST /visits/{visit_id}/diagnostic-conclusion`.
  Future<void> recordConclusion({
    required String visitId,
    required String diagnosisId,
  }) async {
    try {
      await _dio.post(
        '/visits/$visitId/diagnostic-conclusion',
        data: {'diagnosis_id': diagnosisId},
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Removes a WRONG conclusion the current user recorded on this visit (medical
  /// amend). `DELETE /visits/{visit_id}/diagnostic-conclusion/{id}` — gated on
  /// `diagnoses.record`; the backend enforces «own record, visit still live».
  Future<void> deleteConclusion({
    required String visitId,
    required String conclusionId,
  }) async {
    try {
      await _dio.delete('/visits/$visitId/diagnostic-conclusion/$conclusionId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// The current user's allowed diagnoses (for the conclusion picker).
final myDiagnosesProvider = FutureProvider.autoDispose<List<Diagnosis>>(
    (ref) => ref.watch(diagnosesRepositoryProvider).myDiagnoses());
