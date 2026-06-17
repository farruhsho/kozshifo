import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/page.dart';
import '../../../core/utils/input_formatters.dart';
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
    final user = ref.watch(authControllerProvider).user;
    final canCreate = user?.can('patients.create') ?? false;
    final canViewVisits = user?.can('visits.read') ?? false;

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
              builder: (page) =>
                  _PatientList(page: page, canViewVisits: canViewVisits),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRegisterDialog() async {
    final created = await showDialog<Patient>(
      context: context,
      builder: (_) => const RegisterPatientDialog(),
    );
    if (created != null) ref.invalidate(patientsListProvider);
  }
}

class _PatientList extends StatelessWidget {
  const _PatientList({required this.page, required this.canViewVisits});

  final Page<Patient> page;
  final bool canViewVisits;

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
            child: Text(
              'Всего: ${page.total}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
                subtitle: Text(
                  [p.mrn, if (p.phone != null) p.phone!].join('  ·  '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canViewVisits)
                      IconButton(
                        tooltip: 'История визитов',
                        icon: const Icon(Icons.history),
                        onPressed: () =>
                            context.go('/patients/${p.id}/visits'),
                      ),
                    TextButton.icon(
                      onPressed: () => context.go('/patients/${p.id}/card'),
                      icon: const Icon(Icons.medical_information_outlined),
                      label: const Text('Карта'),
                    ),
                  ],
                ),
                onTap: () => context.go('/patients/${p.id}/card'),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Регистрация пациента. Возвращает созданного [Patient] через `Navigator.pop`
/// (используется и списком пациентов, и экраном ресепшена).
class RegisterPatientDialog extends ConsumerStatefulWidget {
  const RegisterPatientDialog({super.key, this.initialPhone});

  /// Предзаполнить телефон (ресепшен: поиск по номеру без результатов).
  final String? initialPhone;

