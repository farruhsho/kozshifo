import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/movement.dart';
import '../domain/product.dart';
import '../domain/stock.dart';

/// A reorder suggestion row (mirrors backend `ReorderSuggestionOut`): an active
/// product at/below min_stock plus a suggested restock quantity. Decimal fields
/// are kept as strings — the server owns the decimal math.
class ReorderSuggestion {
  const ReorderSuggestion({
    required this.product,
    required this.onHand,
    required this.minStock,
    required this.suggestedQty,
  });

  final Product product;
  final String onHand;
  final String minStock;
  final String suggestedQty;

  factory ReorderSuggestion.fromJson(Map<String, dynamic> json) =>
      ReorderSuggestion(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        onHand: json['on_hand'] as String,
        minStock: json['min_stock'] as String,
        suggestedQty: json['suggested_qty'] as String,
      );
}

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
  /// [productType] (medicine | consumable | material | instrument), when set,
  /// restricts the catalog to that class — e.g. a consumables checkbox picker.
  Future<List<Product>> products({String? q, String? productType}) async {
    try {
      // 500 = backend max page size. Searchable pickers are the real fix once
      // the catalog outgrows one page (tracked in AGENTS.md §7 leftovers).
      final resp = await _dio.get('/inventory/products', queryParameters: {
        'q': ?q,
        'product_type': ?productType,
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

  /// Reorder suggestions: active products at/below min_stock in a branch, with
  /// a suggested restock quantity (up to 2× min), most-deficient first. Decimal
  /// quantities arrive as strings — the server owns the decimal math.
  Future<List<ReorderSuggestion>> reorderSuggestions(String branchId) async {
    try {
      final resp = await _dio.get('/inventory/reorder-suggestions',
          queryParameters: {'branch_id': branchId});
      return (resp.data as List<dynamic>)
          .map((e) => ReorderSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Manual stock write-off (FEFO). Decimals pass as strings; the server
  /// consumes batches first-expired-first. With [includeExpired] the FEFO
  /// engine may also consume expired lots (disposal path).
  ///
  /// Throws [ApiException] with statusCode 409 on InsufficientStock — the
  /// caller surfaces `e.message` (the exact server detail) to the user.
  /// Returns the per-batch movements the server recorded (quantity negative).
  Future<List<StockMovement>> writeOff({
    required String productId,
    required String branchId,
    required String quantity,
    required String reason,
    bool includeExpired = false,
  }) async {
    try {
      final resp = await _dio.post('/inventory/write-off', data: {
        'product_id': productId,
        'branch_id': branchId,
        'quantity': quantity,
        'reason': reason,
        'include_expired': includeExpired,
      });
      return (resp.data as List<dynamic>)
          .map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
          .toList();
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

/// Reorder suggestions for a branch (most-deficient first). Keyed by branch id,
/// like [stockProvider]; invalidate after a receipt so the «К заказу» list
/// reflects the new on-hand quantities.
final reorderSuggestionsProvider =
    FutureProvider.autoDispose.family<List<ReorderSuggestion>, String>(
        (ref, branchId) =>
            ref.watch(inventoryRepositoryProvider).reorderSuggestions(branchId));

/// Catalog filtered by a free-text query (name/SKU/barcode), for the searchable
/// write-off picker. Empty/blank query returns the first page of all products.
final productSearchProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, query) {
  final q = query.trim();
  return ref
      .watch(inventoryRepositoryProvider)
      .products(q: q.isEmpty ? null : q);
});
