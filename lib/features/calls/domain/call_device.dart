import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_device.freezed.dart';
part 'call_device.g.dart';

/// A registered reception phone (mirrors backend `CallDeviceOut`). The agent app
/// on this phone reports calls + a heartbeat; `online` is computed server-side
/// against the offline threshold.
@freezed
abstract class CallDevice with _$CallDevice {
  const CallDevice._();

  const factory CallDevice({
    required String id,
    required String label,
    String? phoneNumber,
    String? branchId,
    @Default(true) bool isActive,
    String? lastSeenAt,
    String? appVersion,
    @Default(false) bool online,
  }) = _CallDevice;

  factory CallDevice.fromJson(Map<String, dynamic> json) =>
      _$CallDeviceFromJson(json);
}

/// Result of registering / rotating a device — carries the plaintext key shown
/// ONCE (the backend stores only its hash).
class CreatedDevice {
  const CreatedDevice({required this.device, required this.apiKey});

  final CallDevice device;
  final String apiKey;

  factory CreatedDevice.fromJson(Map<String, dynamic> json) => CreatedDevice(
        device: CallDevice.fromJson(json),
        apiKey: json['api_key'] as String,
      );
}
