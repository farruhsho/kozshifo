import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  /// OAuth2 password grant — the backend expects form-urlencoded username/password.
  Future<void> login(String email, String password) async {
    try {
      final resp = await _dio.post(
        '/auth/login',
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      await _storage.write(resp.data['access_token'] as String);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<AuthUser> currentUser() async {
    try {
      final resp = await _dio.get('/auth/me');
      return AuthUser.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> logout() => _storage.clear();
}
