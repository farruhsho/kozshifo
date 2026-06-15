// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StaffNow _$StaffNowFromJson(Map<String, dynamic> json) => _StaffNow(
  userId: json['user_id'] as String,
  fullName: json['full_name'] as String,
  role: json['role'] as String?,
  status: json['status'] as String,
  lastDirection: json['last_direction'] as String?,
  lastEventAt: json['last_event_at'] as String?,
  firstIn: json['first_in'] as String?,
  late: json['late'] as bool? ?? false,
  workedMinutes: (json['worked_minutes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$StaffNowToJson(_StaffNow instance) => <String, dynamic>{
  'user_id': instance.userId,
  'full_name': instance.fullName,
  'role': instance.role,
  'status': instance.status,
  'last_direction': instance.lastDirection,
  'last_event_at': instance.lastEventAt,
  'first_in': instance.firstIn,
  'late': instance.late,
  'worked_minutes': instance.workedMinutes,
};

_AttendanceStatus _$AttendanceStatusFromJson(Map<String, dynamic> json) =>
    _AttendanceStatus(
      asOf: json['as_of'] as String,
      workDayStart: json['work_day_start'] as String,
      integrationEnabled: json['integration_enabled'] as bool,
      totalStaff: (json['total_staff'] as num).toInt(),
      presentCount: (json['present_count'] as num).toInt(),
      leftCount: (json['left_count'] as num).toInt(),
      absentCount: (json['absent_count'] as num).toInt(),
      lateCount: (json['late_count'] as num).toInt(),
      staff:
          (json['staff'] as List<dynamic>?)
              ?.map((e) => StaffNow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StaffNow>[],
    );

Map<String, dynamic> _$AttendanceStatusToJson(_AttendanceStatus instance) =>
    <String, dynamic>{
      'as_of': instance.asOf,
      'work_day_start': instance.workDayStart,
      'integration_enabled': instance.integrationEnabled,
      'total_staff': instance.totalStaff,
      'present_count': instance.presentCount,
      'left_count': instance.leftCount,
      'absent_count': instance.absentCount,
      'late_count': instance.lateCount,
      'staff': instance.staff.map((e) => e.toJson()).toList(),
    };
