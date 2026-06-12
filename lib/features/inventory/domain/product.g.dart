// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: json['id'] as String,
  sku: json['sku'] as String,
  name: json['name'] as String,
  unit: json['unit'] as String,
  productType: json['product_type'] as String,
  barcode: json['barcode'] as String?,
  minStock: json['min_stock'] as String,
  categoryId: json['category_id'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  description: json['description'] as String?,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'sku': instance.sku,
  'name': instance.name,
  'unit': instance.unit,
  'product_type': instance.productType,
  'barcode': instance.barcode,
  'min_stock': instance.minStock,
  'category_id': instance.categoryId,
  'is_active': instance.isActive,
  'description': instance.description,
};
