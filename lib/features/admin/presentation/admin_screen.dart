import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../../reception/domain/service.dart';
import '../data/admin_repository.dart';
import '../domain/admin_branch.dart';
import '../domain/staff_user.dart';

/// Owner Control Center: услуги и цены · филиалы · сотрудники.
/// Владелец управляет клиникой из UI — без программиста.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Администрирование'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Филиалы'),
              Tab(text: 'Сотрудники'),
              Tab(text: 'Диагнозы'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_BranchesTab(), _StaffTab(), _DiagnosesTab()],
        ),
      ),
    );
  }
}

void _showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

/// Подпись врача в пикере услуги: роли + кабинет (что есть).
String? _doctorSub(AssignableDoctor u) {
  final parts = <String>[
    if (u.roles.isNotEmpty) u.roles.join(', '),
    if (u.cabinet != null && u.cabinet!.trim().isNotEmpty) u.cabinet!.trim(),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Чекбокс-мультивыбор внутри диалога (тот же паттерн, что у ролей): список
/// [options] с уже выбранными id в [selected]; тап переключает через [onToggle].
/// Источник (услуги/сотрудники) разворачивают в `.when` на стороне вызова.
class _MultiPick extends StatelessWidget {
  const _MultiPick({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.emptyHint,
  });

  final String title;
  final List<({String id, String label, String? sub})> options;
  // Мутируется на месте: тап по строке добавляет/убирает id и зовёт onChanged
  // (родитель просто делает setState). Так у 4 диалогов нет своих тогглов.
  final Set<String> selected;
  final VoidCallback onChanged;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        if (options.isEmpty && emptyHint != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              emptyHint!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final o in options)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(o.label),
            subtitle: o.sub == null ? null : Text(o.sub!),
            value: selected.contains(o.id),
            onChanged: (v) {
              if (v ?? false) {
                selected.add(o.id);
              } else {
                selected.remove(o.id);
              }
              onChanged();
            },
          ),
      ],
    );
  }
}

/// Async-список → чекбокс-мультивыбор. Показывает АКТИВНЫЕ элементы плюс любой
/// уже выбранный, даже если он стал неактивным (помечая «(неактивна)») — чтобы
/// устаревшую связь было видно и можно было снять. [prioritize]==true поднимает
/// элемент вверх (например врача с кабинетом). Загрузка/ошибка — единые.
Widget _asyncMultiPick<T>(
  BuildContext context,
  AsyncValue<List<T>> source, {
  required String title,
  required String emptyHint,
  required String errorLabel,
  required Set<String> selected,
  required VoidCallback onChanged,
  required String Function(T) id,
  required String Function(T) label,
  required bool Function(T) isActive,
  String? Function(T)? sub,
  bool Function(T)? prioritize,
  String inactiveSuffix = '(неактивна)',
}) {
  return source.when(
    data: (items) {
      final visible = [
        for (final x in items)
          if (isActive(x) || selected.contains(id(x))) x,
      ];
      if (prioritize != null) {
        visible.sort((a, b) {
          final byPriority = (prioritize(a) ? 0 : 1).compareTo(
            prioritize(b) ? 0 : 1,
          );
          return byPriority != 0 ? byPriority : label(a).compareTo(label(b));
        });
      }
      return _MultiPick(
        title: title,
        emptyHint: emptyHint,
        selected: selected,
        onChanged: onChanged,
        options: [
          for (final x in visible)
            (
              id: id(x),
              label: isActive(x) ? label(x) : '${label(x)} $inactiveSuffix',
              sub: sub?.call(x),
            ),
        ],
      );
    },
    loading: () => const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: LinearProgressIndicator(),
    ),
    error: (e, _) => Text(
      '$errorLabel: $e',
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

// ═══ Услуги и цены ═══════════════════════════════════════════════════════════

/// Управление услугами и ценами. Отдельный экран `/services` (services.read) —
/// доступен ресепшену (он добавляет услуги) и директору.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(adminServicesProvider);
    final user = ref.watch(authControllerProvider).user;
    final canCreate = user?.can('services.create') ?? false;
    final canUpdate = user?.can('services.update') ?? false;
    final disabled = Theme.of(context).disabledColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Услуги и цены')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openCreate(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Новая услуга'),
            )
          : null,
      body: AsyncValueWidget<List<Service>>(
        value: services,
        onRetry: () => ref.invalidate(adminServicesProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Услуг пока нет.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = items[i];
              // Деактивированную услугу серим, но оставляем кликабельной —
              // владелец должен мочь включить её обратно.
              final greyed = s.isActive ? null : TextStyle(color: disabled);
              return ListTile(
                leading: Icon(
                  Icons.medical_services_outlined,
                  color: s.isActive
                      ? Theme.of(context).colorScheme.primary
                      : disabled,
                ),
                title: Text(s.name, style: greyed),
                subtitle: Text(s.code, style: greyed),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!s.isActive) ...[
                      Chip(
                        label: const Text('выкл'),
                        labelStyle: TextStyle(color: disabled),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      formatMoney(s.price),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: s.isActive ? null : disabled,
                      ),
                    ),
                  ],
                ),
                onTap: canUpdate ? () => _openEdit(context, ref, s) : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ServiceCreateDialog(),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(adminServicesProvider);
      _showSnack(context, 'Услуга создана');
    }
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    Service service,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ServiceEditDialog(service: service),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(adminServicesProvider);
      _showSnack(context, 'Услуга обновлена');
    }
  }
}

