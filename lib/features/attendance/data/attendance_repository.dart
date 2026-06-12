import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/attendance_event.dart';
import '../domain/attendance_report.dart';

/// Период табеля (включительно), даты как `YYYY-MM-DD` — record даёт
/// структурное `==`, поэтому годится как ключ family-провайдера.
typedef AttendancePeriod = ({String from, String to});

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
    (ref) => AttendanceRepository(ref.watch(dioProvider)));

/// Учёт рабочего времени (Face ID): табель, журнал отметок, ручные коррекции.
/// Сами терминалы Face ID шлют POST /attendance/punch с общим ключом — это
/// серверная интеграция, UI её не касается.
class AttendanceRepository {
  AttendanceRepository(this._dio);

  final Dio _dio;

  /// Табель: по сотруднику — дни, присутствия/пропуски/опоздания.
  Future<AttendanceReport> report({
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final resp = await _dio.get('/attendance/report', queryParameters: {
        'date_from': dateFrom,
        'date_to': dateTo,
      });
      return AttendanceReport.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Сырой журнал отметок, новые сверху (Page envelope).
  Future<Page<AttendanceEvent>> events({
    required String dateFrom,
    required String dateTo,
    String? userId,
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      final resp = await _dio.get('/attendance/events', queryParameters: {
        'date_from': dateFrom,
        'date_to': dateTo,
        'user_id': ?userId,
        'offset': offset,
        'limit': limit,
      });
      return Page.fromJson(
          resp.data as Map<String, dynamic>, AttendanceEvent.fromJson);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Ручная отметка администратора (коррекция / забытый Face ID).
  /// Backend трактует naive datetime как UTC — поэтому всегда шлём
  /// явный UTC ISO (`...Z`).
  Future<AttendanceEvent> createEvent({
    required String userId,
    required String direction, // in | out
    required DateTime occurredAt,
    String? note,
  }) async {
    try {
      final resp = await _dio.post('/attendance/events', data: {
        'user_id': userId,
        'direction': direction,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'note': ?note,
      });
      return AttendanceEvent.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Тот же табель в CSV (UTF-8 BOM, разделитель «;» — открывается в Excel).
  Future<Uint8List> reportCsv({
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final resp = await _dio.get(
        '/attendance/report.csv',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data as List<int>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final attendanceReportProvider = FutureProvider.autoDispose
    .family<AttendanceReport, AttendancePeriod>((ref, period) => ref
        .watch(attendanceRepositoryProvider)
        .report(dateFrom: period.from, dateTo: period.to));
