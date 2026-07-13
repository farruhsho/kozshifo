/// A single stock movement (mirrors backend `MovementOut`).
///
/// Plain immutable class (no codegen) — it is only a small, read-only view model
/// (write-off result + the movements-history ledger). Quantity is a decimal
/// string, SIGNED by the server: `+` for inflows (receipt / transfer_in),
/// `−` for outflows (write_off / transfer_out / supplier_return); adjustments
/// carry either sign. The history screen colours by that sign.
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
    this.productName,
    this.productSku,
    this.actorName,
  });

  final String id;
  final String productId;
  final String branchId;
  final String movementType;
  final String quantity; // decimal string; signed (see class doc)
  final String? batchId;
  final String? reason;
  final String? refType;
  final String? refId;
  final String createdAt; // ISO datetime

  // Enriched by the movements-history endpoint (absent on the write-off result).
  final String? productName;
  final String? productSku;
  final String? actorName;

  /// The consumed amount as a positive decimal string ("-3.000" → "3.000").
  String get absQuantity =>
      quantity.startsWith('-') ? quantity.substring(1) : quantity;

  /// True when the movement increases stock (leading '+' or no sign).
  bool get isInflow => !quantity.startsWith('-');

  /// Russian label for the movement type (falls back to the raw code).
  String get typeLabel => switch (movementType) {
        'receipt' => 'Приход',
        'write_off' => 'Списание',
        'adjustment' => 'Коррекция',
        'transfer_out' => 'Перемещение (из)',
        'transfer_in' => 'Перемещение (в)',
        'supplier_return' => 'Возврат поставщику',
        _ => movementType,
      };

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
        productName: json['product_name'] as String?,
        productSku: json['product_sku'] as String?,
        actorName: json['actor_name'] as String?,
      );
}
