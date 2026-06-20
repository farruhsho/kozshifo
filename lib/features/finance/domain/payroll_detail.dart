import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_detail.freezed.dart';
part 'payroll_detail.g.dart';

/// Per-day / per-patient salary detalizatsiya for one doctor and month
/// (mirrors backend `PayrollDetail`). Powers the printable detail screen.
@freezed
abstract class PayrollDetail with _$PayrollDetail {
  const factory PayrollDetail({
    required String userId,
    required String fullName,
    required String month,
    String? consultSalaryType,
    String? consultSalaryValue,
    String? operationSalaryType,
    String? operationSalaryValue,
    @Default(<PayrollDetailDay>[]) List<PayrollDetailDay> days,
    @Default(<PayrollDetailOperation>[]) List<PayrollDetailOperation> operations,
    required String consultRevenue,
    required String consultPay,
    required String operationRevenue,
    required int operationCount,
    required String operationPay,
    required String salary,
  }) = _PayrollDetail;

  factory PayrollDetail.fromJson(Map<String, dynamic> json) =>
      _$PayrollDetailFromJson(json);
}

@freezed
abstract class PayrollDetailDay with _$PayrollDetailDay {
  const factory PayrollDetailDay({
    required String date, // YYYY-MM-DD
    @Default(<PayrollDetailPatient>[]) List<PayrollDetailPatient> patients,
    required String revenue,
    required String share,
  }) = _PayrollDetailDay;

  factory PayrollDetailDay.fromJson(Map<String, dynamic> json) =>
      _$PayrollDetailDayFromJson(json);
}

@freezed
abstract class PayrollDetailPatient with _$PayrollDetailPatient {
  const factory PayrollDetailPatient({
    required String visitId,
    required String patientName,
    required String amount,
    required String share,
  }) = _PayrollDetailPatient;

  factory PayrollDetailPatient.fromJson(Map<String, dynamic> json) =>
      _$PayrollDetailPatientFromJson(json);
}

@freezed
abstract class PayrollDetailOperation with _$PayrollDetailOperation {
  const factory PayrollDetailOperation({
    required String date,
    required String patientName,
    required String typeName,
    required String price,
    required String share,
  }) = _PayrollDetailOperation;

  factory PayrollDetailOperation.fromJson(Map<String, dynamic> json) =>
      _$PayrollDetailOperationFromJson(json);
}
