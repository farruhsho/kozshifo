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
          bottom: const TabBar(tabs: [
            Tab(text: 'Услуги и цены'),
            Tab(text: 'Филиалы'),
            Tab(text: 'Сотрудники'),
          ]),
        ),
        body: const TabBarView(children: [
          _ServicesTab(),
          _BranchesTab(),
          _StaffTab(),
        ]),
      ),
    );
  }
}

void _showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}

// ═══ Услуги и цены ═══════════════════════════════════════════════════════════

class _ServicesTab extends ConsumerWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(adminServicesProvider);
    final user = ref.watch(authControllerProvider).user;
    final canCreate = user?.can('services.create') ?? false;
    final canUpdate = user?.can('services.update') ?? false;
    final disabled = Theme.of(context).disabledColor;

    return Scaffold(
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
                leading: Icon(Icons.medical_services_outlined,
                    color: s.isActive
                        ? Theme.of(context).colorScheme.primary
                        : disabled),
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
                    Text(formatMoney(s.price),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: s.isActive ? null : disabled)),
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
      BuildContext context, WidgetRef ref, Service service) async {
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
      await ref.read(adminRepositoryProvider).createService(
            code: _code.text.trim(),
            name: _name.text.trim(),
            price: _normalizedPrice,
            categoryId: _categoryId,
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

    return AlertDialog(
      title: const Text('Новая услуга'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                  labelText: 'Код (уникальный)', hintText: 'CONS-01'),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                      value: null, child: Text('Без категории')),
                  for (final c in items)
                    DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              // Категория необязательна — при ошибке загрузки не блокируем создание.
              error: (e, _) => Text('Категории недоступны: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
      await ref.read(adminRepositoryProvider).updateService(
            widget.service.id,
            name: _name.text.trim(),
            price: _normalizedPrice,
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
    return AlertDialog(
      title: Text('Услуга ${widget.service.code}'),
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
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                leading: Icon(Icons.local_hospital_outlined,
                    color: b.isActive ? primary : disabled),
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
      BuildContext context, WidgetRef ref, AdminBranch branch) async {
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
      await ref.read(adminRepositoryProvider).createBranch(
            name: _name.text.trim(),
            code: _code.text.trim(),
            address:
                _address.text.trim().isEmpty ? null : _address.text.trim(),
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
                  labelText: 'Код (уникальный)', hintText: 'TASH-02'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration:
                  const InputDecoration(labelText: 'Адрес (необязательно)'),
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
                  child: CircularProgressIndicator(strokeWidth: 2))
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
  late final _address =
      TextEditingController(text: widget.branch.address ?? '');
  late final _phone =
      TextEditingController(text: extractUzPhoneLocal(widget.branch.phone));
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
      await ref.read(adminRepositoryProvider).updateBranch(
            widget.branch.id,
            name: _name.text.trim(),
            address:
                _address.text.trim().isEmpty ? null : _address.text.trim(),
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
                  child: CircularProgressIndicator(strokeWidth: 2))
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
              final hasPercent = u.salaryPercent != null;
              return ListTile(
                isThreeLine: u.roles.isNotEmpty || u.isSuperuser || hasPercent,
                leading: CircleAvatar(
                  child: Icon(u.isSuperuser
                      ? Icons.shield_outlined
                      : Icons.person_outline),
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
                                avatar: const Icon(Icons.percent, size: 16),
                                label: Text('${u.salaryPercent}%'),
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
      BuildContext context, WidgetRef ref, StaffUser u, bool value) async {
    try {
      await ref.read(adminRepositoryProvider).updateUser(u.id, isActive: value);
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        _showSnack(context,
            value ? 'Доступ включён: ${u.fullName}' : 'Доступ отключён: ${u.fullName}');
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
      BuildContext context, WidgetRef ref, StaffUser user) async {
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
  final _selectedRoles = <String>{};
  String? _branchId;
  bool _saving = false;

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).createUser(
            email: _email.text.trim(),
            fullName: _fullName.text.trim(),
            password: _password.text,
            roleNames: _selectedRoles.toList(),
            branchId: _branchId,
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
                      labelText: 'Пароль (минимум 8 символов)'),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Минимум 8 символов'
                      : null,
                ),
                const SizedBox(height: 12),
                branches.when(
                  data: (items) => DropdownButtonFormField<String?>(
                    initialValue: _branchId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Филиал'),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('Без филиала')),
                      for (final b in items.where((b) => b.isActive))
                        DropdownMenuItem<String?>(
                            value: b.id,
                            child:
                                Text(b.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _branchId = v),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Text('Филиалы недоступны: $e',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
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
                          subtitle: Text(r.description ??
                              'прав: ${r.permissionCount}'),
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
                  error: (e, _) => Text('Роли недоступны: $e',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
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
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Создать'),
        ),
      ],
    );
  }
}

/// Редактирование сотрудника: процентная оплата врача («Процент врача», 0–100).
/// Пустое поле = снять с процентной оплаты (бэкенду уходит salary_percent: null).
class _UserEditDialog extends ConsumerStatefulWidget {
  const _UserEditDialog({required this.user});

  final StaffUser user;

  @override
  ConsumerState<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends ConsumerState<_UserEditDialog> {
  late final _percent =
      TextEditingController(text: widget.user.salaryPercent ?? '');
  // Предзаполняем текущими ролями пользователя — снять/добавить можно тут же.
  late final _selectedRoles = <String>{...widget.user.roles};
  bool _saving = false;

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  // ru/uz-раскладки дают запятую — нормализуем до точки для Decimal.
  String get _normalizedPercent => _percent.text.trim().replaceAll(',', '.');

  /// Пусто = допустимо (снять с процента). Иначе — число 0..100.
  String? _validatePercent() {
    final raw = _normalizedPercent;
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null) return 'Введите число';
    if (v < 0 || v > 100) return 'Диапазон 0–100';
    return null;
  }

  bool get _canSave => !_saving && _validatePercent() == null;

  Future<void> _save() async {
    setState(() => _saving = true);
    final raw = _normalizedPercent;
    try {
      await ref.read(adminRepositoryProvider).updateUser(
            widget.user.id,
            roleNames: _selectedRoles.toList(),
            salaryPercent: raw.isEmpty ? null : raw,
            // Пустое поле — явный сброс процентной оплаты (отправляем null).
            clearSalaryPercent: raw.isEmpty,
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
    final error = _percent.text.trim().isEmpty ? null : _validatePercent();
    final roles = ref.watch(adminRolesProvider);
    return AlertDialog(
      title: Text(widget.user.fullName),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.email,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              TextField(
                controller: _percent,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Процент врача',
                  hintText: '0–100',
                  suffixText: '%',
                  helperText: 'Пусто — снять с процентной оплаты',
                  errorText: error,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text('Роли / доступ',
                  style: Theme.of(context).textTheme.titleSmall),
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
                            r.description ?? 'прав: ${r.permissionCount}'),
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
                error: (e, _) => Text('Роли недоступны: $e',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
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
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
