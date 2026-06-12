// Finance: repository parsing against a mocked Dio adapter (no network)
// + widget smoke tests of the cash / expenses tabs with overridden providers.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kozshifo/core/network/api_exception.dart';
import 'package:kozshifo/core/utils/formatters.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/finance/data/finance_repository.dart';
import 'package:kozshifo/features/finance/domain/cash_report.dart';
import 'package:kozshifo/features/finance/domain/expense.dart';
import 'package:kozshifo/features/finance/presentation/cash_tab.dart';
import 'package:kozshifo/features/finance/presentation/expenses_tab.dart';
import 'package:kozshifo/features/finance/presentation/finance_screen.dart';

// ─── Mocked Dio adapter ───────────────────────────────────────────────────────

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    lastRequest = options;
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, {int status = 200}) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

(FinanceRepository, _FakeAdapter) _repo(
    ResponseBody Function(RequestOptions) handler) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;
  return (FinanceRepository(dio), adapter);
}

// ─── Canned payloads (snake_case, money as decimal strings) ───────────────────

const _dailyJson = <String, dynamic>{
  'date': '2026-06-12',
  'income_by_method': {
    'cash': '500000.00',
    'card': '250000.00',
    'qr': '0.00',
    'transfer': '100000.00',
  },
  'income_total': '850000.00',
  'refund_total': '50000.00',
  'expense_total': '120000.00',
  'net': '680000.00',
};

const _monthlyJson = <String, dynamic>{
  'month': '2026-06',
  'income_by_method': {
    'cash': '900000.00',
    'card': '300000.00',
    'qr': '10000.00',
    'transfer': '0.00',
  },
  'income_total': '1210000.00',
  'refund_total': '0.00',
  'expense_total': '700000.00',
  'net': '510000.00',
  'payroll_total': '400000.00',
};

const _regularExpenseJson = <String, dynamic>{
  'id': 'e-1',
  'branch_id': 'br-1',
  'category': 'Аренда',
  'amount': '1500000.00',
  'expense_date': '2026-06-10',
  'note': 'июнь',
  'kind': 'regular',
  'payroll_user_id': null,
  'payroll_month': null,
  'created_by_name': 'Бухгалтер',
  'created_at': '2026-06-10T09:00:00Z',
};

const _payrollExpenseJson = <String, dynamic>{
  'id': 'e-2',
  'branch_id': 'br-1',
  'category': 'Зарплата',
  'amount': '400000.00',
  'expense_date': '2026-06-11',
  'note': 'Оклад 10% за 2026-05',
  'kind': 'payroll',
  'payroll_user_id': 'u-7',
  'payroll_month': '2026-05',
  'created_by_name': 'Директор',
  'created_at': '2026-06-11T10:00:00Z',
};

const _payrollRowsJson = [
  {
    'user_id': 'u-7',
    'full_name': 'Иванова Дилноза',
    'salary_percent': '10.00',
    'revenue': '4000000.00',
    'salary': '400000.00',
    'paid': true,
    'paid_at': '2026-06-11T10:00:00Z',
  },
  {
    'user_id': 'u-8',
    'full_name': 'Каримов Жасур',
    'salary_percent': '15.00',
    'revenue': '0.00',
    'salary': '0.00',
    'paid': false,
    'paid_at': null,
  },
];

