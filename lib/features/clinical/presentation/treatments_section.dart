import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../reception/data/reception_repository.dart';
import '../data/clinical_repository.dart';
import '../domain/treatment.dart';

/// Секция «Назначения (лечение)» карты пациента: процедуры и медикаменты
/// визита; выдача медикамента списывает его со склада.
class TreatmentsSection extends ConsumerWidget {
  const TreatmentsSection(
      {super.key, required this.visitId, required this.patientId});

  final String visitId;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatments = ref.watch(visitTreatmentsProvider(visitId));
    final user = ref.watch(authControllerProvider).user;
    final canPrescribe = user?.can('treatments.prescribe') ?? false;
    final canPerform = user?.can('treatments.perform') ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Назначения (лечение)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            AsyncValueWidget<List<Treatment>>(
              value: treatments,
              onRetry: () => ref.invalidate(visitTreatmentsProvider(visitId)),
              builder: (items) {
                if (items.isEmpty) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Назначений по этому визиту нет.'),
                  );
                }
                return Column(
                  children: [
                    for (final t in items)
                      _treatmentTile(context, ref, t, canPerform, canPrescribe),
                  ],
                );
              },
            ),
            if (canPrescribe) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _add(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить назначение'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _treatmentTile(BuildContext context, WidgetRef ref, Treatment t,
      bool canPerform, bool canPrescribe) {
    final statusColor = switch (t.status) {
      'prescribed' => Colors.orange,
      'done' => Colors.green,
      _ => Colors.grey,
    };
    final details = [
      if (t.quantity != null) 'кол-во: ${t.quantity}',
      if (t.isCourse) 'сеанс ${t.sessionProgress}',
      if (t.instructions != null) t.instructions!,
    ].join(' · ');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(t.isMedication
          ? Icons.medication_outlined
          : Icons.healing_outlined),
      title: Text('${t.name} · ${t.kindLabel}'),
      subtitle: details.isEmpty
          ? null
          : Text(details, style: Theme.of(context).textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(t.statusLabel),
            backgroundColor: statusColor.withValues(alpha: 0.15),
            labelStyle: TextStyle(color: statusColor),
            side: BorderSide.none,
          ),
          if (canPerform && t.isPrescribed && t.isMedication)
            TextButton(
              onPressed: () => _act(context, ref,
                  () => ref.read(clinicalRepositoryProvider).dispenseTreatment(t.id),
                  'Медикамент выдан, остаток списан'),
              child: const Text('Выдать'),
            ),
          // Многодневный курс: отмечаем сеансы по одному; на последнем сеансе
          // бэкенд сам переводит назначение в «выполнено».
          if (canPerform && t.isPrescribed && !t.isMedication && t.isCourse)
            TextButton(
              onPressed: () => _act(context, ref,
                  () => ref.read(clinicalRepositoryProvider).markTreatmentSession(t.id),
                  'Сеанс отмечен'),
              child: const Text('Отметить сеанс'),
            ),
          if (canPerform && t.isPrescribed && !t.isMedication && !t.isCourse)
            TextButton(
              onPressed: () => _act(context, ref,
                  () => ref.read(clinicalRepositoryProvider).completeTreatment(t.id),
                  'Процедура выполнена'),
              child: const Text('Выполнено'),
            ),
          if (canPrescribe && t.isPrescribed)
            TextButton(
              onPressed: () => _act(context, ref,
                  () => ref.read(clinicalRepositoryProvider).cancelTreatment(t.id),
                  'Назначение отменено'),
              child: const Text('Отменить'),
            ),
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context, WidgetRef ref,
      Future<Treatment> Function() action, String successMessage) async {
    try {
      await action();
      if (!context.mounted) return;
      ref.invalidate(visitTreatmentsProvider(visitId));
      _snack(context, successMessage);
    } catch (e) {
      // 409 при выдаче несёт сообщение о нехватке на складе — показываем как есть.
      if (context.mounted) _snack(context, e.toString(), error: true);
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _AddTreatmentDialog(visitId: visitId),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(visitTreatmentsProvider(visitId));
      _snack(context, 'Назначение добавлено');
    }
  }

  void _snack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }
}

/// Диалог нового назначения: процедура (название + инструкция) или
/// медикамент (товар со склада → название автоматически, количество).
class _AddTreatmentDialog extends ConsumerStatefulWidget {
  const _AddTreatmentDialog({required this.visitId});

  final String visitId;

  @override
  ConsumerState<_AddTreatmentDialog> createState() =>
      _AddTreatmentDialogState();
}

