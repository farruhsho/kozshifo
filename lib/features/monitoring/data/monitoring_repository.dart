import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/monitoring.dart';

final monitoringRepositoryProvider = Provider<MonitoringRepository>(
  (ref) => MonitoringRepository(ref.watch(dioProvider)),
);

class MonitoringRepository {
  MonitoringRepository(this._dio);

  final Dio _dio;

  Future<MonitoringStats> stats() async {
    try {
      final resp = await _dio.get('/admin/monitoring');
      return MonitoringStats.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<SessionRow>> sessions({int limit = 100}) async {
    try {
      final resp = await _dio.get('/admin/sessions', queryParameters: {'limit': limit});
      return (resp.data as List<dynamic>)
          .map((e) => SessionRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final monitoringStatsProvider = FutureProvider.autoDispose<MonitoringStats>(
    (ref) => ref.watch(monitoringRepositoryProvider).stats());

final sessionsProvider = FutureProvider.autoDispose<List<SessionRow>>(
    (ref) => ref.watch(monitoringRepositoryProvider).sessions());
