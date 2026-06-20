import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_row.freezed.dart';
part 'payroll_row.g.dart';

/// One employee's payroll line for a month (mirrors backend `PayrollRow`), with
/// the consult + operation breakdown. salary = consultPay + operationPay,
/// already computed server-side.
@freezed
abstract class PayrollRow with _$PayrollRow {
  const factory PayrollRow({
    required String userId,
    required String fullName,
    // Consultation side
    String? consultSalaryType, // percent | fixed | null
    String? consultSalaryValue,
    required String consultRevenue,
    required String consultPay,
    // Operation side (as surgeon)
    String? operationSalaryType,
    String? operationSalaryValue,
    required String operationRevenue,
    required int operationCount,
    required String operationPay,
    // Total + payout state
    required String salary,
    required bool paid,
    String? paidAt,
    String? paidAmount,
  }) = _PayrollRow;

  factory PayrollRow.fromJson(Map<String, dynamic> json) =>
      _$PayrollRowFromJson(json);
}
