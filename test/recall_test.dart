// «Повторные приёмы»: repo парсит RecallEntry (mock-транспорт, без сокетов);
// экран рендерит запись и помечает просроченные записи бейджем.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/recall/data/recall_repository.dart';
import 'package:kozshifo/features/recall/domain/recall_entry.dart';
import 'package:kozshifo/features/recall/presentation/recall_screen.dart';

// ── Repository: mock transport ───────────────────────────────────────────────

/// Records the last request and replies with a canned body — no sockets.
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.body);

  final String body;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(RecallRepository, _MockAdapter) _repoWith(String body) {
  final adapter = _MockAdapter(body);
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;
  return (RecallRepository(dio), adapter);
}

void main() {
  group('RecallRepository', () {
    test('парсит RecallEntry из ответа /visits/recall', () async {
      final (repo, adapter) = _repoWith(jsonEncode([
        {
          'visit_id': 'v1',
          'patient_id': 'p1',
          'patient_name': 'Алиев Вали',
          'phone': '+998901112233',
          'follow_up_date': '2026-07-01',
          'last_visit_date': '2026-06-15',
        },
        {
          'visit_id': 'v2',
          'patient_id': 'p2',
          'patient_name': 'Каримова Гуля',
          'phone': null,
          'follow_up_date': '2026-07-04',
          'last_visit_date': null,
        },
      ]));

      final rows = await repo.recallDue();

      expect(adapter.lastOptions!.method, 'GET');
      expect(adapter.lastOptions!.path, '/visits/recall');
      // due_by не передан по умолчанию — сервер сам берёт сегодня.
      expect(adapter.lastOptions!.queryParameters.containsKey('due_by'), isFalse);
      expect(rows, hasLength(2));
      expect(rows.first.visitId, 'v1');
      expect(rows.first.patientName, 'Алиев Вали');
      expect(rows.first.phone, '+998901112233');
      expect(rows.first.followUpDate, DateTime(2026, 7, 1));
      expect(rows.first.lastVisitDate, DateTime(2026, 6, 15));
      // null-поля переносятся корректно.
      expect(rows[1].phone, isNull);
      expect(rows[1].lastVisitDate, isNull);
    });

    test('recallDue передаёт due_by как ISO-дату', () async {
      final (repo, adapter) = _repoWith(jsonEncode(const []));

      await repo.recallDue(dueBy: DateTime(2026, 7, 10));

      expect(adapter.lastOptions!.queryParameters['due_by'], '2026-07-10');
    });
  });

  group('RecallScreen', () {
    Widget host(List<RecallEntry> rows) => ProviderScope(
          overrides: [
            recallDueProvider.overrideWith((ref) async => rows),
          ],
          child: const MaterialApp(home: RecallScreen()),
        );

    testWidgets('рендерит запись и помечает просроченные', (tester) async {
      final overdueDate = DateTime.now().subtract(const Duration(days: 3));
      final futureDate = DateTime.now().add(const Duration(days: 5));

      await tester.pumpWidget(host([
        RecallEntry(
          visitId: 'v1',
          patientId: 'p1',
          patientName: 'Алиев Вали',
          phone: '+998901112233',
          followUpDate: DateTime(
              overdueDate.year, overdueDate.month, overdueDate.day),
          lastVisitDate: DateTime(2026, 6, 15),
        ),
        RecallEntry(
          visitId: 'v2',
          patientId: 'p2',
          patientName: 'Каримова Гуля',
          followUpDate:
              DateTime(futureDate.year, futureDate.month, futureDate.day),
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Повторные приёмы'), findsOneWidget);
      expect(find.text('Алиев Вали'), findsOneWidget);
      expect(find.text('Каримова Гуля'), findsOneWidget);

      // Просроченная на 3 дня запись помечена бейджем; будущая — нет.
      expect(find.text('просрочено 3 дн'), findsOneWidget);
      expect(find.textContaining('просрочено'), findsOneWidget);
    });

    testWidgets('пустой список показывает заглушку', (tester) async {
      await tester.pumpWidget(host(const []));
      await tester.pumpAndSettle();

      expect(find.text('Нет повторных приёмов'), findsOneWidget);
    });
  });
}
