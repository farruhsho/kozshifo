// Inventory warehouse slice: repository parsing/request-shape against a mocked
// Dio adapter (no network) + a widget smoke test of the write-off dialog
// (quantity validation + InsufficientStock surfaced inline). Deterministic.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kozshifo/core/network/api_exception.dart';
import 'package:kozshifo/core/widgets/quantity_stepper.dart';
import 'package:kozshifo/features/inventory/data/inventory_repository.dart';
import 'package:kozshifo/features/inventory/domain/movement.dart';
import 'package:kozshifo/features/inventory/domain/product.dart';
import 'package:kozshifo/features/inventory/domain/stock.dart';
import 'package:kozshifo/features/inventory/presentation/write_off_dialog.dart';

// ─── Mocked Dio adapter ───────────────────────────────────────────────────────

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

(InventoryRepository, _FakeAdapter) _repo(
    ResponseBody Function(RequestOptions) handler) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;
  return (InventoryRepository(dio), adapter);
}

// ─── Canned payloads (snake_case, decimals as strings) ────────────────────────

const _productJson = <String, dynamic>{
  'id': 'prod-1',
  'sku': 'MED-001',
  'name': 'Тропикамид 1%',
  'unit': 'фл',
  'product_type': 'medicine',
  'barcode': '4780000000001',
  'min_stock': '5.000',
  'category_id': 'cat-1',
  'is_active': true,
  'description': null,
};

const _movementJson = <String, dynamic>{
  'id': 'mv-1',
  'product_id': 'prod-1',
  'batch_id': 'batch-1',
  'branch_id': 'br-1',
  'movement_type': 'write_off',
  'quantity': '-3.000', // write-offs are negative
  'reason': 'порча',
  'ref_type': 'manual',
  'ref_id': null,
  'created_at': '2026-06-13T09:00:00Z',
};

Map<String, dynamic> _stockRow({required bool low, String onHand = '12.000'}) =>
    {
      'product': _productJson,
      'on_hand': onHand,
      'low_stock': low,
      'batches': [
        {
          'id': 'batch-1',
          'batch_no': 'B-1',
          'expiry_date': '2026-06-20',
          'quantity': '10.000',
          'unit_cost': '150000.00',
          'received_at': '2026-06-01T09:00:00Z',
          'expired': false,
        },
        {
          'id': 'batch-2',
          'batch_no': 'OLD',
          'expiry_date': '2026-06-01',
          'quantity': '2.000',
          'unit_cost': '140000.00',
          'received_at': '2026-05-01T09:00:00Z',
          'expired': true,
        },
      ],
    };

