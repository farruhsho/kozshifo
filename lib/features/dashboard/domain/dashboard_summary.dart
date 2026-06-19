import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary.freezed.dart';
part 'dashboard_summary.g.dart';

/// Director KPI snapshot (mirrors `GET /dashboard/summary`).
/// Money fields arrive as decimal strings from the backend.
@freezed
abstract class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required String revenueToday,
    required String revenueMonth,
    required int paymentsToday,
    required String averageCheckToday,
    required int visitsToday,
    required int newPatientsToday,
    required int patientsTotal,
    required int queueWaiting,
    @Default(0) int operationsToday,
    @Default(0) int operationsMonth,
    @Default(0) int lowStockCount,
    @Default(0) int expiringSoonCount,
    // Expanded KPIs (all defaulted so older fixtures/payloads still parse).
    @Default('0.00') String expensesToday,
    @Default('0.00') String expensesMonth,
    @Default('0.00') String profitToday,
    @Default('0.00') String profitMonth,
    @Default(0) int newPatientsWeek,
    @Default(0) int newPatientsMonth,
    @Default(0) int returningToday,
    @Default(0) int operationsScheduledToday,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}
