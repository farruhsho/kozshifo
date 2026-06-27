import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/page.dart' as net;
import '../../../core/widgets/async_value_widget.dart';
import '../data/audit_repository.dart';
import '../domain/audit_entry.dart';

final _dateTime = DateFormat('dd.MM.yyyy HH:mm');

/// Аудит действий (Super Admin): кто · что · когда · с какого устройства.
/// Только чтение; журнал append-only. Фильтры: тип сущности + период.
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _entityType = '';
  DateTimeRange? _range;

  // (значение для бэкенда, подпись). Пусто = все.
  static const _entityTypes = <(String, String)>[
    ('', 'Все типы'),
    ('visit', 'Визиты'),
    ('patient', 'Пациенты'),
    ('payment', 'Оплаты'),
    ('operation', 'Операции'),
    ('queue_ticket', 'Очередь'),
    ('treatment', 'Лечение'),
    ('user', 'Сотрудники'),
    ('role', 'Роли'),
    ('expense', 'Расходы'),
  ];

  AuditQuery get _query => (
        entityType: _entityType.isEmpty ? null : _entityType,
        action: null,
        from: _range?.start,
        to: _range?.end,
      );

  String _device(AuditEntry e) {
    final ua = e.userAgent;
    final ip = e.ipAddress;
    if (ua == null && ip == null) return '—';
    return [if (ua != null && ua.isNotEmpty) ua, if (ip != null && ip.isNotEmpty) ip]
        .join('  ·  ');
  }

  String _when(String iso) {
    final dt = DateTime.tryParse(iso);
    return dt == null ? iso : _dateTime.format(dt.toLocal());
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(auditLogProvider(_query));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Аудит действий'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(auditLogProvider(_query)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _entityType,
                    items: [
                      for (final e in _entityTypes)
                        DropdownMenuItem(value: e.$1, child: Text(e.$2)),
                    ],
                    onChanged: (v) => setState(() => _entityType = v ?? ''),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(_range == null
                        ? 'Период'
                        : '${DateFormat('dd.MM').format(_range!.start)} — '
                            '${DateFormat('dd.MM').format(_range!.end)}'),
                    onPressed: _pickRange,
                  ),
                  if (_range != null)
                    IconButton(
                      tooltip: 'Сбросить период',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _range = null),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueWidget<net.Page<AuditEntry>>(
                value: page,
                onRetry: () => ref.invalidate(auditLogProvider(_query)),
                builder: (data) {
                  if (data.items.isEmpty) {
                    return const Center(
                      child: Text('Записей нет',
                          style: TextStyle(color: AppColors.muted)),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(auditLogProvider(_query)),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: data.items.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.line2),
                      itemBuilder: (_, i) => _row(data.items[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AuditEntry e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.summary?.isNotEmpty == true
                      ? e.summary!
                      : '${e.action} · ${e.entityType}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(_when(e.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            // кто: имя/почта актора, then action/entity tag.
            '${e.actorName ?? e.actorEmail ?? 'система'} · ${e.action} · ${e.entityType}',
            style: const TextStyle(color: AppColors.sub, fontSize: 12.5),
          ),
          const SizedBox(height: 2),
          Text(
            'Устройство: ${_device(e)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
