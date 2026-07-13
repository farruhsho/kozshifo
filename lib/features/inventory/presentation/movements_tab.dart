import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../data/inventory_repository.dart';
import '../domain/movement.dart';

/// Вкладка «История движений»: журнал складских движений филиала (приход,
/// списание, коррекция, перемещения, возврат поставщику). Право `inventory.read`
/// (проверяется на входе в экран склада). Фильтр по типу и диапазону дат,
/// подгрузка страниц кнопкой «Показать ещё».
class MovementsTab extends ConsumerStatefulWidget {
  const MovementsTab({super.key, required this.branchId});

  final String branchId;

  @override
  ConsumerState<MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends ConsumerState<MovementsTab> {
  static const _pageSize = 50;

  // Все известные типы движений + «Все» (null).
  static const _types = <(String?, String)>[
    (null, 'Все типы'),
    ('receipt', 'Приход'),
    ('write_off', 'Списание'),
    ('adjustment', 'Коррекция'),
    ('transfer_in', 'Перемещение (в)'),
    ('transfer_out', 'Перемещение (из)'),
    ('supplier_return', 'Возврат поставщику'),
  ];

  String? _type;
  DateTime? _from;
  DateTime? _to;

  // Накопленные загруженные страницы (append при «Показать ещё»).
  final List<StockMovement> _loaded = [];
  int _offset = 0;
  int _total = 0;
  bool _loading = false;
  bool _appending = false;
  Object? _error;

  MovementFilter get _filter => MovementFilter(
        branchId: widget.branchId,
        movementType: _type,
        dateFrom: _from,
        // Полуоткрытый интервал [from, to): чтобы включить весь день «по», берём
        // начало следующего дня как верхнюю границу.
        dateTo: _to?.add(const Duration(days: 1)),
        offset: _offset,
        limit: _pageSize,
      );

  bool get _hasMore => _loaded.length < _total;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// Полная перезагрузка с offset=0 (смена фильтра / pull-to-refresh).
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
    });
    try {
      final page = await ref
          .read(inventoryRepositoryProvider)
          .movements(_filter.copyWith(offset: 0));
      if (!mounted) return;
      setState(() {
        _loaded
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _offset = page.items.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  /// Догрузка следующей страницы (append).
  Future<void> _loadMore() async {
    if (_appending || !_hasMore) return;
    setState(() => _appending = true);
    try {
      final page = await ref
          .read(inventoryRepositoryProvider)
          .movements(_filter.copyWith(offset: _offset));
      if (!mounted) return;
      setState(() {
        _loaded.addAll(page.items);
        _total = page.total;
        _offset += page.items.length;
        _appending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _appending = false);
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _from = DateTime(picked.year, picked.month, picked.day));
      _reload();
    }
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _to = DateTime(picked.year, picked.month, picked.day));
      _reload();
    }
  }

  void _clearDates() {
    setState(() {
      _from = null;
      _to = null;
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filterBar(context),
        const Divider(height: 1),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _filterBar(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy');
    final hasDates = _from != null || _to != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String?>(
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Тип движения',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final t in _types)
                DropdownMenuItem<String?>(value: t.$1, child: Text(t.$2)),
            ],
            onChanged: (v) {
              setState(() => _type = v);
              _reload();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(_from == null ? 'С даты' : dateFmt.format(_from!)),
                  onPressed: _pickFrom,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(_to == null ? 'По дату' : dateFmt.format(_to!)),
                  onPressed: _pickTo,
                ),
              ),
              if (hasDates)
                IconButton(
                  tooltip: 'Сбросить даты',
                  icon: const Icon(Icons.clear),
                  onPressed: _clearDates,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final msg = _error is ApiException
          ? (_error as ApiException).message
          : _error.toString();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 40, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(msg, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(
                  onPressed: _reload, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    if (_loaded.isEmpty) {
      return const Center(child: Text('Движений за период не найдено.'));
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        // +1 строка под футер (кнопка «Показать ещё» / счётчик).
        itemCount: _loaded.length + 1,
        itemBuilder: (context, i) {
          if (i == _loaded.length) return _footer(context);
          return _MovementTile(movement: _loaded[i]);
        },
      ),
    );
  }

  Widget _footer(BuildContext context) {
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          child: _appending
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : OutlinedButton.icon(
                  icon: const Icon(Icons.expand_more),
                  label: Text('Показать ещё (${_loaded.length} из $_total)'),
                  onPressed: _loadMore,
                ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Text('Всего движений: $_total',
            style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

/// Одна строка журнала движений: тип, знак+цвет количества, товар, дата,
/// причина/документ.
class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inflow = movement.isInflow;
    final qtyColor =
        inflow ? Colors.green.shade700 : scheme.error;
    // Сервер уже присылает знак; для приходов гарантируем ведущий «+».
    final qtyText = inflow && !movement.quantity.startsWith('+')
        ? '+${movement.quantity}'
        : movement.quantity;

    final product = movement.productName ?? movement.productId;
    final sku = movement.productSku;
    final when = _formatLocal(movement.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          inflow ? Icons.south_west : Icons.north_east,
          color: qtyColor,
        ),
        title: Text(product, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                movement.typeLabel,
                if (sku != null && sku.isNotEmpty) sku,
                when,
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if ((movement.reason ?? '').isNotEmpty)
              Text(movement.reason!,
                  style: Theme.of(context).textTheme.bodySmall),
            if ((movement.actorName ?? '').isNotEmpty)
              Text('Оператор: ${movement.actorName}',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: Text(
          qtyText,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: qtyColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// ISO-datetime → локальное «dd.MM.yyyy HH:mm». При непарсимой строке
  /// возвращаем исходное значение (не роняем список).
  static String _formatLocal(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd.MM.yyyy HH:mm').format(dt.toLocal());
  }
}
