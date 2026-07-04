import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/file_saver.dart';
import '../../../core/utils/flow_labels.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../attachments/presentation/attachments_section.dart';
import '../../auth/application/auth_controller.dart';
import '../../clinical/presentation/operations_section.dart';
import '../../clinical/presentation/treatments_section.dart';
import '../../devices/data/devices_repository.dart';
import '../../devices/domain/device_result.dart';
import '../../patients/data/patients_repository.dart';
import '../data/doctor_repository.dart';
import '../data/exam_draft_store.dart';
import '../domain/exam_template.dart';
import '../domain/eye_exam.dart';
import '../domain/timeline_event.dart';
import '../domain/visit_diagnosis.dart';
import '../domain/visit_summary.dart';
import 'patient_info_card.dart';

/// Результат диалога выбора даты повторного приёма: [date] == null означает
/// «Без повтора». [isoDate] — 'YYYY-MM-DD' для follow_up_date или null.
class _FollowUpChoice {
  const _FollowUpChoice(this.date);

  final DateTime? date;

  String? get isoDate {
    final d = date;
    if (d == null) return null;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}

/// Прибавляет [months] месяцев к дате, кламп дня к последнему валидному дню
/// целевого месяца (31 янв + 1 мес → 28/29 фев, а не «перекат» в март).
DateTime addMonthClamped(DateTime d, int months) {
  final year = d.year + ((d.month - 1 + months) ~/ 12);
  final month = (d.month - 1 + months) % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day < lastDay ? d.day : lastDay);
}

/// Слитлампово-структурные поля формы 025-8, в порядке бланка.
const _structureFields = <(String, String)>[
  ('orbit', 'Орбита'),
  ('eyeball', 'Кўз олмаси (глазное яблоко)'),
  ('eyelids', 'Қовоқлар (веки)'),
  ('conjunctiva', 'Коньюктива'),
  ('lacrimal', 'Кўз ёш аъзолари (слёзные органы)'),
  ('cornea', 'Шох парда (роговица)'),
  ('anterior_chamber', 'Олд камера (передняя камера)'),
  ('iris', 'Рангдор парда (радужка)'),
  ('pupil', 'Қорачиқ (зрачок)'),
  ('lens', 'Гавҳар (хрусталик)'),
  ('vitreous', 'Шишасимон тана (стекловидное тело)'),
  ('fundus', 'Кўз туби (глазное дно)'),
];

const _allFieldKeys = <String>[
  'complaints',
  'anamnesis',
  'od_va',
  'od_sph',
  'od_cyl',
  'od_axis',
  'od_va_cc',
  'od_va_own',
  'os_va',
  'os_sph',
  'os_cyl',
  'os_axis',
  'os_va_cc',
  'os_va_own',
  'iop_od',
  'iop_os',
  'visual_field',
  'orbit',
  'eyeball',
  'eyelids',
  'conjunctiva',
  'lacrimal',
  'cornea',
  'anterior_chamber',
  'iris',
  'pupil',
  'lens',
  'vitreous',
  'fundus',
  'ab_scan_note',
  'diagnosis',
  'icd10',
  'recommendations',
];

