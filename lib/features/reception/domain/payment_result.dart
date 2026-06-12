import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_result.freezed.dart';
part 'payment_result.g.dart';

/// Receipt + resulting visit state + queue ticket (mirrors `PaymentResult`).
@freezed
abstract class PaymentResult with _$PaymentResult {
  const factory PaymentResult({
    required ReceptionPayment payment,
    required String visitStatus,
    required String visitBalance,
    String? queueTicketNumber,
  }) = _PaymentResult;

  factory PaymentResult.fromJson(Map<String, dynamic> json) =>
      _$PaymentResultFromJson(json);
}

@freezed
abstract class ReceptionPayment with _$ReceptionPayment {
  const factory ReceptionPayment({
    required String id,
    required String receiptNo,
    required String amount,
    required String method,
    required String createdAt,
  }) = _ReceptionPayment;

  factory ReceptionPayment.fromJson(Map<String, dynamic> json) =>
      _$ReceptionPaymentFromJson(json);
}
