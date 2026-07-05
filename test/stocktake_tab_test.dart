// Инвентаризация (stock-count) detail-экран: регрессия «строка залипает после
// сохранения». Раньше _saving никогда не сбрасывался в false и _LineTile без
// Key переиспользовал State на соседней строке → TextField навсегда disabled и
// показывал старое значение. Фикс: сброс _saving, ValueKey(line.id) и
// didUpdateWidget-синк. Тест гоняет реальный экран с фейковым репозиторием,
// чтобы инвалидация провайдера отражала обновлённую строку.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kozshifo/features/inventory/data/inventory_repository.dart';
import 'package:kozshifo/features/inventory/domain/stock_count.dart';
import 'package:kozshifo/features/inventory/presentation/stocktake_tab.dart';

// ─── Фейковый репозиторий: держит одну черновую инвентаризацию с одной строкой ──
// updateCountLine мутирует фактический остаток и пересчитывает variance, как
// сервер, поэтому повторный stockCount() (после ref.invalidate) вернёт свежее
// значение — ровно тот путь, что «залипал».
class _FakeInventoryRepo extends InventoryRepository {
  _FakeInventoryRepo() : super(_neverDio());

  StockCountLine _line = const StockCountLine(
    id: 'line-1',
    productId: 'prod-1',
    batchId: 'batch-1',
    productName: 'Тропикамид 1%',
    productSku: 'MED-001',
    unit: 'фл',
    batchNo: 'B-1',
    expiryDate: '2027-01-01',
    expectedQty: '10',
    countedQty: '10',
    variance: '0',
  );

  int updateCalls = 0;

  StockCount get _count => StockCount(
        id: 'count-1',
        branchId: 'br-1',
        status: 'draft',
        note: null,
        createdAt: '2026-07-04T09:00:00Z',
        surplusTotal: '0',
        shortageTotal: '0',
        linesCount: 1,
        lines: [_line],
      );

  @override
  Future<StockCount> stockCount(String countId) async => _count;

  @override
  Future<StockCountLine> updateCountLine({
    required String countId,
    required String lineId,
    required String countedQty,
  }) async {
    updateCalls++;
    final expected = double.parse(_line.expectedQty);
    final counted = double.parse(countedQty);
    _line = StockCountLine(
      id: _line.id,
      productId: _line.productId,
      batchId: _line.batchId,
      productName: _line.productName,
      productSku: _line.productSku,
      unit: _line.unit,
      batchNo: _line.batchNo,
      expiryDate: _line.expiryDate,
      expectedQty: _line.expectedQty,
      countedQty: countedQty,
      variance: (counted - expected).toString(),
    );
    return _line;
  }
}

// Dio, к которому мы никогда не обращаемся (все методы репо переопределены).
Dio _neverDio() => Dio();

void main() {
  Widget host({required List<Override> overrides}) => ProviderScope(
        overrides: overrides,
        child: const MaterialApp(
          home: StockCountDetailScreen(branchId: 'br-1', countId: 'count-1'),
        ),
      );

  testWidgets(
      'строка редактируема и показывает свежее значение после сохранения',
      (tester) async {
    final repo = _FakeInventoryRepo();
    await tester.pumpWidget(host(overrides: [
      inventoryRepositoryProvider.overrideWithValue(repo),
    ]));
    await tester.pumpAndSettle();

    Finder field() => find.widgetWithText(TextField, 'факт').hitTestable();
    TextField widget() => tester.widget<TextField>(field());

    // Стартовое состояние: одно поле «факт» = 10, доступно для ввода.
    expect(field(), findsOneWidget);
    expect(widget().enabled, isTrue);
    expect(widget().controller!.text, '10');

    // Правим факт на 12 и коммитим (onEditingComplete эмулируем submit).
    await tester.enterText(field(), '12');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);

    // Регрессия бага 1: поле НЕ должно остаться disabled, а значение — устареть.
    expect(widget().enabled, isTrue,
        reason: 'после сохранения поле снова редактируемо (_saving сброшен)');
    expect(widget().controller!.text, '12',
        reason: 'контроллер синхронизирован со свежей строкой провайдера');

    // Можно исправить опечатку ещё раз — второе сохранение проходит.
    await tester.enterText(field(), '9');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 2);
    expect(widget().enabled, isTrue);
    expect(widget().controller!.text, '9');
  });
}