/// Карта пациента (Form 025-8): осмотр окулиста по выбранному визиту,
/// история осмотров, печать официального бланка.
class PatientCardScreen extends ConsumerStatefulWidget {
  const PatientCardScreen({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<PatientCardScreen> createState() => _PatientCardScreenState();
}

class _PatientCardScreenState extends ConsumerState<PatientCardScreen> {
  late final Map<String, TextEditingController> _c = {
    for (final k in _allFieldKeys) k: TextEditingController(),
  };

  String? _visitId;
  EyeExam? _exam;
  bool _loadingExam = false;
  bool _saving = false;
  bool _printing = false;
  bool _printingRx = false;
  bool _applyingRefraction = false;
  bool _finishing = false;
  bool _addingDiagnosis = false;
  String? _deletingDiagnosisId;

  /// Автосейв черновика: любой ввод помечает форму «грязной», периодический
  /// таймер раз в 3 c сбрасывает грязную форму в [ExamDraftStore].
  Timer? _autosaveTimer;
  bool _dirty = false;
  bool _draftRestored = false;

  @override
  void initState() {
    super.initState();
    for (final c in _c.values) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    _dirty = true;
    _autosaveTimer ??= Timer.periodic(
      const Duration(seconds: 3),
      _autosaveTick,
    );
  }

  /// Тик автосейва: грязная форма пишется в черновик, чистая — гасит таймер
  /// (следующий ввод запустит его заново).
  void _autosaveTick(Timer timer) {
    if (!_dirty) {
      timer.cancel();
      if (identical(_autosaveTimer, timer)) _autosaveTimer = null;
      return;
    }
    _dirty = false;
    final visitId = _visitId;
    if (visitId == null) return;
    unawaited(ref.read(examDraftStoreProvider).saveDraft(visitId, _payload()));
  }

  void _populate(EyeExam? exam) {
    String s(Object? v) => v?.toString() ?? '';
    _c['complaints']!.text = s(exam?.complaints);
    _c['anamnesis']!.text = s(exam?.anamnesis);
    _c['od_va']!.text = s(exam?.odVa);
    _c['od_sph']!.text = s(exam?.odSph);
    _c['od_cyl']!.text = s(exam?.odCyl);
    _c['od_axis']!.text = s(exam?.odAxis);
    _c['od_va_cc']!.text = s(exam?.odVaCc);
    _c['od_va_own']!.text = s(exam?.odVaOwn);
    _c['os_va']!.text = s(exam?.osVa);
    _c['os_sph']!.text = s(exam?.osSph);
    _c['os_cyl']!.text = s(exam?.osCyl);
    _c['os_axis']!.text = s(exam?.osAxis);
    _c['os_va_cc']!.text = s(exam?.osVaCc);
    _c['os_va_own']!.text = s(exam?.osVaOwn);
    _c['iop_od']!.text = s(exam?.iopOd);
    _c['iop_os']!.text = s(exam?.iopOs);
    _c['visual_field']!.text = s(exam?.visualField);
    _c['orbit']!.text = s(exam?.orbit);
    _c['eyeball']!.text = s(exam?.eyeball);
    _c['eyelids']!.text = s(exam?.eyelids);
    _c['conjunctiva']!.text = s(exam?.conjunctiva);
    _c['lacrimal']!.text = s(exam?.lacrimal);
    _c['cornea']!.text = s(exam?.cornea);
    _c['anterior_chamber']!.text = s(exam?.anteriorChamber);
    _c['iris']!.text = s(exam?.iris);
    _c['pupil']!.text = s(exam?.pupil);
    _c['lens']!.text = s(exam?.lens);
    _c['vitreous']!.text = s(exam?.vitreous);
    _c['fundus']!.text = s(exam?.fundus);
    _c['ab_scan_note']!.text = s(exam?.abScanNote);
    _c['diagnosis']!.text = s(exam?.diagnosis);
    _c['icd10']!.text = s(exam?.icd10);
    _c['recommendations']!.text = s(exam?.recommendations);
  }

  /// Заполняет форму из карты черновика (ключи — [_allFieldKeys]).
  void _populateFromMap(Map<String, dynamic> draft) {
    for (final key in _allFieldKeys) {
      _c[key]!.text = draft[key]?.toString() ?? '';
    }
  }

  Future<void> _selectVisit(String visitId) async {
    // Несохранённый ввод предыдущего визита уходит в ЕГО черновик —
    // переключение визитов не теряет работу врача.
    final previous = _visitId;
    if (_dirty && previous != null) {
      unawaited(
        ref.read(examDraftStoreProvider).saveDraft(previous, _payload()),
      );
    }
    _dirty = false;
    setState(() {
      _visitId = visitId;
      _loadingExam = true;
      _draftRestored = false;
    });
    try {
      final exam = await ref
          .read(doctorRepositoryProvider)
          .examForVisit(visitId);
      if (!mounted || _visitId != visitId) return;
      setState(() => _exam = exam);
      _populate(exam);
      _dirty = false;
      // Есть черновик, отличающийся от серверной версии? Восстанавливаем его
      // и даём врачу выбор «Оставить / Отменить» в баннере.
      final draft = await ref.read(examDraftStoreProvider).readDraft(visitId);
      if (!mounted || _visitId != visitId) return;
      if (draft != null && !mapEquals(draft, _payload())) {
        _populateFromMap(draft);
        _dirty = false;
        setState(() => _draftRestored = true);
      }
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted && _visitId == visitId) setState(() => _loadingExam = false);
    }
  }

  Map<String, dynamic> _payload() {
    String? v(String key) {
      final t = _c[key]!.text.trim();
      return t.isEmpty ? null : t;
    }

    int? intOf(String key) {
      final t = v(key);
      return t == null ? null : int.tryParse(t);
    }

    return {
      for (final key in _allFieldKeys)
        if (key == 'od_axis' || key == 'os_axis')
          key: intOf(key)
        else
          key: v(key),
    };
  }

  Future<void> _save() async {
    final visitId = _visitId;
    if (visitId == null) return;
    setState(() => _saving = true);
    try {
      final exam = await ref
          .read(doctorRepositoryProvider)
          .upsertExam(visitId, _payload());
      if (!mounted) return;
      setState(() {
        _exam = exam;
        _draftRestored = false;
      });
      _populate(exam);
      _dirty = false;
      // Сервер теперь — истина: черновик больше не нужен.
      unawaited(ref.read(examDraftStoreProvider).clearDraft(visitId));
      ref.invalidate(examHistoryProvider(widget.patientId));
      ref.invalidate(patientTimelineProvider(widget.patientId));
      ref.invalidate(frequentDiagnosesProvider);
      _snack('Осмотр сохранён');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _print() async {
    final visitId = _visitId;
    if (visitId == null) return;
    setState(() => _printing = true);
    try {
      final bytes = await ref.read(doctorRepositoryProvider).cardPdf(visitId);
      final path = await saveBytes(
        bytes,
        'card-025-8-$visitId.pdf',
        'application/pdf',
      );
      if (!mounted) return;
      _snack(path == null ? 'PDF формы 025-8 загружен' : 'PDF сохранён: $path');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  /// «Печать рецепта»: отдельный печатный бланк рецепта (очки/медикаменты) по
  /// ТЕКУЩЕМУ осмотру — рефракция OD/OS + «Тавсия». Байты PDF под `exams.read`.
  Future<void> _printPrescription() async {
    final exam = _exam;
    if (exam == null) return;
    setState(() => _printingRx = true);
    try {
      final bytes = await ref
          .read(doctorRepositoryProvider)
          .prescriptionPdf(exam.id);
      final path = await saveBytes(
        bytes,
        'prescription-${exam.id}.pdf',
        'application/pdf',
      );
      if (!mounted) return;
      _snack(path == null ? 'PDF рецепта загружен' : 'PDF сохранён: $path');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _printingRx = false);
    }
  }

  /// «Подтянуть из рефрактометра»: берём свежайший refraction-результат визита
  /// (RMK-700) и копируем sph/cyl/axis в осмотр через apply-refraction.
  Future<void> _pullFromRefractometer() async {
    final visitId = _visitId;
    if (visitId == null) return;
    setState(() => _applyingRefraction = true);
    try {
      final results = await ref
          .read(devicesRepositoryProvider)
          .resultsForVisit(visitId);
      final refraction = results.where((r) => r.isRefraction).firstOrNull;
      if (refraction == null) {
        _snack('Для этого визита нет результатов рефрактометра', error: true);
        return;
      }
      final exam = await ref
          .read(doctorRepositoryProvider)
          .applyRefraction(visitId, refraction.id);
      if (!mounted) return;
      setState(() => _exam = exam);
      _populate(exam);
      _dirty = false; // apply-refraction уже сохранён сервером
      ref.invalidate(visitDeviceResultsProvider(visitId));
      ref.invalidate(examHistoryProvider(widget.patientId));
      ref.invalidate(patientTimelineProvider(widget.patientId));
      _snack('Рефракция подтянута из RMK-700');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _applyingRefraction = false);
    }
  }

  /// «Завершить приём»: работает ОТ ВИЗИТА — flow engine на сервере переводит
  /// визит в follow_up/completed и сам закрывает активный талон врача, если он
  /// есть. Больше не зависит от наличия активного талона (owner brief
  /// 2026-06-20: ошибка «Нет активного талона» устранена).
  ///
  /// Перед завершением врач опционально указывает дату повторного приёма
  /// (быстрые чипы 1нед/2нед/1мес, выбор даты, либо «Без повтора»). Дата — или
  /// null — прокидывается в finish-appointment как follow_up_date.
  Future<void> _finishAppointment() async {
    final visitId = _visitId;
    if (visitId == null) return;
    final choice = await _pickFollowUpDate();
    if (choice == null || !mounted) return; // отмена диалога
    setState(() => _finishing = true);
    try {
      await ref
          .read(doctorRepositoryProvider)
          .finishAppointment(visitId, followUpDate: choice.isoDate);
      if (!mounted) return;
      ref.invalidate(patientVisitsProvider(widget.patientId));
      ref.invalidate(patientTimelineProvider(widget.patientId));
      _snack('Приём завершён — статус обновлён');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  /// Компактный выбор даты повторного приёма перед завершением приёма.
  /// Возвращает `null` при отмене диалога, `_FollowUpChoice(null)` для «Без
  /// повтора» и `_FollowUpChoice(date)` с выбранной датой.
  Future<_FollowUpChoice?> _pickFollowUpDate() {
    return showDialog<_FollowUpChoice>(
      context: context,
      builder: (ctx) {
        final today = DateTime.now();
        DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
        void pick(DateTime d) =>
            Navigator.of(ctx).pop(_FollowUpChoice(dateOnly(d)));
        return AlertDialog(
          title: const Text('Повторный приём'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Назначить дату повторного приёма?'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Через 1 нед'),
                    onPressed: () => pick(today.add(const Duration(days: 7))),
                  ),
                  ActionChip(
                    label: const Text('Через 2 нед'),
                    onPressed: () => pick(today.add(const Duration(days: 14))),
                  ),
                  ActionChip(
                    label: const Text('Через 1 мес'),
                    onPressed: () => pick(addMonthClamped(today, 1)),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.event_outlined, size: 18),
                    label: const Text('Выбрать дату'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: today.add(const Duration(days: 7)),
                        firstDate: today,
                        lastDate: DateTime(today.year + 2),
                      );
                      if (picked != null && ctx.mounted) pick(picked);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(const _FollowUpChoice(null)),
              child: const Text('Без повтора'),
            ),
          ],
        );
      },
    );
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = ref.watch(patientByIdProvider(widget.patientId));
    final visits = ref.watch(patientVisitsProvider(widget.patientId));
    final canWrite =
        ref.watch(authControllerProvider).user?.can('exams.write') ?? false;

    // Автовыбор самого свежего визита после загрузки списка.
    ref.listen(patientVisitsProvider(widget.patientId), (_, next) {
      final items = next.valueOrNull;
      if (items != null && items.isNotEmpty && _visitId == null) {
        _selectVisit(items.first.id);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: patient.maybeWhen(
          data: (p) => Text('Карта 025-8 · ${p.fullName} (${p.mrn})'),
          orElse: () => const Text('Карта 025-8'),
        ),
        actions: [
          if (_visitId != null &&
              (ref.watch(authControllerProvider).user?.can('queue.manage') ??
                  false))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
                onPressed: _finishing ? null : _finishAppointment,
                icon: _finishing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.task_alt),
                label: const Text('Завершить приём'),
              ),
            ),
          if (_visitId != null && _exam != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
                onPressed: _printing ? null : _print,
                icon: _printing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print_outlined),
                label: const Text('Печать 025-8'),
              ),
            ),
          if (_exam != null &&
              (ref.watch(authControllerProvider).user?.can('exams.read') ??
                  false))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
                onPressed: _printingRx ? null : _printPrescription,
                icon: _printingRx
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long),
                label: const Text('Печать рецепта'),
              ),
            ),
        ],
      ),
      // Горячие клавиши врача (только этот экран): Ctrl+S — сохранить осмотр,
      // F7 — печать 025-8. Работают и при фокусе в текстовом поле.
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
            if (canWrite && !_saving) _save();
          },
          const SingleActivator(LogicalKeyboardKey.f7): () {
            if (_visitId != null && _exam != null && !_printing) _print();
          },
        },
        child: Focus(
          autofocus: true,
          child: AsyncValueWidget<List<VisitSummary>>(
            value: visits,
            onRetry: () =>
                ref.invalidate(patientVisitsProvider(widget.patientId)),
            builder: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'У пациента нет визитов — карта осмотра ведётся в рамках визита.',
                  ),
                );
              }
              // Три колонки врача (≥1280px): ПАЦИЕНТ | ДИАГНОСТИКА | РЕШЕНИЕ —
              // врач не переключает окна. 960–1280px → 2 колонки (Пациент +
              // объединённая «Осмотр»). Уже → один вертикальный скролл.
              final width = MediaQuery.sizeOf(context).width;
              final threeCol = width >= 1280;
              final twoCol = !threeCol && width >= 960;
              const examSpinner = Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
              // Склад проверяется по филиалу ВИЗИТА (perform спишет именно там);
              // филиал врача — лишь fallback для старых записей без branch_id.
              final visitBranchId = items
                  .where((v) => v.id == _visitId)
                  .map((v) => v.branchId)
                  .firstOrNull;

              // ── Содержимое колонок ────────────────────────────────────────
              // ПАЦИЕНТ: карточка + история осмотров + хронология.
              List<Widget> patientColumn() => [
                PatientInfoCard(patientId: widget.patientId),
                _visitHistory(items),
                if (ref.watch(authControllerProvider).user?.can('attachments.read') ??
                    false)
                  AttachmentsSection(
                    patientId: widget.patientId,
                    visitId: _visitId,
                  ),
                if (!_loadingExam) ...[_history(), _timeline()],
              ];
              // ДИАГНОСТИКА: приборы/сканы + структурные показания осмотра.
              List<Widget> diagnosticsColumn() => [
                if (_loadingExam)
                  examSpinner
                else ...[
                  _abScanSection(canWrite),
                  _examReadings(canWrite),
                ],
              ];
              // РЕШЕНИЕ ВРАЧА: диагноз/МКБ/рекомендации + операции + лечение +
              // «Сохранить осмотр».
              List<Widget> decisionColumn() => [
                if (!_loadingExam) ...[
                  _examConclusion(canWrite),
                  if (_visitId != null &&
                      (ref
                              .watch(authControllerProvider)
                              .user
                              ?.can('operations.read') ??
                          false))
                    OperationsSection(
                      visitId: _visitId!,
                      patientId: widget.patientId,
                      branchId: visitBranchId,
                    ),
                  if (_visitId != null &&
                      (ref
                              .watch(authControllerProvider)
                              .user
                              ?.can('treatments.read') ??
                          false))
                    TreatmentsSection(
                      visitId: _visitId!,
                      patientId: widget.patientId,
                    ),
                ],
              ];

              Widget scrollColumn(List<Widget> children) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              );

              if (threeCol) {
                // Каждая колонка скроллится независимо.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _visitPicker(items),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: scrollColumn([
                              _columnHeader('ПАЦИЕНТ'),
                              ...patientColumn(),
                            ]),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            flex: 3,
                            child: scrollColumn([
                              _columnHeader('ДИАГНОСТИКА'),
                              ...diagnosticsColumn(),
                            ]),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            flex: 3,
                            child: scrollColumn([
                              _columnHeader('РЕШЕНИЕ ВРАЧА'),
                              ...decisionColumn(),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (twoCol) {
                // 2 колонки: ПАЦИЕНТ | ДИАГНОСТИКА + РЕШЕНИЕ (одной лентой).
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _visitPicker(items),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: scrollColumn([
                              _columnHeader('ПАЦИЕНТ'),
                              ...patientColumn(),
                            ]),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            flex: 3,
                            child: scrollColumn([
                              _columnHeader('ДИАГНОСТИКА'),
                              ...diagnosticsColumn(),
                              _columnHeader('РЕШЕНИЕ ВРАЧА'),
                              ...decisionColumn(),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Узкий экран → один вертикальный скролл, все секции по очереди.
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _visitPicker(items),
                      const SizedBox(height: 12),
                      _columnHeader('ПАЦИЕНТ'),
                      ...patientColumn(),
                      _columnHeader('ДИАГНОСТИКА'),
                      ...diagnosticsColumn(),
                      _columnHeader('РЕШЕНИЕ ВРАЧА'),
                      ...decisionColumn(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _visitPicker(List<VisitSummary> items) {
    final selected = items.where((v) => v.id == _visitId).firstOrNull;
    return Row(
      children: [
        const Text('Визит:'),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String>(
            value: _visitId,
            isExpanded: true,
            hint: const Text('Выберите визит'),
            items: [
              for (final v in items)
                DropdownMenuItem(value: v.id, child: Text(v.label)),
            ],
            onChanged: (id) {
              if (id != null && id != _visitId) _selectVisit(id);
            },
          ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Tooltip(
              message: 'Статус меняется автоматически',
              child: Chip(
                visualDensity: VisualDensity.compact,
                label: Text(flowStatusLabel(selected.flowStatus)),
              ),
            ),
          ),
        if (_exam == null && _visitId != null)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Chip(label: Text('Осмотр ещё не записан')),
          ),
      ],
    );
  }

  /// Заголовок колонки (ПАЦИЕНТ / ДИАГНОСТИКА / РЕШЕНИЕ ВРАЧА).
  Widget _columnHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Колонка ДИАГНОСТИКА — структурные показания осмотра: жалобы/анамнез,
  /// Visus/рефракция, ВГД, поле зрения, биомикроскопия. A/B-скан рендерится
  /// отдельной секцией ([_abScanSection]) над этим блоком.
  Widget _examReadings(bool canWrite) {
    final enabled = canWrite && _visitId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_draftRestored) _draftBanner(),
        _section('ОКУЛИСТ КУРИГИ (осмотр окулиста)', [
          _text('complaints', 'Шикоятлари (жалобы)', enabled, maxLines: 2),
          _text('anamnesis', 'Анамнез', enabled, maxLines: 2),
        ]),
        _section('Visus / рефракция', [
          _visusRow('OD (правый глаз)', 'od', enabled),
          const SizedBox(height: 8),
          _visusRow('OS (левый глаз)', 'os', enabled),
          if (enabled)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _applyingRefraction ? null : _pullFromRefractometer,
                icon: _applyingRefraction
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined),
                label: const Text('Подтянуть из рефрактометра'),
              ),
            ),
        ]),
        _section('Кўз ички босими (ВГД, мм рт.ст.)', [
          Row(
            children: [
              Expanded(child: _text('iop_od', 'OD', enabled)),
              const SizedBox(width: 12),
              Expanded(child: _text('iop_os', 'OS', enabled)),
            ],
          ),
        ]),
        _section('Кўриш майдони (поле зрения)', [
          _text('visual_field', 'Поле зрения', enabled, maxLines: 3),
        ]),
        _section('Биомикроскопия (по бланку)', [
          for (final (key, label) in _structureFields)
            _text(key, label, enabled),
        ]),
      ],
    );
  }

  /// Колонка РЕШЕНИЕ ВРАЧА — заключение: диагноз/МКБ-10/рекомендации и кнопка
  /// «Сохранить осмотр» (PUT всего бланка: показания + заключение).
  Widget _examConclusion(bool canWrite) {
    final enabled = canWrite && _visitId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Ташхис / Тавсия (заключение)', [
          // Уже добавленные диагнозы визита (их может быть несколько, TZ §7.1.5).
          _diagnosesList(),
          if (enabled) const Divider(height: 20),
          // Compose-блок: шаблоны и частые диагнозы заполняют поля ниже, кнопка
          // «Добавить диагноз» накапливает их в список визита.
          if (enabled) _examTemplatesBlock(),
          if (enabled) _frequentDiagnosisChips(),
          _text('diagnosis', 'Ташхис (диагноз)', enabled, maxLines: 2),
          _text('icd10', 'МКБ-10 (код)', enabled),
          if (enabled)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: FilledButton.tonalIcon(
                  onPressed: _addingDiagnosis ? null : _addDiagnosis,
                  icon: _addingDiagnosis
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Добавить диагноз'),
                ),
              ),
            ),
          const Divider(height: 20),
          _text(
            'recommendations',
            'Тавсия (рекомендации)',
            enabled,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          if (canWrite)
            FilledButton.icon(
              onPressed: (_saving || _visitId == null) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Сохранить осмотр'),
            )
          else
            const Text(
              'Режим просмотра — нет права exams.write',
              textAlign: TextAlign.center,
            ),
        ]),
      ],
    );
  }

  /// Баннер «Восстановлен черновик»: врач решает — оставить восстановленный
  /// ввод или вернуть серверную версию (черновик при этом удаляется).
  Widget _draftBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.history_edu_outlined,
              size: 18,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Восстановлен черновик (не сохранён)')),
            TextButton(
              onPressed: () => setState(() => _draftRestored = false),
              child: const Text('Оставить'),
            ),
            TextButton(onPressed: _discardDraft, child: const Text('Отменить')),
          ],
        ),
      ),
    );
  }

  /// «Отменить» в баннере черновика: форма — из серверного осмотра,
  /// черновик — в корзину.
  Future<void> _discardDraft() async {
    final visitId = _visitId;
    if (visitId == null) return;
    _populate(_exam);
    _dirty = false;
    setState(() => _draftRestored = false);
    await ref.read(examDraftStoreProvider).clearDraft(visitId);
  }

  /// «Қўшиш»: текущий compose-ввод (диагноз + МКБ-10) добавляется как ещё один
  /// диагноз визита (TZ §7.1.5 — диагнозы накапливаются). Поле очищается, чтобы
  /// сразу ввести следующий. Рекомендации остаются в осмотре.
  Future<void> _addDiagnosis() async {
    final visitId = _visitId;
    if (visitId == null) return;
    final text = _c['diagnosis']!.text.trim();
    if (text.isEmpty) {
      _snack('Введите текст диагноза', error: true);
      return;
    }
    final icd = _c['icd10']!.text.trim();
    setState(() => _addingDiagnosis = true);
    try {
      await ref
          .read(doctorRepositoryProvider)
          .addDiagnosis(visitId, diagnosis: text, icd10: icd.isEmpty ? null : icd);
      if (!mounted) return;
      _c['diagnosis']!.clear();
      _c['icd10']!.clear();
      ref.invalidate(visitDiagnosesProvider(visitId));
      ref.invalidate(frequentDiagnosesProvider);
      _snack('Диагноз добавлен');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _addingDiagnosis = false);
    }
  }

  Future<void> _removeDiagnosis(VisitDiagnosis d) async {
    setState(() => _deletingDiagnosisId = d.id);
    try {
      await ref.read(doctorRepositoryProvider).deleteDiagnosis(d.id);
      if (!mounted) return;
      ref.invalidate(visitDiagnosesProvider(d.visitId));
      ref.invalidate(frequentDiagnosesProvider);
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _deletingDiagnosisId = null);
    }
  }

  /// Список уже добавленных диагнозов визита (TZ §7.1.5) с удалением.
  Widget _diagnosesList() {
    final visitId = _visitId;
    if (visitId == null) return const SizedBox.shrink();
    final diagnoses = ref.watch(visitDiagnosesProvider(visitId));
    return AsyncValueWidget<List<VisitDiagnosis>>(
      value: diagnoses,
      onRetry: () => ref.invalidate(visitDiagnosesProvider(visitId)),
      builder: (items) {
        if (items.isEmpty) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Диагнозов пока нет — добавьте ниже.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          );
        }
        return Column(
          children: [
            for (final d in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.coronavirus_outlined, size: 18),
                title: Text(d.diagnosis),
                subtitle: d.icd10 == null ? null : Text('МКБ-10: ${d.icd10}'),
                trailing: _deletingDiagnosisId == d.id
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: 'Удалить',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeDiagnosis(d),
                      ),
              ),
          ],
        );
      },
    );
  }

  /// Подставить сохранённый шаблон в поля заключения (диагноз/МКБ/рекомендации).
  void _applyTemplate(ExamTemplate t) {
    if (t.diagnosis != null) _c['diagnosis']!.text = t.diagnosis!;
    if (t.icd10 != null) _c['icd10']!.text = t.icd10!;
    if (t.recommendations != null) {
      _c['recommendations']!.text = t.recommendations!;
    }
    _snack('Шаблон «${t.name}» подставлен');
  }

  /// Сохранить текущее заключение как именованный шаблон (для повторного выбора).
  Future<void> _saveAsTemplate() async {
    final diagnosis = _c['diagnosis']!.text.trim();
    final icd10 = _c['icd10']!.text.trim();
    final recommendations = _c['recommendations']!.text.trim();
    if (diagnosis.isEmpty && icd10.isEmpty && recommendations.isEmpty) {
      _snack('Сначала заполните диагноз или рекомендации', error: true);
      return;
    }
    final nameController = TextEditingController(
      text: diagnosis.isNotEmpty ? diagnosis : recommendations,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сохранить как шаблон'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название шаблона',
            hintText: 'напр. «Катаракта — стандарт»',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(nameController.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(doctorRepositoryProvider).saveExamTemplate(
            name: name,
            diagnosis: diagnosis,
            icd10: icd10,
            recommendations: recommendations,
          );
      ref.invalidate(examTemplatesProvider);
      if (mounted) _snack('Шаблон «$name» сохранён');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    }
  }

  /// Блок «Шаблоны назначений»: чипы сохранённых заключений (тап — подставить,
  /// крестик — удалить) + кнопка «Сохранить как шаблон».
  Widget _examTemplatesBlock() {
    final templates = ref.watch(examTemplatesProvider).valueOrNull ?? const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmarks_outlined,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Шаблоны назначений',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium),
              ),
              IconButton(
                tooltip: 'Сохранить текущее заключение как шаблон',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.save_as_outlined, size: 20),
                onPressed: _saveAsTemplate,
              ),
            ],
          ),
          if (templates.isEmpty)
            Text('Пока нет шаблонов — сохраните текущее заключение.',
                style: Theme.of(context).textTheme.bodySmall)
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in templates)
                  InputChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(t.name),
                    onPressed: () => _applyTemplate(t),
                    onDeleted: () async {
                      try {
                        await ref
                            .read(doctorRepositoryProvider)
                            .deleteExamTemplate(t.id);
                        ref.invalidate(examTemplatesProvider);
                      } catch (e) {
                        if (mounted) _snack('$e', error: true);
                      }
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Чипы частых диагнозов текущего врача — тап подставляет текст в «Ташхис».
  Widget _frequentDiagnosisChips() {
    final frequent = ref.watch(frequentDiagnosesProvider).valueOrNull;
    if (frequent == null || frequent.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final d in frequent)
            ActionChip(
              visualDensity: VisualDensity.compact,
              label: Text('${d.diagnosis} ×${d.count}'),
              onPressed: () => _c['diagnosis']!.text = d.diagnosis,
            ),
        ],
      ),
    );
  }

  /// Секция «Кўз A/B-скан текшеруви» (приборы/снимки + заключение) — живёт
  /// в колонке ДИАГНОСТИКА над структурными показаниями осмотра.
  Widget _abScanSection(bool canWrite) {
    final enabled = canWrite && _visitId != null;
    return _section('Кўз A/B-скан текшеруви', [
      _text('ab_scan_note', 'Заключение A/B-скан', enabled, maxLines: 2),
      if (_visitId != null &&
          (ref.watch(authControllerProvider).user?.can('device_results.read') ??
              false))
        _AbScanResults(visitId: _visitId!),
    ]);
  }

  Widget _visusRow(String title, String eye, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _text('${eye}_va', 'Visus (б/к)', enabled)),
            const SizedBox(width: 8),
            Expanded(child: _text('${eye}_sph', 'sph', enabled)),
            const SizedBox(width: 8),
            Expanded(child: _text('${eye}_cyl', 'cyl', enabled)),
            const SizedBox(width: 8),
            Expanded(child: _text('${eye}_axis', 'ax (0–180)', enabled)),
            const SizedBox(width: 8),
            Expanded(child: _text('${eye}_va_cc', 'Visus с корр.', enabled)),
            const SizedBox(width: 8),
            Expanded(
              child: _text('${eye}_va_own', 'Своими очками', enabled),
            ),
          ],
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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

  Widget _text(String key, String label, bool enabled, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _c[key],
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }

  /// Иконка события хронологии по его kind (см. backend timeline builder).
  static IconData _kindIcon(String kind) {
    if (kind.startsWith('operation_')) return Icons.medical_services_outlined;
    if (kind.startsWith('treatment_')) return Icons.healing_outlined;
    if (kind.startsWith('visit_')) return Icons.event_outlined;
    return switch (kind) {
      'payment' => Icons.payments_outlined,
      'exam' => Icons.visibility_outlined,
      'device_result' => Icons.biotech_outlined,
      'refund' => Icons.undo,
      _ => Icons.circle_outlined,
    };
  }

  /// Автоматическая хронология пациента — собирается сервером из платежей,
  /// осмотров, операций, лечений и результатов приборов.
  Widget _timeline() {
    final timeline = ref.watch(patientTimelineProvider(widget.patientId));
    return _section('Хронология', [
      AsyncValueWidget<List<TimelineEvent>>(
        value: timeline,
        onRetry: () =>
            ref.invalidate(patientTimelineProvider(widget.patientId)),
        builder: (events) {
          if (events.isEmpty) return const Text('Событий ещё нет.');
          return Column(
            children: [
              for (final e in events.take(30))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_kindIcon(e.kind), size: 18),
                  title: Text(e.title),
                  subtitle: Text(
                    e.detail == null
                        ? e.dateLabel
                        : '${e.dateLabel} · ${e.detail}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    ]);
  }

  /// Структурированная «История визитов»: по каждому визиту — состав услуг,
  /// итог/скидка/оплачено/долг, статус потока и пометка ЭКСТРЕННО. Данные — из
  /// того же `/visits`, что и пикер (см. [VisitSummary]); второго запроса нет.
  /// Текущий визит формы 025-8 подсвечен; «Открыть осмотр» выбирает другой.
  Widget _visitHistory(List<VisitSummary> items) {
    final scheme = Theme.of(context).colorScheme;
    return _section('Визиты (${items.length})', [
      for (final v in items)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: v.id == _visitId
                    ? scheme.primary
                    : v.status == 'cancelled'
                        ? scheme.error
                        : scheme.outlineVariant,
              ),
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Row(
              children: [
                if (v.isEmergency)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.priority_high,
                      size: 16,
                      color: scheme.error,
                    ),
                  ),
                Expanded(
                  child: Text(
                    '${v.visitNo} · ${v.openedDateTime}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: v.id == _visitId
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              [
                flowStatusLabel(v.flowStatus),
                if (v.doctorName != null)
                  'Врач: ${v.doctorName}'
                      '${v.doctorCabinet != null ? ' · каб. ${v.doctorCabinet}' : ''}',
                'Итого ${formatMoney(v.totalAmount)}',
                if (v.hasDebt) 'долг ${formatMoney(v.balance)}',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: v.hasDebt ? scheme.error : null,
              ),
            ),
            children: [
              if (v.items.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Услуги не добавлены'),
                )
              else
                for (final it in v.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.quantity > 1
                                ? '${it.serviceName} ×${it.quantity}'
                                : it.serviceName,
                          ),
                        ),
                        Text(formatMoney(it.total)),
                      ],
                    ),
                  ),
              const Divider(height: 16),
              _moneyRow('Итого', v.totalAmount),
              if (v.hasDiscount)
                _moneyRow('Скидка', v.discountValue, note: v.discountReason),
              if (v.hasDiscount) _moneyRow('К оплате', v.payable),
              _moneyRow('Оплачено', v.paidAmount),
              _moneyRow('Долг', v.balance, danger: v.hasDebt),
              if (v.diagnoses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Диагноз: ${v.diagnoses.join('; ')}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              if (v.treatments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Лечение: ${v.treatments.join('; ')}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: v.id == _visitId
                    ? Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          Icons.check,
                          size: 16,
                          color: scheme.primary,
                        ),
                        label: const Text('Выбран для осмотра'),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => _selectVisit(v.id),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Открыть осмотр'),
                      ),
              ),
            ],
          ),
        ),
    ]);
  }

  /// Строка денежной сводки визита (метка слева, сумма справа).
  Widget _moneyRow(
    String label,
    String amount, {
    bool danger = false,
    String? note,
  }) {
    final style = danger
        ? TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w600,
          )
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              note == null || note.isEmpty ? label : '$label · $note',
              style: style,
            ),
          ),
          Text(formatMoney(amount), style: style),
        ],
      ),
    );
  }

  Widget _history() {
    final history = ref.watch(examHistoryProvider(widget.patientId));
    return _section('История осмотров', [
      AsyncValueWidget<List<EyeExam>>(
        value: history,
        onRetry: () => ref.invalidate(examHistoryProvider(widget.patientId)),
        builder: (items) {
          if (items.isEmpty) return const Text('Осмотров ещё нет.');
          return Column(
            children: [
              for (final e in items)
                ExpansionTile(
                  title: Text(
                    '${e.examDate ?? '—'} · ${e.diagnosis ?? 'без диагноза'}',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.visusLine('OD')),
                    Text(e.visusLine('OS')),
                    if (e.iopOd != null || e.iopOs != null)
                      Text('ВГД: OD ${e.iopOd ?? '—'} / OS ${e.iopOs ?? '—'}'),
                    if (e.recommendations != null)
                      Text('Тавсия: ${e.recommendations}'),
                  ],
                ),
            ],
          );
        },
      ),
    ]);
  }
}

