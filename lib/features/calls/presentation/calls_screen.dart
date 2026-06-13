import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/url_opener.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/calls_repository.dart';
import '../domain/call_record.dart';

/// Журнал звонков IP-телефонии. Read-only: записи приходят с webhook АТС,
/// здесь только просмотр, поиск и переход к карте пациента.
class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key});

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _loadingMore = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(callsSearchProvider.notifier).state = value.trim();
    });
  }

  Future<void> _pickDateRange() async {
    final current = ref.read(callsDateRangeProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.from, end: current.to),
      helpText: 'Период журнала звонков',
    );
    if (picked == null) return;
    ref.read(callsDateRangeProvider.notifier).state = CallsDateFilter(
      DateTime(picked.start.year, picked.start.month, picked.start.day),
      DateTime(picked.end.year, picked.end.month, picked.end.day),
    );
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      await ref.read(callsListControllerProvider.notifier).loadMore();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// url_launcher в зависимостях нет — показываем ссылку с копированием;
  /// на web дополнительно можно открыть в новой вкладке (как TV-табло).
  void _showRecording(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Запись разговора'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ссылка на аудиозапись звонка:'),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy),
            label: const Text('Копировать'),
          ),
          FilledButton.icon(
            onPressed: () {
              final opened = openInNewTab(url);
              if (!opened) return; // не web: ссылку уже можно скопировать
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Открыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRead =
        ref.watch(authControllerProvider).user?.can('calls.read') ?? false;
    if (!canRead) {
      return Scaffold(
        appBar: AppBar(title: const Text('Звонки')),
        body: const Center(
          child: Text('Нет доступа: требуется право calls.read'),
        ),
      );
    }

    final calls = ref.watch(callsListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Звонки')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Телефон или имя пациента…',
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
                const SizedBox(width: 12),
                _buildDateChip(),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueWidget<CallsListState>(
              value: calls,
              onRetry: () => ref.invalidate(callsListControllerProvider),
              builder: _buildList,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip() {
    final range = ref.watch(callsDateRangeProvider);
    return InputChip(
      avatar: const Icon(Icons.date_range, size: 18),
      label: Text(range == null ? 'Все' : _rangeLabel(range)),
      onPressed: _pickDateRange,
      onDeleted: range == null
          ? null
          : () => ref.read(callsDateRangeProvider.notifier).state = null,
      deleteButtonTooltipMessage: 'Сбросить даты (показать все)',
    );
  }

  Widget _buildList(CallsListState state) {
    if (state.items.isEmpty) {
      return const Center(child: Text('Звонков нет'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Всего: ${state.total}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == state.items.length) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: _loadingMore
                        ? const SizedBox(
                            height: 32,
                            width: 32,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : OutlinedButton.icon(
                            onPressed: _loadMore,
                            icon: const Icon(Icons.expand_more),
                            label: Text(
                              'Показать ещё '
                              '(${state.total - state.items.length})',
                            ),
                          ),
                  ),
                );
              }
              return _CallTile(
                call: state.items[i],
                onOpenRecording: _showRecording,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Одна строка журнала: направление, номер, пациент, время, длительность,
/// заметка и запись разговора.
class _CallTile extends StatelessWidget {
  const _CallTile({required this.call, required this.onOpenRecording});

  final CallRecord call;
  final void Function(String url) onOpenRecording;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    final patient = call.patient;
    return ListTile(
      leading: Tooltip(
        message: call.isIncoming ? 'Входящий' : 'Исходящий',
        child: Icon(
          call.isIncoming ? Icons.call_received : Icons.call_made,
          color: call.isIncoming ? Colors.green : Colors.blue,
        ),
      ),
      title: Row(
        children: [
          Text(
            call.phone,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: patient == null
                ? Text(
                    'Неизвестный номер',
                    style: TextStyle(color: muted, fontStyle: FontStyle.italic),
                  )
                : ActionChip(
                    avatar: const Icon(Icons.person_outline, size: 18),
                    label: Text(
                      patient.fullName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Открыть карту пациента',
                    onPressed: () =>
                        context.go('/patients/${patient.id}/card'),
                  ),
          ),
        ],
      ),
      subtitle:
          Text('${_timeLabel(call.startedAt)}  ·  ${call.durationLabel}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (call.note != null && call.note!.isNotEmpty)
            Tooltip(
              message: call.note!,
              child:
                  Icon(Icons.sticky_note_2_outlined, size: 20, color: muted),
            ),
          const SizedBox(width: 4),
          IconButton(
            tooltip:
                call.recordingUrl == null ? 'Записи нет' : 'Запись разговора',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: call.recordingUrl == null
                ? null
                : () => onOpenRecording(call.recordingUrl!),
          ),
        ],
      ),
    );
  }
}

String _two(int v) => v.toString().padLeft(2, '0');

/// «HH:mm dd.MM» из ISO-строки в ЛОКАЛЬНОМ времени; нераспознанное значение
/// показываем как есть. Бэкенд отдаёт `started_at` в UTC (зачастую без
/// смещения — naive). Naive-строку трактуем как UTC, затем переводим в local —
/// иначе журнал показывал бы UTC-часы (сдвиг на местное смещение).
String _timeLabel(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final dt = (parsed.isUtc
          ? parsed
          : DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour,
              parsed.minute, parsed.second))
      .toLocal();
  return '${_two(dt.hour)}:${_two(dt.minute)} ${_two(dt.day)}.${_two(dt.month)}';
}

String _dateLabel(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

String _rangeLabel(CallsDateFilter f) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (f.isSingleDay) {
    return f.from == today ? 'Сегодня' : _dateLabel(f.from);
  }
  return '${_dateLabel(f.from)} – ${_dateLabel(f.to)}';
}
