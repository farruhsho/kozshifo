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

/// Мониторинг звонков ресепшена для директора: KPI ответов/пропусков/времени
/// ответа сверху, затем журнал звонков с поиском. Данные приходят с агентов на
/// телефонах ресепшена; экран сам обновляется ~раз в минуту.
class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key});

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  Timer? _autoRefresh;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    // «Почти реальное время»: раз в минуту тянем свежие KPI и журнал.
    _autoRefresh = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      ref.invalidate(callsSummaryProvider);
      ref.invalidate(callsListControllerProvider);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _autoRefresh?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshNow() {
    ref.invalidate(callsSummaryProvider);
    ref.invalidate(callsListControllerProvider);
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
    final user = ref.watch(authControllerProvider).user;
    final canRead = user?.can('calls.read') ?? false;
    final canManage = user?.can('calls.manage') ?? false;
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
      appBar: AppBar(
        title: const Text('Звонки'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNow,
          ),
          if (canManage)
            IconButton(
              tooltip: 'Телефоны ресепшена',
              icon: const Icon(Icons.smartphone),
              onPressed: () => context.go('/calls/devices'),
            ),
        ],
      ),
      body: Column(
        children: [
          const _CallsKpiHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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

/// Полоса KPI над журналом: отвечено / пропущено / среднее время ответа +
/// баннер офлайн-телефонов. Тихо ничего не показывает, пока грузится.
class _CallsKpiHeader extends ConsumerWidget {
  const _CallsKpiHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(callsSummaryProvider).valueOrNull;
    if (summary == null) {
      return const SizedBox(height: 4);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          if (summary.offlineDevices.isNotEmpty)
            _OfflineBanner(devices: summary.offlineDevices.map((d) => d.label).toList()),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _KpiCard(
                  label: 'Отвечено',
                  value: '${summary.answered}',
                  color: Colors.green,
                  icon: Icons.call_received,
                ),
                _KpiCard(
                  label: 'Пропущено',
                  value: '${summary.missed}',
                  sub: summary.incoming > 0 ? '${summary.missedPercent}%' : null,
                  color: summary.missed > 0 ? Colors.red : Colors.grey,
                  icon: Icons.phone_missed,
                ),
                _KpiCard(
                  label: 'Ср. ответ',
                  value: summary.avgWaitLabel,
                  color: Colors.blue,
                  icon: Icons.timer_outlined,
                ),
                _KpiCard(
                  label: 'Исходящие',
                  value: '${summary.outgoing}',
                  color: Colors.indigo,
                  icon: Icons.call_made,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.sub,
  });

  final String label;
  final String value;
  final String? sub;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
              if (sub != null) ...[
                const SizedBox(width: 4),
                Text(sub!, style: TextStyle(color: color, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.devices});

  final List<String> devices;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Не на связи: ${devices.join(', ')} — звонки могут теряться',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Одна строка журнала: статус (отвечен/пропущен/исходящий), номер, пациент,
/// время, время ответа и длительность, телефон-источник, запись.
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
        message: call.statusLabel,
        child: Icon(call.statusIcon, color: call.statusColor),
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
      subtitle: Text(_subtitle()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (call.device != null)
            Tooltip(
              message: 'Телефон: ${call.device!.label}',
              child: Icon(Icons.smartphone, size: 18, color: muted),
            ),
          if (call.note != null && call.note!.isNotEmpty) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: call.note!,
              child:
                  Icon(Icons.sticky_note_2_outlined, size: 20, color: muted),
            ),
          ],
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

  String _subtitle() {
    final parts = <String>[_timeLabel(call.startedAt)];
    // Время ответа важно для входящих (как быстро взяли трубку).
    if (call.isIncoming && call.status == 'answered') {
      parts.add('ответ ${call.waitLabel}');
    } else if (call.isMissed) {
      parts.add('звонил ${call.waitLabel}');
    }
    if (call.durationSeconds > 0) parts.add('длит. ${call.durationLabel}');
    return parts.join('  ·  ');
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
