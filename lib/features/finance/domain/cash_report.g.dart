// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyReport _$DailyReportFromJson(Map<String, dynamic> json) => _DailyReport(
  date: json['date'] as String,
  incomeByMethod: Map<String, String>.from(json['income_by_method'] as Map),
  incomeTotal: json['income_total'] as String,
  refundTotal: json['refund_total'] as String,
  expenseTotal: json['expense_total'] as String,
  net: json['net'] as String,
);

Map<String, dynamic> _$DailyReportToJson(_DailyReport instance) =>
    <String, dynamic>{
      'date': instance.date,
      'income_by_method': instance.incomeByMethod,
      'income_total': instance.incomeTotal,
      'refund_total': instance.refundTotal,
      'expense_total': instance.expenseTotal,
      'net': instance.net,
    };

_MonthlyReport _$MonthlyReportFromJson(Map<String, dynamic> json) =>
    _MonthlyReport(
      month: json['month'] as String,
      incomeByMethod: Map<String, String>.from(json['income_by_method'] as Map),
      incomeTotal: json['income_total'] as String,
      refundTotal: json['refund_total'] as String,
      expenseTotal: json['expense_total'] as String,
      net: json['net'] as String,
      payrollTotal: json['payroll_total'] as String,
    );

Map<String, dynamic> _$MonthlyReportToJson(_MonthlyReport instance) =>
    <String, dynamic>{
      'month': instance.month,
      'income_by_method': instance.incomeByMethod,
      'income_total': instance.incomeTotal,
      'refund_total': instance.refundTotal,
      'expense_total': instance.expenseTotal,
      'net': instance.net,
      'payroll_total': instance.payrollTotal,
    };
