import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../data/inventory_repository.dart';
import '../domain/product.dart';
import '../domain/stock.dart';

/// Возврат поставщику конкретной партии товара. Причина обязательна. Нехватку в
/// партии (409) показываем текстом сервера. Возвращает true при успехе.
Future<bool?> showSupplierReturnDialog(
  BuildContext context, {
  required Product product,
  required List<StockBatch> batches,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => SupplierReturnDialog(product: product, batches: batches),
  );
}

class SupplierReturnDialog extends ConsumerStatefulWidget {
  const SupplierReturnDialog(
      {super.key, required this.product, required this.batches});

  final Product product;
  final List<StockBatch> batches;

  @override
  ConsumerState<SupplierReturnDialog> createState() =>
      _SupplierReturnDialogState();
}

class _SupplierReturnDialogState extends ConsumerState<SupplierReturnDialog> {
  final _reason = TextEditingController();
  StockBatch? _batch;
  double _quantity = 1;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Партии с положительным остатком — единственная выбирается сразу.
    final live = widget.batches.where((b) => _qty(b) > 0).toList();
    if (live.length == 1) _batch = live.first;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  double _qty(StockBatch b) => double.tryParse(b.quantity) ?? 0;

  bool get _canSave =>
      !_saving &&
      _batch != null &&
      _quantity > 0 &&
      _reason.text.trim().isNotEmpty;

  Future<void> _save() async {
    final batch = _batch;
    if (batch == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(inventoryRepositoryProvider).supplierReturn(
            productId: widget.product.id,
            batchId: batch.id,
            quantity: QuantityStepper.format(_quantity),
            reason: _reason.text.trim(),
            // Поставщик берётся из выбранной партии → движение возврата пишется
            // с ref_id=supplier_id (виден в леджере). Null у партии без
            // поставщика — оставляем как есть.
            supplierId: batch.supplierId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final live = widget.batches.where((b) => _qty(b) > 0).toList();
    return AlertDialog(
      title: const Text('Возврат поставщику'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(widget.product.name),
                subtitle:
                    Text('${widget.product.sku} · ед. ${widget.product.unit}'),
              ),
              const SizedBox(height: 8),
              if (live.isEmpty)
                const Text('Нет партий с остатком для возврата.')
              else
                DropdownButtonFormField<String>(
                  initialValue: _batch?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Партия'),
                  items: [
                    for (final b in live)
                      DropdownMenuItem(
                        value: b.id,
                        child: Text(
                          '${b.batchNo ?? 'без номера'} · '
                          'остаток ${b.quantity} · '
                          'годен до ${b.expiryDate ?? '—'} · '
                          '${formatMoney(b.unitCost)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _batch = live.firstWhere((b) => b.id == v);
                    _error = null;
                  }),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Количество',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 12),
                  QuantityStepper(
                    value: _quantity,
                    unit: widget.product.unit,
                    min: 1,
                    step: 1,
                    max: _batch == null ? null : _qty(_batch!),
                    onChanged: (v) => setState(() => _quantity = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reason,
                decoration: const InputDecoration(
                  labelText: 'Причина',
                  hintText: 'брак, пересорт, отзыв партии…',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: scheme.onErrorContainer)),
                ),
              ],
            ],
          ),
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
              : const Text('Вернуть'),
        ),
      ],
    );
  }
}
