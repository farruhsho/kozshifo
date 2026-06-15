// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Camera _$CameraFromJson(Map<String, dynamic> json) => _Camera(
  id: json['id'] as String,
  name: json['name'] as String,
  host: json['host'] as String,
  port: (json['port'] as num).toInt(),
  username: json['username'] as String,
  useHttps: json['use_https'] as bool? ?? false,
  vendor: json['vendor'] as String? ?? 'hikvision',
  channelNo: (json['channel_no'] as num?)?.toInt() ?? 1,
  snapshotPath: json['snapshot_path'] as String?,
  branchId: json['branch_id'] as String?,
  branchName: json['branch_name'] as String?,
  status: json['status'] as String,
  online: json['online'] as bool? ?? false,
  lastSeen: json['last_seen'] as String?,
  deviceInfo: json['device_info'] as Map<String, dynamic>?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$CameraToJson(_Camera instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'host': instance.host,
  'port': instance.port,
  'username': instance.username,
  'use_https': instance.useHttps,
  'vendor': instance.vendor,
  'channel_no': instance.channelNo,
  'snapshot_path': instance.snapshotPath,
  'branch_id': instance.branchId,
  'branch_name': instance.branchName,
  'status': instance.status,
  'online': instance.online,
  'last_seen': instance.lastSeen,
  'device_info': instance.deviceInfo,
  'created_at': instance.createdAt,
};
