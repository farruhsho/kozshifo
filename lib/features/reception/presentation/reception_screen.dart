import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../../patients/data/patients_repository.dart';
import '../../patients/domain/patient.dart';
import '../../patients/presentation/patients_screen.dart' show RegisterPatientDialog;
import '../data/reception_repository.dart';
import '../domain/payment_result.dart';
import '../domain/reception_visit.dart';
import '../domain/service.dart';

/// Ресепшен: пациент → услуги → визит → оплата → чек + талон очереди.
/// Денежная математика остаётся на сервере; корзина показывает предварительный
/// итог, авторитетные total/balance приходят с созданным визитом.
class ReceptionScreen extends ConsumerStatefulWidget {
  const ReceptionScreen({super.key});

  @override
  ConsumerState<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends ConsumerState<ReceptionScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Patient> _found = const [];
  bool _searching = false;

  Patient? _patient;
  final Map<Service, int> _cart = {};
  ReceptionVisit? _visit;
  PaymentResult? _result;
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Пациент ────────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value.trim()));
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() => _found = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final page = await ref.read(patientsRepositoryProvider).list(q: q, limit: 8);
      if (mounted) setState(() => _found = page.items);
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _registerNew() async {
    final created = await showDialog<Patient>(
      context: context,
      builder: (_) => const RegisterPatientDialog(),
    );
    if (created != null) setState(() => _patient = created);
  }

  // ── Визит и оплата ─────────────────────────────────────────────────────────

  Future<void> _openVisit() async {
    final patient = _patient;
    final branchId =
        patient?.branchId ?? ref.read(authControllerProvider).user?.branchId;
    if (patient == null || _cart.isEmpty) return;
    if (branchId == null) {
      _snack('У пользователя не задан филиал', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final visit = await ref.read(receptionRepositoryProvider).createVisit(
            patientId: patient.id,
            branchId: branchId,
            items: [
              for (final e in _cart.entries)
                (serviceId: e.key.id, quantity: e.value),
            ],
          );
      if (mounted) setState(() => _visit = visit);
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takePayment() async {
    final visit = _visit;
    if (visit == null) return;
    final result = await showDialog<PaymentResult>(
      context: context,
      builder: (_) => _PaymentDialog(visit: visit),
    );
    if (result != null) setState(() => _result = result);
  }

  void _reset() {
    setState(() {
      _patient = null;
      _cart.clear();
      _visit = null;
      _result = null;
      _found = const [];
      _searchController.clear();
    });
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final canBill =
        (user?.can('visits.create') ?? false) && (user?.can('payments.create') ?? false);
    final services = ref.watch(activeServicesProvider);
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _patientSection(canBill),
        const SizedBox(height: 12),
        _servicesSection(services, canBill),
      ],
    );
    final right = _cartSection(canBill);

    return Scaffold(
      appBar: AppBar(title: const Text('Ресепшен')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: left),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: right),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [left, const SizedBox(height: 16), right],
              ),
      ),
    );
  }

  Widget _patientSection(bool canBill) {
    return _card('1. Пациент', [
      if (_patient == null) ...[
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Поиск: ФИО, карта, телефон',
                  prefixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              height: 16, width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : const Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: canBill ? _registerNew : null,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Новый'),
            ),
          ],
        ),
        for (final p in _found)
          ListTile(
            dense: true,
            leading: CircleAvatar(radius: 14, child: Text(p.initials)),
            title: Text(p.fullName),
            subtitle: Text([p.mrn, if (p.phone != null) p.phone!].join('  ·  ')),
            onTap: () => setState(() => _patient = p),
          ),
      ] else
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(_patient!.initials)),
          title: Text(_patient!.fullName),
          subtitle: Text(_patient!.mrn),
          trailing: _visit == null
              ? IconButton(
                  tooltip: 'Сменить пациента',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _patient = null),
                )
              : null,
        ),
    ]);
  }

  Widget _servicesSection(AsyncValue<List<Service>> services, bool canBill) {
    final locked = _visit != null;
    return _card('2. Услуги', [
      AsyncValueWidget<List<Service>>(
        value: services,
        onRetry: () => ref.invalidate(activeServicesProvider),
        builder: (items) => Column(
          children: [
            for (final s in items)
              ListTile(
                dense: true,
                title: Text(s.name),
                subtitle: Text(s.code),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatMoney(s.price)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: (canBill && !locked)
                          ? () => setState(() =>
                              _cart.update(s, (q) => q + 1, ifAbsent: () => 1))
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ]);
  }

  Widget _cartSection(bool canBill) {
    final result = _result;
    final visit = _visit;
    final preTotal =
        cartTotalValue(_cart.entries.map((e) => (e.key.price, e.value)));

    return _card('3. Оплата', [
      if (_cart.isEmpty && visit == null)
        const Text('Добавьте услуги из списка.')
      else ...[
        for (final e in _cart.entries)
          Row(
            children: [
              Expanded(child: Text(e.key.name, overflow: TextOverflow.ellipsis)),
              if (visit == null) ...[
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () => setState(() {
                    final q = _cart[e.key]! - 1;
                    if (q <= 0) {
                      _cart.remove(e.key);
                    } else {
                      _cart[e.key] = q;
                    }
                  }),
                ),
                Text('${e.value}'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => setState(() => _cart[e.key] = e.value + 1),
                ),
              ] else
                Text('× ${e.value}'),
            ],
          ),
        const Divider(),
        Row(
          children: [
            const Text('Итого:'),
            const Spacer(),
            Text(
              visit != null
                  ? formatMoney(visit.totalAmount)
                  : '≈ ${formatMoney(preTotal.toStringAsFixed(2))}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      if (result != null)
        _resultCard(result)
      else if (visit == null)
        FilledButton.icon(
          onPressed: (canBill && _patient != null && _cart.isNotEmpty && !_busy)
              ? _openVisit
              : null,
          icon: _busy
              ? const SizedBox(
                  height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.assignment_add),
          label: const Text('Открыть визит'),
        )
      else ...[
        Text('Визит ${visit.visitNo} · к оплате ${formatMoney(visit.balance)}'),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: canBill ? _takePayment : null,
          icon: const Icon(Icons.point_of_sale),
          label: const Text('Принять оплату'),
        ),
      ],
    ]);
  }

  Widget _resultCard(PaymentResult r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Оплата принята',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Чек: ${r.payment.receiptNo} · ${formatMoney(r.payment.amount)}'
              ' (${r.payment.method})'),
          Text('Остаток по визиту: ${formatMoney(r.visitBalance)}'),
          if (r.queueTicketNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined),
                  const SizedBox(width: 8),
                  Text('Талон очереди: ${r.queueTicketNumber}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Новый приём'),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Диалог оплаты: сумма (по умолчанию — остаток), способ, кабинет для талона.
class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog({required this.visit});

  final ReceptionVisit visit;

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  late final TextEditingController _amount =
      TextEditingController(text: widget.visit.balance);
  final _room = TextEditingController(text: 'Каб. 1');
  String _method = 'cash';
  bool _paying = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final result = await ref.read(receptionRepositoryProvider).takePayment(
            visitId: widget.visit.id,
            amount: _amount.text.trim(),
            method: _method,
            room: _room.text.trim().isEmpty ? null : _room.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Оплата · визит ${widget.visit.visitNo}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Сумма'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Способ оплаты'),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Наличные')),
              DropdownMenuItem(value: 'card', child: Text('Карта')),
              DropdownMenuItem(value: 'transfer', child: Text('Перечисление')),
            ],
            onChanged: (v) => setState(() => _method = v ?? 'cash'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _room,
            decoration: const InputDecoration(
                labelText: 'Кабинет (для талона очереди)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _paying ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _paying ? null : _pay,
          child: _paying
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Оплатить'),
        ),
      ],
    );
  }
}
