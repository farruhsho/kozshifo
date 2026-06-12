import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/product.dart';
import '../domain/stock.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
    (ref) => InventoryRepository(ref.watch(dioProvider)));

class InventoryRepository {
  InventoryRepository(this._dio);

  final Dio _dio;

  /// Stock positions of a branch (optionally only low-stock ones).
  Future<List<StockRow>> stock(
      {required String branchId, bool lowOnly = false}) async {
    try {
      final resp = await _dio.get('/inventory/stock', queryParameters: {
        'branch_id': branchId,
        'low_only': lowOnly,
      });
      return (resp.data as List<dynamic>)
          .map((e) => StockRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Product catalog (Page envelope; we only need the items for dropdowns).
  Future<List<Product>> products({String? q}) async {
    try {
      // 500 = backend max page size. Searchable pickers are the real fix once
      // the catalog outgrows one page (tracked in AGENTS.md §7 leftovers).
      final resp = await _dio.get('/inventory/products', queryParameters: {
        'q': ?q,
        'offset': 0,
        'limit': 500,
      });
      return Page.fromJson(resp.data as Map<String, dynamic>, Product.fromJson)
          .items;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Goods receipt: creates batches and increases stock. Decimals are passed
  /// as strings — the server parses them as exact Decimal.
  Future<void> createReceipt({
    required String branchId,
    required List<
            ({
              String productId,
              String quantity,
              String unitCost,
              String? batchNo,
              String? expiryDate,
            })>
        items,
  }) async {
    try {
      await _dio.post('/inventory/receipts', data: {
        'branch_id': branchId,
        'supplier_id': null,
        'items': [
          for (final it in items)
            {
              'product_id': it.productId,
              'quantity': it.quantity,
              'unit_cost': it.unitCost,
              'batch_no': ?it.batchNo,
              'expiry_date': ?it.expiryDate,
            },
        ],
      });
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final stockProvider = FutureProvider.autoDispose.family<List<StockRow>, String>(
    (ref, branchId) =>
        ref.watch(inventoryRepositoryProvider).stock(branchId: branchId));

final productsProvider = FutureProvider.autoDispose<List<Product>>(
    (ref) => ref.watch(inventoryRepositoryProvider).products());
