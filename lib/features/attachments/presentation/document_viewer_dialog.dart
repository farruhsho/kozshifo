import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_saver.dart';
import '../data/attachments_repository.dart';
import '../domain/attachment.dart';
import 'inline_pdf.dart';

bool _isPdf(Attachment a) {
  if ((a.contentType ?? '').toLowerCase().contains('pdf')) return true;
  return a.displayName.toLowerCase().endsWith('.pdf');
}

String _mimeOf(Attachment a) {
  if (_isPdf(a)) return 'application/pdf';
  final ct = a.contentType;
  return (ct != null && ct.isNotEmpty) ? ct : 'application/octet-stream';
}

String _humanSize(int? bytes) {
  if (bytes == null) return '—';
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
}

/// Просмотр документа в карте пациента (owner brief 2026-06-20): переключатель
/// Информация / Просмотр + зум (картинки), полный экран, скачать, печать.
/// Критично для УЗИ/МРТ/КТ/операционных документов.
Future<void> showDocumentViewer(BuildContext context, Attachment attachment) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 680),
        child: _DocumentViewer(attachment: attachment),
      ),
    ),
  );
}

class _DocumentViewer extends ConsumerStatefulWidget {
  const _DocumentViewer({required this.attachment});
  final Attachment attachment;

  @override
  ConsumerState<_DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends ConsumerState<_DocumentViewer> {
  int _mode = 1; // 0 = информация, 1 = просмотр
  Uint8List? _bytes;
  Object? _error;
  bool _loading = true;
  final _tc = TransformationController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final b =
          await ref.read(attachmentsRepositoryProvider).fileBytes(widget.attachment.id);
      if (mounted) {
        setState(() {
          _bytes = b;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _download() async {
    final b = _bytes;
    if (b == null) return;
    await saveBytes(b, widget.attachment.displayName, _mimeOf(widget.attachment));
  }

  Future<void> _print() async {
    final b = _bytes;
    if (b == null) return;
    await printBytes(b, widget.attachment.displayName, _mimeOf(widget.attachment));
  }

  void _zoom(double factor) =>
      _tc.value = _tc.value.clone()..scaleByDouble(factor, factor, factor, 1);
  void _resetZoom() => _tc.value = Matrix4.identity();

  void _fullscreen() {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.attachment.displayName),
            actions: [
              if (!_isPdf(widget.attachment)) ...[
                IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => _zoom(0.8)),
                IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => _zoom(1.25)),
                IconButton(icon: const Icon(Icons.restart_alt), onPressed: _resetZoom),
              ],
              IconButton(icon: const Icon(Icons.download_outlined), onPressed: _download),
              IconButton(icon: const Icon(Icons.print_outlined), onPressed: _print),
              const SizedBox(width: 8),
            ],
          ),
          body: _viewer(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(a.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(
                tooltip: 'Закрыть',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Информация')),
                  ButtonSegment(value: 1, label: Text('Просмотр')),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const Spacer(),
              if (_mode == 1 && !_isPdf(a)) ...[
                IconButton(tooltip: 'Уменьшить', icon: const Icon(Icons.zoom_out), onPressed: () => _zoom(0.8)),
                IconButton(tooltip: 'Увеличить', icon: const Icon(Icons.zoom_in), onPressed: () => _zoom(1.25)),
                IconButton(tooltip: 'Сброс', icon: const Icon(Icons.restart_alt), onPressed: _resetZoom),
              ],
              IconButton(tooltip: 'Полный экран', icon: const Icon(Icons.fullscreen), onPressed: _fullscreen),
              IconButton(tooltip: 'Скачать', icon: const Icon(Icons.download_outlined), onPressed: _download),
              IconButton(tooltip: 'Печать', icon: const Icon(Icons.print_outlined), onPressed: _print),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _mode == 0 ? _info() : _viewer()),
      ],
    );
  }

  Widget _viewer() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text('Не удалось загрузить: $_error',
          style: const TextStyle(color: AppColors.muted)));
    }
    final b = _bytes!;
    if (_isPdf(widget.attachment)) {
      return inlinePdfView(b, onOpenExternal: _download);
    }
    return InteractiveViewer(
      transformationController: _tc,
      minScale: 0.5,
      maxScale: 5,
      boundaryMargin: const EdgeInsets.all(80),
      child: Center(child: Image.memory(b)),
    );
  }

  Widget _info() {
    final a = widget.attachment;
    final rows = <(String, String)>[
      ('Тип документа', a.kindLabel),
      ('Файл', a.displayName),
      ('Формат', a.contentType ?? '—'),
      ('Размер', _humanSize(a.size)),
      ('Дата', a.dateLabel.isEmpty ? '—' : a.dateLabel),
      ('Загрузил', a.uploadedByName ?? '—'),
      ('Примечание', (a.note != null && a.note!.isNotEmpty) ? a.note! : '—'),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(r.$1, style: const TextStyle(color: AppColors.muted)),
                ),
                Expanded(child: Text(r.$2)),
              ],
            ),
          ),
      ],
    );
  }
}
