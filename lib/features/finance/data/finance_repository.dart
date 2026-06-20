import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/cash_report.dart';
import '../domain/expense.dart';
import '../domain/expense_category.dart';
import '../domain/payroll_detail.dart';
import '../domain/payroll_row.dart';

final financeRepositoryProvider = Provider<FinanceRepository>(
    (ref) => FinanceRepository(ref.watch(dioProvider)));

/// Default page size for the expense list (backend max is 200).
const kExpensePageSize = 50;

/// Backend `Page[ExpenseOut]` envelope; the alias keeps UI files free of the
/// `Page` name clash with Flutter's navigator `Page`.
typedef ExpensePage = Page<Expense>;

/// Expense list filter — a record so the provider family gets value equality.
typedef ExpenseQuery = ({
  String? dateFrom, // YYYY-MM-DD
  String? dateTo, // YYYY-MM-DD
  String? category,
  int offset,
});

class FinanceRepository {
  FinanceRepository(this._dio);

  final Dio _dio;

  // ─── Cash reports ──────────────────────────────────────────────────────────

  Future<DailyReport> dailyReport(String d) async {
    try {
      final resp = await _dio
          .get('/finance/reports/daily', queryParameters: {'d': d});
      return DailyReport.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<MonthlyReport> monthlyReport(String month) async {
    try {
      final resp = await _dio
          .get('/finance/reports/monthly', queryParameters: {'month': month});
      return MonthlyReport.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ─── Expenses ──────────────────────────────────────────────────────────────

  Future<ExpensePage> expenses({
    String? dateFrom,
    String? dateTo,
    String? category,
    int offset = 0,
    int limit = kExpensePageSize,
  }) async {
    try {
      final resp = await _dio.get('/finance/expenses', queryParameters: {
        'date_from': ?dateFrom,
        'date_to': ?dateTo,
        if (category != null && category.isNotEmpty) 'category': category,
        'offset': offset,
        'limit': limit,
      });
      return Page.fromJson(resp.data as Map<String, dynamic>, Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Expense> createExpense({
    required String category,
    required String amount, // decimal string, e.g. "12345.00"
    required String expenseDate, // YYYY-MM-DD
    String? name,
    String? note,
  }) async {
    try {
      final resp = await _dio.post('/finance/expenses', data: {
        'category': category,
        if (name != null && name.isNotEmpty) 'name': name,
        'amount': amount,
        'expense_date': expenseDate,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      return Expense.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ─── Expense types (rasxod turlari) ────────────────────────────────────────

  Future<List<ExpenseCategory>> expenseCategories({bool activeOnly = false}) async {
    try {
      final resp = await _dio.get('/finance/expense-categories',
          queryParameters: {if (activeOnly) 'active_only': true});
      return (resp.data as List<dynamic>)
          .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ExpenseCategory> createExpenseCategory(String name) async {
    try {
      final resp = await _dio
          .post('/finance/expense-categories', data: {'name': name});
      return ExpenseCategory.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ExpenseCategory> updateExpenseCategory(String id,
      {String? name, bool? isActive}) async {
    try {
      final resp = await _dio.patch('/finance/expense-categories/$id', data: {
        'name': ?name,
        'is_active': ?isActive,
      });
      return ExpenseCategory.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// 409 = system type (deactivate instead).
  Future<void> deleteExpenseCategory(String id) async {
    try {
      await _dio.delete('/finance/expense-categories/$id');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ─── Recurring (monthly) expenses ──────────────────────────────────────────

  Future<List<RecurringExpense>> recurringExpenses({String? month}) async {
    try {
      final resp = await _dio.get('/finance/recurring-expenses',
          queryParameters: {'month': ?month});
      return (resp.data as List<dynamic>)
          .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<RecurringExpense> createRecurringExpense({
    required String category,
    required String name,
    String? amount,
    required bool isFixed,
  }) async {
    try {
      final resp = await _dio.post('/finance/recurring-expenses', data: {
        'category': category,
        'name': name,
        if (amount != null && amount.isNotEmpty) 'amount': amount,
        'is_fixed': isFixed,
      });
      return RecurringExpense.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteRecurringExpense(String id) async {
    try {
      await _dio.delete('/finance/recurring-expenses/$id');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Books the template into an Expense for [month]. 409 = already posted.
  Future<Expense> postRecurringExpense(String id, String month,
      {String? amount}) async {
    try {
      final resp = await _dio.post('/finance/recurring-expenses/$id/post', data: {
        'month': month,
        if (amount != null && amount.isNotEmpty) 'amount': amount,
      });
      return Expense.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// 409 = payroll-kind expense (these are deleted only via payroll flows).
  Future<void> deleteExpense(String id) async {
    try {
      await _dio.delete('/finance/expenses/$id');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ─── Payroll ───────────────────────────────────────────────────────────────

  Future<List<PayrollRow>> payroll(String month) async {
    try {
      final resp =
          await _dio.get('/finance/payroll', queryParameters: {'month': month});
      return (resp.data as List<dynamic>)
          .map((e) => PayrollRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// 409 = already paid for this month; 400 = no percent / zero salary.
  Future<Expense> payoutSalary({
    required String userId,
    required String month,
  }) async {
    try {
      final resp = await _dio.post('/finance/payroll/payout', data: {
        'user_id': userId,
        'month': month,
      });
      return Expense.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<PayrollDetail> payrollDetail(String userId, String month) async {
    try {
      final resp = await _dio.get('/finance/payroll/$userId/detail',
          queryParameters: {'month': month});
      return PayrollDetail.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Uint8List> payrollDetailPdf(String userId, String month) =>
      _csv('/finance/payroll/$userId/detail.pdf', {'month': month});

  // ─── CSV exports (bytes → saveBytes) ───────────────────────────────────────

  Future<Uint8List> _csv(String path, Map<String, dynamic> query) async {
    try {
      final resp = await _dio.get(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data as List<int>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Uint8List> expensesCsv({
    String? dateFrom,
    String? dateTo,
    String? category,
  }) =>
      _csv('/finance/expenses.csv', {
        'date_from': ?dateFrom,
        'date_to': ?dateTo,
        if (category != null && category.isNotEmpty) 'category': category,
      });

  Future<Uint8List> payrollCsv(String month) =>
      _csv('/finance/payroll.csv', {'month': month});

  Future<Uint8List> dailyReportCsv(String d) =>
      _csv('/finance/reports/daily.csv', {'d': d});
}

// ─── Providers ────────────────────────────────────────────────────────────────

/// key = YYYY-MM-DD
final dailyReportProvider =
    FutureProvider.autoDispose.family<DailyReport, String>(
        (ref, d) => ref.watch(financeRepositoryProvider).dailyReport(d));

/// key = YYYY-MM
final monthlyReportProvider =
    FutureProvider.autoDispose.family<MonthlyReport, String>(
        (ref, m) => ref.watch(financeRepositoryProvider).monthlyReport(m));

final expensesProvider =
    FutureProvider.autoDispose.family<ExpensePage, ExpenseQuery>(
        (ref, q) => ref.watch(financeRepositoryProvider).expenses(
              dateFrom: q.dateFrom,
              dateTo: q.dateTo,
              category: q.category,
              offset: q.offset,
            ));

/// key = YYYY-MM
final payrollProvider = FutureProvider.autoDispose.family<List<PayrollRow>, String>(
    (ref, m) => ref.watch(financeRepositoryProvider).payroll(m));

/// Active expense types for the create/filter dropdowns.
final activeExpenseCategoriesProvider =
    FutureProvider.autoDispose<List<ExpenseCategory>>(
        (ref) => ref.watch(financeRepositoryProvider).expenseCategories(activeOnly: true));

/// All expense types (the management dialog).
final allExpenseCategoriesProvider =
    FutureProvider.autoDispose<List<ExpenseCategory>>(
        (ref) => ref.watch(financeRepositoryProvider).expenseCategories());

/// Recurring expenses with posted-state for a month. key = YYYY-MM
final recurringExpensesProvider =
    FutureProvider.autoDispose.family<List<RecurringExpense>, String>(
        (ref, m) => ref.watch(financeRepositoryProvider).recurringExpenses(month: m));

/// Salary detalizatsiya. key = (userId, month)
typedef PayrollDetailKey = ({String userId, String month});

final payrollDetailProvider =
    FutureProvider.autoDispose.family<PayrollDetail, PayrollDetailKey>(
        (ref, k) => ref.watch(financeRepositoryProvider).payrollDetail(k.userId, k.month));
