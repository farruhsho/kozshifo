import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/device.dart';
import '../domain/device_result.dart';

final devicesRepositoryProvider =
    Provider<DevicesRepository>((ref) => DevicesRepository(ref.watch(dioProvider)));

class DevicesRepository {
  DevicesRepository(this._dio);

  final Dio _dio;

  Future<Page<Device>> list({int offset = 0, int limit = 50}) async {
    try {
      final resp = await _dio.get('/devices',
          queryParameters: {'offset': offset, 'limit': limit});
      return Page.fromJson(resp.data as Map<String, dynamic>, Device.fromJson);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<DeviceResult>> recentResults(String deviceId, {int limit = 20}) async {
    try {
      final resp = await _dio.get('/devices/$deviceId/results',
          queryParameters: {'limit': limit});
      return (resp.data as List<dynamic>)
          .map((e) => DeviceResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<DeviceResult>> resultsForVisit(String visitId) async {
    try {
      final resp = await _dio.get('/visits/$visitId/device-results');
      return (resp.data as List<dynamic>)
          .map((e) => DeviceResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Uploads a scan/report file (B-scan image, biometry PDF, DICOM…) as a
  /// device result attached to [visitId]. The backend infers `result_type`
  /// from the extension and stores the original name in the payload.
  Future<DeviceResult> uploadResultFile({
    required String deviceId,
    required String visitId,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'visit_id': visitId,
      });
      final resp = await _dio.post('/devices/$deviceId/results/file', data: form);
      return DeviceResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Device results that arrived without a visit (orphans) — staff link them
  /// to the right visit afterwards.
  Future<List<DeviceResult>> unlinkedResults({int limit = 50}) async {
    try {
      final resp = await _dio.get('/device-results/unlinked',
          queryParameters: {'limit': limit});
      return (resp.data as List<dynamic>)
          .map((e) => DeviceResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Attach an orphan result to a visit (and its patient).
  Future<DeviceResult> linkResult(String resultId, String visitId) async {
    try {
      final resp = await _dio.post('/device-results/$resultId/link',
          data: {'visit_id': visitId});
      return DeviceResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Raw bytes of a previously uploaded result file (for preview/download).
  Future<Uint8List> resultFileBytes(String resultId) async {
    try {
      final resp = await _dio.get(
        '/device-results/$resultId/file',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data as List<int>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final devicesListProvider = FutureProvider.autoDispose<Page<Device>>(
    (ref) => ref.watch(devicesRepositoryProvider).list());

final deviceRecentResultsProvider = FutureProvider.autoDispose
    .family<List<DeviceResult>, String>((ref, deviceId) =>
        ref.watch(devicesRepositoryProvider).recentResults(deviceId));

final visitDeviceResultsProvider = FutureProvider.autoDispose
    .family<List<DeviceResult>, String>((ref, visitId) =>
        ref.watch(devicesRepositoryProvider).resultsForVisit(visitId));

final unlinkedDeviceResultsProvider =
    FutureProvider.autoDispose<List<DeviceResult>>(
        (ref) => ref.watch(devicesRepositoryProvider).unlinkedResults());
