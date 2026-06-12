// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Operation _$OperationFromJson(Map<String, dynamic> json) => _Operation(
  id: json['id'] as String,
  visitId: json['visit_id'] as String,
  patientId: json['patient_id'] as String,
  doctorId: json['doctor_id'] as String?,
  operationTypeId: json['operation_type_id'] as String,
  typeName: json['type_name'] as String,
  eye: json['eye'] as String,
  status: json['status'] as String,
  scheduledAt: json['scheduled_at'] as String?,
  performedAt: json['performed_at'] as String?,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$OperationToJson(_Operation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visit_id': instance.visitId,
      'patient_id': instance.patientId,
      'doctor_id': instance.doctorId,
      'operation_type_id': instance.operationTypeId,
      'type_name': instance.typeName,
      'eye': instance.eye,
      'status': instance.status,
      'scheduled_at': instance.scheduledAt,
      'performed_at': instance.performedAt,
      'notes': instance.notes,
      'created_at': instance.createdAt,
    };
