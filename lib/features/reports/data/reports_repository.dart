import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/reports.dart';

final reportsRepositoryProvider =
    Provider<ReportsRepository>((ref) => ReportsRepository(ref.watch(dioProvider)));

/// Все отчёты директора (право `reports.view`). Диапазон дат — локальные даты
/// YYYY-MM-DD; без параметров бэкенд берёт текущий месяц по сегодня.
class ReportsRepository {
  ReportsRepository(this._dio);
  final Dio _dio;

  static String? _date(DateTime? d) {
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Map<String, dynamic> _range(ReportRange r) =>
      {'date_from': ?_date(r.from), 'date_to': ?_date(r.to)};

  Future<T> _get<T>(String path, ReportRange r, T Function(dynamic) parse) async {
    try {
      final resp = await _dio.get(path, queryParameters: _range(r));
      return parse(resp.data);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<FinancialReport> financial(ReportRange r) =>
      _get('/reports/financial', r, (d) => FinancialReport.fromJson(d as Map<String, dynamic>));

  Future<List<DoctorReportRow>> byDoctor(ReportRange r) => _get('/reports/by-doctor', r,
      (d) => (d as List).map((e) => DoctorReportRow.fromJson(e as Map<String, dynamic>)).toList());

  Future<List<DiagnosticianRow>> byDiagnostician(ReportRange r) =>
      _get('/reports/by-diagnostician', r,
          (d) => (d as List).map((e) => DiagnosticianRow.fromJson(e as Map<String, dynamic>)).toList());

  Future<List<PatientSpendRow>> byPatient(ReportRange r) => _get('/reports/by-patient', r,
      (d) => (d as List).map((e) => PatientSpendRow.fromJson(e as Map<String, dynamic>)).toList());

  Future<List<RegionReportRow>> byRegion(ReportRange r) => _get('/reports/by-region', r,
      (d) => (d as List).map((e) => RegionReportRow.fromJson(e as Map<String, dynamic>)).toList());

  Future<OperationsReport> byOperation(ReportRange r) =>
      _get('/reports/by-operation', r, (d) => OperationsReport.fromJson(d as Map<String, dynamic>));

  /// Скачивает CSV отчёта ([slug] = financial|by-doctor|…) за тот же диапазон.
  Future<Uint8List> csv(String slug, ReportRange r) async {
    try {
      final resp = await _dio.get<List<int>>(
        '/reports/$slug.csv',
        queryParameters: _range(r),
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data ?? const []);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

// ── Провайдеры по диапазону дат (record-ключ — value-равенство) ──────────────

final financialReportProvider =
    FutureProvider.autoDispose.family<FinancialReport, ReportRange>(
        (ref, r) => ref.watch(reportsRepositoryProvider).financial(r));

final byDoctorReportProvider =
    FutureProvider.autoDispose.family<List<DoctorReportRow>, ReportRange>(
        (ref, r) => ref.watch(reportsRepositoryProvider).byDoctor(r));

final byDiagnosticianReportProvider =
    FutureProvider.autoDispose.family<List<DiagnosticianRow>, ReportRange>(
        (ref, r) => ref.watch(reportsRepositoryProvider).byDiagnostician(r));

final byPatientReportProvider =
    FutureProvider.autoDispose.family<List<PatientSpendRow>, ReportRange>(
        (ref, r) => ref.watch(reportsRepositoryProvider).byPatient(r));

final byRegionReportProvider =
    FutureProvider.autoDispose.family<List<RegionReportRow>, ReportRange>(
        (ref, r) => ref.watch(reportsRepositoryProvider).byRegion(r));

final byOperationReportProvider =
    FutureProvider.autoDispose.family<OperationsReport, ReportRange>(
        (ref, r) => ref.watch(reportsRepositoryProvider).byOperation(r));
