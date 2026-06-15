// Оптика — заказ очков/линз под рецепт. PLAIN Dart с ручным fromJson
// (без freezed/codegen — см. AGENTS.md). Зеркалит backend `OpticsOrderOut`.
// Поток статуса: ordered → in_progress → ready → issued | cancelled.

class OpticsOrder {
  const OpticsOrder({
    required this.id,
    required this.orderNo,
    required this.branchId,
    required this.patientId,
    required this.patientName,
    this.doctorId,
    this.doctorName,
    required this.kind,
    this.rx,
    this.frame,
    required this.price, // decimal string, e.g. "1290000.00"
    required this.status,
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
  final String kind; // glasses | lenses
  final String? rx;
  final String? frame;
  final String price;
  final String status;
  final String? notes;
  final String createdAt;

  factory OpticsOrder.fromJson(Map<String, dynamic> json) => OpticsOrder(
        id: json['id'].toString(),
        orderNo: (json['order_no'] ?? '').toString(),
        branchId: (json['branch_id'] ?? '').toString(),
        patientId: (json['patient_id'] ?? '').toString(),
        patientName: (json['patient_name'] ?? '').toString(),
        doctorId: json['doctor_id']?.toString(),
        doctorName: json['doctor_name']?.toString(),
        kind: (json['kind'] ?? 'glasses').toString(),
        rx: json['rx']?.toString(),
        frame: json['frame']?.toString(),
        price: (json['price'] ?? '0').toString(),
        status: (json['status'] ?? 'ordered').toString(),
        notes: json['notes']?.toString(),
        createdAt: (json['created_at'] ?? '').toString(),
      );

  String get kindLabel => kind == 'lenses' ? 'Линзы' : 'Очки';

  String get statusLabel => switch (status) {
        'ordered' => 'Заказан',
        'in_progress' => 'В работе',
        'ready' => 'Готов',
        'issued' => 'Выдан',
        'cancelled' => 'Отменён',
        _ => status,
      };
}