class _ServiceCreateDialog extends ConsumerStatefulWidget {
  const _ServiceCreateDialog();

  @override
  ConsumerState<_ServiceCreateDialog> createState() =>
      _ServiceCreateDialogState();
}

class _ServiceCreateDialogState extends ConsumerState<_ServiceCreateDialog> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _price = TextEditingController();
  String? _categoryId;
  bool _isDiagnostic = false;
  final _selectedDoctorIds = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
  String get _normalizedPrice => _price.text.trim().replaceAll(',', '.');

  bool get _canSave =>
      !_saving &&
      _code.text.trim().isNotEmpty &&
      _name.text.trim().isNotEmpty &&
      double.tryParse(_normalizedPrice) != null;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .createService(
            code: _code.text.trim(),
            name: _name.text.trim(),
            price: _normalizedPrice,
            categoryId: _categoryId,
            doctorIds: _selectedDoctorIds.toList(),
            isDiagnostic: _isDiagnostic,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(adminCategoriesProvider);
    final doctors = ref.watch(assignableDoctorsProvider);

    return AlertDialog(
      title: const Text('Новая услуга'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _code,
                decoration: const InputDecoration(
                  labelText: 'Код (уникальный)',
                  hintText: 'CONS-01',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Название'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Цена, сум'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              categories.when(
                data: (items) => DropdownButtonFormField<String?>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Категория'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Без категории'),
                    ),
                    for (final c in items)
                      DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                // Категория необязательна — при ошибке не блокируем создание.
                error: (e, _) => Text(
                  'Категории недоступны: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Диагностическая услуга (УЗИ, биометрия…)'),
                value: _isDiagnostic,
                onChanged: (v) => setState(() => _isDiagnostic = v),
              ),
              const SizedBox(height: 16),
              _asyncMultiPick<AssignableDoctor>(
                context,
                doctors,
                title: 'Принимающие врачи',
                emptyHint: 'Нет сотрудников',
                errorLabel: 'Сотрудники недоступны',
                selected: _selectedDoctorIds,
                onChanged: () => setState(() {}),
                id: (u) => u.id,
                label: (u) => u.fullName,
                isActive: (u) => u.isActive,
                sub: _doctorSub,
                prioritize: (u) =>
                    u.cabinet != null && u.cabinet!.trim().isNotEmpty,
              ),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Создать'),
        ),
      ],
    );
  }
}

class _ServiceEditDialog extends ConsumerStatefulWidget {
  const _ServiceEditDialog({required this.service});

  final Service service;

  @override
  ConsumerState<_ServiceEditDialog> createState() => _ServiceEditDialogState();
}

class _ServiceEditDialogState extends ConsumerState<_ServiceEditDialog> {
  late final _name = TextEditingController(text: widget.service.name);
  late final _price = TextEditingController(text: widget.service.price);
  late bool _isActive = widget.service.isActive;
  late bool _isDiagnostic = widget.service.isDiagnostic;
  late final _selectedDoctorIds = <String>{
    for (final d in widget.service.doctors) d.id,
  };
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  String get _normalizedPrice => _price.text.trim().replaceAll(',', '.');

