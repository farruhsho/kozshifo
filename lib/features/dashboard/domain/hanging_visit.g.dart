// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hanging_visit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HangingVisitRow _$HangingVisitRowFromJson(Map<String, dynamic> json) =>
    _HangingVisitRow(
      visitId: json['visit_id'] as String,
      visitNo: json['visit_no'] as String,
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String,
      flowStatus: json['flow_status'] as String,
      openedAt: json['opened_at'] as String,
      detail: json['detail'] as String,
    );

Map<String, dynamic> _$HangingVisitRowToJson(_HangingVisitRow instance) =>
    <String, dynamic>{
      'visit_id': instance.visitId,
      'visit_no': instance.visitNo,
      'patient_id': instance.patientId,
      'patient_name': instance.patientName,
      'flow_status': instance.flowStatus,
      'opened_at': instance.openedAt,
      'detail': instance.detail,
    };

_HangingCategory _$HangingCategoryFromJson(Map<String, dynamic> json) =>
    _HangingCategory(
      category: json['category'] as String,
      label: json['label'] as String,
      severity: json['severity'] as String,
      count: (json['count'] as num).toInt(),
      route: json['route'] as String?,
      visits:
          (json['visits'] as List<dynamic>?)
              ?.map((e) => HangingVisitRow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <HangingVisitRow>[],
    );

Map<String, dynamic> _$HangingCategoryToJson(_HangingCategory instance) =>
    <String, dynamic>{
      'category': instance.category,
      'label': instance.label,
      'severity': instance.severity,
      'count': instance.count,
      'route': instance.route,
      'visits': instance.visits.map((e) => e.toJson()).toList(),
    };
