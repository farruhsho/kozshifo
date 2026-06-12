import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/file_saver.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../../clinical/presentation/operations_section.dart';
import '../../clinical/presentation/treatments_section.dart';
import '../../devices/data/devices_repository.dart';
import '../../devices/domain/device_result.dart';
import '../../patients/data/patients_repository.dart';
import '../data/doctor_repository.dart';
import '../domain/eye_exam.dart';
import '../domain/visit_summary.dart';

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
  'complaints', 'anamnesis',
  'od_va', 'od_sph', 'od_cyl', 'od_axis', 'od_va_cc',
  'os_va', 'os_sph', 'os_cyl', 'os_axis', 'os_va_cc',
  'iop_od', 'iop_os',
  'orbit', 'eyeball', 'eyelids', 'conjunctiva', 'lacrimal', 'cornea',
  'anterior_chamber', 'iris', 'pupil', 'lens', 'vitreous', 'fundus',
  'ab_scan_note', 'diagnosis', 'icd10', 'recommendations',
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
  bool _applyingRefraction = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
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
    _c['os_va']!.text = s(exam?.osVa);
    _c['os_sph']!.text = s(exam?.osSph);
    _c['os_cyl']!.text = s(exam?.osCyl);
    _c['os_axis']!.text = s(exam?.osAxis);
    _c['os_va_cc']!.text = s(exam?.osVaCc);
    _c['iop_od']!.text = s(exam?.iopOd);
    _c['iop_os']!.text = s(exam?.iopOs);
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

  Future<void> _selectVisit(String visitId) async {
    setState(() {
      _visitId = visitId;
      _loadingExam = true;
    });
    try {
      final exam = await ref.read(doctorRepositoryProvider).examForVisit(visitId);
      if (!mounted) return;
      setState(() => _exam = exam);
      _populate(exam);
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _loadingExam = false);
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
        if (key == 'od_axis' || key == 'os_axis') key: intOf(key) else key: v(key),
    };
  }

  Future<void> _save() async {
    final visitId = _visitId;
    if (visitId == null) return;
    setState(() => _saving = true);
    try {
      final exam =
          await ref.read(doctorRepositoryProvider).upsertExam(visitId, _payload());
      if (!mounted) return;
      setState(() => _exam = exam);
      _populate(exam);
      ref.invalidate(examHistoryProvider(widget.patientId));
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
      final path =
          await saveBytes(bytes, 'card-025-8-$visitId.pdf', 'application/pdf');
      if (!mounted) return;
      _snack(path == null ? 'PDF формы 025-8 загружен' : 'PDF сохранён: $path');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  /// «Подтянуть из рефрактометра»: берём свежайший refraction-результат визита
  /// (RMK-700) и копируем sph/cyl/axis в осмотр через apply-refraction.
  Future<void> _pullFromRefractometer() async {
    final visitId = _visitId;
    if (visitId == null) return;
    setState(() => _applyingRefraction = true);
    try {
      final results =
          await ref.read(devicesRepositoryProvider).resultsForVisit(visitId);
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
      ref.invalidate(visitDeviceResultsProvider(visitId));
      ref.invalidate(examHistoryProvider(widget.patientId));
      _snack('Рефракция подтянута из RMK-700');
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _applyingRefraction = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
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
          if (_visitId != null && _exam != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
                onPressed: _printing ? null : _print,
                icon: _printing
                    ? const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_outlined),
                label: const Text('Печать 025-8'),
              ),
            ),
        ],
      ),
      body: AsyncValueWidget<List<VisitSummary>>(
        value: visits,
        onRetry: () => ref.invalidate(patientVisitsProvider(widget.patientId)),
        builder: (items) {
          if (items.isEmpty) {
            return const Center(
                child: Text('У пациента нет визитов — карта осмотра ведётся в рамках визита.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _visitPicker(items),
                    const SizedBox(height: 12),
                    if (_loadingExam)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      _examForm(canWrite),
                      const SizedBox(height: 16),
                      _history(),
                      if (_visitId != null &&
                          (ref.watch(authControllerProvider).user
                                  ?.can('operations.read') ??
                              false))
                        OperationsSection(
                            visitId: _visitId!, patientId: widget.patientId),
                      if (_visitId != null &&
                          (ref.watch(authControllerProvider).user
                                  ?.can('treatments.read') ??
                              false))
                        TreatmentsSection(
                            visitId: _visitId!, patientId: widget.patientId),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _visitPicker(List<VisitSummary> items) {
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
        if (_exam == null && _visitId != null)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Chip(label: Text('Осмотр ещё не записан')),
          ),
      ],
    );
  }

  Widget _examForm(bool canWrite) {
    final enabled = canWrite && _visitId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined),
                label: const Text('Подтянуть из рефрактометра'),
              ),
            ),
        ]),
        _section('Кўз ички босими (ВГД, мм рт.ст.)', [
          Row(children: [
            Expanded(child: _text('iop_od', 'OD', enabled)),
            const SizedBox(width: 12),
            Expanded(child: _text('iop_os', 'OS', enabled)),
          ]),
        ]),
        _section('Биомикроскопия (по бланку)', [
          for (final (key, label) in _structureFields) _text(key, label, enabled),
        ]),
        _section('Кўз A/B-скан текшеруви', [
          _text('ab_scan_note', 'Заключение A/B-скан', enabled, maxLines: 2),
          if (_visitId != null &&
              (ref.watch(authControllerProvider).user?.can('device_results.read') ??
                  false))
            _AbScanResults(visitId: _visitId!),
        ]),
        _section('Ташхис / Тавсия (заключение)', [
          _text('diagnosis', 'Ташхис (диагноз)', enabled, maxLines: 2),
          _text('icd10', 'МКБ-10 (код)', enabled),
          _text('recommendations', 'Тавсия (рекомендации)', enabled, maxLines: 2),
        ]),
        const SizedBox(height: 12),
        if (canWrite)
          FilledButton.icon(
            onPressed: (_saving || _visitId == null) ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Сохранить осмотр'),
          )
        else
          const Text('Режим просмотра — нет права exams.write',
              textAlign: TextAlign.center),
      ],
    );
  }

  Widget _visusRow(String title, String eye, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _text('${eye}_va', 'Visus (б/к)', enabled)),
          const SizedBox(width: 8),
          Expanded(child: _text('${eye}_sph', 'sph', enabled)),
          const SizedBox(width: 8),
          Expanded(child: _text('${eye}_cyl', 'cyl', enabled)),
          const SizedBox(width: 8),
          Expanded(child: _text('${eye}_axis', 'ax (0–180)', enabled)),
          const SizedBox(width: 8),
          Expanded(child: _text('${eye}_va_cc', 'Visus с корр.', enabled)),
        ]),
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
                  title: Text('${e.examDate ?? '—'} · ${e.diagnosis ?? 'без диагноза'}'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.visusLine('OD')),
                    Text(e.visusLine('OS')),
                    if (e.iopOd != null || e.iopOs != null)
                      Text('ВГД: OD ${e.iopOd ?? '—'} / OS ${e.iopOs ?? '—'}'),
                    if (e.recommendations != null) Text('Тавсия: ${e.recommendations}'),
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
  'jpg', 'jpeg', 'png', 'bmp', 'tif', 'tiff', 'dcm', 'pdf',
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
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
      final bytes =
          await ref.read(devicesRepositoryProvider).resultFileBytes(r.id);
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
      BuildContext dialogContext, DeviceResult r, Uint8List bytes, String name) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(name,
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis),
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
                        style: Theme.of(dialogContext).textTheme.bodyMedium),
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
      BuildContext dialogContext, DeviceResult r, Uint8List bytes, String name) {
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
      final device = devices.items
              .where((d) => d.deviceType == 'ab_ultrasound')
              .firstOrNull ??
          devices.items.firstOrNull;
      if (device == null) {
        _snack('Нет зарегистрированных приборов', error: true);
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

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(visitDeviceResultsProvider(widget.visitId));
    final canUpload = ref
            .watch(authControllerProvider)
            .user
            ?.can('device_results.create') ??
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
                child: Text('Прикреплённых сканов нет.',
                    style: Theme.of(context).textTheme.bodySmall),
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
                        '${r.resultType} · ${r.measuredAt.replaceFirst('T', ' ').split('.').first}'),
                    trailing: r.filePath == null
                        ? null
                        : (_previewingId == r.id
                            ? const SizedBox(
                                height: 16, width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.visibility_outlined)),
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
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file_outlined),
              label: const Text('Загрузить скан'),
            ),
          ),
      ],
    );
  }
}
