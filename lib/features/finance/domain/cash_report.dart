import 'package:freezed_annotation/freezed_annotation.dart';

part 'cash_report.freezed.dart';
part 'cash_report.g.dart';

/// Cash-flow aggregate for a day (mirrors backend `DailyReport`).
/// `incomeByMethod` always carries cash / card / qr / transfer, zero-filled.
/// net = incomeTotal - refundTotal - expenseTotal.
@freezed
abstract class DailyReport with _$DailyReport {
  const factory DailyReport({
    required String date, // YYYY-MM-DD
    required Map<String, String> incomeByMethod,
    required String incomeTotal,
    required String refundTotal,
    required String expenseTotal,
    required String net,
  }) = _DailyReport;

  factory DailyReport.fromJson(Map<String, dynamic> json) =>
      _$DailyReportFromJson(json);
}

/// Cash-flow aggregate for a month (mirrors backend `MonthlyReport`).
@freezed
abstract class MonthlyReport with _$MonthlyReport {
  const factory MonthlyReport({
    required String month, // YYYY-MM
    required Map<String, String> incomeByMethod,
    required String incomeTotal,
    required String refundTotal,
    required String expenseTotal,
    required String net,
    required String payrollTotal,
  }) = _MonthlyReport;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) =>
      _$MonthlyReportFromJson(json);
}
