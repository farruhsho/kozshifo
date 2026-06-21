import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/dashboard_summary.dart';
import '../domain/director_analytics.dart';
import '../domain/finance_by_direction.dart';
import '../domain/hanging_visit.dart';
import '../domain/insight.dart';
import '../domain/lead_source.dart';
import '../domain/period_summary.dart';
import '../domain/region_report.dart';
import '../domain/revenue_trend.dart';

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

  /// Зависшие визиты по 5 категориям с конкретными пациентами (самоочищается).
  Future<List<HangingCategory>> hangingVisits() async {
    try {
      final resp = await _dio.get('/dashboard/hanging-visits');
      return (resp.data as List<dynamic>)
          .map((e) => HangingCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Метрики за выбранный период (date_from/date_to — даты YYYY-MM-DD только для
  /// custom; для пресетов сервер сам считает окно).
  Future<PeriodSummary> periodSummary(PeriodQuery q) async {
    try {
      final resp = await _dio.get('/dashboard/period-summary', queryParameters: {
        'period': q.period,
        'date_from': ?q.from,
        'date_to': ?q.to,
      });
      return PeriodSummary.fromJson(resp.data as Map<String, dynamic>);
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

  /// «Выручка по дням» — тренд завершённой выручки за последние `days`
  /// локальных дней (старые→новые, ровно `days` точек). Право `dashboard.view`.
  Future<RevenueTrend> revenueTrend({int days = 14}) async {
    try {
      final resp = await _dio.get('/dashboard/revenue-trend',
          queryParameters: {'days': days});
      return RevenueTrend.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Доход по врачам» за месяц (по умолчанию — текущий). Право `dashboard.view`.
  Future<DoctorRevenueReport> revenueByDoctor({String? month}) async {
    try {
      final resp = await _dio.get('/dashboard/revenue-by-doctor',
          queryParameters: {'month': ?month});
      return DoctorRevenueReport.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Операции за месяц» — воронка назначено/выполнено/отменено + P&L.
  Future<OperationsSummary> operationsSummary({String? month}) async {
    try {
      final resp = await _dio.get('/dashboard/operations-summary',
          queryParameters: {'month': ?month});
      return OperationsSummary.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Финансы по направлениям» — доход/расход/прибыль по 4 направлениям
  /// (приём/диагностика/лечение/операции) за период day|week|month|year.
  Future<FinanceByDirection> financeByDirection({String period = 'month'}) async {
    try {
      final resp = await _dio.get('/dashboard/finance-by-direction',
          queryParameters: {'period': period});
      return FinanceByDirection.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Структура расходов» за месяц — по категориям (с payroll).
  Future<ExpenseBreakdown> expenseBreakdown({String? month}) async {
    try {
      final resp = await _dio.get('/dashboard/expense-breakdown',
          queryParameters: {'month': ?month});
      return ExpenseBreakdown.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Рост/падение регионов» — новые пациенты этот месяц vs прошлый.
  Future<RegionTrendReport> regionTrend({String? month}) async {
    try {
      final resp = await _dio.get('/dashboard/region-trend',
          queryParameters: {'month': ?month});
      return RegionTrendReport.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Пациенты по районам» одного региона (по умолчанию — домашний, Ферганская).
  Future<DistrictReport> patientsByDistrict({String? region}) async {
    try {
      final resp = await _dio.get('/dashboard/patients-by-district',
          queryParameters: {'region': ?region});
      return DistrictReport.fromJson(resp.data as Map<String, dynamic>);
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

final hangingVisitsProvider =
    FutureProvider.autoDispose<List<HangingCategory>>((ref) {
  return ref.watch(dashboardRepositoryProvider).hangingVisits();
});

/// Ключ периода для [periodSummaryProvider]: пресет + опц. custom-даты
/// (YYYY-MM-DD). Record → value-equality, поэтому family кэширует по периоду.
typedef PeriodQuery = ({String period, String? from, String? to});

final periodSummaryProvider =
    FutureProvider.autoDispose.family<PeriodSummary, PeriodQuery>(
        (ref, q) => ref.watch(dashboardRepositoryProvider).periodSummary(q));

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

/// «Выручка (14 дней)» — тренд завершённой выручки по локальным дням для
/// графика на дашборде директора.
final revenueTrendProvider = FutureProvider.autoDispose<RevenueTrend>((ref) {
  return ref.watch(dashboardRepositoryProvider).revenueTrend(days: 14);
});

/// «Доход по врачам» за текущий месяц.
final revenueByDoctorProvider =
    FutureProvider.autoDispose<DoctorRevenueReport>((ref) {
  return ref.watch(dashboardRepositoryProvider).revenueByDoctor();
});

/// «Операции за месяц» — воронка + P&L (текущий месяц).
final operationsSummaryProvider =
    FutureProvider.autoDispose<OperationsSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).operationsSummary();
});

/// «Финансы по направлениям» — ключ = период (day|week|month|year).
final financeByDirectionProvider = FutureProvider.autoDispose
    .family<FinanceByDirection, String>((ref, period) =>
        ref.watch(dashboardRepositoryProvider).financeByDirection(period: period));

/// «Структура расходов» за текущий месяц.
final expenseBreakdownProvider =
    FutureProvider.autoDispose<ExpenseBreakdown>((ref) {
  return ref.watch(dashboardRepositoryProvider).expenseBreakdown();
});

/// «Рост/падение регионов» — текущий месяц vs прошлый.
final regionTrendProvider =
    FutureProvider.autoDispose<RegionTrendReport>((ref) {
  return ref.watch(dashboardRepositoryProvider).regionTrend();
});

/// «Пациенты по районам» — детализация по выбранному региону (домашний по
/// умолчанию). Ключ — название региона.
final patientsByDistrictProvider =
    FutureProvider.autoDispose.family<DistrictReport, String?>((ref, region) {
  return ref.watch(dashboardRepositoryProvider).patientsByDistrict(region: region);
});
