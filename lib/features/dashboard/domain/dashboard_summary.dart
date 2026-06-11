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
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}
