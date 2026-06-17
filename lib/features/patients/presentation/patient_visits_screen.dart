import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/koz_widgets.dart';
import '../../doctor/data/doctor_repository.dart';
import '../../doctor/domain/visit_summary.dart';
import '../data/patients_repository.dart';

final _date = DateFormat('dd.MM.yyyy');

/// Ф5 — выделенный экран ИСТОРИИ ВИЗИТОВ пациента с фильтрами (диапазон дат,
/// статус, только с долгом). Доступен из списка пациентов; в отличие от
/// врачебной карточки не грузит осмотр — это обзор всех визитов для
/// ресепшена/регистратуры. Тап по визиту открывает медкарту на нём.
class PatientVisitsScreen extends ConsumerStatefulWidget {
  const PatientVisitsScreen({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<PatientVisitsScreen> createState() =>
      _PatientVisitsScreenState();
}

class _PatientVisitsScreenState extends ConsumerState<PatientVisitsScreen> {
  // Worklist-style status chips (null = «Все»). Visit.status values.
  static const _statuses = <(String, String?)>[
    ('Все', null),
    ('Открыт', 'open'),
    ('Завершён', 'completed'),
    ('Отменён', 'cancelled'),
  ];

  String? _status;
  DateTime? _from;
  DateTime? _to;
  bool _owing = false;

  VisitHistoryQuery get _query => (
    patientId: widget.patientId,
    // Date-only local bounds; [to] is the EXCLUSIVE next-day start.
    from: _from == null
        ? null
        : DateTime(_from!.year, _from!.month, _from!.day),
    to: _to == null
        ? null
        : DateTime(_to!.year, _to!.month, _to!.day).add(const Duration(days: 1)),
    status: _status,
    owing: _owing,
  );

  void _reload() => ref.invalidate(patientVisitsFilteredProvider(_query));

  Future<void> _pick({required bool from}) async {
    final now = DateTime.now();
    final initial = (from ? _from : _to) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        if (from) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = ref.watch(patientByIdProvider(widget.patientId));
    final visits = ref.watch(patientVisitsFilteredProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('История визитов'),
        actions: [
          IconButton(
            tooltip: 'Открыть медкарту',
            icon: const Icon(Icons.medical_information_outlined),
            onPressed: () => context.go('/patients/${widget.patientId}/card'),
          ),
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(
                patient.asData?.value.fullName,
                visits.asData?.value.length,
              ),
              const SizedBox(height: 16),
              _filters(),
              const SizedBox(height: 16),
              visits.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => AppCard(
                  child: Center(
                    child: Text(
                      e is ApiException ? e.message : '$e',
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const AppCard(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: Text('Визитов не найдено')),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final v in items) _visitCard(v)],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(String? name, int? count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.sidebarGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 34, color: AppColors.mintLight),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name ?? 'Пациент',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Все визиты пациента',
                  style: TextStyle(
                    color: AppColors.mintLight.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: AppTypography.number(22, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filters() {
    final dateLabel = switch ((_from, _to)) {
      (null, null) => 'Период: весь',
      (final f?, null) => 'с ${_date.format(f)}',
      (null, final t?) => 'по ${_date.format(t)}',
      (final f?, final t?) => '${_date.format(f)} — ${_date.format(t)}',
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value) in _statuses)
                _Chip(
                  label: label,
                  selected: _status == value,
                  onTap: () => setState(() => _status = value),
                ),
              _Chip(
                label: 'С долгом',
                selected: _owing,
                onTap: () => setState(() => _owing = !_owing),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(from: true),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('С даты'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(from: false),
                  icon: const Icon(Icons.event, size: 18),
                  label: const Text('По дату'),
                ),
              ),
              if (_from != null || _to != null)
                IconButton(
                  tooltip: 'Сбросить период',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _from = null;
                    _to = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _visitCard(VisitSummary v) {
    final kind = switch (v.status) {
      'completed' => BadgeKind.success,
      'cancelled' => BadgeKind.neutral,
      _ => BadgeKind.info,
    };
    final dt = DateTime.tryParse(v.openedAt);
    final date = dt == null ? v.openedAt.split('T').first : _date.format(dt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go('/patients/${widget.patientId}/card'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${v.visitNo}  ·  $date',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (v.isEmergency) ...[
                      const Pill(
                        label: 'экстренный',
                        color: AppColors.red,
                        bg: AppColors.redBg,
                      ),
                      const SizedBox(width: 6),
                    ],
                    StatusBadge(v.statusLabel, kind: kind),
                  ],
                ),
                const SizedBox(height: 10),
                if (v.items.isEmpty)
                  const Text(
                    'Услуги не добавлены',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  )
                else
                  for (final it in v.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${it.serviceName}'
                              '${it.quantity > 1 ? ' ×${it.quantity}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            formatMoney(it.total),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.sub,
                            ),
                          ),
                        ],
                      ),
                    ),
                const Divider(height: 18),
                _moneyRow('Итого', v.totalAmount),
                if (v.hasDiscount)
                  _moneyRow('Скидка', v.discountValue, note: v.discountReason),
                _moneyRow('Оплачено', v.paidAmount),
                if (v.hasDebt) _moneyRow('Долг', v.balance, danger: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _moneyRow(
    String label,
    String amount, {
    String? note,
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: danger ? AppColors.red : AppColors.muted,
              fontWeight: danger ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (note != null && note.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '($note)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          Text(
            formatMoney(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: danger ? AppColors.red : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-style toggle chip (brand teal selected / hairline idle).
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.tealDark : AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.tealDark : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.sub,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
