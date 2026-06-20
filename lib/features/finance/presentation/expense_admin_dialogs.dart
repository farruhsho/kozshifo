import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/finance_repository.dart';
import '../domain/expense_category.dart';
import 'finance_common.dart';

/// «Типы расходов» — CRUD над справочником категорий (rasxod turlari).
/// Системные типы (например «Зарплата») нельзя удалить — только деактивировать.
class ExpenseCategoriesDialog extends ConsumerStatefulWidget {
  const ExpenseCategoriesDialog({super.key});

  @override
  ConsumerState<ExpenseCategoriesDialog> createState() =>
      _ExpenseCategoriesDialogState();
}

class _ExpenseCategoriesDialogState
    extends ConsumerState<ExpenseCategoriesDialog> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(allExpenseCategoriesProvider);
    ref.invalidate(activeExpenseCategoriesProvider);
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(financeRepositoryProvider).createExpenseCategory(name);
      _name.clear();
      _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        showFinanceSnack(context,
            e.statusCode == 409 ? 'Такой тип уже есть' : e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(ExpenseCategory c) async {
    try {
      await ref
          .read(financeRepositoryProvider)
          .updateExpenseCategory(c.id, isActive: !c.isActive);
      _refresh();
    } catch (e) {
      if (mounted) showFinanceSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _delete(ExpenseCategory c) async {
    try {
      await ref.read(financeRepositoryProvider).deleteExpenseCategory(c.id);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        showFinanceSnack(
            context,
            e.statusCode == 409
                ? 'Системный тип нельзя удалить — деактивируйте'
                : e.message,
            error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(allExpenseCategoriesProvider);
    return AlertDialog(
      title: const Text('Типы расходов'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration:
                        const InputDecoration(labelText: 'Новый тип расхода'),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _add,
                  child: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AsyncValueWidget<List<ExpenseCategory>>(
                value: cats,
                onRetry: () => ref.invalidate(allExpenseCategoriesProvider),
                builder: (items) => ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(c.isActive
                          ? Icons.label_outline
                          : Icons.label_off_outlined),
                      title: Text(c.name,
                          style: c.isActive
                              ? null
                              : TextStyle(color: Theme.of(context).disabledColor)),
                      subtitle: c.isSystem ? const Text('системный') : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: c.isActive ? 'Деактивировать' : 'Включить',
                            onPressed: () => _toggle(c),
                            icon: Icon(c.isActive
                                ? Icons.toggle_on
                                : Icons.toggle_off_outlined),
                          ),
                          if (!c.isSystem)
                            IconButton(
                              tooltip: 'Удалить',
                              onPressed: () => _delete(c),
                              icon: Icon(Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть')),
      ],
    );
  }
}

/// «Постоянные расходы» за месяц — шаблоны (тип + название + сумма, фикс/переменный)
/// и кнопка «Провести» (создаёт расход за месяц). Фикс. берёт сумму шаблона,
/// переменный спрашивает сумму.
class RecurringExpensesDialog extends ConsumerStatefulWidget {
  const RecurringExpensesDialog({super.key, required this.month});

  final String month; // YYYY-MM

  @override
  ConsumerState<RecurringExpensesDialog> createState() =>
      _RecurringExpensesDialogState();
}

class _RecurringExpensesDialogState
    extends ConsumerState<RecurringExpensesDialog> {
  bool _changed = false;

  void _refresh() => ref.invalidate(recurringExpensesProvider(widget.month));

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _RecurringCreateDialog(),
    );
    if (created == true) _refresh();
  }

  Future<void> _post(RecurringExpense r) async {
    String? amount;
    if (!r.isFixed) {
      amount = await _askAmount(r.name);
      if (amount == null) return;
    }
    try {
      await ref
          .read(financeRepositoryProvider)
          .postRecurringExpense(r.id, widget.month, amount: amount);
      _changed = true;
      _refresh();
      if (mounted) showFinanceSnack(context, 'Проведено: ${r.name}');
    } on ApiException catch (e) {
      if (mounted) {
        showFinanceSnack(context,
            e.statusCode == 409 ? 'Уже проведено за месяц' : e.message,
            error: true);
      }
    }
  }

  Future<String?> _askAmount(String name) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Сумма: $name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Сумма, сум'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Провести')),
        ],
      ),
    );
    final raw = ctrl.text.trim().replaceAll(',', '.');
    ctrl.dispose();
    return ok == true && raw.isNotEmpty ? raw : null;
  }

  Future<void> _delete(RecurringExpense r) async {
    try {
      await ref.read(financeRepositoryProvider).deleteRecurringExpense(r.id);
      _refresh();
    } catch (e) {
      if (mounted) showFinanceSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(recurringExpensesProvider(widget.month));
    return AlertDialog(
      title: Text('Постоянные расходы · ${monthLabel(widget.month)}'),
      content: SizedBox(
        width: 460,
        height: 440,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('Добавить постоянный расход'),
              ),
            ),
            Expanded(
              child: AsyncValueWidget<List<RecurringExpense>>(
                value: list,
                onRetry: () => _refresh(),
                builder: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('Шаблонов нет.'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => _tile(context, items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(_changed),
            child: const Text('Закрыть')),
      ],
    );
  }

  Widget _tile(BuildContext context, RecurringExpense r) {
    final rule = r.isFixed
        ? 'фикс. ${formatMoney(r.amount)}'
        : 'сумма задаётся';
    return ListTile(
      dense: true,
      leading: Icon(r.isFixed ? Icons.event_repeat : Icons.tune),
      title: Text('${r.name}  ·  ${r.category}'),
      subtitle: Text(rule),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (r.posted)
            Chip(
              label: Text('проведено ${formatMoney(r.postedAmount)}'),
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
            )
          else
            FilledButton.tonal(
                onPressed: () => _post(r), child: const Text('Провести')),
          IconButton(
            tooltip: 'Удалить шаблон',
            onPressed: () => _delete(r),
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }
}

class _RecurringCreateDialog extends ConsumerStatefulWidget {
  const _RecurringCreateDialog();

  @override
  ConsumerState<_RecurringCreateDialog> createState() =>
      _RecurringCreateDialogState();
}

class _RecurringCreateDialogState
    extends ConsumerState<_RecurringCreateDialog> {
  String? _category;
  final _name = TextEditingController();
  final _amount = TextEditingController();
  bool _isFixed = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  String get _amt => _amount.text.trim().replaceAll(',', '.');

  bool get _canSave {
    if (_saving || _category == null || _name.text.trim().isEmpty) return false;
    if (_isFixed) return double.tryParse(_amt) != null && double.parse(_amt) > 0;
    return true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(financeRepositoryProvider).createRecurringExpense(
            category: _category!,
            name: _name.text.trim(),
            amount: _isFixed ? _amt : (_amt.isEmpty ? null : _amt),
            isFixed: _isFixed,
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
    final cats = ref.watch(activeExpenseCategoriesProvider);
    return AlertDialog(
      title: const Text('Постоянный расход'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            cats.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (items) => DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Тип расхода'),
                items: [
                  for (final c in items)
                    DropdownMenuItem(value: c.name, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Фиксированная сумма каждый месяц'),
              subtitle: Text(_isFixed
                  ? 'Одна и та же сумма'
                  : 'Сумма задаётся при проведении'),
              value: _isFixed,
              onChanged: (v) => setState(() => _isFixed = v),
            ),
            if (_isFixed)
              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Сумма, сум'),
                onChanged: (_) => setState(() {}),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Отмена')),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Создать'),
        ),
      ],
    );
  }
}
