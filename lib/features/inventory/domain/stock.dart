import 'package:freezed_annotation/freezed_annotation.dart';

import 'product.dart';

part 'stock.freezed.dart';
part 'stock.g.dart';

/// One received batch of a product (mirrors backend `BatchOut`).
/// `quantity` / `unitCost` are decimal strings — never parse to double.
/// `expiryDate` is an ISO date (`YYYY-MM-DD`) or null (no expiry).
/// `expired` is the server's own verdict (business-day aware) — never recompute
/// it client-side: expired lots are never auto-consumed, only disposed of.
@freezed
abstract class StockBatch with _$StockBatch {
  const StockBatch._();

  const factory StockBatch({
    required String id,
    String? batchNo,
    String? expiryDate,
    required String quantity,
    required String unitCost,
    required String receivedAt,
    @Default(false) bool expired,
    // Поставщик партии (для возврата поставщику → ref_id движения). Может быть
    // null: партия без поставщика или бэкенд ещё не отдаёт поле в BatchOut.
    String? supplierId,
  }) = _StockBatch;

  factory StockBatch.fromJson(Map<String, dynamic> json) =>
      _$StockBatchFromJson(json);

  /// Parsed expiry (null when no expiry date or unparseable).
  DateTime? get expiryAt =>
      expiryDate == null ? null : DateTime.tryParse(expiryDate!);

  /// Whole days until expiry from [from] (negative once expired). Null when the
  /// batch has no expiry date. Date-only — time component is ignored.
  int? daysUntilExpiry([DateTime? from]) {
    final at = expiryAt;
    if (at == null) return null;
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(at.year, at.month, at.day);
    return due.difference(today).inDays;
  }

  /// True when the batch expires within [days] days (or is already expired).
  bool expiringWithin(int days, [DateTime? from]) {
    final d = daysUntilExpiry(from);
    return d != null && d <= days;
  }
}

/// Stock position of a product in a branch: total on hand + live batches
/// (mirrors backend `GET /inventory/stock` rows).
@freezed
abstract class StockRow with _$StockRow {
  const factory StockRow({
    required Product product,
    required String onHand,
    @Default(false) bool lowStock,
    @Default(<StockBatch>[]) List<StockBatch> batches,
  }) = _StockRow;

  factory StockRow.fromJson(Map<String, dynamic> json) =>
      _$StockRowFromJson(json);
}
