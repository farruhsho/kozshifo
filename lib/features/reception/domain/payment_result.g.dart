// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentResult _$PaymentResultFromJson(Map<String, dynamic> json) =>
    _PaymentResult(
      payment: ReceptionPayment.fromJson(
        json['payment'] as Map<String, dynamic>,
      ),
      visitStatus: json['visit_status'] as String,
      visitBalance: json['visit_balance'] as String,
      queueTicketNumber: json['queue_ticket_number'] as String?,
    );

Map<String, dynamic> _$PaymentResultToJson(_PaymentResult instance) =>
    <String, dynamic>{
      'payment': instance.payment.toJson(),
      'visit_status': instance.visitStatus,
      'visit_balance': instance.visitBalance,
      'queue_ticket_number': instance.queueTicketNumber,
    };

_ReceptionPayment _$ReceptionPaymentFromJson(Map<String, dynamic> json) =>
    _ReceptionPayment(
      id: json['id'] as String,
      receiptNo: json['receipt_no'] as String,
      amount: json['amount'] as String,
      method: json['method'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$ReceptionPaymentToJson(_ReceptionPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receipt_no': instance.receiptNo,
      'amount': instance.amount,
      'method': instance.method,
      'created_at': instance.createdAt,
    };
