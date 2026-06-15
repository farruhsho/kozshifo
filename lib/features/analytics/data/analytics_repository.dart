import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/top_service.dart';

/// Аналитика поверх дашборд-эндпоинтов. Сводка/источники переиспользуются из
/// dashboard_repository (dashboardSummaryProvider, leadSourcesProvider); здесь
/// только новый «топ услуг по выручке».
final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
    (ref) => AnalyticsRepository(ref.watch(dioProvider)));

class AnalyticsRepository {
  AnalyticsRepository(this._dio);

  final Dio _dio;

  Future<List<TopService>> topServices({int limit = 8}) async {
    try {
      final resp =
          await _dio.get('/dashboard/top-services', queryParameters: {'limit': limit});
      return (resp.data as List<dynamic>)
          .map((e) => TopService.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final topServicesProvider = FutureProvider.autoDispose<List<TopService>>(
    (ref) => ref.watch(analyticsRepositoryProvider).topServices());
