import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_report.freezed.dart';
part 'attendance_report.g.dart';

/// One reconstructed working day (mirrors backend `AttendanceDay`).
/// Multiple in/out pairs per day are normal (lunch); a trailing open "in"
/// contributes 0 to workedMinutes.
@freezed
abstract class AttendanceDay with _$AttendanceDay {
  const factory AttendanceDay({
    required String day, // YYYY-MM-DD
    String? firstIn,
    String? lastOut,
    required int workedMinutes,
    required bool late,
  }) = _AttendanceDay;

  factory AttendanceDay.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDayFromJson(json);
}

/// Per-employee timesheet block (mirrors backend `AttendanceUserReport`).
@freezed
abstract class AttendanceUserReport with _$AttendanceUserReport {
  const factory AttendanceUserReport({
    required String userId,
    required String fullName,
    @Default(<AttendanceDay>[]) List<AttendanceDay> days,
    required int daysPresent,
    required int daysAbsent,
    required int totalMinutes,
    required int lateCount,
  }) = _AttendanceUserReport;

  factory AttendanceUserReport.fromJson(Map<String, dynamic> json) =>
      _$AttendanceUserReportFromJson(json);
}

/// Whole-clinic timesheet for a period (mirrors backend `AttendanceReport`).
@freezed
abstract class AttendanceReport with _$AttendanceReport {
  const factory AttendanceReport({
    required String dateFrom,
    required String dateTo,
    required String workDayStart, // "HH:MM" lateness threshold
    @Default(<AttendanceUserReport>[]) List<AttendanceUserReport> users,
  }) = _AttendanceReport;

  factory AttendanceReport.fromJson(Map<String, dynamic> json) =>
      _$AttendanceReportFromJson(json);
}
