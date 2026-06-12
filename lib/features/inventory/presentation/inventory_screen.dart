import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/inventory_repository.dart';
import '../domain/stock.dart';

/// Склад филиала: остатки по товарам с партиями (срок годности, цена),
/// фильтр дефицита и оформление прихода (требует `inventory.manage`).
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _lowOnly = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final branchId = user?.branchId;
    final canManage = user?.can('inventory.manage') ?? false;

    if (branchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Склад')),
        body: const Center(
            child: Text('У пользователя не задан филиал — склад недоступен.')),
      );
    }

    final stock = ref.watch(stockProvider(branchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Склад'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => ref.invalidate(stockProvider(branchId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showReceiptDialog(branchId),
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Приход'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Только дефицит'),
                selected: _lowOnly,
                onSelected: (v) => setState(() => _lowOnly = v),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueWidget<List<StockRow>>(
              value: stock,
              onRetry: () => ref.invalidate(stockProvider(branchId)),
              builder: (rows) {
                // Дефицит фильтруем на клиенте: список филиала невелик,
                // а переключение фильтра не требует похода на сервер.
                final visible =
                    _lowOnly ? rows.where((r) => r.lowStock).toList() : rows;
                if (visible.isEmpty) {
                  return Center(
                      child: Text(_lowOnly
                          ? 'Дефицитных позиций нет.'
                          : 'Склад пуст — оформите приход.'));
                }
                return ListView(
                  // Нижний отступ — чтобы FAB не закрывал последнюю карточку.
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  children: [for (final r in visible) _StockTile(row: r)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReceiptDialog(String branchId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ReceiptDialog(branchId: branchId),
    );
    if (ok == true && mounted) {
      ref.invalidate(stockProvider(branchId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Приход оформлен')));
    }
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.row});

  final StockRow row;

  @override
  Widget build(BuildContext context) {
    final p = row.product;
    final error = Theme.of(context).colorScheme.error;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.inventory_2_outlined,
            color: Theme.of(context).colorScheme.primary),
        title: Text(p.name),
        subtitle:
            Text('${p.sku} · ${p.typeLabel} · мин. ${p.minStock} ${p.unit}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (row.lowStock) ...[
              Chip(
                label: const Text('дефицит'),
                backgroundColor: error.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: error),
                side: BorderSide.none,
              ),
              const SizedBox(width: 8),
            ],
            Text('${row.onHand} ${p.unit}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (row.batches.isEmpty)
            const Align(
                alignment: Alignment.centerLeft, child: Text('Партий нет.'))
          else
            for (final b in row.batches)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.qr_code_2_outlined),
                title: Text(b.batchNo ?? 'без номера партии'),
                subtitle: Text('годен до ${b.expiryDate ?? '—'} · '
                    'остаток ${b.quantity} ${p.unit} · '
                    'цена ${formatMoney(b.unitCost)}'),
              ),
        ],
      ),
    );
  }
}

/// Диалог прихода: товар, количество, цена закупки, партия, срок годности.
class _ReceiptDialog extends ConsumerStatefulWidget {
  const _ReceiptDialog({required this.branchId});

  final String branchId;

  @override
  ConsumerState<_ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<_ReceiptDialog> {
  final _quantity = TextEditingController();
  final _unitCost = TextEditingController();
  final _batchNo = TextEditingController();
  final _expiry = TextEditingController();
  String? _productId;
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _unitCost.dispose();
    _batchNo.dispose();
    _expiry.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final productId = _productId;
    if (productId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(inventoryRepositoryProvider).createReceipt(
            branchId: widget.branchId,
            items: [
              (
                productId: productId,
                // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
                quantity: _quantity.text.trim().replaceAll(',', '.'),
                unitCost: _unitCost.text.trim().replaceAll(',', '.'),
                batchNo:
                    _batchNo.text.trim().isEmpty ? null : _batchNo.text.trim(),
                expiryDate:
                    _expiry.text.trim().isEmpty ? null : _expiry.text.trim(),
              ),
            ],
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final canSave = !_saving &&
        _productId != null &&
        _quantity.text.trim().isNotEmpty &&
        _unitCost.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Приход товара'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            products.when(
              data: (items) => DropdownButtonFormField<String>(
                initialValue: _productId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Товар'),
                items: [
                  for (final p in items)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} (${p.unit})',
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _productId = v),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text('$e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantity,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Количество'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitCost,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Цена за единицу, сум'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _batchNo,
              decoration: const InputDecoration(
                  labelText: 'Номер партии (необязательно)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expiry,
              decoration: const InputDecoration(
                  labelText: 'Годен до (ГГГГ-ММ-ДД, необязательно)',
                  hintText: '2027-01-01'),
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
          onPressed: canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Оформить'),
        ),
      ],
    );
  }
}
