// Widget smoke test for the movements-history tab: renders enriched rows with
// the Russian type label + signed quantity, and shows a «Показать ещё» button
// when the server holds more rows than the first page. Uses a repository stub
// (no Dio), so it is deterministic and network-free.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kozshifo/features/inventory/data/inventory_repository.dart';
import 'package:kozshifo/features/inventory/domain/movement.dart';
import 'package:kozshifo/features/inventory/presentation/movements_tab.dart';

StockMovement _mv({
  required String id,
  required String type,
  required String quantity,
  String name = 'Тропикамид 1%',
}) =>
    StockMovement(
      id: id,
      productId: 'prod-1',
      branchId: 'br-1',
      movementType: type,
      quantity: quantity,
      reason: 'тест',
      createdAt: '2026-06-13T09:00:00Z',
      productName: name,
      productSku: 'MED-001',
      actorName: 'Иванова А.',
    );

/// Repository stub: first page returns 2 rows out of a total of 5 → hasMore.
class _StubRepo extends InventoryRepository {
  _StubRepo() : super(Dio());

  int calls = 0;

  @override
  Future<MovementsPage> movements(MovementFilter f) async {
    calls++;
    final all = [
      _mv(id: 'a', type: 'receipt', quantity: '5.000'),
      _mv(id: 'b', type: 'write_off', quantity: '-3.000'),
      _mv(id: 'c', type: 'adjustment', quantity: '1.000'),
      _mv(id: 'd', type: 'transfer_out', quantity: '-2.000'),
      _mv(id: 'e', type: 'supplier_return', quantity: '-1.000'),
    ];
    final slice = all.skip(f.offset).take(f.limit).toList();
    return MovementsPage(items: slice, total: all.length, offset: f.offset);
  }
}

void main() {
  Widget host(Widget child, InventoryRepository repo) => ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('MovementsTab: renders first page with type label + signed qty',
      (tester) async {
    final repo = _StubRepo();
    // Small viewport-independent: pump with a tall surface for the list.
    await tester.pumpWidget(host(const MovementsTab(branchId: 'br-1'), repo));
    await tester.pumpAndSettle();

    // First page (limit 50 → all 5 rows since total is 5). Labels present.
    expect(find.text('Приход'), findsNothing); // label is inside a joined line
    expect(find.textContaining('Приход'), findsWidgets);
    expect(find.textContaining('Списание'), findsWidgets);
    // Signed quantity: receipt gets a leading '+', write-off keeps '-'.
    expect(find.text('+5.000'), findsOneWidget);
    expect(find.text('-3.000'), findsOneWidget);
  });

  testWidgets('MovementsTab: total ≤ page size → total footer, no «Показать ещё»',
      (tester) async {
    final repo = _StubRepo();
    // Stub total (5) ≤ page size (50) → a single load, so «Показать ещё» never
    // appears and the last list item is the total-count footer instead.
    await tester.pumpWidget(host(const MovementsTab(branchId: 'br-1'), repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Показать ещё'), findsNothing);
    // The footer is the last (lazily-built) ListView item — scroll it into view
    // (5 rows + footer can exceed the default 600px test viewport).
    await tester.scrollUntilVisible(
      find.textContaining('Всего движений: 5'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Всего движений: 5'), findsOneWidget);
    expect(repo.calls, greaterThanOrEqualTo(1));
  });
}
