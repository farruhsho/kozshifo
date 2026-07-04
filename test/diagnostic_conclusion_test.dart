// Diagnoses slice: repository request-shape against a mocked Dio adapter.
// Covers recordConclusion (POST) and the medical-amend deleteConclusion (DELETE)
// so the exact URLs the backend expects are locked. Deterministic, no network.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kozshifo/features/diagnoses/data/diagnoses_repository.dart';

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

(DiagnosesRepository, _FakeAdapter) _repo(
    ResponseBody Function(RequestOptions) handler) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;
  return (DiagnosesRepository(dio), adapter);
}

void main() {
  test('recordConclusion posts diagnosis_id to the visit conclusion route',
      () async {
    final (repo, adapter) = _repo((_) => _json(<String, dynamic>{}, status: 201));
    await repo.recordConclusion(visitId: 'v-1', diagnosisId: 'd-9');

    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.path, '/visits/v-1/diagnostic-conclusion');
    expect(adapter.lastRequest!.data, {'diagnosis_id': 'd-9'});
  });

  test('deleteConclusion hits the per-visit amend route', () async {
    final (repo, adapter) = _repo((_) => _json(<String, dynamic>{}, status: 204));
    await repo.deleteConclusion(visitId: 'v-1', conclusionId: 'c-7');

    expect(adapter.lastRequest!.method, 'DELETE');
    expect(adapter.lastRequest!.path,
        '/visits/v-1/diagnostic-conclusion/c-7');
  });
}
