import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/inventory_repository.dart';
import '../domain/product.dart';
import '../domain/stock.dart';
import 'write_off_dialog.dart';

/// Склад филиала: остатки по товарам с партиями (срок годности, цена),
/// дефицит, истекающие партии, приход (`inventory.manage`) и списание
/// (`inventory.write_off`).
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  /// Партии, истекающие в ближайшие N дней (или уже просроченные), попадают
  /// во вкладку «Истекает».
  static const expiringWindowDays = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final branchId = user?.branchId;
    final canManage = user?.can('inventory.manage') ?? false;
    final canWriteOff = user?.can('inventory.write_off') ?? false;

    if (branchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Склад')),
        body: const Center(
            child: Text('У пользователя не задан филиал — склад недоступен.')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Склад'),
          actions: [
            IconButton(
              tooltip: 'Обновить',
              onPressed: () => ref.invalidate(stockProvider(branchId)),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Остатки'),
            Tab(text: 'Дефицит'),
            Tab(text: 'Истекает'),
          ]),
        ),
        floatingActionButton: _Fab(
          branchId: branchId,
          canManage: canManage,
          canWriteOff: canWriteOff,
        ),
        body: TabBarView(
          children: [
            _StockListTab(branchId: branchId, canWriteOff: canWriteOff),
            _LowStockTab(branchId: branchId, canWriteOff: canWriteOff),
            _ExpiringTab(branchId: branchId, canWriteOff: canWriteOff),
          ],
        ),
      ),
    );
  }
}

// ═══ FAB: приход и/или списание ══════════════════════════════════════════════

class _Fab extends ConsumerWidget {
  const _Fab({
    required this.branchId,
    required this.canManage,
    required this.canWriteOff,
  });

  final String branchId;
  final bool canManage;
  final bool canWriteOff;

