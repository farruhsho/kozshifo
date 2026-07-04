/// Одна строка списка «Повторные приёмы» (mirrors backend `RecallEntry`).
/// Пациент с визитом в flow_status='follow_up', которому пора вернуться:
/// follow_up_date <= due_by. Даты — ISO 'YYYY-MM-DD' (или null для last_visit).
class RecallEntry {
  const RecallEntry({
    required this.visitId,
    required this.patientId,
    required this.patientName,
    this.phone,
    required this.followUpDate,
    this.lastVisitDate,
  });

  final String visitId;
  final String patientId;
  final String patientName;
  final String? phone;

  /// Дата назначенного повторного приёма (ISO 'YYYY-MM-DD').
  final DateTime followUpDate;

  /// Дата последнего визита (ISO 'YYYY-MM-DD') — может отсутствовать.
  final DateTime? lastVisitDate;

  factory RecallEntry.fromJson(Map<String, dynamic> json) => RecallEntry(
    visitId: json['visit_id'] as String,
    patientId: json['patient_id'] as String,
    patientName: json['patient_name'] as String,
    phone: json['phone'] as String?,
    followUpDate: DateTime.parse(json['follow_up_date'] as String),
    lastVisitDate: switch (json['last_visit_date']) {
      final String s when s.isNotEmpty => DateTime.parse(s),
      _ => null,
    },
  );
}