void main() {
  // ─── Repository: parsing + request shape ────────────────────────────────────

  test('dailyReport: passes d=YYYY-MM-DD, money stays String', () async {
    final (repo, adapter) = _repo((_) => _json(_dailyJson));
    final r = await repo.dailyReport('2026-06-12');
    expect(adapter.lastRequest!.uri.path, endsWith('/finance/reports/daily'));
    expect(adapter.lastRequest!.uri.queryParameters['d'], '2026-06-12');
    expect(r.date, '2026-06-12');
    expect(r.incomeByMethod['cash'], '500000.00');
    expect(r.incomeByMethod['transfer'], '100000.00');
    expect(r.incomeTotal, isA<String>());
    expect(r.net, '680000.00');
  });

  test('monthlyReport: parses payroll_total → payrollTotal', () async {
    final (repo, adapter) = _repo((_) => _json(_monthlyJson));
    final r = await repo.monthlyReport('2026-06');
    expect(adapter.lastRequest!.uri.queryParameters['month'], '2026-06');
    expect(r.month, '2026-06');
    expect(r.payrollTotal, '400000.00');
    expect(r.incomeByMethod.keys,
        containsAll(['cash', 'card', 'qr', 'transfer']));
  });

  test('expenses: Page envelope + filters in query; payroll kind detected',
      () async {
    final (repo, adapter) = _repo((_) => _json({
          'items': [_regularExpenseJson, _payrollExpenseJson],
          'total': 2,
          'offset': 0,
          'limit': 50,
        }));
    final page = await repo.expenses(
        dateFrom: '2026-06-01', dateTo: '2026-06-30', category: 'Аренда');
    final q = adapter.lastRequest!.uri.queryParameters;
    expect(q['date_from'], '2026-06-01');
    expect(q['date_to'], '2026-06-30');
    expect(q['category'], 'Аренда');
    expect(q['offset'], '0');
    expect(q['limit'], '50');
    expect(page.total, 2);
    expect(page.items, hasLength(2));
    expect(page.items.first.category, 'Аренда');
    expect(page.items.first.isPayroll, isFalse);
    expect(page.items.last.isPayroll, isTrue);
    expect(page.items.last.payrollMonth, '2026-05');
    expect(page.items.last.amount, isA<String>());
  });

  test('expenses: empty filters are not sent at all', () async {
    final (repo, adapter) = _repo((_) =>
        _json({'items': [], 'total': 0, 'offset': 0, 'limit': 50}));
    await repo.expenses();
    final q = adapter.lastRequest!.uri.queryParameters;
    expect(q.containsKey('date_from'), isFalse);
    expect(q.containsKey('date_to'), isFalse);
    expect(q.containsKey('category'), isFalse);
  });

  test('createExpense: POST body uses snake_case, amount as string', () async {
    final (repo, adapter) =
        _repo((_) => _json(_regularExpenseJson, status: 201));
    final created = await repo.createExpense(
      category: 'Аренда',
      amount: '1500000.00',
      expenseDate: '2026-06-10',
      note: 'июнь',
    );
    expect(adapter.lastRequest!.method, 'POST');
    final body = adapter.lastRequest!.data as Map<String, dynamic>;
    expect(body['category'], 'Аренда');
    expect(body['amount'], '1500000.00');
    expect(body['expense_date'], '2026-06-10');
    expect(body['note'], 'июнь');
    expect(created.id, 'e-1');
  });

  test('deleteExpense: 409 surfaces backend detail as ApiException', () async {
    final (repo, _) = _repo((_) => _json(
        {'detail': 'Payroll expenses cannot be deleted via the expense API'},
        status: 409));
    await expectLater(
      repo.deleteExpense('e-2'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 409)
          .having((e) => e.message, 'message', contains('Payroll'))),
    );
  });

  test('payroll: parses rows, money stays String', () async {
    final (repo, adapter) = _repo((_) => _json(_payrollRowsJson));
    final rows = await repo.payroll('2026-06');
    expect(adapter.lastRequest!.uri.queryParameters['month'], '2026-06');
    expect(rows, hasLength(2));
    expect(rows.first.fullName, 'Иванова Дилноза');
    expect(rows.first.salaryPercent, '10.00');
    expect(rows.first.salary, '400000.00');
    expect(rows.first.paid, isTrue);
    expect(rows.last.paid, isFalse);
    expect(rows.last.paidAt, isNull);
  });

  test('payoutSalary: 409 (already paid) keeps statusCode for the UI', () async {
    final (repo, _) = _repo((_) =>
        _json({'detail': 'Payroll for 2026-06 is already paid out'},
            status: 409));
    await expectLater(
      repo.payoutSalary(userId: 'u-7', month: '2026-06'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 409)),
    );
  });

  test('dailyReportCsv: returns raw bytes (ResponseType.bytes)', () async {
    const csv = '\u{feff}date,income_cash\r\n2026-06-12,500000.00\r\n';
    final (repo, adapter) = _repo((_) => ResponseBody.fromString(csv, 200,
        headers: {
          Headers.contentTypeHeader: ['text/csv; charset=utf-8']
        }));
    final bytes = await repo.dailyReportCsv('2026-06-12');
    expect(adapter.lastRequest!.responseType, ResponseType.bytes);
    expect(adapter.lastRequest!.uri.queryParameters['d'], '2026-06-12');
    // Байты доходят как есть: BOM (EF BB BF) для Excel сохранён.
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(bytes, utf8.encode(csv));
  });

  // ─── Widget smoke tests ─────────────────────────────────────────────────────

  testWidgets('CashTab: daily + monthly report cards render all lines',
      (tester) async {
    final daily = DailyReport.fromJson(_dailyJson);
    final monthly = MonthlyReport.fromJson(_monthlyJson);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        dailyReportProvider.overrideWith((ref, d) async => daily),
        monthlyReportProvider.overrideWith((ref, m) async => monthly),
      ],
      child: const MaterialApp(home: Scaffold(body: CashTab())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Отчёт за день'), findsOneWidget);
    expect(find.text('Сводка за месяц'), findsOneWidget);
    // Обе карточки содержат канонические строки методов.
    expect(find.text('Наличные'), findsNWidgets(2));
    expect(find.text('Карта'), findsNWidgets(2));
    expect(find.text('QR'), findsNWidgets(2));
    expect(find.text('Перевод'), findsNWidgets(2));
    expect(find.text('Приход'), findsNWidgets(2));
    expect(find.text('Возвраты'), findsNWidgets(2));
    expect(find.text('Расходы'), findsNWidgets(2));
    expect(find.text('Итог'), findsNWidgets(2));
    // «Зарплата» — только в месячной карточке.
    expect(find.text('Зарплата (в составе расходов)'), findsOneWidget);
    expect(find.text(formatMoney('400000.00')), findsOneWidget);
    expect(find.text(formatMoney('680000.00')), findsOneWidget);
  });

  testWidgets(
      'ExpensesTab: manage-права дают FAB и удаление; зарплатная строка — замок',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(const AuthUser(
              id: 'u-1',
              email: 'fin@kozshifo.uz',
              fullName: 'Финансист',
              permissions: ['expenses.read', 'expenses.manage'],
            ))),
        expensesProvider.overrideWith((ref, q) async => ExpensePage(
              items: [
                Expense.fromJson(_regularExpenseJson),
                Expense.fromJson(_payrollExpenseJson),
              ],
              total: 2,
              offset: 0,
              limit: 50,
            )),
      ],
      child: const MaterialApp(home: Scaffold(body: ExpensesTab())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Добавить расход'), findsOneWidget);
    expect(find.text('Аренда'), findsOneWidget);
    expect(find.text('Зарплата'), findsOneWidget);
    // Обычная строка удаляемая, зарплатная — защищена замком.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('FinanceScreen: без payroll.read вкладка «Зарплата» скрыта',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(const AuthUser(
              id: 'u-1',
              email: 'fin@kozshifo.uz',
              fullName: 'Финансист',
              permissions: ['expenses.read'],
            ))),
        dailyReportProvider
            .overrideWith((ref, d) async => DailyReport.fromJson(_dailyJson)),
        monthlyReportProvider.overrideWith(
            (ref, m) async => MonthlyReport.fromJson(_monthlyJson)),
      ],
      child: const MaterialApp(home: FinanceScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Финансы'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Касса'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Расходы'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Зарплата'), findsNothing);
  });

  testWidgets('FinanceScreen: совсем без прав — заглушка вместо вкладок',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(const AuthUser(
              id: 'u-2',
              email: 'nurse@kozshifo.uz',
              fullName: 'Медсестра',
            ))),
      ],
      child: const MaterialApp(home: FinanceScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Нет прав для просмотра финансов.'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });
}

/// Подменяет AuthController: сразу аутентифицирован с заданным пользователем,
/// без restore/refresh-логики настоящего контроллера.
class _FakeAuth extends AuthController {
  _FakeAuth(this._user);

  final AuthUser _user;

  @override
  AuthState build() => AuthState(AuthStatus.authenticated, _user);
}