  bool get _canSave =>
      !_saving &&
      _name.text.trim().isNotEmpty &&
      double.tryParse(_normalizedPrice) != null;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateService(
            widget.service.id,
            name: _name.text.trim(),
            price: _normalizedPrice,
            isActive: _isActive,
            doctorIds: _selectedDoctorIds.toList(),
            isDiagnostic: _isDiagnostic,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(assignableDoctorsProvider);
    return AlertDialog(
      title: Text('Услуга ${widget.service.code}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Название'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Цена, сум'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Активна'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Диагностическая услуга (УЗИ, биометрия…)'),
                value: _isDiagnostic,
                onChanged: (v) => setState(() => _isDiagnostic = v),
              ),
              const SizedBox(height: 12),
              _asyncMultiPick<AssignableDoctor>(
                context,
                doctors,
                title: 'Принимающие врачи',
                emptyHint: 'Нет сотрудников',
                errorLabel: 'Сотрудники недоступны',
                selected: _selectedDoctorIds,
                onChanged: () => setState(() {}),
                id: (u) => u.id,
                label: (u) => u.fullName,
                isActive: (u) => u.isActive,
                sub: _doctorSub,
                prioritize: (u) =>
                    u.cabinet != null && u.cabinet!.trim().isNotEmpty,
              ),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}

// ═══ Филиалы ═════════════════════════════════════════════════════════════════

class _BranchesTab extends ConsumerWidget {
  const _BranchesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(adminBranchesProvider);
    final user = ref.watch(authControllerProvider).user;
    final canCreate = user?.can('branches.create') ?? false;
    final canUpdate = user?.can('branches.update') ?? false;
    final disabled = Theme.of(context).disabledColor;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openCreate(context, ref),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Новый филиал'),
            )
          : null,
      body: AsyncValueWidget<List<AdminBranch>>(
        value: branches,
        onRetry: () => ref.invalidate(adminBranchesProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Филиалов пока нет.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = items[i];
              final greyed = b.isActive ? null : TextStyle(color: disabled);
              return ListTile(
                leading: Icon(
                  Icons.local_hospital_outlined,
                  color: b.isActive ? primary : disabled,
                ),
                title: Text(b.name, style: greyed),
                subtitle: Text(
                  [b.code, if (b.address != null) b.address!].join(' · '),
                  style: greyed,
                ),
                trailing: Chip(
                  label: Text(b.isActive ? 'активен' : 'выкл'),
                  labelStyle: TextStyle(color: b.isActive ? primary : disabled),
                  backgroundColor: b.isActive
                      ? primary.withValues(alpha: 0.1)
                      : null,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
                onTap: canUpdate ? () => _openEdit(context, ref, b) : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _BranchCreateDialog(),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(adminBranchesProvider);
      _showSnack(context, 'Филиал создан');
    }
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    AdminBranch branch,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _BranchEditDialog(branch: branch),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(adminBranchesProvider);
      _showSnack(context, 'Филиал обновлён');
    }
  }
}

class _BranchCreateDialog extends ConsumerStatefulWidget {
  const _BranchCreateDialog();

  @override
  ConsumerState<_BranchCreateDialog> createState() =>
      _BranchCreateDialogState();
}

class _BranchCreateDialogState extends ConsumerState<_BranchCreateDialog> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving && _name.text.trim().isNotEmpty && _code.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .createBranch(
            name: _name.text.trim(),
            code: _code.text.trim(),
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            phone: assembleUzPhone(_phone.text),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый филиал'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Код (уникальный)',
                hintText: 'TASH-02',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Адрес (необязательно)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: uzPhoneLocal,
              decoration: const InputDecoration(
                labelText: 'Телефон (необязательно)',
                prefixText: '+998 ',
                hintText: '90 123 45 67',
              ),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Создать'),
        ),
      ],
    );
  }
}

class _BranchEditDialog extends ConsumerStatefulWidget {
  const _BranchEditDialog({required this.branch});

  final AdminBranch branch;

  @override
  ConsumerState<_BranchEditDialog> createState() => _BranchEditDialogState();
}

