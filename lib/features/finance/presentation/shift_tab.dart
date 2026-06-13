import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/finance_repository.dart';
import '../domain/cash_report.dart';
import 'finance_common.dart';

const _methodLabels = <String, String>{
  'cash': 'Наличные',
  'card': 'Карта',
  'qr': 'QR',
  'transfer': 'Перечисление',
};

/// «Смена» — today's running till summary, reusing the daily report. No backend
/// shift state: «Закрыть смену» surfaces the numbers prominently and offers the
/// daily CSV for the till handover.
class ShiftTab extends ConsumerStatefulWidget {
  const ShiftTab({super.key});

  @override
  ConsumerState<ShiftTab> createState() => _ShiftTabState();
}

class _ShiftTabState extends ConsumerState<ShiftTab> {
  bool _exporting = false;

  // The shift is always "today" — the till is closed at end of the working day.
  String get _today => ymd(DateTime.now());

  Future<void> _refresh() async {
    ref.invalidate(dailyReportProvider(_today));
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final bytes =
          await ref.read(financeRepositoryProvider).dailyReportCsv(_today);
      if (mounted) await saveCsv(context, bytes, 'shift-$_today.csv');
    } catch (e) {
      if (mounted) showFinanceSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _closeShift(DailyReport r) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _CloseShiftDialog(
        report: r,
        exporting: _exporting,
        onExport: () {
          Navigator.of(ctx).pop();
          _exportCsv();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyReportProvider(_today));

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Смена за ${ddMMyyyy(_today)}',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                tooltip: 'Скачать CSV смены',
                onPressed: _exporting ? null : _exportCsv,
                icon: _exporting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AsyncValueWidget<DailyReport>(
            value: daily,
            onRetry: () => ref.invalidate(dailyReportProvider(_today)),
            builder: (r) => Column(
              children: [
                _ShiftSummaryCard(report: r),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _closeShift(r),
                  icon: const Icon(Icons.lock_clock),
                  label: const Text('Закрыть смену'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The cash summary card: income by method → Приход / Возвраты / Расходы → Итог.
class _ShiftSummaryCard extends StatelessWidget {
  const _ShiftSummaryCard({required this.report});

  final DailyReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final netValue = double.tryParse(report.net) ?? 0;
    final netColor = netValue < 0 ? scheme.error : Colors.green.shade700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            for (final entry in _methodLabels.entries)
              _row(context, entry.value,
                  report.incomeByMethod[entry.key] ?? '0.00'),
            const Divider(),
            _row(context, 'Приход', report.incomeTotal),
            _row(context, 'Возвраты', report.refundTotal),
            _row(context, 'Расходы', report.expenseTotal),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Итог по смене',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Text(formatMoney(report.net),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.bold, color: netColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String amount) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(formatMoney(amount), style: style),
        ],
      ),
    );
  }
}

/// Prominent close-of-shift summary with a CSV handover action.
class _CloseShiftDialog extends StatelessWidget {
  const _CloseShiftDialog({
    required this.report,
    required this.exporting,
    required this.onExport,
  });

  final DailyReport report;
  final bool exporting;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Закрытие смены'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Сводка за ${ddMMyyyy(report.date)}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ShiftSummaryCard(report: report),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
        FilledButton.icon(
          onPressed: exporting ? null : onExport,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Скачать CSV'),
        ),
      ],
    );
  }
}
