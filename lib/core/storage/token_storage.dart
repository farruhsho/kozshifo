import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Persists the JWT access token.
///
/// NOTE: `shared_preferences` is used here for a zero-friction cross-platform
/// foundation. Hardening step (Phase 1): move the token to platform secure
/// storage / Keychain / Keystore before production.
class TokenStorage {
  static const _key = 'access_token';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
