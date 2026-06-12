import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// Marker on retried requests so a second 401 never triggers another refresh.
const _kRetriedFlag = 'jwt_refresh_retried';

/// App-wide Dio configured with the API base URL, a JWT-injecting interceptor
/// and transparent access-token refresh on 401 (single retry, rotation-aware).
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final refresher = _TokenRefresher(storage);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.apiBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        final path = options.path;
        final isAuthCall =
            path.endsWith('/auth/login') || path.endsWith('/auth/refresh');
        final alreadyRetried = options.extra[_kRetriedFlag] == true;

        if (error.response?.statusCode != 401 || isAuthCall || alreadyRetried) {
          return handler.next(error);
        }

        final newAccess = await refresher.refresh();
        if (newAccess == null) {
          // Refresh failed -> session is over; propagate the original 401.
          await storage.clear();
          return handler.next(error);
        }

        try {
          options.extra[_kRetriedFlag] = true;
          options.headers['Authorization'] = 'Bearer $newAccess';
          final response = await dio.fetch<dynamic>(options);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      },
    ),
  );

  return dio;
});

/// Exchanges the stored refresh token for a new access+refresh pair.
///
/// Uses a bare Dio instance (no interceptors -> no recursion) and serializes
/// concurrent refreshes: parallel 401s all await the same in-flight Future,
/// so the rotated refresh token is consumed exactly once.
class _TokenRefresher {
  _TokenRefresher(this._storage);

  final TokenStorage _storage;
  Future<String?>? _inFlight;

  Future<String?> refresh() {
    return _inFlight ??=
        _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _storage.readRefresh();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final bare = Dio(
        BaseOptions(
          baseUrl: ApiConstants.apiBase,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      );
      final resp = await bare.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = resp.data as Map<String, dynamic>;
      final access = data['access_token'] as String;
      await _storage.write(access);
      final rotated = data['refresh_token'] as String?;
      if (rotated != null && rotated.isNotEmpty) {
        await _storage.writeRefresh(rotated);
      }
      return access;
    } on DioException {
      return null;
    }
  }
}
