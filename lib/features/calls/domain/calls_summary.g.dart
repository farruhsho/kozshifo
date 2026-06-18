// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calls_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CallDeviceStat _$CallDeviceStatFromJson(Map<String, dynamic> json) =>
    _CallDeviceStat(
      deviceId: json['device_id'] as String?,
      label: json['label'] as String,
      total: (json['total'] as num?)?.toInt() ?? 0,
      answered: (json['answered'] as num?)?.toInt() ?? 0,
      missed: (json['missed'] as num?)?.toInt() ?? 0,
      avgWaitSeconds: (json['avg_wait_seconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CallDeviceStatToJson(_CallDeviceStat instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'label': instance.label,
      'total': instance.total,
      'answered': instance.answered,
      'missed': instance.missed,
      'avg_wait_seconds': instance.avgWaitSeconds,
    };

_CallHourBucket _$CallHourBucketFromJson(Map<String, dynamic> json) =>
    _CallHourBucket(
      hour: (json['hour'] as num).toInt(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      missed: (json['missed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CallHourBucketToJson(_CallHourBucket instance) =>
    <String, dynamic>{
      'hour': instance.hour,
      'total': instance.total,
      'missed': instance.missed,
    };

_CallsSummary _$CallsSummaryFromJson(Map<String, dynamic> json) =>
    _CallsSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      incoming: (json['incoming'] as num?)?.toInt() ?? 0,
      answered: (json['answered'] as num?)?.toInt() ?? 0,
      missed: (json['missed'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      outgoing: (json['outgoing'] as num?)?.toInt() ?? 0,
      missedRate: (json['missed_rate'] as num?)?.toDouble() ?? 0,
      avgWaitSeconds: (json['avg_wait_seconds'] as num?)?.toInt() ?? 0,
      maxWaitSeconds: (json['max_wait_seconds'] as num?)?.toInt() ?? 0,
      byDevice:
          (json['by_device'] as List<dynamic>?)
              ?.map((e) => CallDeviceStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CallDeviceStat>[],
      byHour:
          (json['by_hour'] as List<dynamic>?)
              ?.map((e) => CallHourBucket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CallHourBucket>[],
      offlineDevices:
          (json['offline_devices'] as List<dynamic>?)
              ?.map((e) => CallDevice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CallDevice>[],
    );

Map<String, dynamic> _$CallsSummaryToJson(
  _CallsSummary instance,
) => <String, dynamic>{
  'total': instance.total,
  'incoming': instance.incoming,
  'answered': instance.answered,
  'missed': instance.missed,
  'rejected': instance.rejected,
  'outgoing': instance.outgoing,
  'missed_rate': instance.missedRate,
  'avg_wait_seconds': instance.avgWaitSeconds,
  'max_wait_seconds': instance.maxWaitSeconds,
  'by_device': instance.byDevice.map((e) => e.toJson()).toList(),
  'by_hour': instance.byHour.map((e) => e.toJson()).toList(),
  'offline_devices': instance.offlineDevices.map((e) => e.toJson()).toList(),
};