class _AddTreatmentDialogState extends ConsumerState<_AddTreatmentDialog> {
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _instructions = TextEditingController();
  final _price = TextEditingController();
  final _sessions = TextEditingController(text: '1');
  String _kind = 'procedure';
  String? _productId;
  String? _serviceId; // optional paid service → bills the visit
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _instructions.dispose();
    _price.dispose();
    _sessions.dispose();
    super.dispose();
  }

  bool get _isMedication => _kind == 'medication';

  /// Число сеансов курса (>=1); пустое/битое поле → 1.
  int get _sessionsTotal {
    final n = int.tryParse(_sessions.text.trim()) ?? 1;
    return n < 1 ? 1 : n;
  }

  /// C7 — soft stock advisory at prescribe time: warn (never block) when the
  /// requested medication quantity exceeds usable on-hand stock. The hard guard
  /// stays at dispense (409); this just gives the doctor early feedback.
  Widget _stockAdvisory() {
    if (_productId == null) return const SizedBox.shrink();
    final branchId = ref.watch(authControllerProvider).user?.branchId;
    if (branchId == null) return const SizedBox.shrink();
    return ref.watch(stockProvider(branchId)).maybeWhen(
          data: (rows) {
            final matches = rows.where((r) => r.product.id == _productId);
            if (matches.isEmpty) return const SizedBox.shrink();
            final row = matches.first;
            final onHand = double.tryParse(row.onHand) ?? 0;
            final want =
                double.tryParse(_quantity.text.trim().replaceAll(',', '.')) ?? 0;
            final short = want > onHand;
            final color = short ? Colors.orange.shade800 : null;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    short
                        ? Icons.warning_amber_rounded
                        : Icons.inventory_2_outlined,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      short
                          ? 'Остаток ${row.onHand} — меньше требуемого, но списать можно'
                          : 'Остаток: ${row.onHand}',
                      style: TextStyle(
                          fontSize: 12,
                          color: color ?? Theme.of(context).hintColor),
                    ),
                  ),
                ],
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }

  bool get _canSave =>
      !_saving &&
      _name.text.trim().isNotEmpty &&
      (!_isMedication ||
          (_productId != null && _quantity.text.trim().isNotEmpty));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final instructions = _instructions.text.trim();
      await ref.read(clinicalRepositoryProvider).prescribeTreatment(
            visitId: widget.visitId,
            kind: _kind,
            name: _name.text.trim(),
            productId: _isMedication ? _productId : null,
            // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
            quantity: _isMedication
                ? _quantity.text.trim().replaceAll(',', '.')
                : null,
            instructions: instructions.isEmpty ? null : instructions,
            serviceId: _serviceId,
            // Цену шлём только при выбранной услуге; пусто → каталожная цена.
            unitPrice: _serviceId != null && _price.text.trim().isNotEmpty
                ? _price.text.trim().replaceAll(',', '.')
                : null,
            // Медикамент выдаётся один раз — сеансов у него нет.
            sessionsTotal: _isMedication ? 1 : _sessionsTotal,
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
    final services = ref.watch(activeServicesProvider);

    return AlertDialog(
      title: const Text('Новое назначение'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'procedure', label: Text('Процедура')),
                ButtonSegment(value: 'medication', label: Text('Медикамент')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                if (!_isMedication) _productId = null;
              }),
            ),
            const SizedBox(height: 16),
            if (_isMedication) ...[
              products.when(
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _productId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Препарат со склада'),
                  items: [
                    // Деактивированный товар назначать нельзя (та же
                    // active-only конвенция, что у услуг и типов операций).
                    for (final p in items.where((p) => p.isActive))
                      DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (${p.unit})',
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (id) => setState(() {
                    _productId = id;
                    if (id != null) {
                      // Название назначения берём из товара.
                      _name.text =
                          items.where((p) => p.id == id).first.name;
                    }
                  }),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Text('$e',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название'),
              onChanged: (_) => setState(() {}),
            ),
            // Сеансы — только для процедур; медикамент выдаётся один раз.
            if (!_isMedication) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _sessions,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Сеансов',
                    helperText: 'Многодневный курс; 1 = одноразово'),
              ),
            ],
            if (_isMedication) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _quantity,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Количество'),
                onChanged: (_) => setState(() {}),
              ),
              _stockAdvisory(),
            ],
            const SizedBox(height: 12),
            // Опциональная привязка к платной услуге → биллит визиту (доход
            // лечения; иначе клиническое назначение без оплаты).
            services.when(
              data: (items) => DropdownButtonFormField<String?>(
                initialValue: _serviceId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Платная услуга (необязательно)'),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('— без оплаты —')),
                  for (final s in items.where((s) => s.isActive))
                    DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text('${s.name} · ${formatMoney(s.price)}',
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (id) => setState(() {
                  _serviceId = id;
                  // Префилл цены из услуги — её можно переопределить.
                  if (id != null) {
                    _price.text = items.firstWhere((s) => s.id == id).price;
                  } else {
                    _price.clear();
                  }
                }),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text('$e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            if (_serviceId != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Цена', helperText: 'Можно изменить'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _instructions,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Инструкция (необязательно)',
                  hintText: 'например: по 1 капле 3 раза в день'),
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
