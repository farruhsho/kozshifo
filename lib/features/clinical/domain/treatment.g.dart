// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Treatment _$TreatmentFromJson(Map<String, dynamic> json) => _Treatment(
  id: json['id'] as String,
  visitId: json['visit_id'] as String,
  patientId: json['patient_id'] as String,
  doctorId: json['doctor_id'] as String?,
  kind: json['kind'] as String,
  name: json['name'] as String,
  productId: json['product_id'] as String?,
  quantity: json['quantity'] as String?,
  instructions: json['instructions'] as String?,
  status: json['status'] as String,
  performedAt: json['performed_at'] as String?,
  createdAt: json['created_at'] as String,
  sessionsTotal: (json['sessions_total'] as num?)?.toInt() ?? 1,
  sessionsDone: (json['sessions_done'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TreatmentToJson(_Treatment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visit_id': instance.visitId,
      'patient_id': instance.patientId,
      'doctor_id': instance.doctorId,
      'kind': instance.kind,
      'name': instance.name,
      'product_id': instance.productId,
      'quantity': instance.quantity,
      'instructions': instance.instructions,
      'status': instance.status,
      'performed_at': instance.performedAt,
      'created_at': instance.createdAt,
      'sessions_total': instance.sessionsTotal,
      'sessions_done': instance.sessionsDone,
    };
