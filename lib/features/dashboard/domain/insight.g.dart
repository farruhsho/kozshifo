// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Insight _$InsightFromJson(Map<String, dynamic> json) => _Insight(
  code: json['code'] as String,
  severity: json['severity'] as String,
  title: json['title'] as String,
  detail: json['detail'] as String,
  value: json['value'] as String?,
  route: json['route'] as String?,
);

Map<String, dynamic> _$InsightToJson(_Insight instance) => <String, dynamic>{
  'code': instance.code,
  'severity': instance.severity,
  'title': instance.title,
  'detail': instance.detail,
  'value': instance.value,
  'route': instance.route,
};
