import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/queue_ticket.dart';

/// Routable staff member for the queue assign-picker (mirrors backend
/// `SpecialistOut`). Returned under `queue.manage`, so reception/diagnost can
/// list specialists without the identity-module `users.read` permission.
typedef Specialist = ({String id, String fullName, List<String> roles});

final queueRepositoryProvider =
    Provider<QueueRepository>((ref) => QueueRepository(ref.watch(dioProvider)));

class QueueRepository {
  QueueRepository(this._dio);

  final Dio _dio;

  /// [track]: `doctor` | `diagnostic`; null = обе дорожки одним запросом
  /// (экран очереди делит один список на две колонки на клиенте).
  Future<List<QueueTicket>> list(
      {required String branchId, String? track, bool activeOnly = true}) async {
    try {
      final resp = await _dio.get('/queue', queryParameters: {
        'branch_id': branchId,
        'active_only': activeOnly,
        'track': ?track,
      });
      return (resp.data as List<dynamic>)
          .map((e) => QueueTicket.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// [forUserId] (opt-in): claim the next ticket routed to that specialist OR
  /// still in the open pool. Omitted = unchanged behaviour (any waiting ticket
  /// of the track) — keeps the legacy «вызвать следующего» working as before.
  Future<QueueTicket> callNext(
      {required String branchId,
      required String room,
      String track = 'doctor',
      String? forUserId}) async {
    try {
      final resp = await _dio.post('/queue/call-next', data: {
        'branch_id': branchId,
        'room': room,
        'track': track,
        'for_user_id': ?forUserId,
      });
      return QueueTicket.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<QueueTicket> _transition(String ticketId, String action) async {
    try {
      final resp = await _dio.post('/queue/$ticketId/$action');
      return QueueTicket.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<QueueTicket> serve(String ticketId) => _transition(ticketId, 'serve');
  Future<QueueTicket> done(String ticketId) => _transition(ticketId, 'done');
  Future<QueueTicket> skip(String ticketId) => _transition(ticketId, 'skip');

  /// Route a waiting ticket to [assignedUserId]; pass null to clear it back to
  /// the open pool. Explicit JSON null is required to clear, so the body is
  /// built literally (the null-aware `?` map spread can't emit a null value).
  Future<QueueTicket> assign(String ticketId, {String? assignedUserId}) async {
    try {
      final resp = await _dio.post('/queue/$ticketId/assign',
          data: {'assigned_user_id': assignedUserId});
      return QueueTicket.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Count of today's completed tickets of [track] in [branchId]. Powers the
  /// doctor worklist «принято сегодня» stat (TZ §7.1.6).
  Future<int> servedToday(String branchId, {String track = 'doctor'}) async {
    try {
      final resp = await _dio.get('/queue/served-today',
          queryParameters: {'branch_id': branchId, 'track': track});
      return (resp.data as Map<String, dynamic>)['count'] as int;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Active branch staff for the routing picker (guarded by queue.manage).
  Future<List<Specialist>> specialists(String branchId) async {
    try {
      final resp = await _dio.get('/queue/specialists',
          queryParameters: {'branch_id': branchId});
      return [
        for (final e in resp.data as List<dynamic>)
          (
            id: (e as Map<String, dynamic>)['id'] as String,
            fullName: e['full_name'] as String,
            roles: [for (final r in e['roles'] as List<dynamic>) r as String],
          ),
      ];
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final queueListProvider = FutureProvider.autoDispose
    .family<List<QueueTicket>, String>((ref, branchId) =>
        ref.watch(queueRepositoryProvider).list(branchId: branchId));

final queueSpecialistsProvider = FutureProvider.autoDispose
    .family<List<Specialist>, String>((ref, branchId) =>
        ref.watch(queueRepositoryProvider).specialists(branchId));

/// Today's completed doctor-track tickets for the worklist «принято» stat.
final doctorServedTodayProvider = FutureProvider.autoDispose
    .family<int, String>((ref, branchId) =>
        ref.watch(queueRepositoryProvider).servedToday(branchId));
