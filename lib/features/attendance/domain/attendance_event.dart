import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_event.freezed.dart';
part 'attendance_event.g.dart';

/// One raw attendance punch (mirrors backend `AttendanceEventOut`).
@freezed
abstract class AttendanceEvent with _$AttendanceEvent {
  const AttendanceEvent._();

  const factory AttendanceEvent({
    required String id,
    required String userId,
    String? userFullName,
    String? branchId,
    required String direction, // in | out
    required String occurredAt,
    required String source, // faceid | manual
    String? note,
    String? recordedById,
    String? createdAt,
  }) = _AttendanceEvent;

  factory AttendanceEvent.fromJson(Map<String, dynamic> json) =>
      _$AttendanceEventFromJson(json);

  bool get isIn => direction == 'in';
}
