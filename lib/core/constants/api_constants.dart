class ApiConstants {
  ApiConstants._();

  /// Backend base URL.
  /// - Web / Windows / macOS / Linux desktop: http://127.0.0.1:8000
  /// - Android emulator: replace with http://10.0.2.2:8000
  /// Override at build time with: --dart-define=API_BASE_URL=https://api.example.com
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');

  static const String apiPrefix = '/api/v1';

  static String get apiBase => '$baseUrl$apiPrefix';
}
