import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_record.freezed.dart';
part 'call_record.g.dart';

/// Patient summary inside a call-journal row (mirrors backend `CallPatientBrief`).
@freezed
abstract class CallPatientBrief with _$CallPatientBrief {
  const CallPatientBrief._();

  const factory CallPatientBrief({
    required String id,
    required String lastName,
    required String firstName,
  }) = _CallPatientBrief;

  factory CallPatientBrief.fromJson(Map<String, dynamic> json) =>
      _$CallPatientBriefFromJson(json);

  String get fullName => '$lastName $firstName';
}

/// Which reception phone reported the call (mirrors backend `CallDeviceBrief`).
@freezed
abstract class CallDeviceBrief with _$CallDeviceBrief {
  const factory CallDeviceBrief({
    required String id,
    required String label,
  }) = _CallDeviceBrief;

  factory CallDeviceBrief.fromJson(Map<String, dynamic> json) =>
      _$CallDeviceBriefFromJson(json);
}

/// One call (mirrors backend `CallOut`). Feeds the director's reception-phone
/// monitoring: did the front desk answer, and how fast.
@freezed
abstract class CallRecord with _$CallRecord {
  const CallRecord._();

  const factory CallRecord({
    required String id,
    required String direction, // in | out
    @Default('answered') String status, // answered | missed | rejected | outgoing
    required String phone,
    required String startedAt,
    String? endedAt,
    @Default(0) int waitSeconds,
    @Default(0) int durationSeconds,
    String? recordingUrl,
    String? note,
    String? branchId,
    CallPatientBrief? patient,
    CallDeviceBrief? device,
  }) = _CallRecord;

  factory CallRecord.fromJson(Map<String, dynamic> json) =>
      _$CallRecordFromJson(json);

  bool get isIncoming => direction == 'in';
  bool get isMissed => status == 'missed';

  /// "3:25" for journal rows.
  String get durationLabel {
    final m = durationSeconds ~/ 60, s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Ring time before pickup/drop — "0:08".
  String get waitLabel {
    final m = waitSeconds ~/ 60, s = waitSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get statusLabel => switch (status) {
        'answered' => 'Отвечен',
        'missed' => 'Пропущен',
        'rejected' => 'Отклонён',
        'outgoing' => 'Исходящий',
        _ => status,
      };

  IconData get statusIcon => switch (status) {
        'answered' => Icons.call_received,
        'missed' => Icons.phone_missed,
        'rejected' => Icons.call_end,
        'outgoing' => Icons.call_made,
        _ => Icons.call,
      };

  Color get statusColor => switch (status) {
        'answered' => Colors.green,
        'missed' => Colors.red,
        'rejected' => Colors.orange,
        'outgoing' => Colors.blue,
        _ => Colors.grey,
      };
}
