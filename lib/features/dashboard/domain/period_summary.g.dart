// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PeriodSummary _$PeriodSummaryFromJson(Map<String, dynamic> json) =>
    _PeriodSummary(
      period: json['period'] as String,
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      revenue: json['revenue'] as String,
      expenses: json['expenses'] as String,
      profit: json['profit'] as String,
      newPatients: (json['new_patients'] as num).toInt(),
      visits: (json['visits'] as num).toInt(),
      operations: (json['operations'] as num).toInt(),
      diagnostics: (json['diagnostics'] as num).toInt(),
      treatments: (json['treatments'] as num).toInt(),
    );

Map<String, dynamic> _$PeriodSummaryToJson(_PeriodSummary instance) =>
    <String, dynamic>{
      'period': instance.period,
      'date_from': instance.dateFrom,
      'date_to': instance.dateTo,
      'revenue': instance.revenue,
      'expenses': instance.expenses,
      'profit': instance.profit,
      'new_patients': instance.newPatients,
      'visits': instance.visits,
      'operations': instance.operations,
      'diagnostics': instance.diagnostics,
      'treatments': instance.treatments,
    };
