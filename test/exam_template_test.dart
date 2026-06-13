// Doctor's reusable exam-conclusion templates — repository layer.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/doctor/data/doctor_repository.dart';
import 'package:kozshifo/features/doctor/domain/exam_template.dart';

void main() {
  group('DoctorRepository exam templates', () {
    test('parses the template list', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _Adapter((o) => _json(jsonEncode([
              {
                'id': 't-1', 'doctor_id': 'd-1', 'name': 'Катаракта',
                'diagnosis': 'Возрастная катаракта', 'icd10': 'H25.0',
                'recommendations': 'Факоэмульсификация', 'created_at': '2026-06-13T10:00:00Z',
              },
            ])));
      final list = await DoctorRepository(dio).examTemplates();
      expect(list, hasLength(1));
      expect(list.first, isA<ExamTemplate>());
      expect(list.first.name, 'Катаракта');
      expect(list.first.icd10, 'H25.0');
    });

    test('save sends name + non-empty fields, omitting blanks', () async {
      late RequestOptions captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _Adapter((o) {
          captured = o;
          return _json(jsonEncode({
            'id': 't-2', 'doctor_id': 'd-1', 'name': 'Глаукома',
            'diagnosis': null, 'icd10': null, 'recommendations': 'Тимолол',
          }), 201);
        });
      await DoctorRepository(dio).saveExamTemplate(
        name: 'Глаукома',
        diagnosis: '   ', // blank → omitted
        recommendations: 'Тимолол 0.5%',
      );
      final body = captured.data as Map<String, dynamic>;
      expect(body['name'], 'Глаукома');
      expect(body['recommendations'], 'Тимолол 0.5%');
      expect(body.containsKey('diagnosis'), isFalse);
      expect(body.containsKey('icd10'), isFalse);
    });

    test('delete hits DELETE /exam-templates/{id}', () async {
      late RequestOptions captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _Adapter((o) {
          captured = o;
          return _json('{"detail":"Template deleted"}');
        });
      await DoctorRepository(dio).deleteExamTemplate('t-9');
      expect(captured.method, 'DELETE');
      expect(captured.path, '/exam-templates/t-9');
    });
  });
}

ResponseBody _json(String body, [int code = 200]) => ResponseBody.fromString(
      body, code,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

class _Adapter implements HttpClientAdapter {
  _Adapter(this._handler);
  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}
