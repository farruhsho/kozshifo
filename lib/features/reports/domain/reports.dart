// Модели отчётов директора (модуль «Отчёты»). PLAIN Dart с ручным fromJson
// (без freezed/codegen — см. AGENTS.md). Зеркалят backend GET /reports/*.
// Денежные поля — decimal-строки; счётчики — int.

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
String _money(Object? v) => (v ?? '0').toString();

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

/// Доход и визиты по врачу.
class DoctorReportRow {
  const DoctorReportRow({
    required this.doctorName,
    required this.revenue,
    required this.visits,
  });
  final String doctorName;
  final String revenue;
  final int visits;
  factory DoctorReportRow.fromJson(Map<String, dynamic> j) => DoctorReportRow(
        doctorName: (j['doctor_name'] ?? '—').toString(),
        revenue: _money(j['revenue']),
        visits: _int(j['visits']),
      );
}

/// Заключения по диагносту.
class DiagnosticianRow {
  const DiagnosticianRow({required this.name, required this.conclusions});
  final String name;
  final int conclusions;
  factory DiagnosticianRow.fromJson(Map<String, dynamic> j) => DiagnosticianRow(
        name: (j['name'] ?? '—').toString(),
        conclusions: _int(j['conclusions']),
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

/// Одна строка по хирургу в отчёте операций.
class SurgeonReportRow {
  const SurgeonReportRow({
    required this.surgeonName,
    required this.count,
    required this.revenue,
  });
  final String surgeonName;
  final int count;
  final String revenue;
  factory SurgeonReportRow.fromJson(Map<String, dynamic> j) => SurgeonReportRow(
        surgeonName: (j['surgeon_name'] ?? '—').toString(),
        count: _int(j['count']),
        revenue: _money(j['revenue']),
      );
}

/// Отчёт по операциям: всего + по хирургам.
class OperationsReport {
  const OperationsReport({
    required this.count,
    required this.revenue,
    required this.bySurgeon,
  });
  final int count;
  final String revenue;
  final List<SurgeonReportRow> bySurgeon;
  factory OperationsReport.fromJson(Map<String, dynamic> j) => OperationsReport(
        count: _int(j['count']),
        revenue: _money(j['revenue']),
        bySurgeon: ((j['by_surgeon'] as List<dynamic>?) ?? const [])
            .map((e) => SurgeonReportRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Ключ диапазона дат для провайдеров отчётов (value-равенство record).
typedef ReportRange = ({DateTime? from, DateTime? to});
