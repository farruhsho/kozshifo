// Лаборатория — направление на исследование с результатом. PLAIN Dart с ручным
// fromJson (без freezed/codegen — см. AGENTS.md). Зеркалит backend `LabOrderOut`.
// Поток статуса: referred → in_progress → ready | cancelled.

class LabOrder {
  const LabOrder({
    required this.id,
    required this.orderNo,
    required this.branchId,
    required this.patientId,
    required this.patientName,
    this.doctorId,
    this.doctorName,
    required this.testName,
    required this.status,
    this.result,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String orderNo;
  final String branchId;
  final String patientId;
  final String patientName;
  final String? doctorId;
  final String? doctorName;
  final String testName;
  final String status;
  final String? result;
  final String? notes;
  final String createdAt;

  factory LabOrder.fromJson(Map<String, dynamic> json) => LabOrder(
        id: json['id'].toString(),
        orderNo: (json['order_no'] ?? '').toString(),
        branchId: (json['branch_id'] ?? '').toString(),
        patientId: (json['patient_id'] ?? '').toString(),
        patientName: (json['patient_name'] ?? '').toString(),
        doctorId: json['doctor_id']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        testName: (json['test_name'] ?? '').toString(),
        status: (json['status'] ?? 'referred').toString(),
        result: json['result']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: (json['created_at'] ?? '').toString(),
      );

  bool get hasResult => (result ?? '').trim().isNotEmpty;

  String get statusLabel => switch (status) {
        'referred' => 'Направлен',
        'in_progress' => 'В работе',
        'ready' => 'Готов',
        'cancelled' => 'Отменён',
        _ => status,
      };
}
