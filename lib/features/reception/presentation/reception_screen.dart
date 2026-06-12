import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/flow_labels.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../../patients/data/patients_repository.dart';
import '../../patients/domain/patient.dart';
import '../../patients/presentation/patients_screen.dart'
    show RegisterPatientDialog;
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
  String _lastQuery = '';

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
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(value.trim()),
    );
  }

  Future<void> _search(String q) async {
    _lastQuery = q;
    if (q.isEmpty) {
      setState(() => _found = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final page = await ref
          .read(patientsRepositoryProvider)
          .list(q: q, limit: 8);
      if (mounted) setState(() => _found = page.items);
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Похоже на телефон: только цифры/+/пробелы/дефисы и минимум 7 цифр —
  /// тогда «пациента нет» превращается в регистрацию с этим номером.
  static bool _looksLikePhone(String q) {
    if (!RegExp(r'^[0-9+\s\-]+$').hasMatch(q)) return false;
    return RegExp(r'[0-9]').allMatches(q).length >= 7;
  }

  Future<void> _registerNew({String? initialPhone}) async {
    final created = await showDialog<Patient>(
      context: context,
      builder: (_) => RegisterPatientDialog(initialPhone: initialPhone),
    );
    if (created != null) setState(() => _patient = created);
  }

  // ── Визит и оплата ─────────────────────────────────────────────────────────

  Future<void> _openVisit() async {
    final patient = _patient;
    // Визит происходит там, где пациент физически находится: филиал оператора
    // в приоритете, домашний филиал пациента — только fallback.
    final branchId =
        ref.read(authControllerProvider).user?.branchId ?? patient?.branchId;
    if (patient == null || _cart.isEmpty) return;
    if (branchId == null) {
      _snack('У пользователя не задан филиал', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final visit = await ref
          .read(receptionRepositoryProvider)
          .createVisit(
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
    if (result == null) return;
    final remaining = double.tryParse(result.visitBalance) ?? 0;
    if (remaining > 0) {
      // Частичная оплата: обновляем остаток и оставляем кнопку оплаты доступной.
      setState(
        () => _visit = visit.copyWith(
          balance: result.visitBalance,
          status: result.visitStatus,
        ),
      );
      _snack(
        'Чек ${result.payment.receiptNo}: принято '
        '${formatMoney(result.payment.amount)}. '
        'Остаток: ${formatMoney(result.visitBalance)}',
      );
    } else {
      setState(() => _result = result);
    }
  }

  /// Скидка ресепшена (процент XOR сумма + обязательное основание).
  /// Пересчёт payable/balance делает сервер — диалог возвращает обновлённый визит.
  Future<void> _editDiscount() async {
    final visit = _visit;
    if (visit == null) return;
    final updated = await showDialog<ReceptionVisit>(
      context: context,
      builder: (_) => _DiscountDialog(visit: visit),
    );
    if (updated != null && mounted) setState(() => _visit = updated);
  }

  Future<void> _cancelVisit() async {
    final visit = _visit;
    if (visit == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(receptionRepositoryProvider).cancelVisit(visit.id);
      _snack('Визит ${visit.visitNo} отменён');
      _reset();
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    setState(() {
      _patient = null;
      _cart.clear();
      _visit = null;
      _result = null;
      _found = const [];
      _lastQuery = '';
      _searchController.clear();
    });
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final canBill =
        (user?.can('visits.create') ?? false) &&
        (user?.can('payments.create') ?? false);
    final canRegister = user?.can('patients.create') ?? false;
    final canDiscount = user?.can('visits.update') ?? false;
    final services = ref.watch(activeServicesProvider);
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _patientSection(canRegister),
        const SizedBox(height: 12),
        _servicesSection(services, canBill),
      ],
    );
    final right = _cartSection(canBill, canDiscount);

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

  Widget _patientSection(bool canRegister) {
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
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: canRegister ? _registerNew : null,
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
            subtitle: Text(
              [p.mrn, if (p.phone != null) p.phone!].join('  ·  '),
            ),
            onTap: () => setState(() => _patient = p),
          ),
        // Телефон набран, пациента нет → регистрация в один тап с этим номером.
        if (canRegister &&
            _found.isEmpty &&
            !_searching &&
            _looksLikePhone(_lastQuery))
          ListTile(
            leading: Icon(
              Icons.person_add_alt_1,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Зарегистрировать нового пациента с телефоном $_lastQuery',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _registerNew(initialPhone: _lastQuery),
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
                          ? () => setState(
                              () => _cart.update(
                                s,
                                (q) => q + 1,
                                ifAbsent: () => 1,
                              ),
                            )
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

  /// Скидка установлена сервером (процент XOR сумма) — тогда вместо «Итого»
  /// показываем Сумма / Скидка / К оплате, и должная цифра — payable.
  static bool _hasDiscount(ReceptionVisit v) =>
      v.discountPercent != null || v.discountAmount != null;

  Widget _moneyRow(String label, String value, {bool bold = false}) {
    final style = bold
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : null;
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }

  Widget _cartSection(bool canBill, bool canDiscount) {
    final result = _result;
    final visit = _visit;
    final preTotal = cartTotalValue(
      _cart.entries.map((e) => (e.key.price, e.value)),
    );

    return _card('3. Оплата', [
      if (_cart.isEmpty && visit == null)
        const Text('Добавьте услуги из списка.')
      else ...[
        for (final e in _cart.entries)
          Row(
            children: [
              Expanded(
                child: Text(e.key.name, overflow: TextOverflow.ellipsis),
              ),
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
        if (visit == null)
          _moneyRow(
            'Итого:',
            '≈ ${formatMoney(preTotal.toStringAsFixed(2))}',
            bold: true,
          )
        else if (!_hasDiscount(visit))
          _moneyRow('Итого:', formatMoney(visit.totalAmount), bold: true)
        else ...[
          _moneyRow('Сумма:', formatMoney(visit.totalAmount)),
          _moneyRow(
            'Скидка:',
            '−${formatMoney(visit.discountValue)}'
                '${visit.discountReason == null ? '' : ' (${visit.discountReason})'}',
          ),
          // payable = total − скидка: именно столько должен пациент.
          _moneyRow(
            'К оплате:',
            formatMoney(visit.payable ?? visit.totalAmount),
            bold: true,
          ),
        ],
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
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.assignment_add),
          label: const Text('Открыть визит'),
        )
      else ...[
        // balance — остаток к доплате (payable − оплачено), его ведёт сервер.
        Text('Визит ${visit.visitNo} · остаток ${formatMoney(visit.balance)}'),
        const SizedBox(height: 4),
        // Статус пути пациента — read-only, его двигает flow engine на сервере.
        Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message: 'Статус меняется автоматически',
            child: Chip(
              visualDensity: VisualDensity.compact,
              label: Text(flowStatusLabel(visit.flowStatus)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: (canBill && !_busy) ? _takePayment : null,
          icon: const Icon(Icons.point_of_sale),
          label: const Text('Принять оплату'),
        ),
        const SizedBox(height: 8),
        // Скидка доступна, пока визит открыт (право visits.update).
        OutlinedButton.icon(
          onPressed: (canDiscount && !_busy) ? _editDiscount : null,
          icon: const Icon(Icons.percent),
          label: const Text('Скидка'),
        ),
        const SizedBox(height: 8),
        // Аварийный выход: пациент передумал / услуги выбраны неверно.
        // Сервер отменит только неоплаченный визит (иначе — сначала возврат).
        OutlinedButton.icon(
          onPressed: (canBill && !_busy) ? _cancelVisit : null,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Отменить визит'),
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
          Text(
            'Оплата принята',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Чек: ${r.payment.receiptNo} · ${formatMoney(r.payment.amount)}'
            ' (${r.payment.method})',
          ),
          Text('Остаток по визиту: ${formatMoney(r.visitBalance)}'),
          if (r.queueTicketNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Талон диагностики: ${r.queueTicketNumber}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
  late final TextEditingController _amount = TextEditingController(
    text: widget.visit.balance,
  );
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
      final result = await ref
          .read(receptionRepositoryProvider)
          .takePayment(
            visitId: widget.visit.id,
            // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
            amount: _amount.text.trim().replaceAll(',', '.'),
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
              DropdownMenuItem(value: 'qr', child: Text('QR')),
              DropdownMenuItem(value: 'transfer', child: Text('Перечисление')),
            ],
            onChanged: (v) => setState(() => _method = v ?? 'cash'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _room,
            decoration: const InputDecoration(
              labelText: 'Кабинет (для талона очереди)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Оплатить'),
        ),
      ],
    );
  }
}

/// Типовые основания скидки; «Другое» открывает свободный текст.
const _discountReasons = <String>[
  'Пенсионер',
  'Сотрудник',
  'Повторный пациент',
  'Акция',
  'Другое',
];

/// Диалог скидки: переключатель «Процент / Сумма» (XOR — сервер принимает
/// ровно одно), обязательное основание, «Убрать скидку» (недоступно после
/// первой оплаты). Клиентская валидация — инлайн-текстом, ответы сервера
/// (409 закрытый визит / payable < paid, 422) — SnackBar'ом его текстом.
class _DiscountDialog extends ConsumerStatefulWidget {
  const _DiscountDialog({required this.visit});

  final ReceptionVisit visit;

  @override
  ConsumerState<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends ConsumerState<_DiscountDialog> {
  final _value = TextEditingController();
  final _customReason = TextEditingController();
  bool _byPercent = true;
  String? _reason;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Повторное открытие — редактирование текущей скидки: префилл из визита.
    final v = widget.visit;
    _byPercent = v.discountAmount == null;
    _value.text = v.discountPercent ?? v.discountAmount ?? '';
    final reason = v.discountReason;
    if (reason != null) {
      if (_discountReasons.contains(reason)) {
        _reason = reason;
      } else {
        _reason = 'Другое';
        _customReason.text = reason;
      }
    }
  }

  @override
  void dispose() {
    _value.dispose();
    _customReason.dispose();
    super.dispose();
  }

  bool get _alreadyPaid =>
      (double.tryParse(widget.visit.paidAmount) ?? 0) > 0;

  Future<void> _apply() async {
    // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
    final raw = _value.text.trim().replaceAll(',', '.');
    final number = double.tryParse(raw);
    final reason =
        (_reason == 'Другое' ? _customReason.text.trim() : _reason) ?? '';
    String? error;
    if (number == null || number <= 0) {
      error = _byPercent
          ? 'Введите процент скидки (больше 0)'
          : 'Введите сумму скидки (больше 0)';
    } else if (_byPercent && number > 100) {
      error = 'Процент скидки не может превышать 100';
    } else if (reason.isEmpty) {
      error = 'Укажите основание скидки';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await _send(
      percent: _byPercent ? raw : null,
      amount: _byPercent ? null : raw,
      reason: reason,
    );
  }

  Future<void> _send({
    String? percent,
    String? amount,
    String? reason,
    bool clear = false,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(receptionRepositoryProvider)
          .setDiscount(
            visitId: widget.visit.id,
            percent: percent,
            amount: amount,
            reason: reason,
            clear: clear,
          );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      // 409/422 и прочее — текст сервера (ApiException.toString == message).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : '$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        widget.visit.discountPercent != null ||
        widget.visit.discountAmount != null;
    return AlertDialog(
      title: Text('Скидка · визит ${widget.visit.visitNo}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Процент')),
                ButtonSegment(value: false, label: Text('Сумма')),
              ],
              selected: {_byPercent},
              onSelectionChanged: (s) =>
                  setState(() => _byPercent = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _byPercent ? 'Процент (0–100)' : 'Сумма скидки',
                suffixText: _byPercent ? '%' : 'сум',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(
                labelText: 'Основание (обязательно)',
                isDense: true,
              ),
              items: [
                for (final r in _discountReasons)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() => _reason = v),
            ),
            if (_reason == 'Другое') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customReason,
                decoration: const InputDecoration(
                  labelText: 'Основание (свой вариант)',
                  isDense: true,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        if (hasDiscount)
          // Снятие скидки разрешено, только пока по визиту ничего не оплачено
          // (иначе сервер ответит 409) — кнопка гаснет сразу.
          TextButton(
            onPressed: (_busy || _alreadyPaid)
                ? null
                : () => _send(clear: true),
            child: const Text('Убрать скидку'),
          ),
        FilledButton(
          onPressed: _busy ? null : _apply,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Применить'),
        ),
      ],
    );
  }
}
