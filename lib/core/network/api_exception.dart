import 'package:dio/dio.dart';

/// A user-presentable error mapped from a transport/HTTP failure.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  /// Map a DioException into a friendly message, preferring the backend's
  /// `{"detail": "..."}` payload when present.
  factory ApiException.from(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        // Pydantic 422 sends a list of {loc, msg, ...} dicts — show just the
        // human messages, not the raw structure dump.
        if (detail is List) {
          final msgs = detail
              .map((e) => e is Map ? (e['msg'] ?? e).toString() : e.toString())
              .join('; ');
          return ApiException('Некорректные данные: $msgs', statusCode: status);
        }
        return ApiException(detail.toString(), statusCode: status);
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return ApiException('Сервер не отвечает. Попробуйте позже.', statusCode: status);
        case DioExceptionType.connectionError:
          return ApiException('Нет связи с сервером. Проверьте, запущен ли backend.', statusCode: status);
        default:
          return ApiException('Ошибка запроса (${status ?? 'нет ответа'}).', statusCode: status);
      }
    }
    return ApiException(error.toString());
  }
}
