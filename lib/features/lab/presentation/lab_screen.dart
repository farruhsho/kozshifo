import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../patients/data/patient_search.dart';
import '../data/lab_repository.dart';
import '../domain/lab_order.dart';

/// Лаборатория — направления на исследования и их результаты.
/// Поток статуса: referred → in_progress → ready | cancelled. Внесение
/// результата автоматически переводит направление в `ready`.
class LabScreen extends ConsumerStatefulWidget {
  const LabScreen({super.key});

  @override
  ConsumerState<LabScreen> createState() => _LabScreenState();
}

const _commonTests = <String>[
  'ОКТ макулы',
  'Поле зрения (периметрия)',
  'Биометрия + расчёт ИОЛ',
  'УЗИ глаза (B-скан)',
  'Кератотопография',
];

class _LabScreenState extends ConsumerState<LabScreen> {
  bool _busy = false;

  String? get _branchId => ref.read(authControllerProvider).user?.branchId;

  Future<void> _act(Future<void> Function() fn, {String? ok}) async {
    final branchId = _branchId;
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
        if (branchId != null) ref.invalidate(labListProvider(branchId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = _branchId;
    if (branchId == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Лаборатория')),
        body: const Center(child: Text('У пользователя не задан филиал.')),
      );
    }
    final canManage =
        ref.watch(authControllerProvider).user?.can('lab.manage') ?? false;
    final ordersAsync = ref.watch(labListProvider(branchId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Лаборатория')),
      body: SafeArea(
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text(e is ApiException ? e.message : e.toString())),
          data: (orders) {
            final referred = orders.where((o) => o.status == 'referred').length;
            final inProgress =
                orders.where((o) => o.status == 'in_progress').length;
            final ready = orders.where((o) => o.status == 'ready').length;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _CountCard(label: 'Направлен', value: referred),
                          _CountCard(label: 'В работе', value: inProgress),
                          _CountCard(label: 'Готов', value: ready),
                        ],
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 16),
                      GradientButton(
                        label: 'Новое направление',
                        icon: Icons.add,
                        onPressed: _busy ? null : _openCreate,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: orders.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: Text('Направлений пока нет')),
                        )
                      : _LabTable(
                          orders: orders,
                          canManage: canManage,
                          busy: _busy,
                          onResult: _openResult,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreate() async {
    final branchId = _branchId;
    if (branchId == null) return;
    final res = await showDialog<({String patientId, String testName})>(
      context: context,
      builder: (_) => const _CreateOrderDialog(),
    );
    if (res == null) return;
    await _act(
      () async => ref.read(labRepositoryProvider).create(
            branchId: branchId,
            patientId: res.patientId,
            testName: res.testName,
          ),
      ok: 'Направление создано',
    );
  }

  Future<void> _openResult(LabOrder order) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _ResultDialog(order: order),
    );
    if (text == null) return;
    await _act(
      () async => ref.read(labRepositoryProvider).setResult(order.id, text),
      ok: 'Результат внесён',
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value.toString(), style: AppTypography.number(24)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.sub, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _LabTable extends StatelessWidget {
  const _LabTable({
    required this.orders,
    required this.canManage,
    required this.busy,
    required this.onResult,
  });

  final List<LabOrder> orders;
  final bool canManage;
  final bool busy;
  final void Function(LabOrder order) onResult;

  static String _date(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '—';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }

  static BadgeKind _kind(String status) => switch (status) {
        'ready' => BadgeKind.success,
        'in_progress' => BadgeKind.info,
        'referred' => BadgeKind.warning,
        'cancelled' => BadgeKind.danger,
        _ => BadgeKind.neutral,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line2)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: _HeaderCell('ПАЦИЕНТ')),
              Expanded(flex: 3, child: _HeaderCell('ИССЛЕДОВАНИЕ')),
              Expanded(flex: 4, child: _HeaderCell('РЕЗУЛЬТАТ')),
              SizedBox(width: 64, child: _HeaderCell('ДАТА')),
              SizedBox(width: 300, child: _HeaderCell('СТАТУС')),
            ],
          ),
        ),
        for (var i = 0; i < orders.length; i++)
          _LabRow(
            order: orders[i],
            last: i == orders.length - 1,
            canManage: canManage,
            busy: busy,
            onResult: onResult,
          ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LabRow extends StatelessWidget {
  const _LabRow({
    required this.order,
    required this.last,
    required this.canManage,
    required this.busy,
    required this.onResult,
  });

  final LabOrder order;
  final bool last;
  final bool canManage;
  final bool busy;
  final void Function(LabOrder order) onResult;

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts.first.characters.first;
    return parts[0].characters.first + parts[1].characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final canEnter = canManage &&
        order.status != 'ready' &&
        order.status != 'cancelled';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                InitialsAvatar(_initials(order.patientName), size: 34, fontSize: 12),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              order.testName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              order.result ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: order.result == null ? AppColors.muted : AppColors.ink,
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              _LabTable._date(order.createdAt),
              style: const TextStyle(color: AppColors.sub, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StatusBadge(order.statusLabel, kind: _LabTable._kind(order.status)),
                if (canEnter) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: busy ? null : () => onResult(order),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 34),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Результат'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Новое направление: поиск пациента (как в booking dialog расписания) +
/// выбор исследования из списка частых или свободный ввод.
class _CreateOrderDialog extends ConsumerStatefulWidget {
  const _CreateOrderDialog();

  @override
  ConsumerState<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends ConsumerState<_CreateOrderDialog> {
  final _search = TextEditingController();
  final _custom = TextEditingController();
  String _query = '';
  Timer? _debounce;
  PatientOption? _selected;
  String? _test = _commonTests.first;
  bool _customMode = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _custom.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  String get _testName =>
      _customMode ? _custom.text.trim() : (_test ?? '').trim();

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(patientSearchProvider(_query));
    return AlertDialog(
      title: const Text('Новое направление'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selected != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline, color: AppColors.accent),
                  title: Text(_selected!.name),
                  subtitle: Text('МРН ${_selected!.mrn}'),
                  trailing: TextButton(
                    onPressed: () => setState(() => _selected = null),
                    child: const Text('Сменить'),
                  ),
                )
              else ...[
                TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Пациент (ФИО, МРН, телефон)',
                  ),
                  onChanged: _onSearch,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 170,
                  child: results.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
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
                                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('МРН ${p.mrn}'),
                                onTap: () => setState(() => _selected = p),
                              );
                            },
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _customMode ? '__custom__' : _test,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Исследование',
                ),
                items: [
                  for (final t in _commonTests)
                    DropdownMenuItem(value: t, child: Text(t)),
                  const DropdownMenuItem(
                      value: '__custom__', child: Text('Другое (ввести вручную)')),
                ],
                onChanged: (v) => setState(() {
                  if (v == '__custom__') {
                    _customMode = true;
                  } else {
                    _customMode = false;
                    _test = v;
                  }
                }),
              ),
              if (_customMode) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _custom,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Название исследования',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: (_selected == null || _testName.isEmpty)
              ? null
              : () => Navigator.of(context).pop(
                  (patientId: _selected!.id, testName: _testName)),
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

class _ResultDialog extends StatefulWidget {
  const _ResultDialog({required this.order});
  final LabOrder order;

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog> {
  late final _result = TextEditingController(text: widget.order.result ?? '');

  @override
  void dispose() {
    _result.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Внести результат'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.order.patientName} · ${widget.order.testName}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _result,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Результат исследования',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _result.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_result.text.trim()),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
