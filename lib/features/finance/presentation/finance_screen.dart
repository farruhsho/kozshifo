import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/cashier_repository.dart';
import '../data/finance_repository.dart';
import 'cash_tab.dart';
import 'expenses_tab.dart';
import 'payroll_tab.dart';
import 'refunds_tab.dart';
import 'shift_tab.dart';
import 'till_tab.dart';

/// Финансы клиники: касса кассира (платежи · возвраты · смена) + отчёты
/// (день/месяц) · расходы · процентная зарплата. Вкладки скрываются по правам:
/// «Платежи» — `payments.create`, «Возвраты» — `payments.read`, «Смена» /
/// «Касса» / «Расходы» — `expenses.read`, «Зарплата» — `payroll.read`.
class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final canTill = user?.can('payments.create') ?? false;
    final canPayments = user?.can('payments.read') ?? false;
    final canExpenses = user?.can('expenses.read') ?? false;
    final canPayroll = user?.can('payroll.read') ?? false;

    final tabs = <(Tab, Widget)>[
      // Cashier till first — the cashier's primary workspace.
      if (canTill) (const Tab(text: 'Платежи'), const TillTab()),
      if (canPayments) (const Tab(text: 'Возвраты'), const RefundsTab()),
      if (canExpenses) (const Tab(text: 'Смена'), const ShiftTab()),
      if (canExpenses) (const Tab(text: 'Касса'), const CashTab()),
      if (canExpenses) (const Tab(text: 'Расходы'), const ExpensesTab()),
      if (canPayroll) (const Tab(text: 'Зарплата'), const PayrollTab()),
    ];

    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Финансы')),
        body: const Center(
            child: Text('Нет прав для просмотра финансов.')),
      );
    }

    return DefaultTabController(
      // Смена прав меняет число вкладок — пересоздаём контроллер.
      key: ValueKey(tabs.length),
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Финансы'),
          actions: [
            IconButton(
              tooltip: 'Обновить',
              onPressed: () {
                // Инвалидация семейств обновляет все активные ключи
                // (день/месяц/фильтры) разом.
                ref.invalidate(dailyReportProvider);
                ref.invalidate(monthlyReportProvider);
                ref.invalidate(expensesProvider);
                ref.invalidate(payrollProvider);
                ref.invalidate(openVisitsProvider);
                ref.invalidate(tillPaymentsProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(tabs: [for (final (tab, _) in tabs) tab]),
        ),
        body: TabBarView(children: [for (final (_, body) in tabs) body]),
      ),
    );
  }
}
