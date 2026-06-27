import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// archived vs archivable counts for one entity.
class EntityArchive {
  EntityArchive({required this.archived, required this.archivable});
  final int archived;
  final int archivable;
  factory EntityArchive.fromJson(Map<String, dynamic> j) => EntityArchive(
        archived: (j['archived'] as num).toInt(),
        archivable: (j['archivable'] as num).toInt(),
      );
}

class ArchiveSummary {
  ArchiveSummary({
    required this.olderThanDays,
    required this.visits,
    required this.operations,
    required this.notifications,
  });
  final int olderThanDays;
  final EntityArchive visits;
  final EntityArchive operations;
  final EntityArchive notifications;
  factory ArchiveSummary.fromJson(Map<String, dynamic> j) => ArchiveSummary(
        olderThanDays: (j['older_than_days'] as num).toInt(),
        visits: EntityArchive.fromJson(j['visits'] as Map<String, dynamic>),
        operations: EntityArchive.fromJson(j['operations'] as Map<String, dynamic>),
        notifications:
            EntityArchive.fromJson(j['notifications'] as Map<String, dynamic>),
      );
}

final archiveRepositoryProvider = Provider<ArchiveRepository>(
  (ref) => ArchiveRepository(ref.watch(dioProvider)),
);

class ArchiveRepository {
  ArchiveRepository(this._dio);
  final Dio _dio;

  Future<ArchiveSummary> summary(int olderThanDays) async {
    try {
      final resp = await _dio.get('/admin/archive',
          queryParameters: {'older_than_days': olderThanDays});
      return ArchiveSummary.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Returns (visits, operations, notifications) archived counts.
  Future<(int, int, int)> run(int olderThanDays) async {
    try {
      final resp = await _dio.post('/admin/archive/run',
          queryParameters: {'older_than_days': olderThanDays});
      final j = resp.data as Map<String, dynamic>;
      return (
        (j['visits'] as num).toInt(),
        (j['operations'] as num).toInt(),
        (j['notifications'] as num).toInt(),
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Archive summary for the selected retention window (days).
final archiveSummaryProvider =
    FutureProvider.autoDispose.family<ArchiveSummary, int>(
        (ref, days) => ref.watch(archiveRepositoryProvider).summary(days));
