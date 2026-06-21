import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/archive_repository.dart';

/// Архив (Super Admin): авто-архивирование старых завершённых записей (визиты,
/// операции, уведомления) по сроку давности. Кнопка запускает архивацию; список
/// показывает, сколько уже в архиве и сколько можно архивировать.
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  int _days = 365;
  bool _busy = false;

  static const _windows = <(int, String)>[
    (90, '90 дней'),
    (180, '180 дней'),
    (365, '1 год'),
    (730, '2 года'),
  ];

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final (v, o, n) = await ref.read(archiveRepositoryProvider).run(_days);
      if (!mounted) return;
      ref.invalidate(archiveSummaryProvider(_days));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Архивировано: визитов $v · операций $o · уведомлений $n'),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : '$e'),
          backgroundColor: AppColors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(archiveSummaryProvider(_days));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Архив'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(archiveSummaryProvider(_days)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Архивировать записи старше:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final w in _windows)
                  ChoiceChip(
                    label: Text(w.$2),
                    selected: _days == w.$1,
                    onSelected: _busy ? null : (_) => setState(() => _days = w.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AsyncValueWidget<ArchiveSummary>(
              value: summary,
              onRetry: () => ref.invalidate(archiveSummaryProvider(_days)),
              builder: (s) {
                final canArchive = s.visits.archivable +
                        s.operations.archivable +
                        s.notifications.archivable >
                    0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card('Визиты', s.visits),
                    _card('Операции', s.operations),
                    _card('Уведомления', s.notifications),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.archive_outlined),
                      label: const Text('Архивировать старые'),
                      onPressed: (_busy || !canArchive) ? null : _run,
                    ),
                    if (!canArchive)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Нет записей для архивации в этом окне',
                            style: TextStyle(color: AppColors.muted)),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String label, EntityArchive e) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('В архиве: ${e.archived}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${e.archivable}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: e.archivable > 0 ? AppColors.amber : AppColors.muted)),
              const Text('к архивации', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      );
}
