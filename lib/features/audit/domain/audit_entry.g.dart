// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditEntry _$AuditEntryFromJson(Map<String, dynamic> json) => _AuditEntry(
  id: json['id'] as String,
  createdAt: json['created_at'] as String,
  action: json['action'] as String,
  entityType: json['entity_type'] as String,
  entityId: json['entity_id'] as String?,
  actorId: json['actor_id'] as String?,
  actorName: json['actor_name'] as String?,
  actorEmail: json['actor_email'] as String?,
  branchId: json['branch_id'] as String?,
  summary: json['summary'] as String?,
  ipAddress: json['ip_address'] as String?,
  userAgent: json['user_agent'] as String?,
);

Map<String, dynamic> _$AuditEntryToJson(_AuditEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt,
      'action': instance.action,
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'actor_id': instance.actorId,
      'actor_name': instance.actorName,
      'actor_email': instance.actorEmail,
      'branch_id': instance.branchId,
      'summary': instance.summary,
      'ip_address': instance.ipAddress,
      'user_agent': instance.userAgent,
    };
