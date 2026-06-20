import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../dashboard/domain/insight.dart';
import '../domain/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
    (ref) => NotificationsRepository(ref.watch(dioProvider)));

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  /// Historical DELIVERY journal (may contain resolved events). Kept for audit;
  /// the in-app attention surface uses [activeProblems] instead.
  Future<List<AppNotification>> list({String? event, int limit = 50}) async {
    try {
      final resp = await _dio.get('/notifications', queryParameters: {
        'event': ?event,
        'limit': limit,
      });
      return (resp.data as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// LIVE, self-resolving problem set: a notification exists only while its
  /// problem exists (computed on read on the server — никаких устаревших
  /// записей). Mirrors the dashboard attention panel.
  Future<List<Insight>> activeProblems() async {
    try {
      final resp = await _dio.get('/notifications/active');
      return (resp.data as List<dynamic>)
          .map((e) => Insight.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
    (ref) => ref.watch(notificationsRepositoryProvider).list());

/// Живой набор актуальных проблем для экрана «Уведомления» (самоочищается).
final activeProblemsProvider = FutureProvider.autoDispose<List<Insight>>(
    (ref) => ref.watch(notificationsRepositoryProvider).activeProblems());
