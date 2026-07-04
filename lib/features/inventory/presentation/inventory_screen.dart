import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/inventory_repository.dart';
import '../domain/product.dart';
import '../domain/stock.dart';
import 'stocktake_tab.dart';
import 'supplier_return_dialog.dart';
import 'transfer_dialog.dart';
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
    final canStocktake = user?.can('inventory.stocktake') ?? false;

    if (branchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Склад')),
        body: const Center(
            child: Text('У пользователя не задан филиал — склад недоступен.')),
      );
    }

    // «Инвентаризация» видна только при праве inventory.stocktake — держим
    // список вкладок и вьюшек согласованным по длине.
    final tabs = <Tab>[
      const Tab(text: 'Остатки'),
      const Tab(text: 'Дефицит'),
      const Tab(text: 'Истекает'),
      const Tab(text: 'К заказу'),
      if (canStocktake) const Tab(text: 'Инвентаризация'),
    ];
    final views = <Widget>[
      _StockListTab(
          branchId: branchId, canWriteOff: canWriteOff, canManage: canManage),
      _LowStockTab(
          branchId: branchId, canWriteOff: canWriteOff, canManage: canManage),
      _ExpiringTab(branchId: branchId, canWriteOff: canWriteOff),
      _ReorderTab(branchId: branchId, canManage: canManage),
      if (canStocktake) StocktakeTab(branchId: branchId),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Склад'),
          actions: [
            IconButton(
              tooltip: 'Обновить',
              onPressed: () {
                ref.invalidate(stockProvider(branchId));
                ref.invalidate(reorderSuggestionsProvider(branchId));
                if (canStocktake) {
                  ref.invalidate(stockCountsProvider(branchId));
                }
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(isScrollable: true, tabs: tabs),
        ),
        floatingActionButton: _Fab(
          branchId: branchId,
          canManage: canManage,
          canWriteOff: canWriteOff,
        ),
        body: TabBarView(children: views),
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
  const _StockListTab(
      {required this.branchId,
      required this.canWriteOff,
      required this.canManage});

  final String branchId;
  final bool canWriteOff;
  final bool canManage;

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
                  canManage: widget.canManage,
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
  const _LowStockTab(
      {required this.branchId,
      required this.canWriteOff,
      required this.canManage});

  final String branchId;
  final bool canWriteOff;
  final bool canManage;

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
            canManage: canManage,
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
    this.canManage = false,
    this.showDeficit = false,
  });

  final StockRow row;
  final String branchId;
  final bool canWriteOff;
  final bool canManage;
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
          if (canWriteOff || canManage) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (canManage)
                    TextButton.icon(
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Переместить'),
                      onPressed: () async {
                        final ok = await showTransferDialog(context,
                            fromBranchId: branchId, product: p);
                        if (ok == true && context.mounted) {
                          ref.invalidate(stockProvider(branchId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Перемещение выполнено')),
                          );
                        }
                      },
                    ),
                  if (canManage)
                    TextButton.icon(
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: const Text('Возврат поставщику'),
                      onPressed: () async {
                        final ok = await showSupplierReturnDialog(context,
                            product: p, batches: row.batches);
                        if (ok == true && context.mounted) {
                          ref.invalidate(stockProvider(branchId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Возврат оформлен')),
                          );
                        }
                      },
                    ),
                  if (canWriteOff)
                    TextButton.icon(
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
                ],
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

// ═══ Вкладка 4: К заказу (reorder-suggestions) ═══════════════════════════════

/// «Что заказать»: активные товары на/ниже min_stock с подсказкой количества
/// (до 2× мин), самые дефицитные сверху. Кнопка «Оформить приход на всё»
/// открывает существующий диалог прихода, предзаполненный подсказками.
class _ReorderTab extends ConsumerWidget {
  const _ReorderTab({required this.branchId, required this.canManage});

  final String branchId;
  final bool canManage;

  Future<void> _orderAll(
      BuildContext context, WidgetRef ref, List<ReorderSuggestion> sugg) async {
    final prefill = [
      for (final s in sugg)
        _ReceiptPrefill(product: s.product, quantity: s.suggestedQty),
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ReceiptDialog(branchId: branchId, prefill: prefill),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(stockProvider(branchId));
      ref.invalidate(reorderSuggestionsProvider(branchId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Приход оформлен')));
    }
  }

  Future<void> _orderOne(
      BuildContext context, WidgetRef ref, ReorderSuggestion s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ReceiptDialog(
        branchId: branchId,
        prefill: [_ReceiptPrefill(product: s.product, quantity: s.suggestedQty)],
      ),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(stockProvider(branchId));
      ref.invalidate(reorderSuggestionsProvider(branchId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Приход оформлен')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sugg = ref.watch(reorderSuggestionsProvider(branchId));
    final scheme = Theme.of(context).colorScheme;
    return AsyncValueWidget<List<ReorderSuggestion>>(
      value: sugg,
      onRetry: () => ref.invalidate(reorderSuggestionsProvider(branchId)),
      builder: (rows) {
        if (rows.isEmpty) {
          return const Center(
              child: Text('Нечего заказывать — остатки в норме.'));
        }
        return Column(
          children: [
            if (canManage)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.playlist_add_check_outlined),
                    label: Text('Оформить приход на всё (${rows.length})'),
                    onPressed: () => _orderAll(context, ref, rows),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final s = rows[i];
                  final p = s.product;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Icons.add_shopping_cart_outlined,
                          color: scheme.primary),
                      title: Text(p.name),
                      subtitle: Text('${p.sku} · '
                          'остаток ${_trimQty(s.onHand)} / '
                          'мин ${_trimQty(s.minStock)} ${p.unit}'),
                      trailing: canManage
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _orderChip(scheme, s, p.unit),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _orderOne(context, ref, s),
                                  child: const Text('Заказать'),
                                ),
                              ],
                            )
                          : _orderChip(scheme, s, p.unit),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _orderChip(ColorScheme scheme, ReorderSuggestion s, String unit) =>
      Chip(
        label: Text('заказать ${_trimQty(s.suggestedQty)} $unit'),
        backgroundColor: scheme.primary.withValues(alpha: 0.15),
        labelStyle:
            TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      );
}

/// Decimal-строку количества показываем без лишних нулей: 5.0 → 5, 5.5 → 5.5.
String _trimQty(String value) {
  final d = double.tryParse(value);
  if (d == null) return value;
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toString();
}

// ═══ Диалог прихода ══════════════════════════════════════════════════════════

/// Предзаполненная строка прихода (товар уже выбран, количество подсказано).
class _ReceiptPrefill {
  const _ReceiptPrefill({required this.product, required this.quantity});
  final Product product;
  final String quantity;
}

/// Одна строка диалога прихода: товар + количество/цена/партия/срок. При
/// предзаполнении товар зафиксирован (из подсказки), иначе выбирается в дропдауне.
class _ReceiptLine {
  _ReceiptLine({this.product, String quantity = ''})
      : productId = product?.id,
        quantity = TextEditingController(text: quantity);

  /// Зафиксированный товар (предзаполненная строка) либо null (ручной выбор).
  final Product? product;
  String? productId;
  final TextEditingController quantity;
  final TextEditingController unitCost = TextEditingController();
  final TextEditingController batchNo = TextEditingController();
  final TextEditingController expiry = TextEditingController();

  void dispose() {
    quantity.dispose();
    unitCost.dispose();
    batchNo.dispose();
    expiry.dispose();
  }

  bool get isValid =>
      productId != null && quantity.text.trim().isNotEmpty;
}

/// Диалог прихода: одна или несколько позиций (товар, количество, цена закупки,
/// партия, срок годности). Открывается как из FAB (одна пустая строка), так и из
/// вкладки «К заказу» с [prefill] (строка на каждый предложенный товар).
class _ReceiptDialog extends ConsumerStatefulWidget {
  const _ReceiptDialog({required this.branchId, this.prefill});

  final String branchId;

  /// Предзаполненные позиции (из reorder-подсказок). Null/пусто → одна пустая
  /// строка с дропдауном товара (поведение прежнего диалога).
  final List<_ReceiptPrefill>? prefill;

  @override
  ConsumerState<_ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<_ReceiptDialog> {
  late final List<_ReceiptLine> _lines;
  bool _saving = false;

  bool get _isPrefilled => widget.prefill != null && widget.prefill!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    _lines = (prefill != null && prefill.isNotEmpty)
        ? [
            for (final p in prefill)
              _ReceiptLine(product: p.product, quantity: p.quantity),
          ]
        : [_ReceiptLine()];
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final lines = _lines.where((l) => l.isValid).toList();
    if (lines.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(inventoryRepositoryProvider).createReceipt(
            branchId: widget.branchId,
            items: [
              for (final l in lines)
                (
                  productId: l.productId!,
                  // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
                  quantity: l.quantity.text.trim().replaceAll(',', '.'),
                  // Цена закупки необязательна — backend подставит 0.00.
                  unitCost: l.unitCost.text.trim().isEmpty
                      ? '0'
                      : l.unitCost.text.trim().replaceAll(',', '.'),
                  batchNo: l.batchNo.text.trim().isEmpty
                      ? null
                      : l.batchNo.text.trim(),
                  expiryDate: l.expiry.text.trim().isEmpty
                      ? null
                      : l.expiry.text.trim(),
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
    final canSave = !_saving && _lines.any((l) => l.isValid);

    return AlertDialog(
      title: Text(_isPrefilled
          ? 'Приход по подсказкам (${_lines.length})'
          : 'Приход товара'),
      content: SizedBox(
        width: 460,
        child: _isPrefilled
            ? _prefilledBody()
            : _SingleLineBody(line: _lines.first, onChanged: () => setState(() {})),
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

  /// Предзаполненный режим: товар на строку зафиксирован, количество/цена
  /// редактируются. Список прокручивается — позиций может быть много.
  Widget _prefilledBody() => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _lines.length,
          separatorBuilder: (_, _) => const Divider(height: 24),
          itemBuilder: (_, i) {
            final l = _lines[i];
            final p = l.product!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.name} (${p.unit})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                Text(p.sku,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: l.quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Количество'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: l.unitCost,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Цена, сум', hintText: '0'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
}

/// Тело диалога в ручном режиме — прежний одностраничный приход (одна позиция).
class _SingleLineBody extends ConsumerWidget {
  const _SingleLineBody({required this.line, required this.onChanged});

  final _ReceiptLine line;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        products.when(
          data: (items) => DropdownButtonFormField<String>(
            initialValue: line.productId,
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
            onChanged: (v) {
              line.productId = v;
              onChanged();
            },
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
          controller: line.quantity,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Количество'),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: line.unitCost,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'Цена за единицу, сум'),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: line.batchNo,
          decoration: const InputDecoration(
              labelText: 'Номер партии (необязательно)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: line.expiry,
          decoration: const InputDecoration(
              labelText: 'Годен до (ГГГГ-ММ-ДД, необязательно)',
              hintText: '2027-01-01'),
        ),
      ],
    );
  }
}
