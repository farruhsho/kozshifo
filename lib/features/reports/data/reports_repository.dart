import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/reports.dart';

final reportsRepositoryProvider =
    Provider<ReportsRepository>((ref) => ReportsRepository(ref.watch(dioProvider)));

/// Формат выгрузки отчёта. Каждый отчёт `/reports/<slug>` имеет варианты
/// `.csv`, `.xlsx`, `.pdf`, отдающие файл байтами.
enum ReportFormat {
  csv(extension: 'csv', mime: 'text/csv'),
  xlsx(
      extension: 'xlsx',
      mime:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
  pdf(extension: 'pdf', mime: 'application/pdf');

  const ReportFormat({required this.extension, required this.mime});
  final String extension;
  final String mime;
}

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

  Future<List<RegionRevenueRow>> profitByRegion(ReportRange r) =>
      _get('/reports/profit-by-region', r,
          (d) => (d as List).map((e) => RegionRevenueRow.fromJson(e as Map<String, dynamic>)).toList());

  /// Скачивает отчёт ([slug] = financial|by-doctor|…) в нужном [format] за
  /// диапазон [r]. Возвращает байты файла (csv/xlsx/pdf).
  Future<Uint8List> download(String slug, ReportRange r,
      {ReportFormat format = ReportFormat.csv}) async {
    try {
      final resp = await _dio.get<List<int>>(
        '/reports/$slug.${format.extension}',
        queryParameters: _range(r),
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data ?? const []);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Скачивает CSV отчёта за диапазон. Тонкая обёртка над [download].
  Future<Uint8List> csv(String slug, ReportRange r) =>
      download(slug, r, format: ReportFormat.csv);
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

final profitByRegionReportProvider =
    FutureProvider.autoDispose.family<List<RegionRevenueRow>, ReportRange>(
        (ref, r) => ref.watch(reportsRepositoryProvider).profitByRegion(r));
