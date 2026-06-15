import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/file_saver.dart';
import '../../../core/utils/flow_labels.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../../patients/data/patients_repository.dart';
import '../../patients/domain/patient.dart';
import '../../patients/presentation/patients_screen.dart'
    show RegisterPatientDialog;
import '../data/reception_draft_store.dart';
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
  final _searchFocus = FocusNode();
  Timer? _debounce;
  List<Patient> _found = const [];
  bool _searching = false;
  String _lastQuery = '';

  Patient? _patient;
  final Map<Service, int> _cart = {};
  ReceptionVisit? _visit;
  PaymentResult? _result;
  bool _busy = false;
  // EMERGENCY intake state (mirrors the visit's server-side priority).
  bool _emergency = false;
  String? _emergencyReason;

  // Autosave: persist the in-progress draft (patient + cart, before the visit is
  // opened) every 3s; offer to restore it after a crash/refresh.
  Timer? _autosaveTimer;
  String _savedSig = '';
  Map<String, dynamic>? _restorable;

  @override
  void initState() {
    super.initState();
    _autosaveTimer = Timer.periodic(const Duration(seconds: 3), (_) => _autosave());
    _loadRestorable();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Автосейв черновика ───────────────────────────────────────────────────────

  /// Текущий черновик (только до открытия визита; иначе null).
  Map<String, dynamic>? _currentDraft() {
    if (_patient == null || _cart.isEmpty || _visit != null) return null;
    return {
      'patientId': _patient!.id,
      'items': [
        for (final e in _cart.entries) {'serviceId': e.key.id, 'qty': e.value},
      ],
    };
  }

  void _autosave() {
    final draft = _currentDraft();
    final sig = draft == null ? '' : jsonEncode(draft);
    if (sig == _savedSig) return; // ничего не изменилось
    _savedSig = sig;
    final store = ref.read(receptionDraftStoreProvider);
    if (draft == null) {
      store.clear();
    } else {
      store.save(draft);
    }
  }

  Future<void> _loadRestorable() async {
    try {
      final draft = await ref.read(receptionDraftStoreProvider).read();
      if (draft != null && mounted && _patient == null && _cart.isEmpty) {
        setState(() => _restorable = draft);
      }
    } catch (_) {
      // SharedPreferences недоступен (например, в тестах) — без восстановления.
    }
  }

  Future<void> _restoreDraft() async {
    final draft = _restorable;
    if (draft == null) return;
    setState(() => _busy = true);
    try {
      final patient = await ref
          .read(patientsRepositoryProvider)
          .getById(draft['patientId'] as String);
      final services = ref.read(activeServicesProvider).valueOrNull ??
          await ref.read(receptionRepositoryProvider).services();
      final byId = {for (final s in services) s.id: s};
      final cart = <Service, int>{};
      for (final raw in (draft['items'] as List<dynamic>)) {
        final m = raw as Map<String, dynamic>;
        final s = byId[m['serviceId']];
        if (s != null) cart[s] = (m['qty'] as num).toInt();
      }
      if (mounted) {
        setState(() {
          _patient = patient;
          _cart
            ..clear()
            ..addAll(cart);
          _restorable = null;
        });
      }
    } catch (e) {
      if (mounted) _snack('Не удалось восстановить черновик: $e', error: true);
      _discardDraft();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _discardDraft() {
    setState(() => _restorable = null);
    _savedSig = '';
    ref.read(receptionDraftStoreProvider).clear();
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
      // Визит создан — черновик больше не нужен (истина на сервере).
      _savedSig = '';
      ref.read(receptionDraftStoreProvider).clear();
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

  /// «ЭКСТРЕННО» — mark/clear emergency on the open visit. The minted ticket
  /// inherits the priority + reason (jumps the queue, flags «ЭКСТРЕННЫЙ»).
  Future<void> _toggleEmergency() async {
    final visit = _visit;
    if (visit == null) return;
    if (_emergency) {
      setState(() => _busy = true);
      try {
        await ref.read(receptionRepositoryProvider)
            .setEmergency(visitId: visit.id, emergency: false);
        if (mounted) setState(() { _emergency = false; _emergencyReason = null; });
      } catch (e) {
        if (mounted) _snack('$e', error: true);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _EmergencyReasonDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(receptionRepositoryProvider)
          .setEmergency(visitId: visit.id, emergency: true, reason: reason.trim());
      if (mounted) {
        setState(() { _emergency = true; _emergencyReason = reason.trim(); });
        _snack('Отмечено как ЭКСТРЕННЫЙ приём');
      }
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Downloads + opens the receipt PDF (browser then prints it).
  Future<void> _printReceipt(String paymentId, String receiptNo) async {
    try {
      final bytes = await ref.read(receptionRepositoryProvider).receiptPdf(paymentId);
      await saveBytes(bytes, 'receipt-$receiptNo.pdf', 'application/pdf');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    }
  }

  // Hotkey actions (Ctrl+Enter context-aware: open visit → take payment).
  void _hotNewPatient() {
    final canRegister = ref.read(authControllerProvider).user?.can('patients.create') ?? false;
    if (canRegister && _patient == null && !_busy) _registerNew();
  }

  void _hotPrimary() {
    if (_busy) return;
    if (_result != null) return;
    if (_visit == null) {
      if (_patient != null && _cart.isNotEmpty) _openVisit();
    } else {
      _takePayment();
    }
  }

  void _hotPrintReceipt() {
    final r = _result;
    if (r != null) _printReceipt(r.payment.id, r.payment.receiptNo);
  }

  void _reset() {
    setState(() {
      _patient = null;
      _cart.clear();
      _visit = null;
      _result = null;
      _emergency = false;
      _emergencyReason = null;
      _restorable = null;
      _found = const [];
      _lastQuery = '';
      _searchController.clear();
    });
    _savedSig = '';
    ref.read(receptionDraftStoreProvider).clear();
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

    // Reception hotkeys (spec): Ctrl+N новый пациент · Ctrl+F поиск ·
    // Ctrl+P печать чека · Ctrl+Enter сохранить визит / принять оплату.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _hotNewPatient,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): _hotPrintReceipt,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _hotPrimary,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(title: const Text('Ресепшен')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_restorable != null) ...[
                  _restoreBanner(),
                  const SizedBox(height: 12),
                ],
                wide
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _restoreBanner() {
    final items = (_restorable?['items'] as List?) ?? const [];
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.restore, color: cs.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Найден незавершённый приём (услуг: ${items.length}). Восстановить?',
              style: TextStyle(
                  color: cs.onTertiaryContainer, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _discardDraft,
            child: const Text('Отбросить'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: _busy ? null : _restoreDraft,
            child: const Text('Восстановить'),
          ),
        ],
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
                focusNode: _searchFocus,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Поиск: ID, ФИО, телефон, дата рождения',
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
      ] else ...[
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
        _historyPanel(_patient!.id),
      ],
    ]);
  }

  /// История пациента: посещения, последний визит/диагноз, долг, повторный.
  Widget _historyPanel(String patientId) {
    final summary = ref.watch(patientSummaryProvider(patientId));
    return summary.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (s) {
        final cs = Theme.of(context).colorScheme;
        final chips = <Widget>[
          _miniChip(Icons.event_repeat, 'Визитов: ${s.visitCount}'),
          if (s.isRepeat) _miniChip(Icons.verified_user, 'Повторный', color: cs.primary),
          if (s.lastVisitAt != null) _miniChip(Icons.history, 'Был: ${s.lastVisitAt}'),
          if (s.hasDebt)
            _miniChip(Icons.account_balance_wallet,
                'Долг: ${formatMoney(s.totalDebt)}', color: cs.error),
        ];
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: chips),
              if (s.lastDiagnosis != null) ...[
                const SizedBox(height: 8),
                Text('Посл. диагноз: ${s.lastDiagnosis}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if (s.lastOperation != null)
                Text('Посл. операция: ${s.lastOperation}',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }

  Widget _miniChip(IconData icon, String label, {Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12.5, color: c, fontWeight: FontWeight.w600)),
      ],
    );
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
        const SizedBox(width: 8),
        // Flexible + right-align: a long «−15 000 сум (Пенсионер)» wraps instead
        // of overflowing the narrow right column.
        Expanded(child: Text(value, style: style, textAlign: TextAlign.right)),
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
        if (_emergency) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ЭКСТРЕННЫЙ ПРИЕМ${_emergencyReason == null ? '' : ' · $_emergencyReason'}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
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
        // «ЭКСТРЕННО» — приоритет в очереди + красная метка на талоне/ТВ/чеке.
        OutlinedButton.icon(
          onPressed: (canDiscount && !_busy) ? _toggleEmergency : null,
          icon: Icon(_emergency ? Icons.cancel : Icons.warning_amber_rounded,
              color: _emergency ? null : Theme.of(context).colorScheme.error),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                _emergency ? null : Theme.of(context).colorScheme.error,
          ),
          label: Text(_emergency ? 'Снять экстренность' : 'ЭКСТРЕННО'),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _printReceipt(r.payment.id, r.payment.receiptNo),
                  icon: const Icon(Icons.print),
                  label: const Text('Печать чека'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Новый приём'),
                ),
              ),
            ],
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

/// Причина экстренного приёма (для очереди/чека/аналитики).
const _emergencyReasons = <String>[
  'Травма глаза',
  'ДТП',
  'Острая боль',
  'Резкое снижение зрения',
  'Инородное тело',
  'Химический ожог',
  'Другое',
];

class _EmergencyReasonDialog extends StatefulWidget {
  const _EmergencyReasonDialog();

  @override
  State<_EmergencyReasonDialog> createState() => _EmergencyReasonDialogState();
}

class _EmergencyReasonDialogState extends State<_EmergencyReasonDialog> {
  String _reason = _emergencyReasons.first;
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  String get _value => _reason == 'Другое' ? _custom.text.trim() : _reason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Экстренный приём'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Пациент получит приоритет в очереди, красную метку на табло и в чеке.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(
                  labelText: 'Причина (обязательно)', isDense: true),
              items: [
                for (final r in _emergencyReasons)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() => _reason = v ?? _emergencyReasons.first),
            ),
            if (_reason == 'Другое') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _custom,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Причина (свой вариант)', isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _value.isEmpty ? null : () => Navigator.of(context).pop(_value),
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Отметить экстренным'),
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
