import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/audit_entry.dart';

final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepository(ref.watch(dioProvider)),
);

/// Filter key for the audit log (record equality → one provider per filter).
typedef AuditQuery = ({
  String? entityType,
  String? action,
  DateTime? from,
  DateTime? to,
});

class AuditRepository {
  AuditRepository(this._dio);

  final Dio _dio;

  static String? _date(DateTime? d) =>
      d == null ? null : '${d.year}-${_two(d.month)}-${_two(d.day)}';
  static String _two(int n) => n.toString().padLeft(2, '0');

  Future<Page<AuditEntry>> auditLogs(
    AuditQuery q, {
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      final resp = await _dio.get('/admin/audit-logs', queryParameters: {
        'entity_type': ?q.entityType,
        'action': ?q.action,
        'date_from': ?_date(q.from),
        'date_to': ?_date(q.to),
        'offset': offset,
        'limit': limit,
      });
      return Page.fromJson(resp.data as Map<String, dynamic>, AuditEntry.fromJson);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Audit trail page for the current filter (first page; newest first).
final auditLogProvider =
    FutureProvider.autoDispose.family<Page<AuditEntry>, AuditQuery>(
        (ref, q) => ref.watch(auditRepositoryProvider).auditLogs(q));
