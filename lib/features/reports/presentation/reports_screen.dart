import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/file_saver.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../data/reports_repository.dart';
import '../domain/reports.dart';

final _fmt = DateFormat('dd.MM.yyyy');

/// «12.5 мин» либо «—», если время не определено.
String _minutes(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} мин';

/// Модуль «Отчёты» директора: диапазон дат + вкладки (Финансы / Врачи /
/// Диагносты / Операции / Прибыль по регионам / Регионы / Пациенты) с
/// таблицами и выгрузкой CSV / Excel / PDF.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month, now.day);
  }

  ReportRange get _range => (from: _from, to: _to);

  Future<void> _pick({required bool from}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
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

  void _quick(int days) {
    final now = DateTime.now();
    setState(() {
      _to = DateTime(now.year, now.month, now.day);
      _from = _to.subtract(Duration(days: days - 1));
    });
  }

  Future<void> _download(String slug, ReportFormat format) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      final bytes = await ref
          .read(reportsRepositoryProvider)
          .download(slug, _range, format: format);
      final name =
          '${slug}_${_fmt.format(_from)}_${_fmt.format(_to)}'.replaceAll('.', '-');
      await saveBytes(bytes, '$name.${format.extension}', format.mime);
      messenger.showSnackBar(SnackBar(
          content: Text('${format.extension.toUpperCase()} выгружен')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : '$e'),
        backgroundColor: errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Отчёты'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Финансы'),
              Tab(text: 'Врачи'),
              Tab(text: 'Диагносты'),
              Tab(text: 'Операции'),
              Tab(text: 'По лечениям'),
              Tab(text: 'Прибыль по регионам'),
              Tab(text: 'Регионы'),
              Tab(text: 'Пациенты'),
            ],
          ),
        ),
        body: Column(
          children: [
            _dateBar(),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _financialTab(),
                  _byDoctorTab(),
                  _byDiagnosticianTab(),
                  _byOperationTab(),
                  _byTreatmentTab(),
                  _profitByRegionTab(),
                  _byRegionTab(),
                  _byPatientTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () => _pick(from: true),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text('С: ${_fmt.format(_from)}'),
          ),
          OutlinedButton.icon(
            onPressed: () => _pick(from: false),
            icon: const Icon(Icons.event, size: 16),
            label: Text('По: ${_fmt.format(_to)}'),
          ),
          TextButton(onPressed: () => _quick(7), child: const Text('7 дней')),
          TextButton(onPressed: () => _quick(30), child: const Text('30 дней')),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _from = DateTime(now.year, now.month, 1);
                _to = DateTime(now.year, now.month, now.day);
              });
            },
            child: const Text('Этот месяц'),
          ),
        ],
      ),
    );
  }

  /// Каркас вкладки: меню «Экспорт» (CSV/Excel/PDF) + прокручиваемое тело.
  Widget _tab({required String csvSlug, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<ReportFormat>(
              tooltip: 'Экспорт',
              onSelected: (f) => _download(csvSlug, f),
              itemBuilder: (_) => const [
                PopupMenuItem(value: ReportFormat.csv, child: Text('CSV')),
                PopupMenuItem(value: ReportFormat.xlsx, child: Text('Excel')),
                PopupMenuItem(value: ReportFormat.pdf, child: Text('PDF')),
              ],
              child: AbsorbPointer(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Экспорт'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }

  // ── Финансы ────────────────────────────────────────────────────────────────
  Widget _financialTab() => _tab(
        csvSlug: 'financial',
        child: AsyncValueWidget<FinancialReport>(
          value: ref.watch(financialReportProvider(_range)),
          onRetry: () => ref.invalidate(financialReportProvider(_range)),
          builder: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi('Доход', formatMoney(r.income), Colors.green),
                  _kpi('Расход', formatMoney(r.expenses),
                      Theme.of(context).colorScheme.error),
                  _kpi('Прибыль', formatMoney(r.profit),
                      Theme.of(context).colorScheme.primary),
                ],
              ),
              const SizedBox(height: 16),
              _amountTable('Доход по методам', 'Метод', r.byMethod),
              const SizedBox(height: 16),
              _amountTable('Расход по категориям', 'Категория', r.byCategory),
            ],
          ),
        ),
      );

  Widget _kpi(String label, String value, Color color) => Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          ],
        ),
      );

  Widget _amountTable(String title, String col, List<AmountRow> rows) {
    return _titled(title, rows.isEmpty
        ? const _Empty()
        : _table([col, 'Сумма'], [
            for (final a in rows) [a.label, formatMoney(a.amount)],
          ]));
  }

  // ── Врачи ──────────────────────────────────────────────────────────────────
  Widget _byDoctorTab() => _tab(
        csvSlug: 'by-doctor',
        child: AsyncValueWidget<List<DoctorReportRow>>(
          value: ref.watch(byDoctorReportProvider(_range)),
          onRetry: () => ref.invalidate(byDoctorReportProvider(_range)),
          builder: (rows) => rows.isEmpty
              ? const _Empty()
              : _table([
                  'Врач',
                  'Выручка',
                  'Визитов',
                  'Пациентов',
                  'Повторных',
                  'Средний чек',
                  'Зарплата',
                  'Чистая прибыль',
                  'Ср. время приёма',
                ], [
                  for (final r in rows)
                    [
                      r.doctorName,
                      formatMoney(r.revenue),
                      formatInt(r.visits),
                      formatInt(r.distinctPatients),
                      formatInt(r.repeatPatients),
                      formatMoney(r.avgCheck),
                      formatMoney(r.payrollExpense),
                      formatMoney(r.netProfit),
                      _minutes(r.avgConsultMinutes),
                    ],
                ]),
        ),
      );

  // ── Диагносты ────────────────────────────────────────────────────────────────
  Widget _byDiagnosticianTab() => _tab(
        csvSlug: 'by-diagnostician',
        child: AsyncValueWidget<List<DiagnosticianRow>>(
          value: ref.watch(byDiagnosticianReportProvider(_range)),
          onRetry: () => ref.invalidate(byDiagnosticianReportProvider(_range)),
          builder: (rows) => rows.isEmpty
              ? const _Empty()
              : _table(['Диагност', 'Заключений', 'Исследований', 'Ср. время'], [
                  for (final r in rows)
                    [
                      r.name,
                      formatInt(r.conclusions),
                      formatInt(r.studies),
                      _minutes(r.avgMinutes),
                    ],
                ]),
        ),
      );

  // ── Операции ─────────────────────────────────────────────────────────────────
  Widget _byOperationTab() => _tab(
        csvSlug: 'by-operation',
        child: AsyncValueWidget<OperationsReport>(
          value: ref.watch(byOperationReportProvider(_range)),
          onRetry: () => ref.invalidate(byOperationReportProvider(_range)),
          builder: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi('Операций', formatInt(r.count),
                      Theme.of(context).colorScheme.primary),
                  _kpi('Выручка', formatMoney(r.revenue), Colors.green),
                  _kpi('Расход', formatMoney(r.cogs),
                      Theme.of(context).colorScheme.error),
                  _kpi('Прибыль', formatMoney(r.profit),
                      Theme.of(context).colorScheme.primary),
                ],
              ),
              const SizedBox(height: 16),
              if (r.bySurgeon.isEmpty)
                const _Empty()
              else
                _table(['Хирург', 'Операций', 'Выручка', 'Расход', 'Прибыль'], [
                  for (final s in r.bySurgeon)
                    [
                      s.surgeonName,
                      formatInt(s.count),
                      formatMoney(s.revenue),
                      formatMoney(s.cogs),
                      formatMoney(s.profit),
                    ],
                ]),
            ],
          ),
        ),
      );

  // ── По лечениям ──────────────────────────────────────────────────────────────
  Widget _byTreatmentTab() => _tab(
        csvSlug: 'by-treatment',
        child: AsyncValueWidget<TreatmentsReport>(
          value: ref.watch(byTreatmentReportProvider(_range)),
          onRetry: () => ref.invalidate(byTreatmentReportProvider(_range)),
          builder: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi('Лечений', formatInt(r.count),
                      Theme.of(context).colorScheme.primary),
                  _kpi('Выручка', formatMoney(r.revenue), Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              if (r.byService.isEmpty)
                const _Empty(message: 'За период лечений нет')
              else
                _table(['Услуга', 'Тип', 'Лечений', 'Выручка'], [
                  for (final s in r.byService)
                    [
                      s.serviceName,
                      s.kindLabel,
                      formatInt(s.count),
                      formatMoney(s.revenue),
                    ],
                ], textColumns: const {1}),
            ],
          ),
        ),
      );

  // ── Прибыль по регионам ──────────────────────────────────────────────────────
  Widget _profitByRegionTab() => _tab(
        csvSlug: 'profit-by-region',
        child: AsyncValueWidget<List<RegionRevenueRow>>(
          value: ref.watch(profitByRegionReportProvider(_range)),
          onRetry: () => ref.invalidate(profitByRegionReportProvider(_range)),
          builder: (rows) => rows.isEmpty
              ? const _Empty()
              : _table(['Регион', 'Выручка', 'Новых пациентов'], [
                  for (final r in rows)
                    [r.region, formatMoney(r.revenue), formatInt(r.newPatients)],
                ]),
        ),
      );

  // ── Регионы ──────────────────────────────────────────────────────────────────
  Widget _byRegionTab() => _tab(
        csvSlug: 'by-region',
        child: AsyncValueWidget<List<RegionReportRow>>(
          value: ref.watch(byRegionReportProvider(_range)),
          onRetry: () => ref.invalidate(byRegionReportProvider(_range)),
          builder: (rows) => rows.isEmpty
              ? const _Empty()
              : _table(['Регион', 'Новых пациентов'], [
                  for (final r in rows) [r.region, formatInt(r.newPatients)],
                ]),
        ),
      );

  // ── Пациенты ─────────────────────────────────────────────────────────────────
  Widget _byPatientTab() => _tab(
        csvSlug: 'by-patient',
        child: AsyncValueWidget<List<PatientSpendRow>>(
          value: ref.watch(byPatientReportProvider(_range)),
          onRetry: () => ref.invalidate(byPatientReportProvider(_range)),
          builder: (rows) => rows.isEmpty
              ? const _Empty()
              : _table(['MRN', 'Пациент', 'Оплачено', 'Визитов'], [
                  for (final r in rows)
                    [r.mrn ?? '—', r.fullName, formatMoney(r.totalPaid), formatInt(r.visits)],
                ]),
        ),
      );

  // ── Общие виджеты ────────────────────────────────────────────────────────────
  Widget _titled(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      );

  /// Простая таблица: первый столбец слева, остальные — справа (числа).
  /// [textColumns] — индексы дополнительных текстовых столбцов, которые не
  /// нужно выравнивать по правому краю (например «Тип»).
  Widget _table(List<String> headers, List<List<String>> rows,
      {Set<int> textColumns = const {}}) {
    bool numeric(int i) => i != 0 && !textColumns.contains(i);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        columns: [
          for (var i = 0; i < headers.length; i++)
            DataColumn(label: Text(headers[i]), numeric: numeric(i)),
        ],
        rows: [
          for (final r in rows)
            DataRow(cells: [
              for (var i = 0; i < r.length; i++) DataCell(Text(r[i])),
            ]),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({this.message = 'Нет данных за период'});

  /// Текст пустого состояния (по умолчанию — общий для всех отчётов).
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(message,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6))),
        ),
      );
}
