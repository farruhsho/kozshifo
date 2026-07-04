import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/domain/admin_branch.dart';
import '../data/inventory_repository.dart';
import '../domain/product.dart';

/// Перемещение товара в другой филиал (FEFO из текущего). Товар зафиксирован
/// вызывающей строкой остатков. Нехватку (409) показываем текстом сервера в
/// диалоге. Возвращает true при успехе.
Future<bool?> showTransferDialog(
  BuildContext context, {
  required String fromBranchId,
  required Product product,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) =>
        TransferDialog(fromBranchId: fromBranchId, product: product),
  );
}

class TransferDialog extends ConsumerStatefulWidget {
  const TransferDialog(
      {super.key, required this.fromBranchId, required this.product});

  final String fromBranchId;
  final Product product;

  @override
  ConsumerState<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<TransferDialog> {
  String? _toBranchId;
  double _quantity = 1;
  bool _saving = false;
  String? _error;

  bool get _canSave =>
      !_saving && _toBranchId != null && _quantity > 0;

  Future<void> _save() async {
    final to = _toBranchId;
    if (to == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(inventoryRepositoryProvider).transfer(
            productId: widget.product.id,
            fromBranchId: widget.fromBranchId,
            toBranchId: to,
            quantity: QuantityStepper.format(_quantity),
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
    final branches = ref.watch(adminBranchesProvider);
    return AlertDialog(
      title: const Text('Перемещение в филиал'),
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
              branches.when(
                data: (items) {
                  // Текущий филиал исключаем — перемещать в себя нельзя.
                  final others = items
                      .where((b) => b.id != widget.fromBranchId && b.isActive)
                      .toList();
                  if (others.isEmpty) {
                    return const Text('Нет других филиалов для перемещения.');
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _toBranchId,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Филиал-получатель'),
                    items: [
                      for (final AdminBranch b in others)
                        DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _toBranchId = v;
                      _error = null;
                    }),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) =>
                    Text('$e', style: TextStyle(color: scheme.error)),
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
                    onChanged: (v) => setState(() => _quantity = v),
                  ),
                ],
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
              : const Text('Переместить'),
        ),
      ],
    );
  }
}
