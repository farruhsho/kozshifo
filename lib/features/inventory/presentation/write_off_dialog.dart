import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../data/inventory_repository.dart';
import '../domain/movement.dart';
import '../domain/product.dart';

/// Opens the write-off (списание) dialog and returns the recorded movements on
/// success, or null if cancelled. [product] pre-selects and locks the picker
/// (used from a stock row); when null the user searches for one.
/// [includeExpired] seeds the «включая просроченные» checkbox — pass true from
/// the «Истекает» tab so disposing an expired lot is a one-tap flow.
///
/// The caller is responsible for refreshing stock and showing the success
/// SnackBar — the dialog only reports the result.
Future<List<StockMovement>?> showWriteOffDialog(
  BuildContext context, {
  required String branchId,
  Product? product,
  bool includeExpired = false,
}) {
  return showDialog<List<StockMovement>>(
    context: context,
    builder: (_) => WriteOffDialog(
        branchId: branchId, product: product, includeExpired: includeExpired),
  );
}

/// Списание со склада (FEFO). Поиск товара (если не задан), количество, причина,
/// «включая просроченные». InsufficientStock (409) показываем точным текстом
/// сервера прямо в диалоге, не закрывая его.
class WriteOffDialog extends ConsumerStatefulWidget {
  const WriteOffDialog({
    super.key,
    required this.branchId,
    this.product,
    this.includeExpired = false,
  });

  final String branchId;
  final Product? product;

  /// Initial state of the «включая просроченные» checkbox (true when opened
  /// from the «Истекает» tab to dispose an expired lot).
  final bool includeExpired;

  @override
  ConsumerState<WriteOffDialog> createState() => _WriteOffDialogState();
}

class _WriteOffDialogState extends ConsumerState<WriteOffDialog> {
  final _reason = TextEditingController();
  final _search = TextEditingController();

  Product? _selected;
  double _quantity = 1; // stepper state; min is 1
  String _query = '';
  Timer? _debounce;
  bool _includeExpired = false;
  bool _saving = false;
  String? _error; // server/validation message shown inline

  @override
  void initState() {
    super.initState();
    _selected = widget.product;
    _includeExpired = widget.includeExpired;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _reason.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  /// Quantity is valid only if strictly positive. The stepper enforces min: 1,
  /// so this stays > 0 by construction; we keep the guard to mirror the backend
  /// (gt=0) for the button-enabled state.
  bool get _qtyValid => _quantity > 0;

  bool get _canSave =>
      !_saving &&
      _selected != null &&
      _qtyValid &&
      _reason.text.trim().isNotEmpty;

  Future<void> _save() async {
    final product = _selected;
    if (product == null || !_qtyValid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final movements =
          await ref.read(inventoryRepositoryProvider).writeOff(
                productId: product.id,
                branchId: widget.branchId,
                // API expects a '.'-normalized numeric string.
                quantity: QuantityStepper.format(_quantity),
                reason: _reason.text.trim(),
                includeExpired: _includeExpired,
              );
      if (mounted) Navigator.of(context).pop(movements);
    } on ApiException catch (e) {
      // 409 InsufficientStock и прочие отказы — точный текст сервера в диалоге.
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
    return AlertDialog(
      title: const Text('Списание со склада'),
      content: SizedBox(
        width: 440,
        // Scrollable so the inline error box (and a tall product picker) never
        // overflow the dialog's bounded height on short screens.
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selected != null && widget.product != null)
              // Товар задан вызывающим экраном — фиксируем, без поиска.
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(_selected!.name),
                subtitle: Text('${_selected!.sku} · ед. ${_selected!.unit}'),
              )
            else
              _ProductPicker(
                search: _search,
                query: _query,
                selected: _selected,
                onSearch: _onSearch,
                onPick: (p) => setState(() {
                  _selected = p;
                  _error = null;
                }),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Количество',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 12),
                QuantityStepper(
                  value: _quantity,
                  unit: _selected?.unit,
                  min: 1,
                  step: 1,
                  onChanged: (v) => setState(() => _quantity = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Причина',
                hintText: 'порча, бой, утилизация…',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              value: _includeExpired,
              onChanged: (v) =>
                  setState(() => _includeExpired = v ?? false),
              title: const Text('Включая просроченные партии'),
              subtitle: const Text(
                  'Для утилизации просроченных лотов (иначе они не списываются)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
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
              : const Text('Списать'),
        ),
      ],
    );
  }
}

/// Searchable product picker for the write-off dialog. Debounced query feeds the
/// server-side `q` filter; the chosen product is shown above the field.
class _ProductPicker extends ConsumerWidget {
  const _ProductPicker({
    required this.search,
    required this.query,
    required this.selected,
    required this.onSearch,
    required this.onPick,
  });

  final TextEditingController search;
  final String query;
  final Product? selected;
  final ValueChanged<String> onSearch;
  final ValueChanged<Product> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(productSearchProvider(query));
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle_outline, color: scheme.primary),
            title: Text(selected!.name),
            subtitle: Text('${selected!.sku} · ед. ${selected!.unit}'),
            trailing: const Icon(Icons.edit_outlined, size: 18),
          ),
        TextField(
          controller: search,
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search),
            labelText: 'Товар (поиск по названию, SKU, штрихкоду)',
          ),
          onChanged: onSearch,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 160,
          child: results.when(
            data: (items) {
              // Deactivated products are NOT filtered out: the backend allows
              // writing off their residual stock (e.g. a discontinued SKU still
              // on the shelf) — hiding them would dead-end disposal here.
              if (items.isEmpty) {
                return const Center(child: Text('Ничего не найдено.'));
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final p = items[i];
                  final isSel = p.id == selected?.id;
                  return ListTile(
                    dense: true,
                    selected: isSel,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(p.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${p.sku} · ${p.typeLabel}'
                        '${p.isActive ? '' : ' · неактивен'}'),
                    onTap: () => onPick(p),
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('$e',
                  style: TextStyle(color: scheme.error),
                  textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }
}
