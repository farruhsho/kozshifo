// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttendanceDay _$AttendanceDayFromJson(Map<String, dynamic> json) =>
    _AttendanceDay(
      day: json['day'] as String,
      firstIn: json['first_in'] as String?,
      lastOut: json['last_out'] as String?,
      workedMinutes: (json['worked_minutes'] as num).toInt(),
      late: json['late'] as bool,
    );

Map<String, dynamic> _$AttendanceDayToJson(_AttendanceDay instance) =>
    <String, dynamic>{
      'day': instance.day,
      'first_in': instance.firstIn,
      'last_out': instance.lastOut,
      'worked_minutes': instance.workedMinutes,
      'late': instance.late,
    };

_AttendanceUserReport _$AttendanceUserReportFromJson(
  Map<String, dynamic> json,
) => _AttendanceUserReport(
  userId: json['user_id'] as String,
  fullName: json['full_name'] as String,
  days:
      (json['days'] as List<dynamic>?)
          ?.map((e) => AttendanceDay.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AttendanceDay>[],
  daysPresent: (json['days_present'] as num).toInt(),
  daysAbsent: (json['days_absent'] as num).toInt(),
  totalMinutes: (json['total_minutes'] as num).toInt(),
  lateCount: (json['late_count'] as num).toInt(),
);

Map<String, dynamic> _$AttendanceUserReportToJson(
  _AttendanceUserReport instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'full_name': instance.fullName,
  'days': instance.days.map((e) => e.toJson()).toList(),
  'days_present': instance.daysPresent,
  'days_absent': instance.daysAbsent,
  'total_minutes': instance.totalMinutes,
  'late_count': instance.lateCount,
};

_AttendanceReport _$AttendanceReportFromJson(Map<String, dynamic> json) =>
    _AttendanceReport(
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      workDayStart: json['work_day_start'] as String,
      users:
          (json['users'] as List<dynamic>?)
              ?.map(
                (e) => AttendanceUserReport.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <AttendanceUserReport>[],
    );

Map<String, dynamic> _$AttendanceReportToJson(_AttendanceReport instance) =>
    <String, dynamic>{
      'date_from': instance.dateFrom,
      'date_to': instance.dateTo,
      'work_day_start': instance.workDayStart,
      'users': instance.users.map((e) => e.toJson()).toList(),
    };
