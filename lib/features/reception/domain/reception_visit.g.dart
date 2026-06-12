// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_visit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReceptionVisit _$ReceptionVisitFromJson(Map<String, dynamic> json) =>
    _ReceptionVisit(
      id: json['id'] as String,
      visitNo: json['visit_no'] as String,
      status: json['status'] as String,
      totalAmount: json['total_amount'] as String,
      paidAmount: json['paid_amount'] as String,
      balance: json['balance'] as String,
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
      'status': instance.status,
      'total_amount': instance.totalAmount,
      'paid_amount': instance.paidAmount,
      'balance': instance.balance,
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
