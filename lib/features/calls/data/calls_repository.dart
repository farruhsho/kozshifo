import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/call_record.dart';

final callsRepositoryProvider =
    Provider<CallsRepository>((ref) => CallsRepository(ref.watch(dioProvider)));

/// Журнал IP-телефонии — read-only: записи создаёт webhook АТС.
class CallsRepository {
  CallsRepository(this._dio);

  final Dio _dio;

  /// Список звонков, новые сверху. `q` — фрагмент номера или имя пациента;
  /// [dateFrom]/[dateTo] — границы по `started_at` (включительно).
  Future<Page<CallRecord>> list({
    String? q,
    DateTime? dateFrom,
    DateTime? dateTo,
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      // Бэкенд трактует naive datetime как UTC. Границы [dateFrom]/[dateTo]
      // строятся из ЛОКАЛЬНЫХ DateTime (полночь / конец дня по местному
      // времени) — поэтому переводим в UTC явно, иначе «Сегодня» уезжал бы
      // на местное смещение. Зеркалит attendance_repository (.toUtc()).
      final resp = await _dio.get('/calls', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (dateFrom != null) 'date_from': dateFrom.toUtc().toIso8601String(),
        if (dateTo != null) 'date_to': dateTo.toUtc().toIso8601String(),
        'offset': offset,
        'limit': limit,
      });
      return Page.fromJson(
          resp.data as Map<String, dynamic>, CallRecord.fromJson);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Фильтр по датам (date-only, обе границы включительно).
class CallsDateFilter {
  const CallsDateFilter(this.from, this.to);

  /// Начало периода (полночь).
  final DateTime from;

  /// Конец периода (полночь дня; до конца дня дополняет контроллер).
  final DateTime to;

  static CallsDateFilter today() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return CallsDateFilter(day, day);
  }

  bool get isSingleDay => from == to;
}

/// Поисковая строка (дебаунс делает экран).
final callsSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Диапазон дат; `null` = «Все». По умолчанию — сегодня.
final callsDateRangeProvider = StateProvider.autoDispose<CallsDateFilter?>(
    (ref) => CallsDateFilter.today());

/// Загруженные строки журнала + общее количество (для «Показать ещё»).
class CallsListState {
  const CallsListState({required this.items, required this.total});

  final List<CallRecord> items;
  final int total;

  bool get hasMore => items.length < total;
}

final callsListControllerProvider = AsyncNotifierProvider.autoDispose<
    CallsListController, CallsListState>(CallsListController.new);

class CallsListController extends AutoDisposeAsyncNotifier<CallsListState> {
  static const _pageSize = 50;

  @override
  Future<CallsListState> build() async {
    final q = ref.watch(callsSearchProvider);
    final range = ref.watch(callsDateRangeProvider);
    final page = await _fetch(q: q, range: range, offset: 0);
    return CallsListState(items: page.items, total: page.total);
  }

  /// Догрузить следующую страницу. Кидает [ApiException] —
  /// экран показывает SnackBar.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    final q = ref.read(callsSearchProvider);
    final range = ref.read(callsDateRangeProvider);
    final page =
        await _fetch(q: q, range: range, offset: current.items.length);
    state = AsyncData(CallsListState(
      items: [...current.items, ...page.items],
      total: page.total,
    ));
  }

  Future<Page<CallRecord>> _fetch({
    required String q,
    required CallsDateFilter? range,
    required int offset,
  }) {
    return ref.read(callsRepositoryProvider).list(
          q: q,
          dateFrom: range?.from,
          dateTo: range == null
              ? null
              : DateTime(range.to.year, range.to.month, range.to.day, 23, 59, 59),
          offset: offset,
          limit: _pageSize,
        );
  }
}
