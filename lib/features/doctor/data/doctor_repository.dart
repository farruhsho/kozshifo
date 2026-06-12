import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/eye_exam.dart';
import '../domain/frequent_diagnosis.dart';
import '../domain/timeline_event.dart';
import '../domain/visit_summary.dart';

final doctorRepositoryProvider = Provider<DoctorRepository>(
  (ref) => DoctorRepository(ref.watch(dioProvider)),
);

class DoctorRepository {
  DoctorRepository(this._dio);

  final Dio _dio;

  Future<List<VisitSummary>> visitsForPatient(String patientId) async {
    try {
      final resp = await _dio.get(
        '/visits',
        queryParameters: {'patient_id': patientId, 'limit': 200},
      );
      final items = (resp.data['items'] as List<dynamic>)
          .map((e) => VisitSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      return items;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Returns null when no exam has been recorded for the visit yet (404).
  Future<EyeExam?> examForVisit(String visitId) async {
    try {
      final resp = await _dio.get('/visits/$visitId/exam');
      return EyeExam.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.from(e);
    }
  }

  Future<EyeExam> upsertExam(
    String visitId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.put('/visits/$visitId/exam', data: payload);
      return EyeExam.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<EyeExam>> examHistory(String patientId) async {
    try {
      final resp = await _dio.get('/patients/$patientId/exams');
      return (resp.data as List<dynamic>)
          .map((e) => EyeExam.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Uint8List> cardPdf(String visitId) async {
    try {
      final resp = await _dio.get(
        '/visits/$visitId/exam/card.pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data as List<int>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Автоматическая хронология пациента (платежи, осмотры, операции, лечение…)
  /// — собирается backend'ом, по убыванию времени.
  Future<List<TimelineEvent>> timeline(String patientId) async {
    try {
      final resp = await _dio.get(
        '/patients/$patientId/timeline',
        queryParameters: {'limit': 200},
      );
      return (resp.data['events'] as List<dynamic>)
          .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Топ-10 диагнозов ТЕКУЩЕГО врача (сервер агрегирует по точному тексту) —
  /// для чипов быстрого заполнения поля «Ташхис».
  Future<List<FrequentDiagnosis>> frequentDiagnoses() async {
    try {
      final resp = await _dio.get('/exams/frequent-diagnoses');
      return (resp.data as List<dynamic>)
          .map((e) => FrequentDiagnosis.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Copies a refractometer DeviceResult into the visit's exam (OD/OS sph/cyl/axis).
  Future<EyeExam> applyRefraction(String visitId, String resultId) async {
    try {
      final resp = await _dio.post(
        '/visits/$visitId/exam/apply-refraction',
        queryParameters: {'result_id': resultId},
      );
      return EyeExam.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final patientVisitsProvider = FutureProvider.autoDispose
    .family<List<VisitSummary>, String>(
      (ref, patientId) =>
          ref.watch(doctorRepositoryProvider).visitsForPatient(patientId),
    );

final examHistoryProvider = FutureProvider.autoDispose
    .family<List<EyeExam>, String>(
      (ref, patientId) =>
          ref.watch(doctorRepositoryProvider).examHistory(patientId),
    );

final patientTimelineProvider = FutureProvider.autoDispose
    .family<List<TimelineEvent>, String>(
      (ref, patientId) =>
          ref.watch(doctorRepositoryProvider).timeline(patientId),
    );

/// Частые диагнозы текущего врача; инвалидируется после сохранения осмотра.
final frequentDiagnosesProvider =
    FutureProvider.autoDispose<List<FrequentDiagnosis>>(
      (ref) => ref.watch(doctorRepositoryProvider).frequentDiagnoses(),
    );
