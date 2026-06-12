// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockBatch _$StockBatchFromJson(Map<String, dynamic> json) => _StockBatch(
  id: json['id'] as String,
  batchNo: json['batch_no'] as String?,
  expiryDate: json['expiry_date'] as String?,
  quantity: json['quantity'] as String,
  unitCost: json['unit_cost'] as String,
  receivedAt: json['received_at'] as String,
);

Map<String, dynamic> _$StockBatchToJson(_StockBatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batch_no': instance.batchNo,
      'expiry_date': instance.expiryDate,
      'quantity': instance.quantity,
      'unit_cost': instance.unitCost,
      'received_at': instance.receivedAt,
    };

_StockRow _$StockRowFromJson(Map<String, dynamic> json) => _StockRow(
  product: Product.fromJson(json['product'] as Map<String, dynamic>),
  onHand: json['on_hand'] as String,
  lowStock: json['low_stock'] as bool? ?? false,
  batches:
      (json['batches'] as List<dynamic>?)
          ?.map((e) => StockBatch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <StockBatch>[],
);

Map<String, dynamic> _$StockRowToJson(_StockRow instance) => <String, dynamic>{
  'product': instance.product.toJson(),
  'on_hand': instance.onHand,
  'low_stock': instance.lowStock,
  'batches': instance.batches.map((e) => e.toJson()).toList(),
};
