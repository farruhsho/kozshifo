// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PayrollDetail _$PayrollDetailFromJson(Map<String, dynamic> json) =>
    _PayrollDetail(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      month: json['month'] as String,
      consultSalaryType: json['consult_salary_type'] as String?,
      consultSalaryValue: json['consult_salary_value'] as String?,
      operationSalaryType: json['operation_salary_type'] as String?,
      operationSalaryValue: json['operation_salary_value'] as String?,
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => PayrollDetailDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PayrollDetailDay>[],
      operations:
          (json['operations'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PayrollDetailOperation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <PayrollDetailOperation>[],
      consultRevenue: json['consult_revenue'] as String,
      consultPay: json['consult_pay'] as String,
      operationRevenue: json['operation_revenue'] as String,
      operationCount: (json['operation_count'] as num).toInt(),
      operationPay: json['operation_pay'] as String,
      salary: json['salary'] as String,
    );

Map<String, dynamic> _$PayrollDetailToJson(_PayrollDetail instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'full_name': instance.fullName,
      'month': instance.month,
      'consult_salary_type': instance.consultSalaryType,
      'consult_salary_value': instance.consultSalaryValue,
      'operation_salary_type': instance.operationSalaryType,
      'operation_salary_value': instance.operationSalaryValue,
      'days': instance.days.map((e) => e.toJson()).toList(),
      'operations': instance.operations.map((e) => e.toJson()).toList(),
      'consult_revenue': instance.consultRevenue,
      'consult_pay': instance.consultPay,
      'operation_revenue': instance.operationRevenue,
      'operation_count': instance.operationCount,
      'operation_pay': instance.operationPay,
      'salary': instance.salary,
    };

_PayrollDetailDay _$PayrollDetailDayFromJson(Map<String, dynamic> json) =>
    _PayrollDetailDay(
      date: json['date'] as String,
      patients:
          (json['patients'] as List<dynamic>?)
              ?.map(
                (e) => PayrollDetailPatient.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <PayrollDetailPatient>[],
      revenue: json['revenue'] as String,
      share: json['share'] as String,
    );

Map<String, dynamic> _$PayrollDetailDayToJson(_PayrollDetailDay instance) =>
    <String, dynamic>{
      'date': instance.date,
      'patients': instance.patients.map((e) => e.toJson()).toList(),
      'revenue': instance.revenue,
      'share': instance.share,
    };

_PayrollDetailPatient _$PayrollDetailPatientFromJson(
  Map<String, dynamic> json,
) => _PayrollDetailPatient(
  visitId: json['visit_id'] as String,
  patientName: json['patient_name'] as String,
  amount: json['amount'] as String,
  share: json['share'] as String,
);

Map<String, dynamic> _$PayrollDetailPatientToJson(
  _PayrollDetailPatient instance,
) => <String, dynamic>{
  'visit_id': instance.visitId,
  'patient_name': instance.patientName,
  'amount': instance.amount,
  'share': instance.share,
};

_PayrollDetailOperation _$PayrollDetailOperationFromJson(
  Map<String, dynamic> json,
) => _PayrollDetailOperation(
  date: json['date'] as String,
  patientName: json['patient_name'] as String,
  typeName: json['type_name'] as String,
  price: json['price'] as String,
  share: json['share'] as String,
);

Map<String, dynamic> _$PayrollDetailOperationToJson(
  _PayrollDetailOperation instance,
) => <String, dynamic>{
  'date': instance.date,
  'patient_name': instance.patientName,
  'type_name': instance.typeName,
  'price': instance.price,
  'share': instance.share,
};
