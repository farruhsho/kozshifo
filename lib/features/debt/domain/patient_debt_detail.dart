import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient_debt_detail.freezed.dart';
part 'patient_debt_detail.g.dart';

/// One owing visit inside a patient's debt detail (mirrors backend visit row).
/// Money fields are decimal strings; `services` is the «причина» (what's owed
/// for). `remaining` = payable − paid.
@freezed
abstract class DebtVisitRow with _$DebtVisitRow {
  const factory DebtVisitRow({
    required String visitId,
    required String visitNo,
    required String openedAt, // ISO datetime
    required String payable, // decimal string
    required String paid, // decimal string
    required String remaining, // decimal string
    required String services,
    required String flowStatus,
  }) = _DebtVisitRow;

  factory DebtVisitRow.fromJson(Map<String, dynamic> json) =>
      _$DebtVisitRowFromJson(json);
}

/// One payment in the patient's repayment history (mirrors backend payment row).
@freezed
abstract class DebtPaymentRow with _$DebtPaymentRow {
  const factory DebtPaymentRow({
    required String paidAt, // ISO datetime
    required String amount, // decimal string
    required String method, // cash | card | qr | transfer
    String? cashierName,
    String? note,
    required String visitNo,
    required String status, // completed | refunded
  }) = _DebtPaymentRow;

  factory DebtPaymentRow.fromJson(Map<String, dynamic> json) =>
      _$DebtPaymentRowFromJson(json);
}

/// Full per-patient debt picture (mirrors backend `PatientDebtDetail`):
/// header total + the owing visits + the repayment history.
@freezed
abstract class PatientDebtDetail with _$PatientDebtDetail {
  const factory PatientDebtDetail({
    required String patientId,
    required String patientName,
    String? phone,
    required String totalDebt, // decimal string
    required List<DebtVisitRow> visits,
    required List<DebtPaymentRow> payments,
  }) = _PatientDebtDetail;

  factory PatientDebtDetail.fromJson(Map<String, dynamic> json) =>
      _$PatientDebtDetailFromJson(json);
}
