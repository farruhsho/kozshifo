// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) =>
    _DashboardSummary(
      revenueToday: json['revenue_today'] as String,
      revenueMonth: json['revenue_month'] as String,
      paymentsToday: (json['payments_today'] as num).toInt(),
      averageCheckToday: json['average_check_today'] as String,
      visitsToday: (json['visits_today'] as num).toInt(),
      newPatientsToday: (json['new_patients_today'] as num).toInt(),
      patientsTotal: (json['patients_total'] as num).toInt(),
      queueWaiting: (json['queue_waiting'] as num).toInt(),
    );

Map<String, dynamic> _$DashboardSummaryToJson(_DashboardSummary instance) =>
    <String, dynamic>{
      'revenue_today': instance.revenueToday,
      'revenue_month': instance.revenueMonth,
      'payments_today': instance.paymentsToday,
      'average_check_today': instance.averageCheckToday,
      'visits_today': instance.visitsToday,
      'new_patients_today': instance.newPatientsToday,
      'patients_total': instance.patientsTotal,
      'queue_waiting': instance.queueWaiting,
    };
