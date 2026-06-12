// Calls journal (IP-телефония): Page<CallRecord> parsing — snake_case,
// null patient — plus a CallsScreen smoke test with a fake repository.
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/core/network/page.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/calls/data/calls_repository.dart';
import 'package:kozshifo/features/calls/domain/call_record.dart';
import 'package:kozshifo/features/calls/presentation/calls_screen.dart';

const _pageJson = <String, dynamic>{
  'items': [
    {
      'id': 'c-1',
      'direction': 'in',
      'phone': '+998901234567',
      'started_at': '2026-06-12T10:15:00',
      'duration_seconds': 205,
      'recording_url': 'https://pbx.kozshifo.uz/rec/c-1.mp3',
      'note': 'Перезвонить после 18:00',
      'patient': {
        'id': 'p-1',
        'last_name': 'Иванова',
        'first_name': 'Дилноза',
      },
    },
    {
      'id': 'c-2',
      'direction': 'out',
      'phone': '+998711112233',
      'started_at': '2026-06-12T09:05:00',
      'duration_seconds': 40,
      'recording_url': null,
      'note': null,
      'patient': null,
    },
  ],
  'total': 2,
  'offset': 0,
  'limit': 50,
};

void main() {
  group('CallRecord parsing', () {
    test('Page<CallRecord> parses both rows, incl. null patient', () {
      final page = Page.fromJson(_pageJson, CallRecord.fromJson);
      expect(page.total, 2);
      expect(page.items, hasLength(2));

      final withPatient = page.items.first;
      expect(withPatient.isIncoming, isTrue);
      expect(withPatient.phone, '+998901234567');
      expect(withPatient.durationLabel, '3:25');
      expect(withPatient.patient?.fullName, 'Иванова Дилноза');
      expect(withPatient.recordingUrl, isNotNull);
      expect(withPatient.note, 'Перезвонить после 18:00');

      final unknown = page.items.last;
      expect(unknown.isIncoming, isFalse);
      expect(unknown.patient, isNull);
      expect(unknown.recordingUrl, isNull);
      expect(unknown.note, isNull);
      expect(unknown.durationLabel, '0:40');
    });

    test('duration_seconds defaults to 0 when omitted', () {
      final c = CallRecord.fromJson(const {
        'id': 'c-3',
        'direction': 'in',
        'phone': '+998900000000',
        'started_at': '2026-06-12T08:00:00',
      });
      expect(c.durationSeconds, 0);
      expect(c.durationLabel, '0:00');
      expect(c.patient, isNull);
    });
  });

  group('CallsScreen', () {
    Widget app(CallsRepository repo) => ProviderScope(
          overrides: [
            callsRepositoryProvider.overrideWithValue(repo),
            authControllerProvider.overrideWith(_FakeAuthController.new),
          ],
          child: const MaterialApp(home: CallsScreen()),
        );

    testWidgets('renders rows: patient chip and unknown number', (tester) async {
      await tester.pumpWidget(app(_FakeCallsRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Звонки'), findsOneWidget);
      expect(find.text('Всего: 2'), findsOneWidget);
      expect(find.text('+998901234567'), findsOneWidget);
      // Чип пациента — ФИО, кликабельный (ActionChip).
      expect(
        find.widgetWithText(ActionChip, 'Иванова Дилноза'),
        findsOneWidget,
      );
      expect(find.text('Неизвестный номер'), findsOneWidget);
      expect(find.byIcon(Icons.call_received), findsOneWidget); // входящий
      expect(find.byIcon(Icons.call_made), findsOneWidget); // исходящий
      // Все 2 из 2 загружены — кнопки пагинации нет.
      expect(find.textContaining('Показать ещё'), findsNothing);
    });

    testWidgets('empty journal shows «Звонков нет»', (tester) async {
      await tester.pumpWidget(app(_FakeCallsRepository(empty: true)));
      await tester.pumpAndSettle();

      expect(find.text('Звонков нет'), findsOneWidget);
    });
  });
}

/// Фейковый репозиторий: отдаёт фиксированную страницу без сети.
class _FakeCallsRepository implements CallsRepository {
  _FakeCallsRepository({this.empty = false});

  final bool empty;

  @override
  Future<Page<CallRecord>> list({
    String? q,
    DateTime? dateFrom,
    DateTime? dateTo,
    int offset = 0,
    int limit = 50,
  }) async {
    if (empty) {
      return Page(items: const [], total: 0, offset: 0, limit: limit);
    }
    return Page.fromJson(_pageJson, CallRecord.fromJson);
  }
}

/// Авторизованный пользователь с правом calls.read — без сети и restore.
class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        AuthStatus.authenticated,
        AuthUser(
          id: 'u-1',
          email: 'reception@kozshifo.uz',
          fullName: 'Ресепшен Тест',
          permissions: ['calls.read'],
        ),
      );
}
