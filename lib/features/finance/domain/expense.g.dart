// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  id: json['id'] as String,
  branchId: json['branch_id'] as String,
  category: json['category'] as String,
  name: json['name'] as String?,
  amount: json['amount'] as String,
  expenseDate: json['expense_date'] as String,
  note: json['note'] as String?,
  kind: json['kind'] as String? ?? 'regular',
  payrollUserId: json['payroll_user_id'] as String?,
  payrollMonth: json['payroll_month'] as String?,
  createdByName: json['created_by_name'] as String?,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'id': instance.id,
  'branch_id': instance.branchId,
  'category': instance.category,
  'name': instance.name,
  'amount': instance.amount,
  'expense_date': instance.expenseDate,
  'note': instance.note,
  'kind': instance.kind,
  'payroll_user_id': instance.payrollUserId,
  'payroll_month': instance.payrollMonth,
  'created_by_name': instance.createdByName,
  'created_at': instance.createdAt,
};
