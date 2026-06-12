// ExamDraftStore: автосейв черновика осмотра поверх shared_preferences —
// round-trip карты payload, очистка, отсутствующий визит, изоляция по визитам.
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/doctor/data/exam_draft_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExamDraftStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = ExamDraftStore();
  });

  group('ExamDraftStore', () {
    test('save → read round-trips the payload map', () async {
      final payload = <String, dynamic>{
        'complaints': 'Снижение зрения вдаль',
        'diagnosis': 'Миопия слабой степени OU',
        'od_axis': 170, // int survives jsonEncode/jsonDecode
        'os_axis': null, // null survives too
        'recommendations': 'очковая коррекция',
      };

      await store.saveDraft('v1', payload);
      final read = await store.readDraft('v1');

      expect(read, payload);
    });

    test('clearDraft removes the draft', () async {
      await store.saveDraft('v1', {'diagnosis': 'Катаракта'});

      await store.clearDraft('v1');

      expect(await store.readDraft('v1'), isNull);
    });

    test('readDraft of unknown visit returns null', () async {
      expect(await store.readDraft('no-such-visit'), isNull);
    });

    test('drafts are isolated per visit', () async {
      await store.saveDraft('v1', {'diagnosis': 'Миопия'});
      await store.saveDraft('v2', {'diagnosis': 'Глаукома'});

      expect((await store.readDraft('v1'))!['diagnosis'], 'Миопия');
      expect((await store.readDraft('v2'))!['diagnosis'], 'Глаукома');

      await store.clearDraft('v1');
      expect(await store.readDraft('v1'), isNull);
      expect((await store.readDraft('v2'))!['diagnosis'], 'Глаукома');
    });
  });
}
