import 'package:freezed_annotation/freezed_annotation.dart';

import 'product.dart';

part 'stock.freezed.dart';
part 'stock.g.dart';

/// One received batch of a product (mirrors backend `BatchOut`).
/// `quantity` / `unitCost` are decimal strings — never parse to double.
@freezed
abstract class StockBatch with _$StockBatch {
  const factory StockBatch({
    required String id,
    String? batchNo,
    String? expiryDate,
    required String quantity,
    required String unitCost,
    required String receivedAt,
  }) = _StockBatch;

  factory StockBatch.fromJson(Map<String, dynamic> json) =>
      _$StockBatchFromJson(json);
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
