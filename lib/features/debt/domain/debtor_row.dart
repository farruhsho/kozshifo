import 'package:freezed_annotation/freezed_annotation.dart';

part 'debtor_row.freezed.dart';
part 'debtor_row.g.dart';

/// One row of the debtors list (mirrors backend `DebtorRow`), highest debt
/// first. Money is a decimal string on the wire; dates are ISO-8601 strings.
@freezed
abstract class DebtorRow with _$DebtorRow {
  const factory DebtorRow({
    required String patientId,
    required String patientName,
    String? phone,
    String? patientNo,
    required String totalDebt, // decimal string, e.g. "150000.00"
    required int visitCount,
    required String oldestDebtAt, // ISO datetime
    String? lastPaymentAt, // ISO datetime | null
  }) = _DebtorRow;

  factory DebtorRow.fromJson(Map<String, dynamic> json) =>
      _$DebtorRowFromJson(json);
}
