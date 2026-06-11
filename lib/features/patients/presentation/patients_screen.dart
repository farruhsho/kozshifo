import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/page.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/patients_repository.dart';
import '../domain/patient.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(patientSearchProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(patientsListProvider);
    final canCreate = ref.watch(authControllerProvider).user?.can('patients.create') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Пациенты')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openRegisterDialog,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Регистрация'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Поиск по ФИО, номеру карты или телефону',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueWidget<Page<Patient>>(
              value: patients,
              onRetry: () => ref.invalidate(patientsListProvider),
              builder: (page) => _PatientList(page: page),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRegisterDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _RegisterPatientDialog(),
    );
    if (created == true) ref.invalidate(patientsListProvider);
  }
}

class _PatientList extends StatelessWidget {
  const _PatientList({required this.page});

  final Page<Patient> page;

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) {
      return const Center(child: Text('Пациенты не найдены'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Всего: ${page.total}',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = page.items[i];
              return ListTile(
                leading: CircleAvatar(child: Text(p.initials)),
                title: Text(p.fullName),
                subtitle: Text([p.mrn, if (p.phone != null) p.phone!].join('  ·  ')),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RegisterPatientDialog extends ConsumerStatefulWidget {
  const _RegisterPatientDialog();

  @override
  ConsumerState<_RegisterPatientDialog> createState() => _RegisterPatientDialogState();
}

class _RegisterPatientDialogState extends ConsumerState<_RegisterPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final branchId = ref.read(authControllerProvider).user?.branchId;
      await ref.read(patientsRepositoryProvider).create(
            lastName: _lastName.text.trim(),
            firstName: _firstName.text.trim(),
            phone: _phone.text.trim(),
            branchId: branchId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Регистрация пациента'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Фамилия'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Имя'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Телефон (необязательно)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
