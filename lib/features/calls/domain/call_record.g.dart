// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CallPatientBrief _$CallPatientBriefFromJson(Map<String, dynamic> json) =>
    _CallPatientBrief(
      id: json['id'] as String,
      lastName: json['last_name'] as String,
      firstName: json['first_name'] as String,
    );

Map<String, dynamic> _$CallPatientBriefToJson(_CallPatientBrief instance) =>
    <String, dynamic>{
      'id': instance.id,
      'last_name': instance.lastName,
      'first_name': instance.firstName,
    };

_CallRecord _$CallRecordFromJson(Map<String, dynamic> json) => _CallRecord(
  id: json['id'] as String,
  direction: json['direction'] as String,
  phone: json['phone'] as String,
  startedAt: json['started_at'] as String,
  durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
  recordingUrl: json['recording_url'] as String?,
  note: json['note'] as String?,
  patient: json['patient'] == null
      ? null
      : CallPatientBrief.fromJson(json['patient'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CallRecordToJson(_CallRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'direction': instance.direction,
      'phone': instance.phone,
      'started_at': instance.startedAt,
      'duration_seconds': instance.durationSeconds,
      'recording_url': instance.recordingUrl,
      'note': instance.note,
      'patient': instance.patient?.toJson(),
    };
