// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Service _$ServiceFromJson(Map<String, dynamic> json) => _Service(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
  price: json['price'] as String,
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  description: json['description'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  isDiagnostic: json['is_diagnostic'] as bool? ?? false,
  categoryId: json['category_id'] as String?,
  doctors: json['doctors'] == null
      ? const <ServiceDoctor>[]
      : serviceDoctorsFromJson(json['doctors']),
);

Map<String, dynamic> _$ServiceToJson(_Service instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'price': instance.price,
  'duration_minutes': instance.durationMinutes,
  'description': instance.description,
  'is_active': instance.isActive,
  'is_diagnostic': instance.isDiagnostic,
  'category_id': instance.categoryId,
  'doctors': serviceDoctorsToJson(instance.doctors),
};