class _BranchEditDialogState extends ConsumerState<_BranchEditDialog> {
  late final _name = TextEditingController(text: widget.branch.name);
  late final _address = TextEditingController(
    text: widget.branch.address ?? '',
  );
  late final _phone = TextEditingController(
    text: extractUzPhoneLocal(widget.branch.phone),
  );
  late bool _isActive = widget.branch.isActive;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSave => !_saving && _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateBranch(
            widget.branch.id,
            name: _name.text.trim(),
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            phone: assembleUzPhone(_phone.text),
            isActive: _isActive,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Код филиала неизменяем (в BranchUpdate его нет) — показываем в заголовке.
    return AlertDialog(
      title: Text('Филиал ${widget.branch.code}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Адрес'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Телефон'),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Активен'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}

// ═══ Сотрудники ══════════════════════════════════════════════════════════════

class _StaffTab extends ConsumerWidget {
  const _StaffTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    final branches = ref.watch(adminBranchesProvider);
    final me = ref.watch(authControllerProvider).user;
    final canCreate = me?.can('users.create') ?? false;
    final canUpdate = me?.can('users.update') ?? false;
    final disabled = Theme.of(context).disabledColor;

    final branchNames = {
      for (final b in branches.valueOrNull ?? const <AdminBranch>[])
        b.id: b.name,
    };

    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openCreate(context, ref),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Новый сотрудник'),
            )
          : null,
      body: AsyncValueWidget<List<StaffUser>>(
        value: users,
        onRetry: () => ref.invalidate(adminUsersProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Сотрудников пока нет.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = items[i];
              final greyed = u.isActive ? null : TextStyle(color: disabled);
              final branch = branchNames[u.branchId];
              final payLabel = _payLabel(u);
              final hasPercent = payLabel != null;
              return ListTile(
                isThreeLine: u.roles.isNotEmpty || u.isSuperuser || hasPercent,
                leading: CircleAvatar(
                  child: Icon(
                    u.isSuperuser
                        ? Icons.shield_outlined
                        : Icons.person_outline,
                  ),
                ),
                title: Text(u.fullName, style: greyed),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text([u.email, ?branch].join(' · '), style: greyed),
                    if (u.roles.isNotEmpty || u.isSuperuser || hasPercent)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (u.isSuperuser)
                              const Chip(
                                label: Text('владелец'),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                              ),
                            for (final r in u.roles)
                              Chip(
                                label: Text(r),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (hasPercent)
                              Chip(
                                avatar: const Icon(Icons.payments_outlined,
                                    size: 16),
                                label: Text(payLabel),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Владельца (superuser) из UI не деактивируем — защита от
                // самоблокировки системы.
                trailing: Switch(
                  value: u.isActive,
                  onChanged: (canUpdate && !u.isSuperuser)
                      ? (v) => _toggleActive(context, ref, u, v)
                      : null,
                ),
                // Тап по строке — редактирование (процент врача). Владельца не
                // трогаем; без права users.update строка не кликабельна.
                onTap: (canUpdate && !u.isSuperuser)
                    ? () => _openEdit(context, ref, u)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    StaffUser u,
    bool value,
  ) async {
    try {
      await ref.read(adminRepositoryProvider).updateUser(u.id, isActive: value);
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        _showSnack(
          context,
          value
              ? 'Доступ включён: ${u.fullName}'
              : 'Доступ отключён: ${u.fullName}',
        );
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _UserCreateDialog(),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(adminUsersProvider);
      _showSnack(context, 'Сотрудник создан');
    }
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    StaffUser user,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _UserEditDialog(user: user),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(adminUsersProvider);
      _showSnack(context, 'Сотрудник обновлён');
    }
  }
}

class _UserCreateDialog extends ConsumerStatefulWidget {
  const _UserCreateDialog();

  @override
  ConsumerState<_UserCreateDialog> createState() => _UserCreateDialogState();
}

class _UserCreateDialogState extends ConsumerState<_UserCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();
  final _cabinet = TextEditingController();
  final _queuePrefix = TextEditingController();
  bool _isExternalSurgeon = false;
  final _selectedRoles = <String>{};
  final _selectedServiceIds = <String>{};
  final _selectedDiagnosisIds = <String>{};
  String? _branchId;
  // Оплата врача — задаётся сразу при добавлении (тип нет/процент/фикс + значение).
  String _consultType = _kNoPay;
  String _operationType = _kNoPay;
  final _consultValue = TextEditingController();
  final _operationValue = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _password.dispose();
    _cabinet.dispose();
    _queuePrefix.dispose();
    _consultValue.dispose();
    _operationValue.dispose();
    super.dispose();
  }

  String _normPay(TextEditingController c) => c.text.trim().replaceAll(',', '.');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_payErr(_consultType, _consultValue) != null ||
        _payErr(_operationType, _operationValue) != null) {
      setState(() {}); // surface inline errors
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .createUser(
            email: _email.text.trim(),
            fullName: _fullName.text.trim(),
            password: _password.text,
            roleNames: _selectedRoles.toList(),
            branchId: _branchId,
            cabinet: _cabinet.text.trim().isEmpty ? null : _cabinet.text.trim(),
            serviceIds: _selectedServiceIds.toList(),
            queuePrefix: _queuePrefix.text.trim().isEmpty
                ? null
                : _queuePrefix.text.trim(),
            isExternalSurgeon: _isExternalSurgeon,
            diagnosisIds: _selectedDiagnosisIds.toList(),
            consultSalaryType: _consultType == _kNoPay ? null : _consultType,
            consultSalaryValue:
                _consultType == _kNoPay ? null : _normPay(_consultValue),
            operationSalaryType:
                _operationType == _kNoPay ? null : _operationType,
            operationSalaryValue:
                _operationType == _kNoPay ? null : _normPay(_operationValue),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(adminRolesProvider);
    final branches = ref.watch(adminBranchesProvider);
    final services = ref.watch(adminServicesProvider);
    final diagnoses = ref.watch(adminDiagnosesProvider);

    return AlertDialog(
      title: const Text('Новый сотрудник'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Обязательное поле';
                    if (!s.contains('@') || !s.contains('.')) {
                      return 'Некорректный email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(labelText: 'ФИО'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Обязательное поле'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль (минимум 8 символов)',
                  ),
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Минимум 8 символов' : null,
                ),
                const SizedBox(height: 12),
                branches.when(
                  data: (items) => DropdownButtonFormField<String?>(
                    initialValue: _branchId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Филиал'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Без филиала'),
                      ),
                      for (final b in items.where((b) => b.isActive))
                        DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _branchId = v),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Text(
                    'Филиалы недоступны: $e',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cabinet,
                  decoration: const InputDecoration(
                    labelText: 'Кабинет (для врача)',
                    hintText: 'Каб. 1',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _queuePrefix,
                  decoration: const InputDecoration(
                    labelText: 'Префикс очереди (напр. С → С-001)',
                    hintText: 'авто из имени',
                  ),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Внешний хирург (из Ташкента)'),
                  value: _isExternalSurgeon,
                  onChanged: (v) => setState(() => _isExternalSurgeon = v),
                ),
                const SizedBox(height: 12),
                Text('Оплата врача',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _PaySideField(
                  label: 'За приём',
                  type: _consultType,
                  value: _consultValue,
                  onType: (v) => setState(() => _consultType = v),
                  onChanged: () => setState(() {}),
                  fixedHint: 'фикс. в месяц',
                ),
                const SizedBox(height: 12),
                _PaySideField(
                  label: 'За операции (хирургу)',
                  type: _operationType,
                  value: _operationValue,
                  onType: (v) => setState(() => _operationType = v),
                  onChanged: () => setState(() {}),
                  fixedHint: 'за операцию',
                ),
                const SizedBox(height: 16),
                Text('Роли', style: Theme.of(context).textTheme.titleSmall),
                roles.when(
                  data: (items) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final r in items)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(r.name),
                          subtitle: Text(
                            r.description ?? 'прав: ${r.permissionCount}',
                          ),
                          value: _selectedRoles.contains(r.name),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selectedRoles.add(r.name);
                            } else {
                              _selectedRoles.remove(r.name);
                            }
                          }),
                        ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Text(
                    'Роли недоступны: $e',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _asyncMultiPick<Service>(
                  context,
                  services,
                  title: 'Услуги врача',
                  emptyHint: 'Нет услуг',
                  errorLabel: 'Услуги недоступны',
                  selected: _selectedServiceIds,
                  onChanged: () => setState(() {}),
                  id: (s) => s.id,
                  label: (s) => s.name,
                  isActive: (s) => s.isActive,
                  sub: (s) => '${s.code} · ${formatMoney(s.price)}',
                ),
                const SizedBox(height: 16),
                _asyncMultiPick<DiagnosisRef>(
                  context,
                  diagnoses,
                  title: 'Разрешённые заключения',
                  emptyHint: 'Нет диагнозов',
                  errorLabel: 'Диагнозы недоступны',
                  selected: _selectedDiagnosisIds,
                  onChanged: () => setState(() {}),
                  id: (d) => d.id,
                  label: (d) => d.name,
                  isActive: (d) => true,
                  sub: (d) => d.category,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Создать'),
        ),
      ],
    );
  }
}

/// Редактирование сотрудника: кабинет врача, услуги, которые он ведёт, роли и
/// процентная оплата («Процент врача», 0–100). Пустой процент = снять с процента
/// (salary_percent: null); пустой кабинет = очистить (cabinet: null).
class _UserEditDialog extends ConsumerStatefulWidget {
  const _UserEditDialog({required this.user});

