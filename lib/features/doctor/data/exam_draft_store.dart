import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final examDraftStoreProvider = Provider<ExamDraftStore>(
  (ref) => ExamDraftStore(),
);

/// Локальный автосейв НЕсохранённой формы осмотра (Form 025-8) — по визиту.
///
/// Чистый Dart поверх `shared_preferences` (как [TokenStorage]): переживает
/// перезапуск приложения / случайное закрытие карты и юнит-тестируется через
/// `SharedPreferences.setMockInitialValues`. Источник истины — сервер: черновик
/// удаляется при успешном сохранении осмотра.
class ExamDraftStore {
  static String _key(String visitId) => 'exam_draft_$visitId';

  Future<void> saveDraft(String visitId, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(visitId), jsonEncode(payload));
  }

  /// Черновик формы или `null`, если его нет (или запись повреждена).
  Future<Map<String, dynamic>?> readDraft(String visitId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(visitId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null; // повреждённый черновик равносилен отсутствующему
    }
  }

  Future<void> clearDraft(String visitId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(visitId));
  }
}
