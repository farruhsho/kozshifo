// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debtor_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DebtorRow _$DebtorRowFromJson(Map<String, dynamic> json) => _DebtorRow(
  patientId: json['patient_id'] as String,
  patientName: json['patient_name'] as String,
  phone: json['phone'] as String?,
  patientNo: json['patient_no'] as String?,
  totalDebt: json['total_debt'] as String,
  visitCount: (json['visit_count'] as num).toInt(),
  oldestDebtAt: json['oldest_debt_at'] as String,
  lastPaymentAt: json['last_payment_at'] as String?,
);

Map<String, dynamic> _$DebtorRowToJson(_DebtorRow instance) =>
    <String, dynamic>{
      'patient_id': instance.patientId,
      'patient_name': instance.patientName,
      'phone': instance.phone,
      'patient_no': instance.patientNo,
      'total_debt': instance.totalDebt,
      'visit_count': instance.visitCount,
      'oldest_debt_at': instance.oldestDebtAt,
      'last_payment_at': instance.lastPaymentAt,
    };