  final StaffUser user;

  @override
  ConsumerState<_UserEditDialog> createState() => _UserEditDialogState();
}

/// Sentinel for the «не оплачивается» option in the pay-type dropdowns.
const _kNoPay = '';

/// Validate one pay side (type нет/percent/fixed + value). Null = valid.
String? _payErr(String type, TextEditingController c) {
  if (type == _kNoPay) return null;
  final raw = c.text.trim().replaceAll(',', '.');
  if (raw.isEmpty) return 'Введите значение';
  final v = double.tryParse(raw);
  if (v == null) return 'Введите число';
  if (v < 0) return 'Не меньше 0';
  if (type == 'percent' && v > 100) return 'Процент 0–100';
  return null;
}

/// Reusable «одна сторона оплаты»: dropdown (нет/процент/фикс) + поле значения.
class _PaySideField extends StatelessWidget {
  const _PaySideField({
    required this.label,
    required this.type,
    required this.value,
    required this.onType,
    required this.onChanged,
    required this.fixedHint,
  });

  final String label;
  final String type;
  final TextEditingController value;
  final ValueChanged<String> onType;
  final VoidCallback onChanged;
  final String fixedHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: type,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: const [
            DropdownMenuItem(value: _kNoPay, child: Text('Не оплачивается')),
            DropdownMenuItem(value: 'percent', child: Text('Процент (%)')),
            DropdownMenuItem(value: 'fixed', child: Text('Фикс. сумма')),
          ],
          onChanged: (v) => onType(v ?? _kNoPay),
        ),
        if (type != _kNoPay) ...[
          const SizedBox(height: 8),
          TextField(
            controller: value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              labelText: type == 'percent' ? 'Процент' : 'Сумма, сум',
              suffixText: type == 'percent' ? '%' : null,
              hintText: type == 'percent' ? '0–100' : fixedHint,
              errorText: _payErr(type, value),
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ],
    );
  }
}

