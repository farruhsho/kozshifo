// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CallDevice _$CallDeviceFromJson(Map<String, dynamic> json) => _CallDevice(
  id: json['id'] as String,
  label: json['label'] as String,
  phoneNumber: json['phone_number'] as String?,
  branchId: json['branch_id'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  lastSeenAt: json['last_seen_at'] as String?,
  appVersion: json['app_version'] as String?,
  online: json['online'] as bool? ?? false,
);

Map<String, dynamic> _$CallDeviceToJson(_CallDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'phone_number': instance.phoneNumber,
      'branch_id': instance.branchId,
      'is_active': instance.isActive,
      'last_seen_at': instance.lastSeenAt,
      'app_version': instance.appVersion,
      'online': instance.online,
    };
