import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/finance_repository.dart';
import '../domain/expense.dart';
import 'finance_common.dart';

/// «Расходы»: список с фильтрами (период + категория), добавление и удаление
/// (требует `expenses.manage`), CSV-экспорт. Зарплатные строки защищены замком.
class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  final _category = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  int _offset = 0;
  bool _exporting = false;

  @override
  void dispose() {
    _category.dispose();
    super.dispose();
  }

  ExpenseQuery get _query => (
        dateFrom: _from == null ? null : ymd(_from!),
        dateTo: _to == null ? null : ymd(_to!),
        category: _category.text.trim().isEmpty ? null : _category.text.trim(),
        offset: _offset,
      );

  Future<void> _pickDate({required bool from}) async {
    final initial = (from ? _from : _to) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
      _offset = 0;
    });
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final q = _query;
      final bytes = await ref.read(financeRepositoryProvider).expensesCsv(
            dateFrom: q.dateFrom,
            dateTo: q.dateTo,
            category: q.category,
          );
      if (mounted) await saveCsv(context, bytes, 'expenses.csv');
    } catch (e) {
      if (mounted) showFinanceSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openCreate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExpenseCreateDialog(),
    );
    if (ok == true && mounted) {
      ref.invalidate(expensesProvider);
      showFinanceSnack(context, 'Расход добавлен');
    }
  }

  Future<void> _delete(Expense e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить расход?'),
        content: Text(
            '${e.category} · ${formatMoney(e.amount)} от ${ddMMyyyy(e.expenseDate)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(financeRepositoryProvider).deleteExpense(e.id);
      ref.invalidate(expensesProvider);
      if (mounted) showFinanceSnack(context, 'Расход удалён');
    } catch (err) {
      if (mounted) showFinanceSnack(context, err.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(expensesProvider(_query));
    final user = ref.watch(authControllerProvider).user;
    final canManage = user?.can('expenses.manage') ?? false;

    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Добавить расход'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _dateChip(
                  label: _from == null ? 'С даты' : 'с ${ddMMyyyy(ymd(_from!))}',
                  selected: _from != null,
                  onTap: () => _pickDate(from: true),
                  onClear: _from == null
                      ? null
                      : () => setState(() {
                            _from = null;
                            _offset = 0;
                          }),
                ),
                const SizedBox(width: 8),
                _dateChip(
                  label: _to == null ? 'По дату' : 'по ${ddMMyyyy(ymd(_to!))}',
                  selected: _to != null,
                  onTap: () => _pickDate(from: false),
                  onClear: _to == null
                      ? null
                      : () => setState(() {
                            _to = null;
                            _offset = 0;
                          }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _category,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Категория',
                      prefixIcon: const Icon(Icons.filter_alt_outlined),
                      suffixIcon: _category.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _category.clear();
                                setState(() => _offset = 0);
                              },
                            ),
                    ),
                    onSubmitted: (_) => setState(() => _offset = 0),
                  ),
                ),
                const SizedBox(width: 4),
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
            child: AsyncValueWidget<ExpensePage>(
              value: page,
              onRetry: () => ref.invalidate(expensesProvider(_query)),
              builder: (data) {
                if (data.items.isEmpty) {
                  return const Center(
                      child: Text('Расходов по выбранным фильтрам нет.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(expensesProvider),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: data.items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) =>
                              _tile(context, data.items[i], canManage),
                        ),
                      ),
                      if (data.total > data.limit)
                        _pager(context, data),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InputChip(
      label: Text(label),
      selected: selected,
      onPressed: onTap,
      onDeleted: onClear,
      deleteIcon: onClear == null ? null : const Icon(Icons.clear, size: 16),
    );
  }

  Widget _tile(BuildContext context, Expense e, bool canManage) {
    final subtitleParts = [
      ddMMyyyy(e.expenseDate),
      if (e.note != null && e.note!.isNotEmpty) e.note!,
      if (e.createdByName != null) e.createdByName!,
    ];
    return ListTile(
      leading: Icon(
        e.isPayroll ? Icons.badge_outlined : Icons.receipt_long_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(e.category),
      subtitle: Text(subtitleParts.join(' · ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatMoney(e.amount),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (canManage) ...[
            const SizedBox(width: 4),
            if (e.isPayroll)
              // Зарплатные расходы создаются выплатой и не удаляются отсюда.
              Tooltip(
                message: 'Зарплатная выплата — удаление недоступно',
                child: Icon(Icons.lock_outline,
                    color: Theme.of(context).disabledColor),
              )
            else
              IconButton(
                tooltip: 'Удалить',
                onPressed: () => _delete(e),
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
              ),
          ],
        ],
      ),
    );
  }

  Widget _pager(BuildContext context, ExpensePage data) {
    final fromN = data.offset + 1;
    final toN = data.offset + data.items.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$fromN–$toN из ${data.total}',
              style: Theme.of(context).textTheme.bodySmall),
          IconButton(
            tooltip: 'Назад',
            onPressed: data.offset == 0
                ? null
                : () => setState(() {
                      final prev = data.offset - data.limit;
                      _offset = prev < 0 ? 0 : prev;
                    }),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Вперёд',
            onPressed: toN >= data.total
                ? null
                : () => setState(() => _offset = data.offset + data.limit),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// Диалог нового расхода: категория, сумма, дата, примечание.
class _ExpenseCreateDialog extends ConsumerStatefulWidget {
  const _ExpenseCreateDialog();

  @override
  ConsumerState<_ExpenseCreateDialog> createState() =>
      _ExpenseCreateDialogState();
}

class _ExpenseCreateDialogState extends ConsumerState<_ExpenseCreateDialog> {
  final _category = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _category.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
  String get _normalizedAmount => _amount.text.trim().replaceAll(',', '.');

  bool get _canSave {
    if (_saving || _category.text.trim().isEmpty) return false;
    final amount = double.tryParse(_normalizedAmount);
    return amount != null && amount > 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(financeRepositoryProvider).createExpense(
            category: _category.text.trim(),
            amount: _normalizedAmount,
            expenseDate: ymd(_date),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showFinanceSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый расход'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _category,
              decoration: const InputDecoration(
                  labelText: 'Категория', hintText: 'Аренда, коммуналка…'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Сумма, сум'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Дата: ${ddMMyyyy(ymd(_date))}',
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: const Text('Изменить'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                  labelText: 'Примечание (необязательно)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Добавить'),
        ),
      ],
    );
  }
}
