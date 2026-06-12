// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OperationType _$OperationTypeFromJson(Map<String, dynamic> json) =>
    _OperationType(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      serviceId: json['service_id'] as String,
      price: json['price'] as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      isActive: json['is_active'] as bool? ?? true,
      description: json['description'] as String?,
      consumables:
          (json['consumables'] as List<dynamic>?)
              ?.map(
                (e) => OperationConsumable.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <OperationConsumable>[],
    );

Map<String, dynamic> _$OperationTypeToJson(_OperationType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'service_id': instance.serviceId,
      'price': instance.price,
      'duration_minutes': instance.durationMinutes,
      'is_active': instance.isActive,
      'description': instance.description,
      'consumables': instance.consumables.map((e) => e.toJson()).toList(),
    };

_OperationConsumable _$OperationConsumableFromJson(Map<String, dynamic> json) =>
    _OperationConsumable(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as String,
    );

Map<String, dynamic> _$OperationConsumableToJson(
  _OperationConsumable instance,
) => <String, dynamic>{
  'product_id': instance.productId,
  'product_name': instance.productName,
  'quantity': instance.quantity,
};
