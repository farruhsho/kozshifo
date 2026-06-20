// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PayrollRow _$PayrollRowFromJson(Map<String, dynamic> json) => _PayrollRow(
  userId: json['user_id'] as String,
  fullName: json['full_name'] as String,
  consultSalaryType: json['consult_salary_type'] as String?,
  consultSalaryValue: json['consult_salary_value'] as String?,
  consultRevenue: json['consult_revenue'] as String,
  consultPay: json['consult_pay'] as String,
  operationSalaryType: json['operation_salary_type'] as String?,
  operationSalaryValue: json['operation_salary_value'] as String?,
  operationRevenue: json['operation_revenue'] as String,
  operationCount: (json['operation_count'] as num).toInt(),
  operationPay: json['operation_pay'] as String,
  salary: json['salary'] as String,
  paid: json['paid'] as bool,
  paidAt: json['paid_at'] as String?,
  paidAmount: json['paid_amount'] as String?,
);

Map<String, dynamic> _$PayrollRowToJson(_PayrollRow instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'full_name': instance.fullName,
      'consult_salary_type': instance.consultSalaryType,
      'consult_salary_value': instance.consultSalaryValue,
      'consult_revenue': instance.consultRevenue,
      'consult_pay': instance.consultPay,
      'operation_salary_type': instance.operationSalaryType,
      'operation_salary_value': instance.operationSalaryValue,
      'operation_revenue': instance.operationRevenue,
      'operation_count': instance.operationCount,
      'operation_pay': instance.operationPay,
      'salary': instance.salary,
      'paid': instance.paid,
      'paid_at': instance.paidAt,
      'paid_amount': instance.paidAmount,
    };
