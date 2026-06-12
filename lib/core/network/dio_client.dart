import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'session_events.dart';

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

        final outcome = await refresher.refresh();
        switch (outcome.status) {
          case _RefreshStatus.denied:
            // The server definitively rejected the refresh token — the
            // session is over. Wipe it and tell the auth layer.
            await storage.clear();
            ref.read(sessionExpiredTickProvider.notifier).state++;
            return handler.next(error);
          case _RefreshStatus.unavailable:
            // Transient failure (network/5xx): the 30-day refresh token is
            // still valid — keep it and just surface the original error.
            return handler.next(error);
          case _RefreshStatus.success:
            try {
              options.extra[_kRetriedFlag] = true;
              options.headers['Authorization'] = 'Bearer ${outcome.accessToken}';
              final response = await dio.fetch<dynamic>(options);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
        }
      },
    ),
  );

  return dio;
});

enum _RefreshStatus {
  /// New pair obtained — retry the original request.
  success,

  /// The server rejected the refresh token (4xx) or none is stored:
  /// the session is over, tokens must be cleared.
  denied,

  /// Transient problem (network, timeout, 5xx) — keep the tokens.
  unavailable,
}

class _RefreshOutcome {
  const _RefreshOutcome(this.status, [this.accessToken]);

  final _RefreshStatus status;
  final String? accessToken;
}

/// Exchanges the stored refresh token for a new access+refresh pair.
///
/// Uses a bare Dio instance (no interceptors -> no recursion) and serializes
/// concurrent refreshes: parallel 401s all await the same in-flight Future,
/// so the rotated refresh token is consumed exactly once.
class _TokenRefresher {
  _TokenRefresher(this._storage);

  final TokenStorage _storage;
  Future<_RefreshOutcome>? _inFlight;

  Future<_RefreshOutcome> refresh() {
    return _inFlight ??=
        _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<_RefreshOutcome> _doRefresh() async {
    final refreshToken = await _storage.readRefresh();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const _RefreshOutcome(_RefreshStatus.denied);
    }

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
      return _RefreshOutcome(_RefreshStatus.success, access);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Only a definitive server verdict kills the session; a flaky network
      // or a 5xx must never destroy a still-valid 30-day refresh token.
      if (status != null && status >= 400 && status < 500) {
        return const _RefreshOutcome(_RefreshStatus.denied);
      }
      return const _RefreshOutcome(_RefreshStatus.unavailable);
    }
  }
}
