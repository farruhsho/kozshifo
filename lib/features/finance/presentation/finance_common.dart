import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/utils/file_saver.dart';

/// Russian month names by index 1–12 (avoids intl locale-data init in tests).
const kRuMonths = [
  '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String ym(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

/// "2026-06" → "Июнь 2026"; on garbage returns the input unchanged.
String monthLabel(String month) {
  final parts = month.split('-');
  final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
  if (m == null || m < 1 || m > 12) return month;
  return '${kRuMonths[m]} ${parts[0]}';
}

/// ISO datetime/date string → "dd.MM" (for the «Выплачено dd.MM» chip).
String ddMM(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
}

/// "YYYY-MM-DD" → "dd.MM.yyyy" for list rows; garbage passes through.
String ddMMyyyy(String isoDate) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return isoDate;
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

void showFinanceSnack(BuildContext context, String message,
    {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}

/// Downloads CSV [bytes] via the platform saver and reports the outcome.
Future<void> saveCsv(
    BuildContext context, Uint8List bytes, String filename) async {
  final path = await saveBytes(bytes, filename, 'text/csv');
  if (!context.mounted) return;
  showFinanceSnack(
      context, path == null ? 'CSV загружен: $filename' : 'CSV сохранён: $path');
}

/// «‹ Июнь 2026 ›» — month stepper used by the cash and payroll tabs.
class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key, required this.month, required this.onChanged});

  /// YYYY-MM
  final String month;
  final ValueChanged<String> onChanged;

  void _shift(int delta) {
    final parts = month.split('-');
    final base = DateTime(int.parse(parts[0]), int.parse(parts[1]) + delta);
    onChanged(ym(base));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = month == ym(now);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Предыдущий месяц',
          onPressed: () => _shift(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(monthLabel(month),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        IconButton(
          tooltip: 'Следующий месяц',
          // Будущие месяцы пусты по определению — не даём листать вперёд.
          onPressed: isCurrent ? null : () => _shift(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
