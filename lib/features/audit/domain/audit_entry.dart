import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_entry.freezed.dart';
part 'audit_entry.g.dart';

/// One audit-trail row (mirrors backend `AuditLogOut`): who (actorName) did what
/// (action/summary) to which entity, when (createdAt), from which device
/// (ipAddress + userAgent).
@freezed
abstract class AuditEntry with _$AuditEntry {
  const factory AuditEntry({
    required String id,
    required String createdAt,
    required String action,
    required String entityType,
    String? entityId,
    String? actorId,
    String? actorName,
    String? actorEmail,
    String? branchId,
    String? summary,
    String? ipAddress,
    String? userAgent,
  }) = _AuditEntry;

  factory AuditEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryFromJson(json);
}
