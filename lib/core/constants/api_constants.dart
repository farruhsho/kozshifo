import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// The port the FastAPI backend listens on (uvicorn --port 8000, Compose, the
  /// .claude launch config — all 8000). The web client talks to this port.
  static const int backendPort = 8000;

  /// Backend base URL, resolved in priority order:
  /// 1. `--dart-define=API_BASE_URL=...` — explicit override wins on any platform.
  /// 2. On **web** with no override:
  ///    - served BY the backend (origin port 8000) or behind a normal web port
  ///      (80/443/none) → talk to the SAME origin (`localhost`, a LAN IP like
  ///      http://10.34.93.194:8000, or a hostname) — no rebuild when the IP changes;
  ///    - served by a dev server (`flutter run -d chrome` lands on some random
  ///      port that has NO /api) → talk to the same host on :8000, so dev
  ///      "just works" against a local backend (dev CORS allows any localhost).
  /// 3. Desktop/mobile dev fallback: http://127.0.0.1:8000
  ///    (Android emulator: pass `--dart-define=API_BASE_URL=http://10.0.2.2:8000`).
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) {
      final base = Uri.base;
      // port == 0 means the scheme's default (80 for http, 443 for https).
      const sameOriginPorts = {0, 80, 443, backendPort};
      if (sameOriginPorts.contains(base.port)) return base.origin;
      return '${base.scheme}://${base.host}:$backendPort';
    }
    return 'http://127.0.0.1:$backendPort';
  }

  static const String apiPrefix = '/api/v1';

  static String get apiBase => '$baseUrl$apiPrefix';
}
