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

_CallDeviceBrief _$CallDeviceBriefFromJson(Map<String, dynamic> json) =>
    _CallDeviceBrief(id: json['id'] as String, label: json['label'] as String);

Map<String, dynamic> _$CallDeviceBriefToJson(_CallDeviceBrief instance) =>
    <String, dynamic>{'id': instance.id, 'label': instance.label};

_CallRecord _$CallRecordFromJson(Map<String, dynamic> json) => _CallRecord(
  id: json['id'] as String,
  direction: json['direction'] as String,
  status: json['status'] as String? ?? 'answered',
  phone: json['phone'] as String,
  startedAt: json['started_at'] as String,
  endedAt: json['ended_at'] as String?,
  waitSeconds: (json['wait_seconds'] as num?)?.toInt() ?? 0,
  durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
  recordingUrl: json['recording_url'] as String?,
  note: json['note'] as String?,
  branchId: json['branch_id'] as String?,
  patient: json['patient'] == null
      ? null
      : CallPatientBrief.fromJson(json['patient'] as Map<String, dynamic>),
  device: json['device'] == null
      ? null
      : CallDeviceBrief.fromJson(json['device'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CallRecordToJson(_CallRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'direction': instance.direction,
      'status': instance.status,
      'phone': instance.phone,
      'started_at': instance.startedAt,
      'ended_at': instance.endedAt,
      'wait_seconds': instance.waitSeconds,
      'duration_seconds': instance.durationSeconds,
      'recording_url': instance.recordingUrl,
      'note': instance.note,
      'branch_id': instance.branchId,
      'patient': instance.patient?.toJson(),
      'device': instance.device?.toJson(),
    };
