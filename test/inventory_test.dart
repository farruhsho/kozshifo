// Inventory models: snake_case parsing, decimal strings stay String.
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/inventory/domain/product.dart';
import 'package:kozshifo/features/inventory/domain/stock.dart';

void main() {
  const productJson = <String, dynamic>{
    'id': 'prod-1',
    'sku': 'MED-001',
    'name': 'Тропикамид 1%',
    'unit': 'фл',
    'product_type': 'medicine',
    'barcode': '4780000000001',
    'min_stock': '5.000',
    'category_id': 'cat-1',
    'is_active': true,
    'description': 'Капли для расширения зрачка',
  };

  test('Product parses snake_case (min_stock → minStock, stays String)', () {
    final p = Product.fromJson(productJson);
    expect(p.sku, 'MED-001');
    expect(p.productType, 'medicine');
    expect(p.minStock, '5.000');
    expect(p.minStock, isA<String>());
    expect(p.categoryId, 'cat-1');
    expect(p.isActive, isTrue);
    expect(Product.fromJson(p.toJson()), p);
  });

  test('Product is_active defaults to true when omitted', () {
    final p = Product.fromJson({...productJson}..remove('is_active'));
    expect(p.isActive, isTrue);
  });

  const stockRowJson = <String, dynamic>{
    'product': productJson,
    'on_hand': '12.000',
    'low_stock': false,
    'batches': [
      {
        'id': 'batch-1',
        'batch_no': 'B-1',
        'expiry_date': '2027-01-01',
        'quantity': '10.000',
        'unit_cost': '150000.00',
        'received_at': '2026-06-12T09:00:00Z',
      },
      {
        'id': 'batch-2',
        'batch_no': null,
        'expiry_date': null,
        'quantity': '2.000',
        'unit_cost': '140000.00',
        'received_at': '2026-06-01T09:00:00Z',
      },
    ],
  };

  test('StockRow round-trips nested product + batches, quantities stay String',
      () {
    final row = StockRow.fromJson(stockRowJson);
    expect(row.product.name, 'Тропикамид 1%');
    expect(row.onHand, '12.000');
    expect(row.onHand, isA<String>());
    expect(row.lowStock, isFalse);
    expect(row.batches, hasLength(2));
    expect(row.batches.first.batchNo, 'B-1');
    expect(row.batches.first.expiryDate, '2027-01-01');
    expect(row.batches.first.quantity, '10.000');
    expect(row.batches.first.unitCost, '150000.00');
    expect(row.batches.last.batchNo, isNull);
    expect(row.batches.last.expiryDate, isNull);
    expect(StockRow.fromJson(row.toJson()), row);
  });

  test('StockRow low_stock flag parses; missing batches default to empty', () {
    final low = StockRow.fromJson(const {
      'product': productJson,
      'on_hand': '1.000',
      'low_stock': true,
    });
    expect(low.lowStock, isTrue);
    expect(low.batches, isEmpty);
  });
}