  @override
  ConsumerState<RegisterPatientDialog> createState() =>
      _RegisterPatientDialogState();
}

/// Patient gender — wire value → RU label (mirrors backend `Gender`).
const kGenderLabels = <String, String>{
  'male': 'Мужской',
  'female': 'Женский',
  'other': 'Другой',
};

/// CRM lead source — wire value → RU label (mirrors backend `LeadSource`).
/// Feeds the director's «Источники пациентов» analytics, so it's a first-class
/// field on the registration form, not buried.
const kLeadSourceLabels = <String, String>{
  'instagram': 'Instagram',
  'telegram': 'Telegram',
  'google': 'Google',
  'referral': 'Рекомендация',
  'banner': 'Баннер',
  'walk_in': 'Проходил мимо',
  'other': 'Другое',
};

class _RegisterPatientDialogState extends ConsumerState<RegisterPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  // Basics (always visible).
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  // Телефон хранит только локальную часть (9 цифр); префикс «+998 » — в поле.
  late final _phone =
      TextEditingController(text: extractUzPhoneLocal(widget.initialPhone));
  // Дата рождения вводится текстом в маске ДД.ММ.ГГГГ (или из календаря).
  final _birthDate = TextEditingController();
  String? _gender;
  String? _leadSource;
  // Advanced (collapsed — rarely used, must not slow the common path).
  final _phone2 = TextEditingController();
  final _address = TextEditingController();
  final _passport = TextEditingController();
  final _pinfl = TextEditingController();
  final _workplace = TextEditingController();
  final _profession = TextEditingController();
  final _notes = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  // Управляет раскрытием «Расширенных данных» — раскрываем при ошибке валидации
  // в свёрнутых полях, чтобы сообщение было видно.
  final _advancedController = ExpansibleController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _lastName, _firstName, _middleName, _phone, _birthDate, _phone2,
      _address, _passport, _pinfl, _workplace, _profession, _notes,
    ]) {
      c.dispose();
    }
    _firstNameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  /// Парсит дату из поля (маска `ДД.ММ.ГГГГ`) в [DateTime].
  /// Возвращает `null`, если дата неполная или некорректная (несуществующий
  /// день/месяц, будущая дата, год вне диапазона).
  DateTime? _parseBirthDate() {
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(_birthDate.text);
    if (m == null) return null;
    final day = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    final year = int.parse(m.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 1900) return null;
    final d = DateTime(year, month, day);
    // Отклоняем «перетекание» (например 31.02) и будущие даты.
    if (d.year != year || d.month != month || d.day != day) return null;
    if (d.isAfter(DateTime.now())) return null;
    return d;
  }

  /// Дата рождения для бэкенда (`YYYY-MM-DD`) или `null`, если поле пустое.
  String? _ymd() {
    final d = _parseBirthDate();
    return d == null
        ? null
        : '${d.year.toString().padLeft(4, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseBirthDate() ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Дата рождения',
    );
    if (picked != null) {
      setState(() => _birthDate.text =
          '${picked.day.toString().padLeft(2, '0')}.'
          '${picked.month.toString().padLeft(2, '0')}.'
          '${picked.year}');
    }
  }

  /// Свёрнутые расширенные поля заполнены, но не проходят валидацию — тогда
  /// перед показом ошибок раскрываем секцию, иначе сообщение не видно.
  bool get _advancedHasInvalid {
    bool badDigits(String v, int len) {
      final d = v.replaceAll(RegExp(r'[^0-9]'), '');
      return d.isNotEmpty && d.length != len;
    }

    final passport = _passport.text.trim();
    return badDigits(_phone2.text, kUzPhoneLocalLength) ||
        badDigits(_pinfl.text, 14) ||
        (passport.isNotEmpty && !RegExp(r'^[A-Z]{2}\d{7}$').hasMatch(passport));
  }

  Future<void> _save() async {
    if (_advancedHasInvalid && !_advancedController.isExpanded) {
      _advancedController.expand();
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final branchId = ref.read(authControllerProvider).user?.branchId;
      final patient = await ref
          .read(patientsRepositoryProvider)
          .create(
            lastName: _lastName.text.trim(),
            firstName: _firstName.text.trim(),
            middleName: _middleName.text,
            birthDate: _ymd(),
            gender: _gender,
            // Поле хранит локальную часть — собираем «+998…» для бэкенда.
            phone: assembleUzPhone(_phone.text),
            phone2: assembleUzPhone(_phone2.text),
            leadSource: _leadSource,
            address: _address.text,
            passport: _passport.text,
            pinfl: _pinfl.text,
            workplace: _workplace.text,
            profession: _profession.text,
            notes: _notes.text,
            branchId: branchId,
          );
      if (mounted) Navigator.of(context).pop(patient);
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
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Поток без мыши на основных текстовых полях:
                // фамилия → Enter → имя → Enter → телефон → Enter = сохранить.
                TextFormField(
                  controller: _lastName,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _firstNameFocus.requestFocus(),
                  decoration: const InputDecoration(labelText: 'Фамилия'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Обязательное поле'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstName,
                  focusNode: _firstNameFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                  decoration: const InputDecoration(labelText: 'Имя'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Обязательное поле'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _middleName,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Отчество'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _birthDate,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [DateInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Дата рождения',
                          hintText: 'ДД.ММ.ГГГГ',
                          suffixIcon: IconButton(
                            tooltip: 'Выбрать в календаре',
                            icon: const Icon(Icons.calendar_today, size: 18),
                            onPressed: _pickBirthDate,
                          ),
                        ),
                        // Необязательное поле, но если заполнено — должно быть
                        // корректной датой.
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return _parseBirthDate() == null
                              ? 'Неверная дата'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(labelText: 'Пол'),
                        items: [
                          for (final e in kGenderLabels.entries)
                            DropdownMenuItem(value: e.key, child: Text(e.value)),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: uzPhoneLocal,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Телефон (необязательно)',
                    prefixText: '+998 ',
                    hintText: '90 123 45 67',
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.isEmpty) return null; // необязательное
                    return digits.length == kUzPhoneLocalLength
                        ? null
                        : 'Введите 9 цифр номера';
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _leadSource,
                  decoration: const InputDecoration(
                    labelText: 'Источник клиента',
                    helperText: 'Откуда пришёл пациент — для аналитики',
                  ),
                  items: [
                    for (final e in kLeadSourceLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => _leadSource = v),
                ),
                const SizedBox(height: 4),
                // Редко используемые поля — свёрнуты, чтобы не замедлять обычную
                // регистрацию (SELF IMPROVEMENT MEDICAL MODE).
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    controller: _advancedController,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: const Text('Расширенные данные'),
                    children: [
                      TextFormField(
                        controller: _phone2,
                        keyboardType: TextInputType.phone,
                        inputFormatters: uzPhoneLocal,
                        decoration: const InputDecoration(
                          labelText: 'Дополнительный телефон',
                          prefixText: '+998 ',
                          hintText: '90 123 45 67',
                        ),
                        validator: (v) {
                          final digits =
                              (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.isEmpty) return null;
                          return digits.length == kUzPhoneLocalLength
                              ? null
                              : 'Введите 9 цифр номера';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(labelText: 'Адрес'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passport,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: const [PassportInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Паспорт',
                          hintText: 'AB1234567',
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return null;
                          return RegExp(r'^[A-Z]{2}\d{7}$').hasMatch(t)
                              ? null
                              : 'Формат: 2 буквы + 7 цифр';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pinfl,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsOnly(14),
                        decoration: const InputDecoration(
                          labelText: 'ПИНФЛ',
                          hintText: '14 цифр',
                        ),
                        validator: (v) {
                          final digits =
                              (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.isEmpty) return null;
                          return digits.length == 14
                              ? null
                              : 'ПИНФЛ — ровно 14 цифр';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _workplace,
                        decoration: const InputDecoration(
                          labelText: 'Место работы',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _profession,
                        decoration: const InputDecoration(
                          labelText: 'Профессия',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notes,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Примечание',
                        ),
                      ),
                    ],
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
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
