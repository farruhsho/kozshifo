// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_debt_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DebtVisitRow _$DebtVisitRowFromJson(Map<String, dynamic> json) =>
    _DebtVisitRow(
      visitId: json['visit_id'] as String,
      visitNo: json['visit_no'] as String,
      openedAt: json['opened_at'] as String,
      payable: json['payable'] as String,
      paid: json['paid'] as String,
      remaining: json['remaining'] as String,
      services: json['services'] as String,
      flowStatus: json['flow_status'] as String,
    );

Map<String, dynamic> _$DebtVisitRowToJson(_DebtVisitRow instance) =>
    <String, dynamic>{
      'visit_id': instance.visitId,
      'visit_no': instance.visitNo,
      'opened_at': instance.openedAt,
      'payable': instance.payable,
      'paid': instance.paid,
      'remaining': instance.remaining,
      'services': instance.services,
      'flow_status': instance.flowStatus,
    };

_DebtPaymentRow _$DebtPaymentRowFromJson(Map<String, dynamic> json) =>
    _DebtPaymentRow(
      paidAt: json['paid_at'] as String,
      amount: json['amount'] as String,
      method: json['method'] as String,
      cashierName: json['cashier_name'] as String?,
      note: json['note'] as String?,
      visitNo: json['visit_no'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$DebtPaymentRowToJson(_DebtPaymentRow instance) =>
    <String, dynamic>{
      'paid_at': instance.paidAt,
      'amount': instance.amount,
      'method': instance.method,
      'cashier_name': instance.cashierName,
      'note': instance.note,
      'visit_no': instance.visitNo,
      'status': instance.status,
    };

_PatientDebtDetail _$PatientDebtDetailFromJson(Map<String, dynamic> json) =>
    _PatientDebtDetail(
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String,
      phone: json['phone'] as String?,
      totalDebt: json['total_debt'] as String,
      visits: (json['visits'] as List<dynamic>)
          .map((e) => DebtVisitRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List<dynamic>)
          .map((e) => DebtPaymentRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PatientDebtDetailToJson(_PatientDebtDetail instance) =>
    <String, dynamic>{
      'patient_id': instance.patientId,
      'patient_name': instance.patientName,
      'phone': instance.phone,
      'total_debt': instance.totalDebt,
      'visits': instance.visits.map((e) => e.toJson()).toList(),
      'payments': instance.payments.map((e) => e.toJson()).toList(),
    };
