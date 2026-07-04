import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/recall_entry.dart';

final recallRepositoryProvider =
    Provider<RecallRepository>((ref) => RecallRepository(ref.watch(dioProvider)));

/// «Повторные приёмы» — пациенты с визитом в follow_up, которым пора вернуться
/// (follow_up_date <= due_by, по умолчанию — сегодня).
class RecallRepository {
  RecallRepository(this._dio);

  final Dio _dio;

  /// Визиты в follow_up с датой повтора <= [dueBy] (default = сегодня по
  /// локальной дате), отсортированные по дате повтора по возрастанию.
  Future<List<RecallEntry>> recallDue({DateTime? dueBy}) async {
    try {
      final resp = await _dio.get('/visits/recall', queryParameters: {
        if (dueBy != null) 'due_by': _isoDate(dueBy),
      });
      return (resp.data as List<dynamic>)
          .map((e) => RecallEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Локальная дата в ISO 'YYYY-MM-DD' без времени/таймзоны.
String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Список повторных приёмов на сегодня (и просроченных).
final recallDueProvider = FutureProvider.autoDispose<List<RecallEntry>>(
    (ref) => ref.watch(recallRepositoryProvider).recallDue());