  Future<void> _receipt(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ReceiptDialog(branchId: branchId),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(stockProvider(branchId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Приход оформлен')));
    }
  }

  Future<void> _writeOff(BuildContext context, WidgetRef ref,
      {Product? product}) async {
    final movements = await showWriteOffDialog(context,
        branchId: branchId, product: product);
    if (movements != null && context.mounted) {
      ref.invalidate(stockProvider(branchId));
      final qty = movements.fold<int>(0, (n, _) => n + 1);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Списание выполнено: партий затронуто $qty'),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canManage && !canWriteOff) return const SizedBox.shrink();
    // Один тип права — одна прямая кнопка; оба — меню выбора действия.
    if (canManage && !canWriteOff) {
      return FloatingActionButton.extended(
        onPressed: () => _receipt(context, ref),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Приход'),
      );
    }
    if (canWriteOff && !canManage) {
      return FloatingActionButton.extended(
        onPressed: () => _writeOff(context, ref),
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('Списание'),
      );
    }
    return PopupMenuButton<String>(
      tooltip: 'Действия со складом',
      onSelected: (v) {
        if (v == 'receipt') _receipt(context, ref);
        if (v == 'write_off') _writeOff(context, ref);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'receipt',
          child: ListTile(
            leading: Icon(Icons.add_box_outlined),
            title: Text('Приход'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'write_off',
          child: ListTile(
            leading: Icon(Icons.remove_circle_outline),
            title: Text('Списание'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: FloatingActionButton.extended(
        onPressed: null, // PopupMenuButton перехватывает тап
        icon: const Icon(Icons.warehouse_outlined),
        label: const Text('Операции'),
      ),
    );
  }
}

// ═══ Вкладка 1: Остатки (поиск + ленивый список) ═════════════════════════════

class _StockListTab extends ConsumerStatefulWidget {
  const _StockListTab({required this.branchId, required this.canWriteOff});

  final String branchId;
  final bool canWriteOff;

  @override
  ConsumerState<_StockListTab> createState() => _StockListTabState();
}

class _StockListTabState extends ConsumerState<_StockListTab> {
  final _search = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    // Дебаунс: фильтруем на клиенте, но не дёргаем setState на каждый символ.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final stock = ref.watch(stockProvider(widget.branchId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _search,
            builder: (context, value, _) => TextField(
              controller: _search,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: 'Поиск по названию, SKU, штрихкоду',
                border: const OutlineInputBorder(),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _onSearch('');
                        },
                      ),
              ),
              onChanged: _onSearch,
            ),
          ),
        ),
        Expanded(
          child: AsyncValueWidget<List<StockRow>>(
            value: stock,
            onRetry: () => ref.invalidate(stockProvider(widget.branchId)),
            builder: (rows) {
              final visible = _query.isEmpty
                  ? rows
                  : rows.where((r) => _matches(r, _query)).toList();
              if (visible.isEmpty) {
                return Center(
                    child: Text(_query.isEmpty
                        ? 'Склад пуст — оформите приход.'
                        : 'Ничего не найдено.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: visible.length,
                itemBuilder: (_, i) => _StockTile(
                  row: visible[i],
                  branchId: widget.branchId,
                  canWriteOff: widget.canWriteOff,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static bool _matches(StockRow r, String q) {
    final p = r.product;
    return p.name.toLowerCase().contains(q) ||
        p.sku.toLowerCase().contains(q) ||
        (p.barcode?.toLowerCase().contains(q) ?? false);
  }
}

// ═══ Вкладка 2: Дефицит ══════════════════════════════════════════════════════

class _LowStockTab extends ConsumerWidget {
  const _LowStockTab({required this.branchId, required this.canWriteOff});

  final String branchId;
  final bool canWriteOff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockProvider(branchId));
    return AsyncValueWidget<List<StockRow>>(
      value: stock,
      onRetry: () => ref.invalidate(stockProvider(branchId)),
      builder: (rows) {
        // Дефицит фильтруем на клиенте: список филиала невелик, а сервер уже
        // вернул флаг low_stock в каждой строке.
        final low = rows.where((r) => r.lowStock).toList();
        if (low.isEmpty) {
          return const Center(child: Text('Дефицитных позиций нет.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: low.length,
          itemBuilder: (_, i) => _StockTile(
            row: low[i],
            branchId: branchId,
            canWriteOff: canWriteOff,
            showDeficit: true,
          ),
        );
      },
    );
  }
}

// ═══ Вкладка 3: Истекает (партии ≤30 дней, просрочка — красным) ══════════════

class _ExpiringRow {
  const _ExpiringRow(this.product, this.batch);
  final Product product;
  final StockBatch batch;
}

class _ExpiringTab extends ConsumerWidget {
  const _ExpiringTab({required this.branchId, required this.canWriteOff});

  final String branchId;
  final bool canWriteOff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockProvider(branchId));
    final scheme = Theme.of(context).colorScheme;
    return AsyncValueWidget<List<StockRow>>(
      value: stock,
      onRetry: () => ref.invalidate(stockProvider(branchId)),
      builder: (rows) {
        final now = DateTime.now();
        final expiring = <_ExpiringRow>[
          for (final r in rows)
            for (final b in r.batches)
              if (b.expiringWithin(InventoryScreen.expiringWindowDays, now))
                _ExpiringRow(r.product, b),
        ]..sort((a, b) {
            // Просроченные/ближайшие — наверх. Партии без даты не попадают сюда.
            final da = a.batch.daysUntilExpiry(now) ?? 1 << 30;
            final db = b.batch.daysUntilExpiry(now) ?? 1 << 30;
            return da.compareTo(db);
          });
        if (expiring.isEmpty) {
          return const Center(
              child: Text('Партий с истекающим сроком нет.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: expiring.length,
          itemBuilder: (_, i) {
            final e = expiring[i];
            final days = e.batch.daysUntilExpiry(now) ?? 0;
            final isExpired = e.batch.expired || days < 0;
            final badgeColor = isExpired ? scheme.error : scheme.tertiary;
            final label = isExpired
                ? (e.batch.expired ? 'просрочено' : 'истекло')
                : (days == 0 ? 'сегодня' : 'через $days дн.');
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(Icons.event_busy_outlined, color: badgeColor),
                title: Text(e.product.name),
                subtitle: Text(
                    'партия ${e.batch.batchNo ?? '—'} · '
                    'остаток ${e.batch.quantity} ${e.product.unit} · '
                    'годен до ${e.batch.expiryDate ?? '—'}'),
                trailing: Chip(
                  label: Text(label),
                  backgroundColor: badgeColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: badgeColor),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ═══ Карточка позиции остатка ════════════════════════════════════════════════

class _StockTile extends ConsumerWidget {
  const _StockTile({
    required this.row,
    required this.branchId,
    required this.canWriteOff,
    this.showDeficit = false,
  });

  final StockRow row;
  final String branchId;
  final bool canWriteOff;
  final bool showDeficit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = row.product;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.inventory_2_outlined, color: scheme.primary),
        title: Text(p.name),
        subtitle:
            Text('${p.sku} · ${p.typeLabel} · мин. ${p.minStock} ${p.unit}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (row.lowStock) ...[
              Chip(
                label: Text(showDeficit
                    ? 'дефицит ${_deficit(p.minStock, row.onHand)} ${p.unit}'
                    : 'дефицит'),
                backgroundColor: scheme.error.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: scheme.error),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
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
                leading: Icon(Icons.qr_code_2_outlined,
                    color: b.expired ? scheme.error : null),
                title: Text(b.batchNo ?? 'без номера партии'),
                subtitle: Text('годен до ${b.expiryDate ?? '—'} · '
                    'остаток ${b.quantity} ${p.unit} · '
                    'цена ${formatMoney(b.unitCost)}'),
                trailing: b.expired
                    ? Text('просрочено',
                        style: TextStyle(color: scheme.error, fontSize: 12))
                    : null,
              ),
          if (canWriteOff) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Списать'),
                onPressed: () async {
                  final movements = await showWriteOffDialog(context,
                      branchId: branchId, product: p);
                  if (movements != null && context.mounted) {
                    ref.invalidate(stockProvider(branchId));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Списание выполнено: партий затронуто ${movements.length}'),
                    ));
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Дефицит = min_stock − on_hand (для подписи чипа). Decimal как строки —
  /// используем double только для отображения, не для хранения.
  String _deficit(String minStock, String onHand) {
    final d = (double.tryParse(minStock) ?? 0) - (double.tryParse(onHand) ?? 0);
    if (d <= 0) return '0';
    // Без лишних нулей: 5.0 → 5, 5.5 → 5.5.
    return d == d.roundToDouble()
        ? d.toStringAsFixed(0)
        : d.toString();
  }
}

// ═══ Диалог прихода (без изменений в логике) ═════════════════════════════════

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
                  // Приход в деактивированный товар backend отклоняет (422) —
                  // не предлагаем его вовсе.
                  for (final p in items.where((p) => p.isActive))
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
