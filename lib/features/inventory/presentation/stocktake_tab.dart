import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/inventory_repository.dart';
import '../domain/stock_count.dart';

/// Вкладка «Инвентаризация»: список пересчётов филиала + кнопка «Новый пересчёт».
/// Открытый черновик ведёт к экрану ввода факта и проведения.
class StocktakeTab extends ConsumerWidget {
  const StocktakeTab({super.key, required this.branchId});

  final String branchId;

  Future<void> _openNew(BuildContext context, WidgetRef ref) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новый пересчёт'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Примечание (необязательно)',
            hintText: 'плановая инвентаризация, месяц…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final count = await ref
          .read(inventoryRepositoryProvider)
          .createStockCount(branchId,
              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
      ref.invalidate(stockCountsProvider(branchId));
      if (context.mounted) {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StockCountDetailScreen(
              branchId: branchId, countId: count.id),
        ));
        ref.invalidate(stockCountsProvider(branchId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(stockCountsProvider(branchId));
    return Stack(
      children: [
        AsyncValueWidget<List<StockCount>>(
          value: counts,
          onRetry: () => ref.invalidate(stockCountsProvider(branchId)),
          builder: (rows) {
            if (rows.isEmpty) {
              return const Center(
                  child: Text('Пересчётов пока нет — начните новый.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: rows.length,
              itemBuilder: (_, i) => _CountCard(branchId: branchId, count: rows[i]),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'stocktake_fab',
            onPressed: () => _openNew(context, ref),
            icon: const Icon(Icons.playlist_add_check_outlined),
            label: const Text('Новый пересчёт'),
          ),
        ),
      ],
    );
  }
}

class _CountCard extends ConsumerWidget {
  const _CountCard({required this.branchId, required this.count});

  final String branchId;
  final StockCount count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDraft = count.isDraft;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isDraft ? Icons.edit_note_outlined : Icons.task_alt_outlined,
          color: isDraft ? scheme.tertiary : scheme.primary,
        ),
        title: Text(count.note?.isNotEmpty == true
            ? count.note!
            : 'Пересчёт от ${_date(count.createdAt)}'),
        subtitle: Text('${count.linesCount} позиций · '
            'излишек +${_trim(count.surplusTotal)} · '
            'недостача −${_trim(count.shortageTotal)}'),
        trailing: Chip(
          label: Text(isDraft ? 'черновик' : 'проведён'),
          backgroundColor:
              (isDraft ? scheme.tertiary : scheme.primary).withValues(alpha: 0.15),
          labelStyle:
              TextStyle(color: isDraft ? scheme.tertiary : scheme.primary),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                StockCountDetailScreen(branchId: branchId, countId: count.id),
          ));
          ref.invalidate(stockCountsProvider(branchId));
        },
      ),
    );
  }

  static String _date(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

String _trim(String value) {
  final d = double.tryParse(value);
  if (d == null) return value;
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toString();
}

// ═══ Экран одного пересчёта: ввод факта по строкам + проведение ══════════════

/// Detail-провайдер: одна инвентаризация со строками. Не autoDispose-family на
/// экране, чтобы редактирование строк не сбрасывало прокрутку — держим локально.
final _stockCountProvider =
    FutureProvider.autoDispose.family<StockCount, String>(
        (ref, countId) =>
            ref.watch(inventoryRepositoryProvider).stockCount(countId));

class StockCountDetailScreen extends ConsumerWidget {
  const StockCountDetailScreen(
      {super.key, required this.branchId, required this.countId});

  final String branchId;
  final String countId;

  Future<void> _commit(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Провести инвентаризацию?'),
        content: const Text(
            'Расхождения будут применены к остаткам: излишек — приход, '
            'недостача — списание. Действие необратимо.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Провести'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(inventoryRepositoryProvider).commitStockCount(countId);
      ref.invalidate(_stockCountProvider(countId));
      ref.invalidate(stockProvider(branchId));
      ref.invalidate(reorderSuggestionsProvider(branchId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Инвентаризация проведена')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_stockCountProvider(countId));
    return Scaffold(
      appBar: AppBar(title: const Text('Инвентаризация')),
      body: AsyncValueWidget<StockCount>(
        value: count,
        onRetry: () => ref.invalidate(_stockCountProvider(countId)),
        builder: (c) {
          if (c.lines.isEmpty) {
            return const Center(
                child: Text('В филиале нет остатков для пересчёта.'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.isDraft
                            ? 'Внесите фактический остаток в каждой строке.'
                            : 'Пересчёт проведён.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text('излишек +${_trim(c.surplusTotal)} · '
                        'недостача −${_trim(c.shortageTotal)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                  itemCount: c.lines.length,
                  itemBuilder: (_, i) => _LineTile(
                    countId: countId,
                    line: c.lines[i],
                    editable: c.isDraft,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: count.maybeWhen(
        data: (c) => c.isDraft
            ? FloatingActionButton.extended(
                onPressed: () => _commit(context, ref),
                icon: const Icon(Icons.task_alt_outlined),
                label: const Text('Провести'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}

class _LineTile extends ConsumerStatefulWidget {
  const _LineTile(
      {required this.countId, required this.line, required this.editable});

  final String countId;
  final StockCountLine line;
  final bool editable;

  @override
  ConsumerState<_LineTile> createState() => _LineTileState();
}

class _LineTileState extends ConsumerState<_LineTile> {
  late final TextEditingController _counted;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _counted = TextEditingController(text: _trim(widget.line.countedQty));
  }

  @override
  void dispose() {
    _counted.dispose();
    super.dispose();
  }

  Future<void> _commitEdit() async {
    final raw = _counted.text.trim().replaceAll(',', '.');
    if (raw.isEmpty || raw == _trim(widget.line.countedQty)) return;
    setState(() => _saving = true);
    try {
      await ref.read(inventoryRepositoryProvider).updateCountLine(
            countId: widget.countId,
            lineId: widget.line.id,
            countedQty: raw,
          );
      ref.invalidate(_stockCountProvider(widget.countId));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = widget.line;
    final variance = line.varianceValue;
    // Светофор: расхождение отсутствует — зелёный, есть — оранжевый/красный.
    final Color varColor = variance == 0
        ? scheme.primary
        : (variance > 0 ? scheme.tertiary : scheme.error);
    final varLabel = variance == 0
        ? '0'
        : (variance > 0 ? '+${_trim(line.variance)}' : _trim(line.variance));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: varColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${line.productSku} · партия ${line.batchNo ?? '—'} · '
                    'ожидалось ${_trim(line.expectedQty)} ${line.unit}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 88,
              child: TextField(
                controller: _counted,
                enabled: widget.editable && !_saving,
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'факт',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: _commitEdit,
                onTapOutside: (_) => _commitEdit(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: Text(
                varLabel,
                textAlign: TextAlign.end,
                style: TextStyle(color: varColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