void main() {
  // ─── Repository: write-off ──────────────────────────────────────────────────

  test('writeOff: POST body is snake_case; quantity stays string; parses '
      'negative movement', () async {
    final (repo, adapter) = _repo((_) => _json([_movementJson]));
    final movements = await repo.writeOff(
      productId: 'prod-1',
      branchId: 'br-1',
      quantity: '3.000',
      reason: 'порча',
      includeExpired: true,
    );
    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.uri.path, endsWith('/inventory/write-off'));
    final body = adapter.lastRequest!.data as Map<String, dynamic>;
    expect(body['product_id'], 'prod-1');
    expect(body['branch_id'], 'br-1');
    expect(body['quantity'], '3.000');
    expect(body['reason'], 'порча');
    expect(body['include_expired'], true);

    expect(movements, hasLength(1));
    final m = movements.first;
    expect(m.movementType, 'write_off');
    expect(m.quantity, '-3.000');
    expect(m.quantity, isA<String>());
    expect(m.absQuantity, '3.000');
    expect(m.reason, 'порча');
  });

  test('writeOff: 409 InsufficientStock surfaces server detail as ApiException',
      () async {
    final (repo, _) = _repo((_) => _json(
        {'detail': 'Insufficient stock for Тропикамид 1% (MED-001): '
            'requested 100, available 12'},
        status: 409));
    await expectLater(
      repo.writeOff(
        productId: 'prod-1',
        branchId: 'br-1',
        quantity: '100',
        reason: 'тест',
      ),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 409)
          .having((e) => e.message, 'message', contains('Insufficient stock'))),
    );
  });

  test('writeOff: include_expired defaults to false', () async {
    final (repo, adapter) = _repo((_) => _json([_movementJson]));
    await repo.writeOff(
      productId: 'prod-1',
      branchId: 'br-1',
      quantity: '1',
      reason: 'списание',
    );
    final body = adapter.lastRequest!.data as Map<String, dynamic>;
    expect(body['include_expired'], false);
  });

  // ─── Repository: stock + low-stock ──────────────────────────────────────────

  test('stock: lowOnly=true is sent as low_only query param', () async {
    final (repo, adapter) = _repo((_) => _json([_stockRow(low: true)]));
    final rows = await repo.stock(branchId: 'br-1', lowOnly: true);
    expect(adapter.lastRequest!.uri.path, endsWith('/inventory/stock'));
    expect(adapter.lastRequest!.uri.queryParameters['branch_id'], 'br-1');
    expect(adapter.lastRequest!.uri.queryParameters['low_only'], 'true');
    expect(rows, hasLength(1));
    expect(rows.first.lowStock, isTrue);
    expect(rows.first.onHand, '12.000');
  });

  test('stock: batches parse expired flag; decimals stay String', () async {
    final (repo, _) = _repo((_) => _json([_stockRow(low: false)]));
    final rows = await repo.stock(branchId: 'br-1');
    final batches = rows.first.batches;
    expect(batches, hasLength(2));
    expect(batches.first.expired, isFalse);
    expect(batches.last.expired, isTrue);
    expect(batches.first.quantity, '10.000');
    expect(batches.first.quantity, isA<String>());
    expect(batches.first.expiryDate, '2026-06-20');
  });

  // ─── Repository: supplier return (supplier_id from the batch) ───────────────

  test('supplierReturn: POST body carries supplier_id from the chosen batch',
      () async {
    final (repo, adapter) = _repo((_) => _json({}, status: 200));
    await repo.supplierReturn(
      productId: 'prod-1',
      batchId: 'batch-1',
      quantity: '2',
      reason: 'брак',
      supplierId: 'sup-7',
    );
    expect(adapter.lastRequest!.uri.path, endsWith('/inventory/supplier-returns'));
    final body = adapter.lastRequest!.data as Map<String, dynamic>;
    expect(body['product_id'], 'prod-1');
    expect(body['batch_id'], 'batch-1');
    expect(body['quantity'], '2');
    expect(body['reason'], 'брак');
    // Ключевой фикс бага 5: поставщик уходит в тело → движение с ref_id.
    expect(body['supplier_id'], 'sup-7');
  });

  test('supplierReturn: supplier_id omitted when the batch has none', () async {
    final (repo, adapter) = _repo((_) => _json({}, status: 200));
    await repo.supplierReturn(
      productId: 'prod-1',
      batchId: 'batch-1',
      quantity: '1',
      reason: 'пересорт',
    );
    final body = adapter.lastRequest!.data as Map<String, dynamic>;
    expect(body.containsKey('supplier_id'), isFalse);
  });

  test('StockBatch parses supplier_id → supplierId (null when absent)', () {
    final withSup = StockBatch.fromJson(const {
      'id': 'batch-1',
      'batch_no': 'B-1',
      'expiry_date': '2027-01-01',
      'quantity': '10.000',
      'unit_cost': '150000.00',
      'received_at': '2026-06-12T09:00:00Z',
      'supplier_id': 'sup-7',
    });
    expect(withSup.supplierId, 'sup-7');
    final noSup = StockBatch.fromJson(const {
      'id': 'batch-2',
      'quantity': '1.000',
      'unit_cost': '0.00',
      'received_at': '2026-06-01T09:00:00Z',
    });
    expect(noSup.supplierId, isNull);
  });

  // ─── Domain: expiry helpers (date-only, server-verdict aware) ────────────────

  test('StockBatch expiry helpers compute days + expiringWithin window', () {
    final from = DateTime(2026, 6, 13);
    const soon = StockBatch(
      id: 'b',
      quantity: '1.000',
      unitCost: '0.00',
      receivedAt: '2026-06-01T00:00:00Z',
      expiryDate: '2026-06-20',
    );
    expect(soon.daysUntilExpiry(from), 7);
    expect(soon.expiringWithin(30, from), isTrue);
    expect(soon.expiringWithin(3, from), isFalse);

    const past = StockBatch(
      id: 'b2',
      quantity: '1.000',
      unitCost: '0.00',
      receivedAt: '2026-05-01T00:00:00Z',
      expiryDate: '2026-06-01',
      expired: true,
    );
    expect(past.daysUntilExpiry(from), lessThan(0));
    expect(past.expiringWithin(30, from), isTrue); // already expired ⇒ included

    const noExpiry = StockBatch(
      id: 'b3',
      quantity: '1.000',
      unitCost: '0.00',
      receivedAt: '2026-06-01T00:00:00Z',
    );
    expect(noExpiry.daysUntilExpiry(from), isNull);
    expect(noExpiry.expiringWithin(30, from), isFalse); // no date ⇒ excluded
  });

  // ─── Widget: write-off dialog ───────────────────────────────────────────────

  final product = Product.fromJson(_productJson);

  Widget host(Widget child, {List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('WriteOffDialog: button stays disabled until reason set '
      '(qty defaults to 1 via stepper)', (tester) async {
    await tester.pumpWidget(host(
      WriteOffDialog(branchId: 'br-1', product: product),
    ));
    await tester.pumpAndSettle();

    Finder save() => find.widgetWithText(FilledButton, 'Списать');
    bool enabled() => tester.widget<FilledButton>(save()).onPressed != null;

    // The QuantityStepper seeds quantity at its min (1), so quantity is valid
    // from the start — the only thing still gating the button is the reason.
    expect(find.byType(QuantityStepper), findsOneWidget);
    expect(enabled(), isFalse);

    // Reason filled → enabled (quantity already 1).
    await tester.enterText(
        find.widgetWithText(TextField, 'Причина'), 'порча');
    await tester.pump();
    expect(enabled(), isTrue);
  });

  testWidgets('WriteOffDialog: 409 shows server message inline, dialog stays',
      (tester) async {
    // Override the repository so writeOff throws a 409 ApiException.
    final repo = _ThrowingRepo(ApiException(
        'Insufficient stock for Тропикамид 1% (MED-001): '
        'requested 100, available 12',
        statusCode: 409));
    await tester.pumpWidget(host(
      WriteOffDialog(branchId: 'br-1', product: product),
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(repo),
      ],
    ));
    await tester.pumpAndSettle();

    // Quantity defaults to 1 via the stepper; the stub throws regardless of
    // amount, so we only need a reason to enable submit.
    await tester.enterText(
        find.widgetWithText(TextField, 'Причина'), 'тест');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Списать'));
    await tester.pumpAndSettle();

    // Dialog still open, server detail shown inline.
    expect(find.byType(WriteOffDialog), findsOneWidget);
    expect(find.textContaining('Insufficient stock'), findsOneWidget);
  });
}

/// Repository stub whose writeOff always throws — for the 409 widget test.
class _ThrowingRepo extends InventoryRepository {
  _ThrowingRepo(this._error) : super(Dio());
  final Object _error;

  @override
  Future<List<StockMovement>> writeOff({
    required String productId,
    required String branchId,
    required String quantity,
    required String reason,
    bool includeExpired = false,
  }) async =>
      throw _error;
}
