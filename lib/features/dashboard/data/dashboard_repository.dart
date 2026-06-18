import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/dashboard_summary.dart';
import '../domain/insight.dart';
import '../domain/lead_source.dart';
import '../domain/region_report.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) => DashboardRepository(ref.watch(dioProvider)));

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardSummary> summary() async {
    try {
      final resp = await _dio.get('/dashboard/summary');
      return DashboardSummary.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Что требует внимания» — backend отдаёт уже отсортированным
  /// critical → warning → info; пустой список = всё в порядке.
  Future<List<Insight>> insights() async {
    try {
      final resp = await _dio.get('/dashboard/insights');
      return (resp.data as List<dynamic>)
          .map((e) => Insight.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Источники пациентов» — распределение визитов/пациентов по каналам
  /// привлечения. Бэкенд принимает даты-only (YYYY-MM-DD); без параметров
  /// считает текущий месяц. Список уже отсортирован по count desc и включает
  /// все 7 каналов + bucket «Не указан» (нули в т.ч.).
  Future<LeadSourceReport> leadSources({DateTime? from, DateTime? to}) async {
    try {
      final resp = await _dio.get('/dashboard/lead-sources', queryParameters: {
        'date_from': ?_date(from),
        'date_to': ?_date(to),
      });
      return LeadSourceReport.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Пациенты по регионам» — распределение пациентов по географии с разбивкой
  /// новые/посещавшие. Бэкенд уже отсортировал по total desc и держит bucket
  /// «Не указано» для пациентов без региона.
  Future<RegionReport> patientsByRegion() async {
    try {
      final resp = await _dio.get('/dashboard/patients-by-region');
      return RegionReport.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  static String? _date(DateTime? d) {
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).summary();
});

final insightsProvider = FutureProvider.autoDispose<List<Insight>>((ref) {
  return ref.watch(dashboardRepositoryProvider).insights();
});

/// «Источники пациентов» за текущий месяц (с 1-го числа по сегодня).
/// Дефолтный диапазон совпадает с бэкендовским «month-to-date», но шлём явно,
/// чтобы UI и сервер не разъехались на границе месяца.
final leadSourcesProvider = FutureProvider.autoDispose<LeadSourceReport>((ref) {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1);
  return ref.watch(dashboardRepositoryProvider).leadSources(from: from, to: now);
});

/// «Пациенты по регионам» — география всей базы (без диапазона дат; бэкенд
/// считает совокупно), с разбивкой новые/посещавшие.
final patientsByRegionProvider =
    FutureProvider.autoDispose<RegionReport>((ref) {
  return ref.watch(dashboardRepositoryProvider).patientsByRegion();
});
