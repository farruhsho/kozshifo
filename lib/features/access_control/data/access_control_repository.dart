import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/access_event.dart';
import '../domain/enrollment.dart';
import '../domain/face_terminal.dart';

final accessControlRepositoryProvider = Provider<AccessControlRepository>(
    (ref) => AccessControlRepository(ref.watch(dioProvider)));

/// Face ID / access control: connect terminals over LAN, enroll staff, read events.
class AccessControlRepository {
  AccessControlRepository(this._dio);

  final Dio _dio;

  // ── Terminals ───────────────────────────────────────────────────────────────

  Future<List<FaceTerminal>> terminals() async {
    try {
      final resp = await _dio.get('/access-control/terminals');
      return (resp.data as List<dynamic>)
          .map((e) => FaceTerminal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<FaceTerminal> createTerminal({
    required String name,
    required String host,
    required int port,
    required String username,
    required String password,
    int doorNo = 1,
    bool useHttps = false,
    String? branchId,
  }) async {
    try {
      final resp = await _dio.post('/access-control/terminals', data: {
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'door_no': doorNo,
        'use_https': useHttps,
        'branch_id': ?branchId,
      });
      return FaceTerminal.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// PATCH with exclude-unset semantics; omit `password` to keep it unchanged.
  Future<FaceTerminal> updateTerminal(
    String id, {
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    int? doorNo,
    bool? useHttps,
    String? status,
  }) async {
    try {
      final resp = await _dio.patch('/access-control/terminals/$id', data: {
        'name': ?name,
        'host': ?host,
        'port': ?port,
        'username': ?username,
        'password': ?password,
        'door_no': ?doorNo,
        'use_https': ?useHttps,
        'status': ?status,
      });
      return FaceTerminal.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteTerminal(String id) async {
    try {
      await _dio.delete('/access-control/terminals/$id');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<TerminalTestResult> testTerminal(String id) async {
    try {
      final resp = await _dio.post('/access-control/terminals/$id/test');
      return TerminalTestResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// One-click: tell the terminal to push its events to our webhook.
  /// [serverHost]/[serverPort] = the address the device should reach us on
  /// (the web origin); when omitted the server auto-detects its LAN IP.
  Future<({bool configured, String url, String? error})> configurePush(
    String id, {
    String? serverHost,
    int? serverPort,
  }) async {
    try {
      final resp = await _dio.post(
        '/access-control/terminals/$id/configure-push',
        data: {'server_host': ?serverHost, 'server_port': ?serverPort},
      );
      final d = resp.data as Map<String, dynamic>;
      return (
        configured: d['configured'] as bool,
        url: d['url'] as String,
        error: d['error'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ── Enrollment ──────────────────────────────────────────────────────────────

  Future<List<EnrollmentRow>> enrollment() async {
    try {
      final resp = await _dio.get('/access-control/enrollment');
      return (resp.data as List<dynamic>)
          .map((e) => EnrollmentRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<EnrollResult> enroll(String terminalId, String userId) async {
    try {
      final resp = await _dio
          .post('/access-control/terminals/$terminalId/enroll/$userId');
      return EnrollResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<EnrollResult> uploadFace({
    required String terminalId,
    required String userId,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final resp = await _dio.post(
        '/access-control/terminals/$terminalId/enroll/$userId/face',
        data: form,
      );
      return EnrollResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<EnrollResult> removeEnrollment(String terminalId, String userId) async {
    try {
      final resp = await _dio
          .delete('/access-control/terminals/$terminalId/enroll/$userId');
      return EnrollResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ── Events ──────────────────────────────────────────────────────────────────

  Future<List<AccessEvent>> events({int limit = 50}) async {
    try {
      final resp = await _dio
          .get('/access-control/events', queryParameters: {'limit': limit});
      return (resp.data as List<dynamic>)
          .map((e) => AccessEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final terminalsProvider = FutureProvider.autoDispose<List<FaceTerminal>>(
    (ref) => ref.watch(accessControlRepositoryProvider).terminals());

final enrollmentProvider = FutureProvider.autoDispose<List<EnrollmentRow>>(
    (ref) => ref.watch(accessControlRepositoryProvider).enrollment());

final accessEventsProvider = FutureProvider.autoDispose<List<AccessEvent>>(
    (ref) => ref.watch(accessControlRepositoryProvider).events());
