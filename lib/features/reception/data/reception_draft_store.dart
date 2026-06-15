import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final receptionDraftStoreProvider =
    Provider<ReceptionDraftStore>((ref) => ReceptionDraftStore());

/// Автосейв НЕзавершённого черновика приёма (выбранный пациент + корзина услуг
/// ДО открытия визита). Переживает случайное закрытие/перезагрузку вкладки.
///
/// Чистый Dart поверх `shared_preferences` (как [ExamDraftStore]). После
/// открытия визита истина — на сервере, поэтому черновик чистится. Один черновик
/// на устройство (рабочее место регистратора).
class ReceptionDraftStore {
  static const _key = 'reception_draft';

  Future<void> save(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(payload));
  }

  /// Черновик или `null`, если его нет / запись повреждена.
  Future<Map<String, dynamic>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
