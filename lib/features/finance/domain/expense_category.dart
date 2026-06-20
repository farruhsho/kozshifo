import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_category.freezed.dart';
part 'expense_category.g.dart';

/// Admin-managed expense type — rasxod turi (mirrors backend `ExpenseCategoryOut`).
@freezed
abstract class ExpenseCategory with _$ExpenseCategory {
  const factory ExpenseCategory({
    required String id,
    required String name,
    @Default(true) bool isActive,
    @Default(false) bool isSystem,
    @Default(0) int sortOrder,
  }) = _ExpenseCategory;

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) =>
      _$ExpenseCategoryFromJson(json);
}

/// Recurring (monthly) expense template + per-month posted state (mirrors
/// backend `RecurringExpenseStatus`).
@freezed
abstract class RecurringExpense with _$RecurringExpense {
  const factory RecurringExpense({
    required String id,
    required String category,
    required String name,
    String? amount,
    @Default(true) bool isFixed,
    @Default(true) bool isActive,
    @Default(false) bool posted,
    String? postedAmount,
  }) = _RecurringExpense;

  factory RecurringExpense.fromJson(Map<String, dynamic> json) =>
      _$RecurringExpenseFromJson(json);
}
