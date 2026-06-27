import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/debt_repository.dart';
import '../domain/debtor_row.dart';

final _date = DateFormat('dd.MM.yyyy');

String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final dt = DateTime.tryParse(iso);
  return dt == null ? iso : _date.format(dt.toLocal());
}

/// «Долги» — список должников клиники, самый крупный долг сверху. Тап по строке
/// открывает детализацию долга пациента (по визитам + история оплат).
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtors = ref.watch(debtorsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Долги'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(debtorsProvider),
          ),
        ],
      ),
      body: AsyncValueWidget<List<DebtorRow>>(
        value: debtors,
        onRetry: () => ref.invalidate(debtorsProvider),
        builder: (rows) {
          if (rows.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(debtorsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _DebtorTile(row: rows[i]),
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
          const Icon(Icons.verified_outlined, size: 48, color: AppColors.green),
          const SizedBox(height: 12),
          Text('Нет задолженностей',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Все визиты оплачены полностью',
              style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _DebtorTile extends StatelessWidget {
  const _DebtorTile({required this.row});

  final DebtorRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = <String>[
      if (row.phone != null && row.phone!.isNotEmpty) row.phone!,
      '${row.visitCount} визитов',
      'с ${_fmtDate(row.oldestDebtAt)}',
      if (row.lastPaymentAt != null)
        'посл. оплата ${_fmtDate(row.lastPaymentAt)}',
    ].join('  ·  ');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => context.go('/debts/${row.patientId}'),
        title: Text(row.patientName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Text(
          formatMoney(row.totalDebt),
          style: TextStyle(
            color: scheme.error,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
