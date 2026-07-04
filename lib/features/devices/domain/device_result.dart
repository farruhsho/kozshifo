import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_result.freezed.dart';
part 'device_result.g.dart';

/// One measurement from a device (mirrors backend `DeviceResultOut`).
@freezed
abstract class DeviceResult with _$DeviceResult {
  const DeviceResult._();

  const factory DeviceResult({
    required String id,
    required String deviceId,
    String? patientId,
    String? visitId,
    required String resultType,
    Map<String, dynamic>? payload,
    String? filePath,
    required String measuredAt,
    required String source,
  }) = _DeviceResult;

  factory DeviceResult.fromJson(Map<String, dynamic> json) =>
      _$DeviceResultFromJson(json);

  bool get isRefraction => resultType == 'refraction';
  bool get isScan =>
      resultType == 'bscan_image' || resultType == 'biometry' || resultType == 'file';

  /// Original filename of an uploaded result (from payload metadata) — so staff
  /// see WHAT a file result is, not the stored UUID name.
  String? get originalName {
    final name = payload?['original_name'];
    return (name is String && name.isNotEmpty) ? name : null;
  }

  /// «OD sph -1.25 cyl -0.50 ax 170» — refraction summary for lists. For file
  /// results shows the original filename instead of the raw UUID stored name.
  String get summary {
    if (isRefraction && payload != null) {
      String eye(String key) {
        final e = payload![key];
        if (e is! Map) return '';
        return '${key.toUpperCase()} sph ${e['sph'] ?? '—'} cyl ${e['cyl'] ?? '—'} ax ${e['axis'] ?? '—'}';
      }

      return [eye('od'), eye('os')].where((s) => s.isNotEmpty).join(' · ');
    }
    return originalName ?? filePath ?? resultType;
  }
}
