// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_visit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReceptionVisit _$ReceptionVisitFromJson(Map<String, dynamic> json) =>
    _ReceptionVisit(
      id: json['id'] as String,
      visitNo: json['visit_no'] as String,
      patientId: json['patient_id'] as String?,
      status: json['status'] as String,
      flowStatus: json['flow_status'] as String? ?? 'registered',
      totalAmount: json['total_amount'] as String,
      paidAmount: json['paid_amount'] as String,
      balance: json['balance'] as String,
      discountPercent: json['discount_percent'] as String?,
      discountAmount: json['discount_amount'] as String?,
      discountReason: json['discount_reason'] as String?,
      discountValue: json['discount_value'] as String?,
      payable: json['payable'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => ReceptionVisitItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ReceptionVisitItem>[],
    );

Map<String, dynamic> _$ReceptionVisitToJson(_ReceptionVisit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visit_no': instance.visitNo,
      'patient_id': instance.patientId,
      'status': instance.status,
      'flow_status': instance.flowStatus,
      'total_amount': instance.totalAmount,
      'paid_amount': instance.paidAmount,
      'balance': instance.balance,
      'discount_percent': instance.discountPercent,
      'discount_amount': instance.discountAmount,
      'discount_reason': instance.discountReason,
      'discount_value': instance.discountValue,
      'payable': instance.payable,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_ReceptionVisitItem _$ReceptionVisitItemFromJson(Map<String, dynamic> json) =>
    _ReceptionVisitItem(
      id: json['id'] as String,
      serviceName: json['service_name'] as String,
      unitPrice: json['unit_price'] as String,
      quantity: (json['quantity'] as num).toInt(),
      total: json['total'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$ReceptionVisitItemToJson(_ReceptionVisitItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service_name': instance.serviceName,
      'unit_price': instance.unitPrice,
      'quantity': instance.quantity,
      'total': instance.total,
      'status': instance.status,
    };
