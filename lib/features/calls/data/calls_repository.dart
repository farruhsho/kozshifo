import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/call_device.dart';
import '../domain/call_record.dart';
import '../domain/calls_summary.dart';

final callsRepositoryProvider =
    Provider<CallsRepository>((ref) => CallsRepository(ref.watch(dioProvider)));

/// Журнал + мониторинг звонков. Записи приходят с агентов на телефонах ресепшена
/// (или webhook АТС); экран директора показывает их и KPI ответов/пропусков.
class CallsRepository {
  CallsRepository(this._dio);

  final Dio _dio;

  /// KPI за период (по умолчанию — сегодня): отвечено / пропущено / среднее
  /// время ответа, разбивка по телефонам и по часам, офлайн-телефоны.
  Future<CallsSummary> summary({DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final resp = await _dio.get('/calls/summary', queryParameters: {
        if (dateFrom != null) 'date_from': _ymd(dateFrom),
        if (dateTo != null) 'date_to': _ymd(dateTo),
      });
      return CallsSummary.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Зарегистрированные телефоны ресепшена (для директора, право calls.manage).
  Future<List<CallDevice>> listDevices() async {
    try {
      final resp = await _dio.get('/calls/devices');
      return (resp.data as List<dynamic>)
          .map((e) => CallDevice.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Регистрирует телефон; ключ возвращается ОДИН раз (хранится только хэш).
  Future<CreatedDevice> createDevice({
    required String label,
    String? phoneNumber,
    String? branchId,
  }) async {
    try {
      final resp = await _dio.post('/calls/devices', data: {
        'label': label,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
        'branch_id': ?branchId,
      });
      return CreatedDevice.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Редактирует телефон (название / активность). Возвращает обновлённую запись.
  Future<CallDevice> updateDevice(
    String id, {
    String? label,
    bool? isActive,
  }) async {
    try {
      final resp = await _dio.patch('/calls/devices/$id', data: {
        'label': ?label,
        'is_active': ?isActive,
      });
      return CallDevice.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Выдаёт новый ключ (старый сразу перестаёт работать).
  Future<CreatedDevice> rotateKey(String id) async {
    try {
      final resp = await _dio.post('/calls/devices/$id/rotate-key');
      return CreatedDevice.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Филиалы как (id, name) — для выпадающего списка при привязке телефона.
  /// Лёгкий запрос: отдельной branches-фичи на фронте нет.
  Future<List<({String id, String name})>> branchOptions() async {
    try {
      final resp = await _dio.get('/branches');
      return (resp.data as List<dynamic>)
          .map((e) => (
                id: (e as Map<String, dynamic>)['id'] as String,
                name: e['name'] as String,
              ))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// `YYYY-MM-DD` из локальной даты (бэкенд summary принимает date-only).
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

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

/// KPI-сводка за выбранный период (тот же диапазон, что и журнал).
/// Экран дёргает refresh раз в ~60с — мониторинг «почти в реальном времени».
final callsSummaryProvider = FutureProvider.autoDispose<CallsSummary>((ref) {
  final range = ref.watch(callsDateRangeProvider);
  return ref.watch(callsRepositoryProvider).summary(
        dateFrom: range?.from,
        dateTo: range?.to,
      );
});

/// Список зарегистрированных телефонов ресепшена (экран управления).
final callDevicesProvider = FutureProvider.autoDispose<List<CallDevice>>(
    (ref) => ref.watch(callsRepositoryProvider).listDevices());

/// Филиалы (id → name) для привязки телефона.
final branchOptionsProvider =
    FutureProvider.autoDispose<List<({String id, String name})>>(
        (ref) => ref.watch(callsRepositoryProvider).branchOptions());

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
    // The search field / date chip stay live during the load, and changing
    // either re-runs build() (it watches both providers), replacing state with
    // the correct offset-0 list for the NEW filter. If that happened while this
    // page was in flight, dropping our stale page is the whole fix — otherwise
    // it would clobber the fresh list with old-filter rows + an inflated total.
    if (q != ref.read(callsSearchProvider) ||
        range != ref.read(callsDateRangeProvider)) {
      return;
    }
    final latest = state.valueOrNull;
    if (latest == null) return;
    state = AsyncData(CallsListState(
      items: [...latest.items, ...page.items],
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
