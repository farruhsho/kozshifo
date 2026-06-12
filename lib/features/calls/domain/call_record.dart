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

/// One IP-telephony call (mirrors backend `CallOut`).
@freezed
abstract class CallRecord with _$CallRecord {
  const CallRecord._();

  const factory CallRecord({
    required String id,
    required String direction, // in | out
    required String phone,
    required String startedAt,
    @Default(0) int durationSeconds,
    String? recordingUrl,
    String? note,
    CallPatientBrief? patient,
  }) = _CallRecord;

  factory CallRecord.fromJson(Map<String, dynamic> json) =>
      _$CallRecordFromJson(json);

  bool get isIncoming => direction == 'in';

  /// "3:25" for journal rows.
  String get durationLabel {
    final m = durationSeconds ~/ 60, s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
