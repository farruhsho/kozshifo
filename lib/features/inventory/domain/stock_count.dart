// Инвентаризация (stock-count) view models — plain immutable classes (no
// codegen). Decimal quantities are kept as strings; the server owns the math.

/// One counted line: a (product, batch) snapshot with the expected qty frozen at
/// open time, the counted qty entered by staff, and the resulting variance.
class StockCountLine {
  const StockCountLine({
    required this.id,
    required this.productId,
    this.batchId,
    required this.productName,
    required this.productSku,
    required this.unit,
    this.batchNo,
    this.expiryDate,
    required this.expectedQty,
    required this.countedQty,
    required this.variance,
  });

  final String id;
  final String productId;
  final String? batchId;
  final String productName;
  final String productSku;
  final String unit;
  final String? batchNo;
  final String? expiryDate;
  final String expectedQty;
  final String countedQty;
  final String variance; // counted − expected; negative = shortage

  /// Signed variance as a double for the traffic-light colouring (display only).
  double get varianceValue => double.tryParse(variance) ?? 0;

  factory StockCountLine.fromJson(Map<String, dynamic> json) => StockCountLine(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        batchId: json['batch_id'] as String?,
        productName: json['product_name'] as String,
        productSku: json['product_sku'] as String,
        unit: json['unit'] as String,
        batchNo: json['batch_no'] as String?,
        expiryDate: json['expiry_date'] as String?,
        expectedQty: json['expected_qty'].toString(),
        countedQty: json['counted_qty'].toString(),
        variance: json['variance'].toString(),
      );
}

/// A stock-count header with its totals (and, for the detail view, its lines).
class StockCount {
  const StockCount({
    required this.id,
    required this.branchId,
    required this.status,
    this.note,
    required this.createdAt,
    required this.surplusTotal,
    required this.shortageTotal,
    required this.linesCount,
    this.lines = const [],
  });

  final String id;
  final String branchId;
  final String status; // draft | committed
  final String? note;
  final String createdAt;
  final String surplusTotal;
  final String shortageTotal;
  final int linesCount;
  final List<StockCountLine> lines;

  bool get isDraft => status == 'draft';

  factory StockCount.fromJson(Map<String, dynamic> json) => StockCount(
        id: json['id'] as String,
        branchId: json['branch_id'] as String,
        status: json['status'] as String,
        note: json['note'] as String?,
        createdAt: json['created_at'].toString(),
        surplusTotal: json['surplus_total'].toString(),
        shortageTotal: json['shortage_total'].toString(),
        linesCount: (json['lines_count'] as num).toInt(),
        lines: (json['lines'] as List<dynamic>? ?? const [])
            .map((e) => StockCountLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
