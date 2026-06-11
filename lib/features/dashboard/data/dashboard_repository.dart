import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/dashboard_summary.dart';

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
}

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).summary();
});
