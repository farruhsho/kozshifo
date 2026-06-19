import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/file_saver.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/attachments_repository.dart';
import '../domain/attachment.dart';

/// Extensions the backend accepts for attachments (УЗИ, анализы — PDF/сканы).
const _attachmentExtensions = <String>[
  'pdf', 'jpg', 'jpeg', 'png', 'bmp', 'tif', 'tiff',
];

String _mimeFor(String name) {
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'bmp' => 'image/bmp',
    'tif' || 'tiff' => 'image/tiff',
    _ => 'application/octet-stream',
  };
}

/// Reusable «Файлы и анализы» block: lists a patient's document attachments
/// (УЗИ-заключения, анализ на ВИЧ, прочие сканы), uploads new PDFs/images, and
/// downloads/opens existing ones. Embedded in the doctor card, the «Приём»
/// screen, and the operation card. When [operationId] is set with
/// [filterToOperation], it shows only that operation's documents (e.g. the
/// pre-op HIV analysis) and staples new uploads to that operation.
class AttachmentsSection extends ConsumerStatefulWidget {
  const AttachmentsSection({
    super.key,
    required this.patientId,
    this.visitId,
    this.operationId,
    this.allowedKinds = const ['uzi', 'hiv', 'lab', 'other'],
    this.defaultKind = 'other',
    this.title = 'Файлы и анализы',
    this.filterToOperation = false,
  });

  final String patientId;
  final String? visitId;
  final String? operationId;
  final List<String> allowedKinds;
  final String defaultKind;
  final String title;
  final bool filterToOperation;

  @override
  ConsumerState<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends ConsumerState<AttachmentsSection> {
  bool _uploading = false;
  String? _busyId; // id currently downloading or being deleted

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _open(Attachment a) async {
    if (_busyId != null) return;
    setState(() => _busyId = a.id);
    try {
      final bytes =
          await ref.read(attachmentsRepositoryProvider).fileBytes(a.id);
      if (!mounted) return;
      final name = a.displayName;
      final path = await saveBytes(bytes, name, _mimeFor(name));
      _snack(path == null ? 'Файл открыт' : 'Файл сохранён: $path');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(Attachment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text(a.displayName),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyId = a.id);
    try {
      await ref.read(attachmentsRepositoryProvider).delete(a.id);
      if (!mounted) return;
      ref.invalidate(patientAttachmentsProvider(widget.patientId));
      _snack('Файл удалён');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _attachmentExtensions,
        withData: true,
      );
      final file = picked?.files.firstOrNull;
      final bytes = file?.bytes;
      if (file == null || bytes == null) return; // отмена выбора
      if (!mounted) return;
      final meta = await _askKindAndNote();
      if (meta == null) return; // отмена
      await ref.read(attachmentsRepositoryProvider).upload(
            patientId: widget.patientId,
            kind: meta.$1,
            bytes: bytes,
            filename: file.name,
            visitId: widget.visitId,
            operationId: widget.operationId,
            note: meta.$2,
          );
      if (!mounted) return;
      ref.invalidate(patientAttachmentsProvider(widget.patientId));
      _snack('Файл «${file.name}» прикреплён');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Asks the operator for the document kind + an optional note before upload.
  Future<(String, String?)?> _askKindAndNote() async {
    var kind = widget.allowedKinds.contains(widget.defaultKind)
        ? widget.defaultKind
        : widget.allowedKinds.first;
    final noteCtrl = TextEditingController();
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Тип документа'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Тип'),
                items: [
                  for (final k in widget.allowedKinds)
                    DropdownMenuItem(
                      value: k,
                      child: Text(Attachment.kindLabels[k] ?? k),
                    ),
                ],
                onChanged: (v) => setLocal(() => kind = v ?? kind),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Примечание (необязательно)',
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop((kind, noteCtrl.text.trim())),
              child: const Text('Загрузить'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final attachments = ref.watch(patientAttachmentsProvider(widget.patientId));
    final canWrite =
        ref.watch(authControllerProvider).user?.can('attachments.write') ??
            false;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.folder_open_outlined,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.title,
                      style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AsyncValueWidget<List<Attachment>>(
              value: attachments,
              onRetry: () => ref
                  .invalidate(patientAttachmentsProvider(widget.patientId)),
              builder: (all) {
                final items = widget.filterToOperation &&
                        widget.operationId != null
                    ? all
                        .where((a) => a.operationId == widget.operationId)
                        .toList()
                    : all;
                if (items.isEmpty) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Файлов пока нет.',
                        style: theme.textTheme.bodySmall),
                  );
                }
                return Column(
                  children: [
                    for (final a in items)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(a.displayName,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [
                            a.kindLabel,
                            a.dateLabel,
                            if (a.uploadedByName != null) a.uploadedByName!,
                            if (a.note != null && a.note!.isNotEmpty) a.note!,
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: _busyId == a.id
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Открыть / скачать',
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                        Icons.download_outlined, size: 20),
                                    onPressed: () => _open(a),
                                  ),
                                  if (canWrite)
                                    IconButton(
                                      tooltip: 'Удалить',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                          Icons.delete_outline, size: 20),
                                      onPressed: () => _delete(a),
                                    ),
                                ],
                              ),
                        onTap: () => _open(a),
                      ),
                  ],
                );
              },
            ),
            if (canWrite)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : _upload,
                    icon: _uploading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: const Text('Прикрепить файл'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
