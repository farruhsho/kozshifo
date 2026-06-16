// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VisitSummary _$VisitSummaryFromJson(Map<String, dynamic> json) =>
    _VisitSummary(
      id: json['id'] as String,
      visitNo: json['visit_no'] as String,
      status: json['status'] as String,
      flowStatus: json['flow_status'] as String? ?? 'registered',
      openedAt: json['opened_at'] as String,
      branchId: json['branch_id'] as String?,
      visitType: json['visit_type'] as String? ?? 'consultation',
      closedAt: json['closed_at'] as String?,
      totalAmount: json['total_amount'] as String? ?? '0',
      paidAmount: json['paid_amount'] as String? ?? '0',
      discountValue: json['discount_value'] as String? ?? '0',
      payable: json['payable'] as String? ?? '0',
      balance: json['balance'] as String? ?? '0',
      discountReason: json['discount_reason'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => VisitItemSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <VisitItemSummary>[],
    );

Map<String, dynamic> _$VisitSummaryToJson(_VisitSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visit_no': instance.visitNo,
      'status': instance.status,
      'flow_status': instance.flowStatus,
      'opened_at': instance.openedAt,
      'branch_id': instance.branchId,
      'visit_type': instance.visitType,
      'closed_at': instance.closedAt,
      'total_amount': instance.totalAmount,
      'paid_amount': instance.paidAmount,
      'discount_value': instance.discountValue,
      'payable': instance.payable,
      'balance': instance.balance,
      'discount_reason': instance.discountReason,
      'priority': instance.priority,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_VisitItemSummary _$VisitItemSummaryFromJson(Map<String, dynamic> json) =>
    _VisitItemSummary(
      serviceName: json['service_name'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      total: json['total'] as String? ?? '0',
    );

Map<String, dynamic> _$VisitItemSummaryToJson(_VisitItemSummary instance) =>
    <String, dynamic>{
      'service_name': instance.serviceName,
      'quantity': instance.quantity,
      'total': instance.total,
    };
