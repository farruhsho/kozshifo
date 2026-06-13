/// A single stock movement (mirrors backend `MovementOut`).
///
/// Plain immutable class (no codegen) — it is only a small, read-only view model
/// for the write-off result. Quantity is a decimal string; for write-off
/// movements it is NEGATIVE (e.g. "-3.000"), matching the FEFO engine.
class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.branchId,
    required this.movementType,
    required this.quantity,
    this.batchId,
    this.reason,
    this.refType,
    this.refId,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String branchId;
  final String movementType; // receipt | write_off
  final String quantity; // decimal string; negative for write-offs
  final String? batchId;
  final String? reason;
  final String? refType;
  final String? refId;
  final String createdAt; // ISO datetime

  /// The consumed amount as a positive decimal string ("-3.000" → "3.000").
  String get absQuantity =>
      quantity.startsWith('-') ? quantity.substring(1) : quantity;

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        branchId: json['branch_id'] as String,
        movementType: json['movement_type'] as String,
        quantity: json['quantity'].toString(),
        batchId: json['batch_id'] as String?,
        reason: json['reason'] as String?,
        refType: json['ref_type'] as String?,
        refId: json['ref_id'] as String?,
        createdAt: json['created_at'].toString(),
      );
}
