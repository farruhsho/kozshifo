import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/camera.dart';

/// Outcome of probing a camera (mirrors backend `CameraTestResult`).
typedef CameraTestResult = ({
  bool online,
  String? model,
  String? firmware,
  String? serial,
  String? deviceName,
  String? error,
});

final camerasRepositoryProvider =
    Provider<CamerasRepository>((ref) => CamerasRepository(ref.watch(dioProvider)));

/// IP cameras: connect by IP, live snapshot, test. Mirrors the access-control
/// (Face ID) repository. Snapshots are fetched as raw bytes (JWT auto-attached
/// by the Dio interceptor) and rendered with Image.memory — Image.network can't
/// attach the auth header on web.
class CamerasRepository {
  CamerasRepository(this._dio);

  final Dio _dio;

  Future<List<Camera>> list() async {
    try {
      final resp = await _dio.get('/cameras'); // plain list, no Page envelope
      return (resp.data as List<dynamic>)
          .map((e) => Camera.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Camera> create({
    required String name,
    required String host,
    required int port,
    required String username,
    required String password,
    bool useHttps = false,
    String vendor = 'hikvision',
    int channelNo = 1,
    String? snapshotPath,
    String? branchId,
  }) async {
    try {
      final resp = await _dio.post('/cameras', data: {
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'use_https': useHttps,
        'vendor': vendor,
        'channel_no': channelNo,
        'snapshot_path': ?snapshotPath,
        'branch_id': ?branchId,
      });
      return Camera.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// PATCH with exclude-unset semantics; omit password to leave it unchanged.
  Future<Camera> update(
    String id, {
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? useHttps,
    String? vendor,
    int? channelNo,
    String? snapshotPath,
    String? branchId,
    String? status,
  }) async {
    try {
      final resp = await _dio.patch('/cameras/$id', data: {
        'name': ?name,
        'host': ?host,
        'port': ?port,
        'username': ?username,
        'password': ?password,
        'use_https': ?useHttps,
        'vendor': ?vendor,
        'channel_no': ?channelNo,
        'snapshot_path': ?snapshotPath,
        'branch_id': ?branchId,
        'status': ?status,
      });
      return Camera.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/cameras/$id');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<CameraTestResult> test(String id) async {
    try {
      final resp = await _dio.post('/cameras/$id/test');
      final m = resp.data as Map<String, dynamic>;
      return (
        online: m['online'] as bool? ?? false,
        model: m['model'] as String?,
        firmware: m['firmware'] as String?,
        serial: m['serial'] as String?,
        deviceName: m['device_name'] as String?,
        error: m['error'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// One live JPEG frame. Throws [ApiException] (502) when the camera is down —
  /// the caller shows «нет сигнала» and keeps polling.
  Future<Uint8List> snapshot(String id) async {
    try {
      final resp = await _dio.get(
        '/cameras/$id/snapshot',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data as List<int>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final camerasListProvider = FutureProvider.autoDispose<List<Camera>>(
    (ref) => ref.watch(camerasRepositoryProvider).list());
