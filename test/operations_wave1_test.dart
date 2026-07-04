// Wave 1, операционный срез: P&L дня несёт гонорары хирургов
// (surgeon_fees_total, с дефолтом для старых бэкендов) и перенос операции без
// выбранного хирурга НЕ шлёт surgeon_id (сервер трактует омит как «не менять»).
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kozshifo/features/clinical/data/clinical_repository.dart';
import 'package:kozshifo/features/dashboard/domain/hanging_visit.dart';
import 'package:kozshifo/features/operations/presentation/operations_screen.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    lastRequest = options;
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, {int status = 200}) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

(ClinicalRepository, _FakeAdapter) _repo(
    ResponseBody Function(RequestOptions) handler) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;
  return (ClinicalRepository(dio), adapter);
}

const _operationJson = <String, dynamic>{
  'id': 'op-1',
  'visit_id': 'v-1',
  'patient_id': 'p-1',
  'patient_name': 'Тестов Опер',
  'referring_doctor_id': null,
  'referring_doctor_name': null,
  'surgeon_id': 'surg-1',
  'surgeon_name': 'Хирург Тестовый',
  'operation_type_id': 'ot-1',
  'type_name': 'Факоэмульсификация',
  'eye': 'od',
  'priority': 'normal',
  'status': 'scheduled',
  'price': '900000.00',
  'scheduled_at': '2026-08-01T09:00:00Z',
  'performed_at': null,
  'completed_at': null,
  'financially_closed_at': null,
  'notes': null,
  'result': null,
  'created_at': '2026-07-01T09:00:00Z',
};

void main() {
  test('operationDaySummary: parses surgeon_fees_total; money stays String',
      () async {
    final (repo, adapter) = _repo((_) => _json({
          'date': '2026-07-04',
          'operations_count': 1,
          'revenue': '900000.00',
          'cogs': '5000.00',
          'expenses': '0',
          'surgeon_fees_total': '90000.00',
          'profit': '805000.00',
        }));
    final pnl = await repo.operationDaySummary(date: '2026-07-04');
    expect(adapter.lastRequest!.uri.path, endsWith('/operations/day-summary'));
    expect(pnl.surgeonFees, '90000.00');
    expect(pnl.surgeonFees, isA<String>());
    expect(pnl.profit, '805000.00');
  });

  test('operationDaySummary: absent surgeon_fees_total defaults to "0"',
      () async {
    final (repo, _) = _repo((_) => _json({
          'date': '2026-07-04',
          'operations_count': 0,
          'revenue': '0',
          'cogs': '0',
          'expenses': '0',
          'profit': '0',
        }));
    final pnl = await repo.operationDaySummary(date: '2026-07-04');
    expect(pnl.surgeonFees, '0');
  });

  test('scheduleOperation: null surgeonId omits surgeon_id from the body '
      '(сервер трактует омит как «не менять»)', () async {
    final (repo, adapter) = _repo((_) => _json(_operationJson));
    await repo.scheduleOperation(
      id: 'op-1',
      scheduledAt: '2026-08-01T09:00:00Z',
    );
    final body = adapter.lastRequest!.data as Map<String, dynamic>;
    expect(body.containsKey('surgeon_id'), isFalse);
  });

  test('scheduleOperation: chosen surgeonId is sent', () async {
    final (repo, adapter) = _repo((_) => _json(_operationJson));
    final op = await repo.scheduleOperation(
      id: 'op-1',
      scheduledAt: '2026-08-01T09:00:00Z',
      surgeonId: 'surg-1',
    );
    final body = adapter.lastRequest!.data as Map<String, dynamic>;
    expect(body['surgeon_id'], 'surg-1');
    expect(op.surgeonId, 'surg-1');
  });

  test('OperationsScreen конструируется (компиляционная страховка экрана)', () {
    expect(const OperationsScreen(), isA<Widget>());
  });

  test('HangingCategory: severity различает info | warning | critical', () {
    HangingCategory cat(String severity) => HangingCategory(
          category: 'done_not_closed',
          label: 'Тест',
          severity: severity,
          count: 1,
        );
    final info = cat('info');
    expect(info.isInfo, isTrue);
    expect(info.isCritical, isFalse);

    final warning = cat('warning');
    expect(warning.isInfo, isFalse);
    expect(warning.isCritical, isFalse);

    final critical = cat('critical');
    expect(critical.isInfo, isFalse);
    expect(critical.isCritical, isTrue);
  });
}
