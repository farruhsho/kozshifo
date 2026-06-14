import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../scheduling/data/scheduling_repository.dart';
import '../data/optics_repository.dart';
import '../domain/optics_order.dart';

/// Оптика и салон — заказы очков/линз под рецепт. Поток статуса:
/// Заказан → В работе → Готов → Выдан (отмена допустима до выдачи).
class OpticsScreen extends ConsumerStatefulWidget {
  const OpticsScreen({super.key});

  @override
  ConsumerState<OpticsScreen> createState() => _OpticsScreenState();
}

class _OpticsScreenState extends ConsumerState<OpticsScreen> {
  bool _busy = false;

  String? get _branchId => ref.read(authControllerProvider).user?.branchId;

  void _refresh() {
    final b = _branchId;
    if (b != null) ref.invalidate(opticsListProvider(b));
  }

  Future<void> _act(Future<void> Function() fn, {String? ok}) async {
    setState(() => _busy = true);
    try {
      await fn();
      if (ok != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : '$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
    }
  }

  String? _nextStatus(String s) => switch (s) {
        'ordered' => 'in_progress',
        'in_progress' => 'ready',
        'ready' => 'issued',
        _ => null,
      };

  String _nextLabel(String s) => switch (s) {
        'ordered' => 'В работу',
        'in_progress' => 'Готов',
        'ready' => 'Выдать',
        _ => '',
      };

  BadgeKind _badgeKind(String s) => switch (s) {
        'ready' => BadgeKind.success,
        'issued' => BadgeKind.neutral,
        'cancelled' => BadgeKind.danger,
        'in_progress' => BadgeKind.info,
        'ordered' => BadgeKind.warning,
        _ => BadgeKind.neutral,
      };

  Future<void> _openCreate(String branchId) async {
    final res = await showDialog<({String patientId, String kind, String? rx, String? frame, String price})>(
      context: context,
      builder: (_) => const _CreateOrderDialog(),
    );
    if (res == null) return;
    await _act(
      () async => ref.read(opticsRepositoryProvider).create(
            branchId: branchId,
            patientId: res.patientId,
            kind: res.kind,
            rx: res.rx,
            frame: res.frame,
            price: res.price,
          ),
      ok: 'Заказ оптики создан',
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchId = _branchId;
    if (branchId == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Оптика и салон')),
        body: const Center(child: Text('У пользователя не задан филиал.')),
      );
    }
    final canManage =
        ref.watch(authControllerProvider).user?.can('optics.manage') ?? false;
    final ordersAsync = ref.watch(opticsListProvider(branchId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Оптика и салон')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text(e is ApiException ? e.message : e.toString())),
            data: (orders) {
              final ordered =
                  orders.where((o) => o.status == 'ordered').length;
              final inProgress =
                  orders.where((o) => o.status == 'in_progress').length;
              final ready = orders.where((o) => o.status == 'ready').length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CountCard(
                          label: 'Заказан',
                          value: ordered,
                          color: AppColors.amber),
                      const SizedBox(width: 16),
                      _CountCard(
                          label: 'В работе',
                          value: inProgress,
                          color: AppColors.blue),
                      const SizedBox(width: 16),
                      _CountCard(
                          label: 'Готов',
                          value: ready,
                          color: AppColors.green),
                      const Spacer(),
                      if (canManage)
                        SizedBox(
                          width: 200,
                          child: GradientButton(
                            label: 'Новый заказ',
                            icon: Icons.add,
                            loading: _busy,
                            onPressed:
                                _busy ? null : () => _openCreate(branchId),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: orders.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                                child: Text('Заказов оптики пока нет',
                                    style: TextStyle(color: AppColors.muted))),
                          )
                        : Column(
                            children: [
                              const _HeaderRow(),
                              const Divider(height: 1, color: AppColors.line2),
                              for (var i = 0; i < orders.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                      height: 1, color: AppColors.line2),
                                _OrderRow(
                                  order: orders[i],
                                  canManage: canManage,
                                  busy: _busy,
                                  badgeKind: _badgeKind(orders[i].status),
                                  nextStatus: _nextStatus(orders[i].status),
                                  nextLabel: _nextLabel(orders[i].status),
                                  onAdvance: (next) => _act(
                                    () async => ref
                                        .read(opticsRepositoryProvider)
                                        .setStatus(orders[i].id, next),
                                    ok: 'Статус обновлён',
                                  ),
                                  onCancel: () => _act(
                                    () async => ref
                                        .read(opticsRepositoryProvider)
                                        .setStatus(orders[i].id, 'cancelled'),
                                    ok: 'Заказ отменён',
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatInt(value),
              style: AppTypography.number(24, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.sub, fontSize: 13)),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  TextStyle get _style => const TextStyle(
      color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('ПАЦИЕНТ', style: _style)),
          Expanded(flex: 2, child: Text('ТИП', style: _style)),
          Expanded(flex: 3, child: Text('РЕЦЕПТ', style: _style)),
          Expanded(flex: 2, child: Text('ОПРАВА', style: _style)),
          Expanded(
              flex: 2,
              child: Text('СУММА', style: _style, textAlign: TextAlign.right)),
          const SizedBox(width: 16),
          SizedBox(
              width: 250,
              child: Text('СТАТУС', style: _style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.canManage,
    required this.busy,
    required this.badgeKind,
    required this.nextStatus,
    required this.nextLabel,
    required this.onAdvance,
    required this.onCancel,
  });

  final OpticsOrder order;
  final bool canManage;
  final bool busy;
  final BadgeKind badgeKind;
  final String? nextStatus;
  final String nextLabel;
  final void Function(String next) onAdvance;
  final VoidCallback onCancel;

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first;
    }
    return parts[0].characters.first + parts[1].characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = canManage &&
        order.status != 'issued' &&
        order.status != 'cancelled';
    final canAdvance = canManage && nextStatus != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                InitialsAvatar(_initials(order.patientName), size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(order.patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5)),
                      Text(order.orderNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(order.kindLabel,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(order.rx ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                    color: AppColors.sub)),
          ),
          Expanded(
            flex: 2,
            child: Text(order.frame ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.sub)),
          ),
          Expanded(
            flex: 2,
            child: Text(formatMoney(order.price),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.tealDark)),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canCancel) ...[
                  OutlinedButton(
                    onPressed: busy ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (canAdvance)
                  FilledButton(
                    onPressed: busy ? null : () => onAdvance(nextStatus!),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    child: Text(nextLabel),
                  )
                else
                  StatusBadge(order.statusLabel, kind: badgeKind),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Создание заказа оптики. Поиск пациента — как в диалоге записи расписания.
class _CreateOrderDialog extends ConsumerStatefulWidget {
  const _CreateOrderDialog();

  @override
  ConsumerState<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends ConsumerState<_CreateOrderDialog> {
  final _search = TextEditingController();
  final _rx = TextEditingController();
  final _frame = TextEditingController();
  final _price = TextEditingController(text: '0');
  String _query = '';
  String _kind = 'glasses';
  Timer? _debounce;
  PatientOption? _selected;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _rx.dispose();
    _frame.dispose();
    _price.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  void _submit() {
    final p = _selected;
    if (p == null) return;
    final price = _price.text.trim();
    final rx = _rx.text.trim();
    final frame = _frame.text.trim();
    Navigator.of(context).pop((
      patientId: p.id,
      kind: _kind,
      rx: rx.isEmpty ? null : rx,
      frame: frame.isEmpty ? null : frame,
      price: price.isEmpty ? '0' : price,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(patientSearchProvider(_query));
    return AlertDialog(
      title: const Text('Новый заказ оптики'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selected != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline,
                      color: AppColors.tealDark),
                  title: Text(_selected!.name),
                  subtitle: Text('МРН ${_selected!.mrn}'),
                  trailing: TextButton(
                      onPressed: () => setState(() => _selected = null),
                      child: const Text('Сменить')),
                )
              else ...[
                TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Пациент (ФИО, МРН, телефон)'),
                  onChanged: _onSearch,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 170,
                  child: results.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text(e is ApiException ? e.message : '$e',
                            style: const TextStyle(color: AppColors.red))),
                    data: (items) => items.isEmpty
                        ? const Center(child: Text('Ничего не найдено'))
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final p = items[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.person_outline),
                                title: Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text('МРН ${p.mrn}'),
                                onTap: () => setState(() => _selected = p),
                              );
                            },
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'glasses', label: Text('Очки')),
                  ButtonSegment(value: 'lenses', label: Text('Линзы')),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rx,
                decoration: const InputDecoration(
                    isDense: true, labelText: 'Рецепт (RX)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _frame,
                decoration: const InputDecoration(
                    isDense: true, labelText: 'Оправа'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(isDense: true, labelText: 'Сумма'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена')),
        FilledButton(
          onPressed: _selected == null ? null : _submit,
          child: const Text('Создать'),
        ),
      ],
    );
  }
}
