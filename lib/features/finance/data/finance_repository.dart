import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/cash_report.dart';
import '../domain/expense.dart';
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
    String? note,
  }) async {
    try {
      final resp = await _dio.post('/finance/expenses', data: {
        'category': category,
        'amount': amount,
        'expense_date': expenseDate,
        if (note != null && note.isNotEmpty) 'note': note,
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
