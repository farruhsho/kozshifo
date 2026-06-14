import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera.freezed.dart';
part 'camera.g.dart';

/// IP camera registry entry (mirrors backend `CameraOut`).
/// The admin password is write-only on the backend and never present here.
@freezed
abstract class Camera with _$Camera {
  const Camera._();

  const factory Camera({
    required String id,
    required String name,
    required String host,
    required int port,
    required String username,
    @Default(false) bool useHttps,
    @Default('hikvision') String vendor,
    @Default(1) int channelNo,
    String? snapshotPath,
    String? branchId,
    String? branchName,
    required String status,
    @Default(false) bool online,
    String? lastSeen,
    Map<String, dynamic>? deviceInfo,
    required String createdAt,
  }) = _Camera;

  factory Camera.fromJson(Map<String, dynamic> json) => _$CameraFromJson(json);

  String get address => '$host:$port';
}
