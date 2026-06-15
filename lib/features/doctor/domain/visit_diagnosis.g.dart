// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_diagnosis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VisitDiagnosis _$VisitDiagnosisFromJson(Map<String, dynamic> json) =>
    _VisitDiagnosis(
      id: json['id'] as String,
      visitId: json['visit_id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String?,
      diagnosis: json['diagnosis'] as String,
      icd10: json['icd10'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$VisitDiagnosisToJson(_VisitDiagnosis instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visit_id': instance.visitId,
      'patient_id': instance.patientId,
      'doctor_id': instance.doctorId,
      'diagnosis': instance.diagnosis,
      'icd10': instance.icd10,
      'created_at': instance.createdAt,
    };