/// Расширения, которые принимает backend для файла B-скана.
const _scanExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'bmp',
  'tif',
  'tiff',
  'dcm',
  'pdf',
];

/// Прикреплённые к визиту результаты A/B-скана (CAS-2000BER): снимки,
/// биометрия, файлы — превью по тапу, скачивание и загрузка новых сканов.
class _AbScanResults extends ConsumerStatefulWidget {
  const _AbScanResults({required this.visitId});

  final String visitId;

  @override
  ConsumerState<_AbScanResults> createState() => _AbScanResultsState();
}

class _AbScanResultsState extends ConsumerState<_AbScanResults> {
  bool _uploading = false;
  String? _previewingId;

  /// Имя для отображения: original_name из payload, иначе file_path.
  String _displayName(DeviceResult r) {
    final orig = r.payload?['original_name'];
    if (orig is String && orig.trim().isNotEmpty) return orig;
    return r.filePath ?? r.resultType;
  }

  /// Имя файла для скачивания — без директорий из file_path.
  String _downloadName(DeviceResult r) =>
      _displayName(r).split(RegExp(r'[\\/]+')).last;

  bool _looksLikeImage(String? name) {
    if (name == null) return false;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    const imageExts = {'jpg', 'jpeg', 'png', 'bmp', 'tif', 'tiff'};
    return imageExts.contains(name.substring(dot + 1).toLowerCase());
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _saveToDisk(Uint8List bytes, String filename) async {
    try {
      final path = await saveBytes(bytes, filename, 'application/octet-stream');
      _snack(path == null ? 'Файл загружен' : 'Файл сохранён: $path');
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  /// Тап по строке: тянем байты, картинки показываем в диалоге,
  /// остальное (DICOM/PDF) предлагаем скачать.
  Future<void> _openPreview(DeviceResult r) async {
    if (_previewingId != null) return;
    setState(() => _previewingId = r.id);
    try {
      final bytes = await ref
          .read(devicesRepositoryProvider)
          .resultFileBytes(r.id);
      if (!mounted) return;
      final name = _displayName(r);
      final isImage = _looksLikeImage(name) || _looksLikeImage(r.filePath);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => isImage
            ? _imageDialog(dialogContext, r, bytes, name)
            : _downloadDialog(dialogContext, r, bytes, name),
      );
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _previewingId = null);
    }
  }

  Widget _imageDialog(
    BuildContext dialogContext,
    DeviceResult r,
    Uint8List bytes,
    String name,
  ) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                name,
                style: Theme.of(dialogContext).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Не удалось отобразить снимок — формат не поддерживается. '
                      'Скачайте файл, чтобы открыть его локально.',
                      textAlign: TextAlign.center,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _saveToDisk(bytes, _downloadName(r)),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Скачать'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _downloadDialog(
    BuildContext dialogContext,
    DeviceResult r,
    Uint8List bytes,
    String name,
  ) {
    return AlertDialog(
      title: const Text('Файл результата'),
      content: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.insert_drive_file_outlined),
        title: Text(name, overflow: TextOverflow.ellipsis),
        subtitle: Text('${r.resultType} · ${bytes.length} байт'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Закрыть'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _saveToDisk(bytes, _downloadName(r));
          },
          icon: const Icon(Icons.download_outlined),
          label: const Text('Скачать'),
        ),
      ],
    );
  }

  /// «Загрузить скан»: выбрать файл → выбрать прибор (предпочтительно
  /// A/B-сканер) → POST multipart → обновить список.
  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _scanExtensions,
        withData: true,
      );
      final file = picked?.files.firstOrNull;
      final bytes = file?.bytes;
      if (file == null || bytes == null) return; // отмена выбора
      final repo = ref.read(devicesRepositoryProvider);
      final devices = await repo.list();
      // Скан атрибутируется ТОЛЬКО активному A/B-сканеру — молчаливый fallback
      // на «первый попавшийся прибор» портил бы происхождение медзаписи.
      final device = devices.items
          .where((d) => d.deviceType == 'ab_ultrasound' && d.status == 'active')
          .firstOrNull;
      if (device == null) {
        _snack(
          'Активный A/B-сканер не зарегистрирован — загрузка невозможна',
          error: true,
        );
        return;
      }
      await repo.uploadResultFile(
        deviceId: device.id,
        visitId: widget.visitId,
        bytes: bytes,
        filename: file.name,
      );
      if (!mounted) return;
      ref.invalidate(visitDeviceResultsProvider(widget.visitId));
      _snack('Скан «${file.name}» прикреплён к визиту');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Отвязать ошибочно прикреплённый результат: он вернётся в список
  /// несвязанных и его можно будет привязать к правильному визиту (медбезопасность).
  Future<void> _unlink(DeviceResult r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Отвязать результат'),
        content: const Text(
          'Отвязать результат от визита? Он вернётся в список несвязанных.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Отвязать'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(devicesRepositoryProvider).unlinkResult(r.id);
      if (!mounted) return;
      ref.invalidate(visitDeviceResultsProvider(widget.visitId));
      ref.invalidate(unlinkedDeviceResultsProvider);
      _snack('Результат отвязан');
    } on ApiException catch (e) {
      _snack('$e', error: true);
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  /// Действия строки результата: превью (если есть файл) и «Отвязать»
  /// (только при праве device_results.create).
  Widget? _trailing(DeviceResult r, bool canUnlink) {
    final preview = r.filePath == null
        ? null
        : (_previewingId == r.id
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.visibility_outlined));
    if (!canUnlink) return preview;
    final unlink = IconButton(
      icon: const Icon(Icons.link_off),
      tooltip: 'Отвязать от визита',
      visualDensity: VisualDensity.compact,
      onPressed: () => _unlink(r),
    );
    if (preview == null) return unlink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [preview, const SizedBox(width: 8), unlink],
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(visitDeviceResultsProvider(widget.visitId));
    final canUpload =
        ref.watch(authControllerProvider).user?.can('device_results.create') ??
        false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AsyncValueWidget<List<DeviceResult>>(
          value: results,
          onRetry: () =>
              ref.invalidate(visitDeviceResultsProvider(widget.visitId)),
          builder: (items) {
            final scans = items.where((r) => r.isScan).toList();
            if (scans.isEmpty) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Прикреплённых сканов нет.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return Column(
              children: [
                for (final r in scans)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.image_outlined),
                    title: Text(_displayName(r)),
                    subtitle: Text(
                      '${r.resultType} · ${r.measuredAt.replaceFirst('T', ' ').split('.').first}',
                    ),
                    trailing: _trailing(r, canUpload),
                    onTap: r.filePath == null ? null : () => _openPreview(r),
                  ),
              ],
            );
          },
        ),
        if (canUpload)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: _uploading ? null : _upload,
              icon: _uploading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: const Text('Загрузить скан'),
            ),
          ),
      ],
    );
  }
}
