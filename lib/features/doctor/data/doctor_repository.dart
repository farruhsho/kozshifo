import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/exam_template.dart';
import '../domain/eye_exam.dart';
import '../domain/frequent_diagnosis.dart';
import '../domain/timeline_event.dart';
import '../domain/visit_diagnosis.dart';
import '../domain/visit_summary.dart';

final doctorRepositoryProvider = Provider<DoctorRepository>(
  (ref) => DoctorRepository(ref.watch(dioProvider)),
);

class DoctorRepository {
  DoctorRepository(this._dio);

  final Dio _dio;

  /// A patient's visits (newest first), optionally narrowed by an `opened_at`
  /// date window ([openedFrom, openedTo) as absolute UTC), status, and a
  /// debt-only filter — feeds both the doctor card panel (no filters) and the
  /// standalone visit-history screen (Ф5).
  Future<List<VisitSummary>> visitsForPatient(
    String patientId, {
    DateTime? openedFrom,
    DateTime? openedTo,
    String? status,
    bool owing = false,
  }) async {
    try {
      final resp = await _dio.get(
        '/visits',
        queryParameters: {
          'patient_id': patientId,
          'status': ?status,
          if (owing) 'owing': true,
          'opened_from': ?openedFrom?.toUtc().toIso8601String(),
          'opened_to': ?openedTo?.toUtc().toIso8601String(),
          'limit': 200,
        },
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

  /// Печатная форма РЕЦЕПТА (очки/медикаменты) по осмотру — отдельно от карты
  /// 025-8; собирает рефракцию OD/OS и «Тавсия» в бланк рецепта. Байты PDF под
  /// тем же правом `exams.read`, что и карта.
  Future<Uint8List> prescriptionPdf(String examId) async {
    try {
      final resp = await _dio.get(
        '/exams/$examId/prescription.pdf',
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

  /// Сохранённые шаблоны заключений текущего врача (назначения для повторного
  /// использования), новые сверху.
  Future<List<ExamTemplate>> examTemplates() async {
    try {
      final resp = await _dio.get('/exam-templates');
      return (resp.data as List<dynamic>)
          .map((e) => ExamTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Сохранить текущее заключение как именованный шаблон (повтор имени — замена).
  Future<ExamTemplate> saveExamTemplate({
    required String name,
    String? diagnosis,
    String? icd10,
    String? recommendations,
  }) async {
    try {
      final resp = await _dio.post('/exam-templates', data: {
        'name': name,
        if (diagnosis != null && diagnosis.trim().isNotEmpty) 'diagnosis': diagnosis,
        if (icd10 != null && icd10.trim().isNotEmpty) 'icd10': icd10,
        if (recommendations != null && recommendations.trim().isNotEmpty)
          'recommendations': recommendations,
      });
      return ExamTemplate.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteExamTemplate(String id) async {
    try {
      await _dio.delete('/exam-templates/$id');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Diagnoses accumulated on a visit (TZ §7.1.5), oldest-first.
  Future<List<VisitDiagnosis>> diagnosesForVisit(String visitId) async {
    try {
      final resp = await _dio.get('/visits/$visitId/diagnoses');
      return (resp.data as List<dynamic>)
          .map((e) => VisitDiagnosis.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<VisitDiagnosis> addDiagnosis(
    String visitId, {
    required String diagnosis,
    String? icd10,
  }) async {
    try {
      final resp = await _dio.post(
        '/visits/$visitId/diagnoses',
        data: {'diagnosis': diagnosis, 'icd10': ?icd10},
      );
      return VisitDiagnosis.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteDiagnosis(String diagnosisId) async {
    try {
      await _dio.delete('/diagnoses/$diagnosisId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Завершить приём врача ПО ВИЗИТУ: сервер через flow engine переводит визит в
  /// follow_up/completed и сам закрывает активный талон врача, если он есть. Не
  /// требует активного талона (owner brief 2026-06-20 — «Нет активного талона»
  /// больше не блокирует завершение приёма).
  ///
  /// [followUpDate] (ISO 'YYYY-MM-DD') — опциональная дата повторного приёма;
  /// когда указана, сервер сохраняет её на визите. Без даты поведение прежнее.
  Future<void> finishAppointment(String visitId, {String? followUpDate}) async {
    try {
      await _dio.post(
        '/visits/$visitId/finish-appointment',
        data: {'follow_up_date': ?followUpDate},
      );
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

/// Filter key for the standalone visit-history screen (Ф5). [from]/[to] are
/// date-only local-midnight bounds (record equality keeps one provider instance
/// per distinct filter); [to] is the EXCLUSIVE upper bound (next day's start).
typedef VisitHistoryQuery = ({
  String patientId,
  DateTime? from,
  DateTime? to,
  String? status,
  bool owing,
});

/// A patient's visits narrowed by the visit-history filter bar (date window,
/// status, debt-only). Separate from [patientVisitsProvider] so the doctor
/// card's unfiltered panel is untouched.
final patientVisitsFilteredProvider = FutureProvider.autoDispose
    .family<List<VisitSummary>, VisitHistoryQuery>(
      (ref, q) => ref
          .watch(doctorRepositoryProvider)
          .visitsForPatient(
            q.patientId,
            openedFrom: q.from,
            openedTo: q.to,
            status: q.status,
            owing: q.owing,
          ),
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

/// Сохранённые шаблоны заключений текущего врача; инвалидируется при сохранении/
/// удалении шаблона.
final examTemplatesProvider = FutureProvider.autoDispose<List<ExamTemplate>>(
  (ref) => ref.watch(doctorRepositoryProvider).examTemplates(),
);

/// Диагнозы визита (TZ §7.1.5) — много на один визит; ключ — visitId.
final visitDiagnosesProvider = FutureProvider.autoDispose
    .family<List<VisitDiagnosis>, String>(
      (ref, visitId) =>
          ref.watch(doctorRepositoryProvider).diagnosesForVisit(visitId),
    );
