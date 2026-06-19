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
      operationsToday: (json['operations_today'] as num?)?.toInt() ?? 0,
      operationsMonth: (json['operations_month'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['low_stock_count'] as num?)?.toInt() ?? 0,
      expiringSoonCount: (json['expiring_soon_count'] as num?)?.toInt() ?? 0,
      expensesToday: json['expenses_today'] as String? ?? '0.00',
      expensesMonth: json['expenses_month'] as String? ?? '0.00',
      profitToday: json['profit_today'] as String? ?? '0.00',
      profitMonth: json['profit_month'] as String? ?? '0.00',
      newPatientsWeek: (json['new_patients_week'] as num?)?.toInt() ?? 0,
      newPatientsMonth: (json['new_patients_month'] as num?)?.toInt() ?? 0,
      returningToday: (json['returning_today'] as num?)?.toInt() ?? 0,
      operationsScheduledToday:
          (json['operations_scheduled_today'] as num?)?.toInt() ?? 0,
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
      'operations_today': instance.operationsToday,
      'operations_month': instance.operationsMonth,
      'low_stock_count': instance.lowStockCount,
      'expiring_soon_count': instance.expiringSoonCount,
      'expenses_today': instance.expensesToday,
      'expenses_month': instance.expensesMonth,
      'profit_today': instance.profitToday,
      'profit_month': instance.profitMonth,
      'new_patients_week': instance.newPatientsWeek,
      'new_patients_month': instance.newPatientsMonth,
      'returning_today': instance.returningToday,
      'operations_scheduled_today': instance.operationsScheduledToday,
    };
