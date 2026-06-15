// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccessEvent _$AccessEventFromJson(Map<String, dynamic> json) => _AccessEvent(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  userFullName: json['user_full_name'] as String?,
  direction: json['direction'] as String,
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  source: json['source'] as String,
);

Map<String, dynamic> _$AccessEventToJson(_AccessEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'user_full_name': instance.userFullName,
      'direction': instance.direction,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'source': instance.source,
    };
