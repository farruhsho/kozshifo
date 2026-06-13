import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Persists the JWT access + refresh tokens.
///
/// The access token is cached in memory after the first read so the Dio
/// request interceptor — which needs it on EVERY call — doesn't pay an async
/// SharedPreferences hop per request (a visible source of UI lag). Writes
/// update both the cache and disk; `clear()` empties both.
///
/// NOTE: `shared_preferences` is used here for a zero-friction cross-platform
/// foundation. Hardening step (Phase 1): move the tokens to platform secure
/// storage / Keychain / Keystore before production.
class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  String? _accessCache;
  bool _accessLoaded = false;

  Future<String?> read() async {
    if (_accessLoaded) return _accessCache;
    final prefs = await SharedPreferences.getInstance();
    _accessCache = prefs.getString(_accessKey);
    _accessLoaded = true;
    return _accessCache;
  }

  Future<void> write(String token) async {
    _accessCache = token;
    _accessLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, token);
  }

  Future<String?> readRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> writeRefresh(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshKey, token);
  }

  Future<void> clear() async {
    _accessCache = null;
    _accessLoaded = true; // empty is a known state — no disk re-read needed
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
