import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_status.freezed.dart';
part 'attendance_status.g.dart';

/// One employee's live state today (mirrors backend `StaffNow`).
@freezed
abstract class StaffNow with _$StaffNow {
  const StaffNow._();

  const factory StaffNow({
    required String userId,
    required String fullName,
    String? role,
    required String status, // present | left | absent
    String? lastDirection, // in | out
    String? lastEventAt,
    String? firstIn,
    @Default(false) bool late,
    @Default(0) int workedMinutes,
  }) = _StaffNow;

  factory StaffNow.fromJson(Map<String, dynamic> json) =>
      _$StaffNowFromJson(json);

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
}

/// Live roster + Face ID integration health (mirrors backend `AttendanceStatus`).
@freezed
abstract class AttendanceStatus with _$AttendanceStatus {
  const factory AttendanceStatus({
    required String asOf,
    required String workDayStart,
    required bool integrationEnabled,
    required int totalStaff,
    required int presentCount,
    required int leftCount,
    required int absentCount,
    required int lateCount,
    @Default(<StaffNow>[]) List<StaffNow> staff,
  }) = _AttendanceStatus;

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) =>
      _$AttendanceStatusFromJson(json);
}
