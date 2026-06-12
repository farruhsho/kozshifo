import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Inventory product (mirrors backend `ProductOut`).
/// Quantity/money decimals (`minStock`) arrive as strings — keep them String,
/// the server owns the decimal math.
@freezed
abstract class Product with _$Product {
  const Product._();

  const factory Product({
    required String id,
    required String sku,
    required String name,
    required String unit,
    required String productType,
    String? barcode,
    required String minStock,
    String? categoryId,
    @Default(true) bool isActive,
    String? description,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

  String get typeLabel => switch (productType) {
        'medicine' => 'Лекарство',
        'consumable' => 'Расходник',
        'material' => 'Материал',
        'instrument' => 'Инструмент',
        _ => productType,
      };
}
