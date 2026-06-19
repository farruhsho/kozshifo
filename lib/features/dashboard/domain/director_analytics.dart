// Директорская аналитика дашборда — доход по врачам, воронка операций, структура
// расходов, рост/падение регионов и детализация по районам. PLAIN Dart-классы с
// ручным fromJson (без freezed/codegen — см. AGENTS.md). Денежные поля приходят
// строками-decimal; для графиков есть числовые геттеры.

double _num(Object? v) => double.tryParse('${v ?? 0}') ?? 0;
int _int(Object? v) => (v as num?)?.toInt() ?? 0;

// ── Доход по врачам (GET /dashboard/revenue-by-doctor) ───────────────────────

class DoctorRevenueRow {
  const DoctorRevenueRow({
    required this.doctorId,
    required this.doctorName,
    required this.revenue,
  });

  final String doctorId;
  final String doctorName;
  final String revenue;

  double get revenueValue => _num(revenue);

  factory DoctorRevenueRow.fromJson(Map<String, dynamic> j) => DoctorRevenueRow(
        doctorId: (j['doctor_id'] ?? '').toString(),
        doctorName: (j['doctor_name'] ?? '—').toString(),
        revenue: (j['revenue'] ?? '0').toString(),
      );
}

class DoctorRevenueReport {
  const DoctorRevenueReport({
    required this.month,
    required this.total,
    required this.doctors,
  });

  final String month;
  final String total;
  final List<DoctorRevenueRow> doctors;

  double get totalValue => _num(total);
  bool get isEmpty => doctors.isEmpty;

  factory DoctorRevenueReport.fromJson(Map<String, dynamic> j) =>
      DoctorRevenueReport(
        month: (j['month'] ?? '').toString(),
        total: (j['total'] ?? '0').toString(),
        doctors: ((j['doctors'] as List<dynamic>?) ?? const [])
            .map((e) => DoctorRevenueRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Воронка операций + P&L (GET /dashboard/operations-summary) ───────────────

class OperationsSummary {
  const OperationsSummary({
    required this.month,
    required this.scheduled,
    required this.performed,
    required this.cancelled,
    required this.revenue,
    required this.cogs,
    required this.expenses,
    required this.profit,
  });

  final String month;
  final int scheduled; // назначено
  final int performed; // выполнено
  final int cancelled; // отменено
  final String revenue;
  final String cogs;
  final String expenses;
  final String profit;

  double get revenueValue => _num(revenue);
  double get cogsValue => _num(cogs);
  double get expensesValue => _num(expenses);
  double get profitValue => _num(profit);

  factory OperationsSummary.fromJson(Map<String, dynamic> j) => OperationsSummary(
        month: (j['month'] ?? '').toString(),
        scheduled: _int(j['scheduled']),
        performed: _int(j['performed']),
        cancelled: _int(j['cancelled']),
        revenue: (j['revenue'] ?? '0').toString(),
        cogs: (j['cogs'] ?? '0').toString(),
        expenses: (j['expenses'] ?? '0').toString(),
        profit: (j['profit'] ?? '0').toString(),
      );
}

// ── Структура расходов (GET /dashboard/expense-breakdown) ────────────────────

class ExpenseCategoryRow {
  const ExpenseCategoryRow({required this.category, required this.amount});

  final String category;
  final String amount;

  double get amountValue => _num(amount);

  factory ExpenseCategoryRow.fromJson(Map<String, dynamic> j) =>
      ExpenseCategoryRow(
        category: (j['category'] ?? '—').toString(),
        amount: (j['amount'] ?? '0').toString(),
      );
}

class ExpenseBreakdown {
  const ExpenseBreakdown({
    required this.month,
    required this.total,
    required this.categories,
  });

  final String month;
  final String total;
  final List<ExpenseCategoryRow> categories;

  double get totalValue => _num(total);
  bool get isEmpty => categories.isEmpty || totalValue <= 0;

  factory ExpenseBreakdown.fromJson(Map<String, dynamic> j) => ExpenseBreakdown(
        month: (j['month'] ?? '').toString(),
        total: (j['total'] ?? '0').toString(),
        categories: ((j['categories'] as List<dynamic>?) ?? const [])
            .map((e) => ExpenseCategoryRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Рост/падение регионов (GET /dashboard/region-trend) ──────────────────────

class RegionTrendRow {
  const RegionTrendRow({
    required this.region,
    required this.currentNew,
    required this.previousNew,
    required this.delta,
  });

  final String region;
  final int currentNew;
  final int previousNew;
  final int delta;

  bool get isGrowing => delta > 0;
  bool get isDeclining => delta < 0;

  factory RegionTrendRow.fromJson(Map<String, dynamic> j) => RegionTrendRow(
        region: (j['region'] ?? '').toString(),
        currentNew: _int(j['current_new']),
        previousNew: _int(j['previous_new']),
        delta: _int(j['delta']),
      );
}

class RegionTrendReport {
  const RegionTrendReport({
    required this.month,
    required this.previousMonth,
    required this.regions,
  });

  final String month;
  final String previousMonth;
  final List<RegionTrendRow> regions;

  bool get isEmpty => regions.isEmpty;

  factory RegionTrendReport.fromJson(Map<String, dynamic> j) => RegionTrendReport(
        month: (j['month'] ?? '').toString(),
        previousMonth: (j['previous_month'] ?? '').toString(),
        regions: ((j['regions'] as List<dynamic>?) ?? const [])
            .map((e) => RegionTrendRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Детализация по районам (GET /dashboard/patients-by-district) ─────────────

class DistrictCount {
  const DistrictCount({
    required this.district,
    required this.newCount,
    required this.returningCount,
    required this.total,
  });

  final String district;
  final int newCount;
  final int returningCount;
  final int total;

  factory DistrictCount.fromJson(Map<String, dynamic> j) => DistrictCount(
        district: (j['district'] ?? '').toString(),
        newCount: _int(j['new_count']),
        returningCount: _int(j['returning_count']),
        total: _int(j['total']),
      );
}

class DistrictReport {
  const DistrictReport({
    required this.region,
    required this.total,
    required this.districts,
  });

  final String region;
  final int total;
  final List<DistrictCount> districts;

  bool get isEmpty => districts.isEmpty;

  factory DistrictReport.fromJson(Map<String, dynamic> j) => DistrictReport(
        region: (j['region'] ?? '').toString(),
        total: _int(j['total']),
        districts: ((j['districts'] as List<dynamic>?) ?? const [])
            .map((e) => DistrictCount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
