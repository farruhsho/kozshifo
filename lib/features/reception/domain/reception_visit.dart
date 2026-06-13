import 'package:freezed_annotation/freezed_annotation.dart';

part 'reception_visit.freezed.dart';
part 'reception_visit.g.dart';

/// Visit as the reception sees it after opening (mirrors `VisitOut`).
@freezed
abstract class ReceptionVisit with _$ReceptionVisit {
  const factory ReceptionVisit({
    required String id,
    required String visitNo,
    String? patientId,
    required String status,
    @Default('registered') String flowStatus,
    required String totalAmount,
    required String paidAmount,
    required String balance,
    // Reception discount (TZ Modul 2.2): percent XOR amount + reason.
    // `payable` (total - discount) is the cashier's due figure, not totalAmount.
    String? discountPercent,
    String? discountAmount,
    String? discountReason,
    String? discountValue,
    String? payable,
    @Default(<ReceptionVisitItem>[]) List<ReceptionVisitItem> items,
  }) = _ReceptionVisit;

  factory ReceptionVisit.fromJson(Map<String, dynamic> json) =>
      _$ReceptionVisitFromJson(json);
}

@freezed
abstract class ReceptionVisitItem with _$ReceptionVisitItem {
  const factory ReceptionVisitItem({
    required String id,
    required String serviceName,
    required String unitPrice,
    required int quantity,
    required String total,
    required String status,
  }) = _ReceptionVisitItem;

  factory ReceptionVisitItem.fromJson(Map<String, dynamic> json) =>
      _$ReceptionVisitItemFromJson(json);
}
