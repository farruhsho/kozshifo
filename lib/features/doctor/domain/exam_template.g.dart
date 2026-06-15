// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExamTemplate _$ExamTemplateFromJson(Map<String, dynamic> json) =>
    _ExamTemplate(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String,
      name: json['name'] as String,
      diagnosis: json['diagnosis'] as String?,
      icd10: json['icd10'] as String?,
      recommendations: json['recommendations'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$ExamTemplateToJson(_ExamTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'doctor_id': instance.doctorId,
      'name': instance.name,
      'diagnosis': instance.diagnosis,
      'icd10': instance.icd10,
      'recommendations': instance.recommendations,
      'created_at': instance.createdAt,
    };
