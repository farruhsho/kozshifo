import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/finance_repository.dart';
import '../domain/payroll_row.dart';
import 'finance_common.dart';
import 'payroll_detail_screen.dart';

/// «Зарплата»: процентные оклады за месяц — ФИО, %, выручка, зарплата,
/// статус выплаты. Кнопка «Выплатить» требует `payroll.manage`.
class PayrollTab extends ConsumerStatefulWidget {
  const PayrollTab({super.key});

  @override
  ConsumerState<PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends ConsumerState<PayrollTab> {
  late String _month = ym(DateTime.now());
  bool _exporting = false;

  /// id сотрудника, по которому сейчас идёт выплата (спиннер на кнопке).
  String? _payingUserId;

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final bytes =
          await ref.read(financeRepositoryProvider).payrollCsv(_month);
      if (mounted) await saveCsv(context, bytes, 'payroll-$_month.csv');
    } catch (e) {
      if (mounted) showFinanceSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _payout(PayrollRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выплатить зарплату?'),
        content: Text(
            '${row.fullName}\n${formatMoney(row.salary)} за ${monthLabel(_month).toLowerCase()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Выплатить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _payingUserId = row.userId);
    try {
      await ref
          .read(financeRepositoryProvider)
          .payoutSalary(userId: row.userId, month: _month);
      ref.invalidate(payrollProvider(_month));
      // Выплата создаёт Expense(kind=payroll) — обновляем кассу и расходы.
      ref.invalidate(expensesProvider);
      ref.invalidate(dailyReportProvider);
      ref.invalidate(monthlyReportProvider);
      if (mounted) {
        showFinanceSnack(context, 'Зарплата выплачена: ${row.fullName}');
      }
    } on ApiException catch (e) {
      if (mounted) {
        showFinanceSnack(
          context,
          e.statusCode == 409 ? 'Уже выплачено за этот месяц' : e.message,
          error: true,
        );
      }
    } catch (e) {
      if (mounted) showFinanceSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _payingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(payrollProvider(_month));
    final user = ref.watch(authControllerProvider).user;
    final canManage = user?.can('payroll.manage') ?? false;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: MonthSelector(
                  month: _month,
                  onChanged: (m) => setState(() => _month = m),
                ),
              ),
              IconButton(
                tooltip: 'Скачать CSV',
                onPressed: _exporting ? null : _exportCsv,
                icon: _exporting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncValueWidget<List<PayrollRow>>(
            value: rows,
            onRetry: () => ref.invalidate(payrollProvider(_month)),
            builder: (items) {
              if (items.isEmpty) {
                return const Center(
                    child: Text(
                        'Нет сотрудников с настроенной оплатой.\nОплата задаётся в карточке сотрудника.'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(payrollProvider(_month)),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _tile(context, items[i], canManage),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, PayrollRow row, bool canManage) {
    final paying = _payingUserId == row.userId;
    final salaryValue = double.tryParse(row.salary) ?? 0;

    final Widget status;
    if (row.paid) {
      final primary = Theme.of(context).colorScheme.primary;
      status = Chip(
        label: Text(row.paidAt == null
            ? 'Выплачено'
            : 'Выплачено ${ddMM(row.paidAt!)}'),
        labelStyle: TextStyle(color: primary),
        backgroundColor: primary.withValues(alpha: 0.1),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      );
    } else if (canManage) {
      status = FilledButton.tonal(
        // Нулевая зарплата → backend ответит 400; не даём нажать.
        onPressed: (paying || salaryValue <= 0) ? null : () => _payout(row),
        child: paying
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Выплатить'),
      );
    } else {
      status = Chip(
        label: const Text('Не выплачено'),
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      );
    }

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(row.fullName),
      subtitle: Text(_payBreakdown(row)),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PayrollDetailScreen(
            userId: row.userId, fullName: row.fullName, month: _month),
      )),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatMoney(row.salary),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          status,
        ],
      ),
    );
  }

  /// "Приём: 30% (450 000 сум) · Опер.: 50 000/оп ×3" — only the configured sides.
  String _payBreakdown(PayrollRow row) {
    final parts = <String>[];
    if (row.consultSalaryType != null) {
      final rule = row.consultSalaryType == 'percent'
          ? '${row.consultSalaryValue}%'
          : 'фикс';
      parts.add('Приём: $rule (${formatMoney(row.consultPay)})');
    }
    if (row.operationSalaryType != null) {
      final rule = row.operationSalaryType == 'percent'
          ? '${row.operationSalaryValue}%'
          : '${formatMoney(row.operationSalaryValue)}/оп';
      parts.add('Опер.: $rule ×${row.operationCount} (${formatMoney(row.operationPay)})');
    }
    return parts.isEmpty ? 'оплата не настроена' : parts.join(' · ');
  }
}
