// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttendanceEvent _$AttendanceEventFromJson(Map<String, dynamic> json) =>
    _AttendanceEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userFullName: json['user_full_name'] as String?,
      branchId: json['branch_id'] as String?,
      direction: json['direction'] as String,
      occurredAt: json['occurred_at'] as String,
      source: json['source'] as String,
      note: json['note'] as String?,
      recordedById: json['recorded_by_id'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$AttendanceEventToJson(_AttendanceEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'user_full_name': instance.userFullName,
      'branch_id': instance.branchId,
      'direction': instance.direction,
      'occurred_at': instance.occurredAt,
      'source': instance.source,
      'note': instance.note,
      'recorded_by_id': instance.recordedById,
      'created_at': instance.createdAt,
    };
