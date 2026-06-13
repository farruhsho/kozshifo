/// A payment row as the cashier sees it in the history / refund list
/// (mirrors backend `PaymentOut`). Plain immutable class — no codegen — because
/// it is a small read-only view model. Money stays a string on the wire.
class TillPayment {
  const TillPayment({
    required this.id,
    required this.receiptNo,
    required this.visitId,
    required this.patientId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String receiptNo;
  final String visitId;
  final String patientId;
  final String amount; // decimal string, e.g. "150000.00"
  final String method; // cash | card | qr | transfer
  final String status; // completed | refunded
  final String createdAt; // ISO-8601 with offset
  final String? note;

  bool get isRefunded => status == 'refunded';

  factory TillPayment.fromJson(Map<String, dynamic> json) => TillPayment(
        id: json['id'] as String,
        receiptNo: json['receipt_no'] as String,
        visitId: json['visit_id'] as String,
        patientId: json['patient_id'] as String,
        amount: json['amount'].toString(),
        method: json['method'] as String,
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
        note: json['note'] as String?,
      );
}
