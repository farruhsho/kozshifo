// Document viewer smoke test: the Info/Просмотр toggle renders, metadata shows,
// and a PDF falls back to «Открыть PDF» (the in-app iframe is web-only; the test
// VM hits the io fallback). Bytes come from a fake repo (no network).
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/attachments/data/attachments_repository.dart';
import 'package:kozshifo/features/attachments/domain/attachment.dart';
import 'package:kozshifo/features/attachments/presentation/document_viewer_dialog.dart';

class _FakeRepo extends AttachmentsRepository {
  _FakeRepo() : super(Dio());
  @override
  Future<Uint8List> fileBytes(String id) async => Uint8List.fromList([1, 2, 3, 4]);
}

void main() {
  testWidgets('document viewer: toggle + info + PDF fallback', (tester) async {
    const att = Attachment(
      id: 'a1', patientId: 'p1', kind: 'uzi',
      createdAt: '2026-06-20T08:00:00Z', originalName: 'uzi-result.pdf',
      contentType: 'application/pdf', size: 2048, note: 'OD',
      uploadedByName: 'Диагност Тест',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [attachmentsRepositoryProvider.overrideWithValue(_FakeRepo())],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDocumentViewer(ctx, att),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Информация'), findsOneWidget);
    expect(find.text('Просмотр'), findsOneWidget);
    // PDF → io fallback in the test VM (web embeds an iframe instead).
    expect(find.text('Открыть PDF'), findsOneWidget);

    await tester.tap(find.text('Информация'));
    await tester.pumpAndSettle();
    expect(find.text('УЗИ'), findsOneWidget);              // kind label
    expect(find.text('Диагност Тест'), findsOneWidget);    // uploader
    expect(tester.takeException(), isNull);
  });
}
