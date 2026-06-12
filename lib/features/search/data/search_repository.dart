import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/search_results.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(dioProvider)),
);

/// Global smart search: one query hits patients, visits and receipts at once.
/// The backend filters sections by the caller's permissions (a section the
/// user may not read comes back as an empty list — never an error).
class SearchRepository {
  SearchRepository(this._dio);

  final Dio _dio;

  Future<SearchResults> search(String q, {int limit = 10}) async {
    try {
      final resp = await _dio.get(
        '/search',
        queryParameters: {'q': q, 'limit': limit},
      );
      return SearchResults.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
