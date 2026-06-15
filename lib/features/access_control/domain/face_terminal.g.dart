// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'face_terminal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FaceTerminal _$FaceTerminalFromJson(Map<String, dynamic> json) =>
    _FaceTerminal(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      username: json['username'] as String,
      doorNo: (json['door_no'] as num).toInt(),
      useHttps: json['use_https'] as bool? ?? false,
      branchId: json['branch_id'] as String?,
      branchName: json['branch_name'] as String?,
      status: json['status'] as String? ?? 'active',
      online: json['online'] as bool? ?? false,
      lastSeen: json['last_seen'] == null
          ? null
          : DateTime.parse(json['last_seen'] as String),
      deviceInfo: json['device_info'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FaceTerminalToJson(_FaceTerminal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'host': instance.host,
      'port': instance.port,
      'username': instance.username,
      'door_no': instance.doorNo,
      'use_https': instance.useHttps,
      'branch_id': instance.branchId,
      'branch_name': instance.branchName,
      'status': instance.status,
      'online': instance.online,
      'last_seen': instance.lastSeen?.toIso8601String(),
      'device_info': instance.deviceInfo,
      'created_at': instance.createdAt.toIso8601String(),
    };

_TerminalTestResult _$TerminalTestResultFromJson(Map<String, dynamic> json) =>
    _TerminalTestResult(
      online: json['online'] as bool,
      model: json['model'] as String?,
      firmware: json['firmware'] as String?,
      serial: json['serial'] as String?,
      deviceName: json['device_name'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$TerminalTestResultToJson(_TerminalTestResult instance) =>
    <String, dynamic>{
      'online': instance.online,
      'model': instance.model,
      'firmware': instance.firmware,
      'serial': instance.serial,
      'device_name': instance.deviceName,
      'error': instance.error,
    };
