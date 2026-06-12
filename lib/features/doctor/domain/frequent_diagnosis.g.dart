// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frequent_diagnosis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FrequentDiagnosis _$FrequentDiagnosisFromJson(Map<String, dynamic> json) =>
    _FrequentDiagnosis(
      diagnosis: json['diagnosis'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$FrequentDiagnosisToJson(_FrequentDiagnosis instance) =>
    <String, dynamic>{'diagnosis': instance.diagnosis, 'count': instance.count};
