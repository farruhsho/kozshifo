import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/recall_repository.dart';
import '../domain/recall_entry.dart';

final _date = DateFormat('dd.MM.yyyy');

/// «Повторные приёмы» — пациенты, которым пора вернуться (визит в follow_up,
/// дата повтора наступила или просрочена). Тап по строке открывает медкарту
/// пациента.
class RecallScreen extends ConsumerWidget {
  const RecallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(recallDueProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Повторные приёмы'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(recallDueProvider),
          ),
        ],
      ),
      body: AsyncValueWidget<List<RecallEntry>>(
        value: entries,
        onRetry: () => ref.invalidate(recallDueProvider),
        builder: (rows) {
          if (rows.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(recallDueProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _RecallTile(entry: rows[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available_outlined,
              size: 48, color: AppColors.green),
          const SizedBox(height: 12),
          Text('Нет повторных приёмов',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Никого не нужно приглашать сегодня',
              style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// Целых дней просрочки повторного приёма (по локальной календарной дате);
/// 0 — если срок ещё не наступил или наступает сегодня.
int _overdueDays(DateTime followUp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(followUp.year, followUp.month, followUp.day);
  final diff = today.difference(due).inDays;
  return diff > 0 ? diff : 0;
}

class _RecallTile extends StatelessWidget {
  const _RecallTile({required this.entry});

  final RecallEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = _overdueDays(entry.followUpDate);
    final subtitle = <String>[
      if (entry.phone != null && entry.phone!.isNotEmpty) entry.phone!,
      'повтор ${_date.format(entry.followUpDate)}',
      if (entry.lastVisitDate != null)
        'был ${_date.format(entry.lastVisitDate!)}',
    ].join('  ·  ');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => context.go('/patients/${entry.patientId}/card'),
        title: Text(entry.patientName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: overdue > 0
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'просрочено $overdue дн',
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