/// Short pay summary for the staff list chip, e.g. «Приём 30% · Опер. фикс».
/// Falls back to the legacy salaryPercent. Null = no pay configured.
String? _payLabel(StaffUser u) {
  String? side(String? type, String? value, String prefix) {
    final t = type ?? (prefix == 'Приём' && u.salaryPercent != null ? 'percent' : null);
    final v = value ?? (prefix == 'Приём' ? u.salaryPercent : null);
    if (t == null) return null;
    if (t == 'percent') return '$prefix $v%';
    return '$prefix фикс';
  }

  final parts = [
    ?side(u.consultSalaryType, u.consultSalaryValue, 'Приём'),
    ?side(u.operationSalaryType, u.operationSalaryValue, 'Опер.'),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

class _UserEditDialogState extends ConsumerState<_UserEditDialog> {
  // Оплата врача: тип ('percent'|'fixed'|'' = нет) + значение, отдельно за приём
  // и за операции. Приём предзаполняем из новой пары, иначе из legacy salaryPercent.
  late String _consultType =
      widget.user.consultSalaryType ??
      (widget.user.salaryPercent != null ? 'percent' : _kNoPay);
  late String _operationType = widget.user.operationSalaryType ?? _kNoPay;
  late final _consultValue = TextEditingController(
    text: widget.user.consultSalaryValue ?? widget.user.salaryPercent ?? '',
  );
  late final _operationValue = TextEditingController(
    text: widget.user.operationSalaryValue ?? '',
  );
  late final _cabinet = TextEditingController(text: widget.user.cabinet ?? '');
  late final _queuePrefix = TextEditingController(
    text: widget.user.queuePrefix ?? '',
  );
  late bool _isExternalSurgeon = widget.user.isExternalSurgeon;
  // Предзаполняем текущими ролями пользователя — снять/добавить можно тут же.
  late final _selectedRoles = <String>{...widget.user.roles};
  late final _selectedServiceIds = <String>{
    for (final s in widget.user.services) s.id,
  };
  late final _selectedDiagnosisIds = <String>{
    for (final d in widget.user.diagnoses) d.id,
  };
  bool _saving = false;

  @override
  void dispose() {
    _consultValue.dispose();
    _operationValue.dispose();
    _cabinet.dispose();
    _queuePrefix.dispose();
    super.dispose();
  }

  // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
  String _norm(TextEditingController c) => c.text.trim().replaceAll(',', '.');

  /// Validate one pay side: empty value with a type set, non-numeric, negative,
  /// or percent > 100. Returns an error string or null.
  String? _validateSide(String type, TextEditingController c) {
    if (type == _kNoPay) return null;
    final raw = _norm(c);
    if (raw.isEmpty) return 'Введите значение';
    final v = double.tryParse(raw);
    if (v == null) return 'Введите число';
    if (v < 0) return 'Не меньше 0';
    if (type == 'percent' && v > 100) return 'Процент 0–100';
    return null;
  }

  bool get _canSave =>
      !_saving &&
      _validateSide(_consultType, _consultValue) == null &&
      _validateSide(_operationType, _operationValue) == null;

  Future<void> _save() async {
    setState(() => _saving = true);
    final cab = _cabinet.text.trim();
    final qp = _queuePrefix.text.trim();
    final consultRaw = _norm(_consultValue);
    final operationRaw = _norm(_operationValue);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateUser(
            widget.user.id,
            roleNames: _selectedRoles.toList(),
            // Новая гибкая оплата: тип + значение, отдельно за приём и операции.
            // Тип «нет» отправляет null/null — снимает оплату на этой стороне.
            updateConsultSalary: true,
            consultSalaryType: _consultType == _kNoPay ? null : _consultType,
            consultSalaryValue: _consultType == _kNoPay ? null : consultRaw,
            updateOperationSalary: true,
            operationSalaryType: _operationType == _kNoPay ? null : _operationType,
            operationSalaryValue:
                _operationType == _kNoPay ? null : operationRaw,
            // Заодно гасим legacy-поле, чтобы оно не «зеркалировалось» обратно.
            clearSalaryPercent: true,
            cabinet: cab.isEmpty ? null : cab,
            clearCabinet: cab.isEmpty,
            serviceIds: _selectedServiceIds.toList(),
            queuePrefix: qp.isEmpty ? null : qp,
            // Пустое поле — явный сброс префикса очереди (отправляем null).
            clearQueuePrefix: qp.isEmpty,
            isExternalSurgeon: _isExternalSurgeon,
            diagnosisIds: _selectedDiagnosisIds.toList(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack(context, e.toString(), error: true);
      }
    }
  }

  /// One pay side: a type dropdown (нет/процент/фикс) + a value field that
  /// only shows when a type is chosen.
  Widget _paySide({
    required String label,
    required String type,
    required TextEditingController value,
    required ValueChanged<String> onType,
    required String fixedHint,
  }) {
    final err = _validateSide(type, value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: type,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: const [
            DropdownMenuItem(value: _kNoPay, child: Text('Не оплачивается')),
            DropdownMenuItem(value: 'percent', child: Text('Процент (%)')),
            DropdownMenuItem(value: 'fixed', child: Text('Фикс. сумма')),
          ],
          onChanged: (v) => setState(() => onType(v ?? _kNoPay)),
        ),
        if (type != _kNoPay) ...[
          const SizedBox(height: 8),
          TextField(
            controller: value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              labelText: type == 'percent' ? 'Процент' : 'Сумма, сум',
              suffixText: type == 'percent' ? '%' : null,
              hintText: type == 'percent' ? '0–100' : fixedHint,
              errorText: err,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(adminRolesProvider);
    final services = ref.watch(adminServicesProvider);
    final diagnoses = ref.watch(adminDiagnosesProvider);
    return AlertDialog(
      title: Text(widget.user.fullName),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.email,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Оплата врача',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _paySide(
                label: 'За приём',
                type: _consultType,
                value: _consultValue,
                onType: (v) => _consultType = v,
                fixedHint: 'фикс. в месяц',
              ),
              const SizedBox(height: 12),
              _paySide(
                label: 'За операции (хирургу)',
                type: _operationType,
                value: _operationValue,
                onType: (v) => _operationType = v,
                fixedHint: 'за операцию',
              ),
              const Divider(height: 24),
              const SizedBox(height: 4),
              TextField(
                controller: _cabinet,
                decoration: const InputDecoration(
                  labelText: 'Кабинет (для врача)',
                  hintText: 'Каб. 1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _queuePrefix,
                decoration: const InputDecoration(
                  labelText: 'Префикс очереди (напр. С → С-001)',
                  hintText: 'авто из имени',
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Внешний хирург (из Ташкента)'),
                value: _isExternalSurgeon,
                onChanged: (v) => setState(() => _isExternalSurgeon = v),
              ),
              const SizedBox(height: 16),
              Text(
                'Роли / доступ',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              roles.when(
                data: (items) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final r in items)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(r.name),
                        subtitle: Text(
                          r.description ?? 'прав: ${r.permissionCount}',
                        ),
                        value: _selectedRoles.contains(r.name),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedRoles.add(r.name);
                          } else {
                            _selectedRoles.remove(r.name);
                          }
                        }),
                      ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Text(
                  'Роли недоступны: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),
              _asyncMultiPick<Service>(
                context,
                services,
                title: 'Услуги врача',
                emptyHint: 'Нет услуг',
                errorLabel: 'Услуги недоступны',
                selected: _selectedServiceIds,
                onChanged: () => setState(() {}),
                id: (s) => s.id,
                label: (s) => s.name,
                isActive: (s) => s.isActive,
                sub: (s) => '${s.code} · ${formatMoney(s.price)}',
              ),
              const SizedBox(height: 16),
              _asyncMultiPick<DiagnosisRef>(
                context,
                diagnoses,
                title: 'Разрешённые заключения',
                emptyHint: 'Нет диагнозов',
                errorLabel: 'Диагнозы недоступны',
                selected: _selectedDiagnosisIds,
                onChanged: () => setState(() {}),
                id: (d) => d.id,
                label: (d) => d.name,
                isActive: (d) => true,
                sub: (d) => d.category,
              ),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}

// ═══ Диагнозы (справочник заключений) ════════════════════════════════════════

/// Каталог диагнозов/заключений. Сотруднику можно разрешить лишь часть из них
/// (см. пикер «Разрешённые заключения» в карточке сотрудника).
class _DiagnosesTab extends ConsumerWidget {
  const _DiagnosesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnoses = ref.watch(adminDiagnosesProvider);
    final user = ref.watch(authControllerProvider).user;
    final canManage = user?.can('diagnoses.manage') ?? false;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openCreate(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Новый диагноз'),
            )
          : null,
      body: AsyncValueWidget<List<DiagnosisRef>>(
        value: diagnoses,
        onRetry: () => ref.invalidate(adminDiagnosesProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Диагнозов пока нет.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = items[i];
              return ListTile(
                leading: Icon(Icons.assignment_outlined, color: primary),
                title: Text(d.name),
                subtitle: Text(
                  [d.code, if (d.category != null) d.category!].join(' · '),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _DiagnosisCreateDialog(),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(adminDiagnosesProvider);
      _showSnack(context, 'Диагноз создан');
    }
  }
}

class _DiagnosisCreateDialog extends ConsumerStatefulWidget {
  const _DiagnosisCreateDialog();

  @override
  ConsumerState<_DiagnosisCreateDialog> createState() =>
      _DiagnosisCreateDialogState();
}

class _DiagnosisCreateDialogState
    extends ConsumerState<_DiagnosisCreateDialog> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _category = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _category.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving && _code.text.trim().isNotEmpty && _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .createDiagnosis(
            code: _code.text.trim(),
            name: _name.text.trim(),
            category: _category.text.trim().isEmpty
                ? null
                : _category.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый диагноз'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Код (уникальный)',
                hintText: 'H52.1',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: 'Категория (необязательно)',
              ),
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Создать'),
        ),
      ],
    );
  }
}
