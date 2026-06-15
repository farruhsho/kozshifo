// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Operation _$OperationFromJson(Map<String, dynamic> json) => _Operation(
  id: json['id'] as String,
  visitId: json['visit_id'] as String,
  patientId: json['patient_id'] as String,
  patientName: json['patient_name'] as String,
  referringDoctorId: json['referring_doctor_id'] as String?,
  referringDoctorName: json['referring_doctor_name'] as String?,
  surgeonId: json['surgeon_id'] as String?,
  surgeonName: json['surgeon_name'] as String?,
  operationTypeId: json['operation_type_id'] as String,
  typeName: json['type_name'] as String,
  eye: json['eye'] as String,
  priority: json['priority'] as String? ?? 'normal',
  status: json['status'] as String,
  price: json['price'] as String?,
  scheduledAt: json['scheduled_at'] as String?,
  performedAt: json['performed_at'] as String?,
  completedAt: json['completed_at'] as String?,
  notes: json['notes'] as String?,
  result: json['result'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$OperationToJson(_Operation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visit_id': instance.visitId,
      'patient_id': instance.patientId,
      'patient_name': instance.patientName,
      'referring_doctor_id': instance.referringDoctorId,
      'referring_doctor_name': instance.referringDoctorName,
      'surgeon_id': instance.surgeonId,
      'surgeon_name': instance.surgeonName,
      'operation_type_id': instance.operationTypeId,
      'type_name': instance.typeName,
      'eye': instance.eye,
      'priority': instance.priority,
      'status': instance.status,
      'price': instance.price,
      'scheduled_at': instance.scheduledAt,
      'performed_at': instance.performedAt,
      'completed_at': instance.completedAt,
      'notes': instance.notes,
      'result': instance.result,
      'created_at': instance.createdAt,
    };
