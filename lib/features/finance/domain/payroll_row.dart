import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_row.freezed.dart';
part 'payroll_row.g.dart';

/// One employee's percent-payroll line for a month (mirrors backend `PayrollRow`).
/// salary = revenue × salaryPercent / 100, already computed server-side.
@freezed
abstract class PayrollRow with _$PayrollRow {
  const factory PayrollRow({
    required String userId,
    required String fullName,
    required String salaryPercent,
    required String revenue,
    required String salary,
    required bool paid,
    String? paidAt,
  }) = _PayrollRow;

  factory PayrollRow.fromJson(Map<String, dynamic> json) =>
      _$PayrollRowFromJson(json);
}
