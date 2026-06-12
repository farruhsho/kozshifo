// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PayrollRow _$PayrollRowFromJson(Map<String, dynamic> json) => _PayrollRow(
  userId: json['user_id'] as String,
  fullName: json['full_name'] as String,
  salaryPercent: json['salary_percent'] as String,
  revenue: json['revenue'] as String,
  salary: json['salary'] as String,
  paid: json['paid'] as bool,
  paidAt: json['paid_at'] as String?,
);

Map<String, dynamic> _$PayrollRowToJson(_PayrollRow instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'full_name': instance.fullName,
      'salary_percent': instance.salaryPercent,
      'revenue': instance.revenue,
      'salary': instance.salary,
      'paid': instance.paid,
      'paid_at': instance.paidAt,
    };
