import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

/// One clinic outflow — rashod (mirrors backend `ExpenseOut`).
/// Payroll payouts are expenses too (`kind == "payroll"`) and cannot be deleted.
@freezed
abstract class Expense with _$Expense {
  const Expense._();

  const factory Expense({
    required String id,
    required String branchId,
    required String category,
    required String amount,
    required String expenseDate, // YYYY-MM-DD
    String? note,
    @Default('regular') String kind, // regular | payroll
    String? payrollUserId,
    String? payrollMonth, // YYYY-MM
    String? createdByName,
    String? createdAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

  bool get isPayroll => kind == 'payroll';
}
