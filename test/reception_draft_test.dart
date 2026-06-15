// Reception draft autosave: save → read round-trips, clear removes, corrupt → null.
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/reception/data/reception_draft_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save → read round-trips the draft; clear removes it', () async {
    final store = ReceptionDraftStore();
    expect(await store.read(), isNull);

    final draft = {
      'patientId': 'p1',
      'items': [
        {'serviceId': 's1', 'qty': 2},
        {'serviceId': 's2', 'qty': 1},
      ],
    };
    await store.save(draft);

    final got = await store.read();
    expect(got, isNotNull);
    expect(got!['patientId'], 'p1');
    expect((got['items'] as List), hasLength(2));
    expect((got['items'] as List).first['qty'], 2);

    await store.clear();
    expect(await store.read(), isNull);
  });

  test('corrupt payload reads back as null (treated as absent)', () async {
    SharedPreferences.setMockInitialValues({'reception_draft': 'not-json{'});
    expect(await ReceptionDraftStore().read(), isNull);
  });
}
