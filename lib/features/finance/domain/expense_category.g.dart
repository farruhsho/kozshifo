// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseCategory _$ExpenseCategoryFromJson(Map<String, dynamic> json) =>
    _ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      isSystem: json['is_system'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ExpenseCategoryToJson(_ExpenseCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_active': instance.isActive,
      'is_system': instance.isSystem,
      'sort_order': instance.sortOrder,
    };

_RecurringExpense _$RecurringExpenseFromJson(Map<String, dynamic> json) =>
    _RecurringExpense(
      id: json['id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      amount: json['amount'] as String?,
      isFixed: json['is_fixed'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      posted: json['posted'] as bool? ?? false,
      postedAmount: json['posted_amount'] as String?,
    );

Map<String, dynamic> _$RecurringExpenseToJson(_RecurringExpense instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'name': instance.name,
      'amount': instance.amount,
      'is_fixed': instance.isFixed,
      'is_active': instance.isActive,
      'posted': instance.posted,
      'posted_amount': instance.postedAmount,
    };
