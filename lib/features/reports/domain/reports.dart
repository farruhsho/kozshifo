// Модели отчётов директора (модуль «Отчёты»). PLAIN Dart с ручным fromJson
// (без freezed/codegen — см. AGENTS.md). Зеркалят backend GET /reports/*.
// Денежные поля — decimal-строки; счётчики — int.

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
String _money(Object? v) => (v ?? '0').toString();
double? _numOrNull(Object? v) => (v as num?)?.toDouble();

/// Строка «метка — сумма» (метод оплаты / категория расхода).
class AmountRow {
  const AmountRow({required this.label, required this.amount});
  final String label;
  final String amount;
  factory AmountRow.fromJson(Map<String, dynamic> j) =>
      AmountRow(label: (j['label'] ?? '—').toString(), amount: _money(j['amount']));
}

/// Финансовый отчёт: доход (по методам) − расход (по категориям) = прибыль.
class FinancialReport {
  const FinancialReport({
    required this.dateFrom,
    required this.dateTo,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.byMethod,
    required this.byCategory,
  });

  final String dateFrom;
  final String dateTo;
  final String income;
  final String expenses;
  final String profit;
  final List<AmountRow> byMethod;
  final List<AmountRow> byCategory;

  factory FinancialReport.fromJson(Map<String, dynamic> j) => FinancialReport(
        dateFrom: (j['date_from'] ?? '').toString(),
        dateTo: (j['date_to'] ?? '').toString(),
        income: _money(j['income']),
        expenses: _money(j['expenses']),
        profit: _money(j['profit']),
        byMethod: ((j['by_method'] as List<dynamic>?) ?? const [])
            .map((e) => AmountRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        byCategory: ((j['by_category'] as List<dynamic>?) ?? const [])
            .map((e) => AmountRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Доход, визиты, пациенты, средний чек, зарплата и чистая прибыль по врачу.
class DoctorReportRow {
  const DoctorReportRow({
    required this.doctorId,
    required this.doctorName,
    required this.revenue,
    required this.visits,
    required this.distinctPatients,
    required this.repeatPatients,
    required this.avgCheck,
    required this.payrollExpense,
    required this.netProfit,
    required this.avgConsultMinutes,
  });
  final String? doctorId;
  final String doctorName;
  final String revenue;
  final int visits;
  final int distinctPatients;
  final int repeatPatients;
  final String avgCheck;
  final String payrollExpense;
  final String netProfit;
  final double? avgConsultMinutes;
  factory DoctorReportRow.fromJson(Map<String, dynamic> j) => DoctorReportRow(
        doctorId: j['doctor_id']?.toString(),
        doctorName: (j['doctor_name'] ?? '—').toString(),
        revenue: _money(j['revenue']),
        visits: _int(j['visits']),
        distinctPatients: _int(j['distinct_patients']),
        repeatPatients: _int(j['repeat_patients']),
        avgCheck: _money(j['avg_check']),
        payrollExpense: _money(j['payroll_expense']),
        netProfit: _money(j['net_profit']),
        avgConsultMinutes: _numOrNull(j['avg_consult_minutes']),
      );
}

/// Заключения, исследования и среднее время по диагносту.
class DiagnosticianRow {
  const DiagnosticianRow({
    required this.name,
    required this.conclusions,
    required this.studies,
    required this.avgMinutes,
  });
  final String name;
  final int conclusions;
  final int studies;
  final double? avgMinutes;
  factory DiagnosticianRow.fromJson(Map<String, dynamic> j) => DiagnosticianRow(
        name: (j['name'] ?? '—').toString(),
        conclusions: _int(j['conclusions']),
        studies: _int(j['studies']),
        avgMinutes: _numOrNull(j['avg_minutes']),
      );
}

/// Траты пациента за период (LTV-срез).
class PatientSpendRow {
  const PatientSpendRow({
    required this.mrn,
    required this.fullName,
    required this.totalPaid,
    required this.visits,
  });
  final String? mrn;
  final String fullName;
  final String totalPaid;
  final int visits;
  factory PatientSpendRow.fromJson(Map<String, dynamic> j) => PatientSpendRow(
        mrn: j['mrn']?.toString(),
        fullName: (j['full_name'] ?? '—').toString(),
        totalPaid: _money(j['total_paid']),
        visits: _int(j['visits']),
      );
}

/// Новые пациенты по региону за период.
class RegionReportRow {
  const RegionReportRow({required this.region, required this.newPatients});
  final String region;
  final int newPatients;
  factory RegionReportRow.fromJson(Map<String, dynamic> j) => RegionReportRow(
        region: (j['region'] ?? '—').toString(),
        newPatients: _int(j['new_patients']),
      );
}

/// Выручка и новые пациенты по региону за период (profit-by-region).
class RegionRevenueRow {
  const RegionRevenueRow({
    required this.region,
    required this.revenue,
    required this.newPatients,
  });
  final String region;
  final String revenue;
  final int newPatients;
  factory RegionRevenueRow.fromJson(Map<String, dynamic> j) => RegionRevenueRow(
        region: (j['region'] ?? '—').toString(),
        revenue: _money(j['revenue']),
        newPatients: _int(j['new_patients']),
      );
}

/// Одна строка по хирургу в отчёте операций: операции, выручка, расход, прибыль.
class SurgeonReportRow {
  const SurgeonReportRow({
    required this.surgeonName,
    required this.count,
    required this.revenue,
    required this.cogs,
    required this.profit,
  });
  final String surgeonName;
  final int count;
  final String revenue;
  final String cogs;
  final String profit;
  factory SurgeonReportRow.fromJson(Map<String, dynamic> j) => SurgeonReportRow(
        surgeonName: (j['surgeon_name'] ?? '—').toString(),
        count: _int(j['count']),
        revenue: _money(j['revenue']),
        cogs: _money(j['cogs']),
        profit: _money(j['profit']),
      );
}

/// Отчёт по операциям: всего (выручка/расход/прибыль) + по хирургам.
class OperationsReport {
  const OperationsReport({
    required this.count,
    required this.revenue,
    required this.cogs,
    required this.profit,
    required this.bySurgeon,
  });
  final int count;
  final String revenue;
  final String cogs;
  final String profit;
  final List<SurgeonReportRow> bySurgeon;
  factory OperationsReport.fromJson(Map<String, dynamic> j) => OperationsReport(
        count: _int(j['count']),
        revenue: _money(j['revenue']),
        cogs: _money(j['cogs']),
        profit: _money(j['profit']),
        bySurgeon: ((j['by_surgeon'] as List<dynamic>?) ?? const [])
            .map((e) => SurgeonReportRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Одна строка по услуге в отчёте лечений: тип (процедура/медикамент),
/// число лечений и суммарная выручка.
class TreatmentServiceRow {
  const TreatmentServiceRow({
    required this.serviceName,
    required this.kind,
    required this.count,
    required this.revenue,
  });
  final String serviceName;

  /// `procedure` | `medication` (сырое значение бэкенда).
  final String kind;
  final int count;
  final String revenue;
  factory TreatmentServiceRow.fromJson(Map<String, dynamic> j) =>
      TreatmentServiceRow(
        serviceName: (j['service_name'] ?? '—').toString(),
        kind: (j['kind'] ?? '').toString(),
        count: _int(j['count']),
        revenue: _money(j['revenue']),
      );

  /// Человекочитаемый тип: Процедура / Медикамент (иначе — сырое значение).
  String get kindLabel => switch (kind) {
        'procedure' => 'Процедура',
        'medication' => 'Медикамент',
        _ => kind,
      };
}

/// Отчёт по лечениям: всего (кол-во/выручка) + разбивка по услугам.
class TreatmentsReport {
  const TreatmentsReport({
    required this.count,
    required this.revenue,
    required this.byService,
  });
  final int count;
  final String revenue;
  final List<TreatmentServiceRow> byService;
  factory TreatmentsReport.fromJson(Map<String, dynamic> j) => TreatmentsReport(
        count: _int(j['count']),
        revenue: _money(j['revenue']),
        byService: ((j['by_service'] as List<dynamic>?) ?? const [])
            .map((e) => TreatmentServiceRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Ключ диапазона дат для провайдеров отчётов (value-равенство record).
typedef ReportRange = ({DateTime? from, DateTime? to});
