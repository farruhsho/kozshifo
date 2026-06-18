import 'package:freezed_annotation/freezed_annotation.dart';

import 'call_device.dart';

part 'calls_summary.freezed.dart';
part 'calls_summary.g.dart';

/// Per-phone call stats (mirrors backend `CallDeviceStat`).
@freezed
abstract class CallDeviceStat with _$CallDeviceStat {
  const factory CallDeviceStat({
    String? deviceId,
    required String label,
    @Default(0) int total,
    @Default(0) int answered,
    @Default(0) int missed,
    @Default(0) int avgWaitSeconds,
  }) = _CallDeviceStat;

  factory CallDeviceStat.fromJson(Map<String, dynamic> json) =>
      _$CallDeviceStatFromJson(json);
}

/// One clinic-local hour bucket for the heatmap (mirrors `CallHourBucket`).
@freezed
abstract class CallHourBucket with _$CallHourBucket {
  const factory CallHourBucket({
    required int hour,
    @Default(0) int total,
    @Default(0) int missed,
  }) = _CallHourBucket;

  factory CallHourBucket.fromJson(Map<String, dynamic> json) =>
      _$CallHourBucketFromJson(json);
}

/// Director call-monitoring KPIs (mirrors backend `CallsSummary`).
@freezed
abstract class CallsSummary with _$CallsSummary {
  const CallsSummary._();

  const factory CallsSummary({
    @Default(0) int total,
    @Default(0) int incoming,
    @Default(0) int answered,
    @Default(0) int missed,
    @Default(0) int rejected,
    @Default(0) int outgoing,
    @Default(0) double missedRate,
    @Default(0) int avgWaitSeconds,
    @Default(0) int maxWaitSeconds,
    @Default(<CallDeviceStat>[]) List<CallDeviceStat> byDevice,
    @Default(<CallHourBucket>[]) List<CallHourBucket> byHour,
    @Default(<CallDevice>[]) List<CallDevice> offlineDevices,
  }) = _CallsSummary;

  factory CallsSummary.fromJson(Map<String, dynamic> json) =>
      _$CallsSummaryFromJson(json);

  /// "0:08" average answer wait.
  String get avgWaitLabel {
    final m = avgWaitSeconds ~/ 60, s = avgWaitSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  int get missedPercent => (missedRate * 100).round();
}
