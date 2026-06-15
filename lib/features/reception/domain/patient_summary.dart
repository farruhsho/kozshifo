// История пациента для панели ресепшена. PLAIN Dart (см. AGENTS.md).
// Зеркалит backend GET /patients/{id}/summary.

class PatientSummary {
  const PatientSummary({
    required this.patientId,
    required this.visitCount,
    this.lastVisitAt,
    this.lastDiagnosis,
    this.lastOperation,
    this.lastPaymentAmount,
    this.lastPaymentAt,
    required this.totalDebt, // decimal string
    this.lastDiscountReason,
    required this.isRepeat,
  });

  final String patientId;
  final int visitCount;
  final String? lastVisitAt; // YYYY-MM-DD
  final String? lastDiagnosis;
  final String? lastOperation;
  final String? lastPaymentAmount; // decimal string
  final String? lastPaymentAt;
  final String totalDebt;
  final String? lastDiscountReason;
  final bool isRepeat;

  bool get hasDebt => (double.tryParse(totalDebt) ?? 0) > 0;

  factory PatientSummary.fromJson(Map<String, dynamic> json) => PatientSummary(
        patientId: json['patient_id'].toString(),
        visitCount: (json['visit_count'] as num?)?.toInt() ?? 0,
        lastVisitAt: json['last_visit_at']?.toString(),
        lastDiagnosis: json['last_diagnosis']?.toString(),
        lastOperation: json['last_operation']?.toString(),
        lastPaymentAmount: json['last_payment_amount']?.toString(),
        lastPaymentAt: json['last_payment_at']?.toString(),
        totalDebt: (json['total_debt'] ?? '0').toString(),
        lastDiscountReason: json['last_discount_reason']?.toString(),
        isRepeat: json['is_repeat'] == true,
      );
}

/// Возможный дубликат, показываемый ДО создания нового пациента.
class DuplicateCandidate {
  const DuplicateCandidate({
    required this.id,
    this.patientNo,
    required this.fullName,
    this.birthDate,
    this.phone,
    required this.reason,
  });

  final String id;
  final String? patientNo;
  final String fullName;
  final String? birthDate;
  final String? phone;
  final String reason; // «телефон» / «ФИО + дата рождения» / «ФИО»

  factory DuplicateCandidate.fromJson(Map<String, dynamic> json) => DuplicateCandidate(
        id: json['id'].toString(),
        patientNo: json['patient_no']?.toString(),
        fullName: (json['full_name'] ?? '').toString(),
        birthDate: json['birth_date']?.toString(),
        phone: json['phone']?.toString(),
        reason: (json['reason'] ?? '').toString(),
      );
}
