// Attendance (учёт рабочего времени, Face ID): snake_case parsing of the
// timesheet report, the «Xч Yм» minutes label, and a widget smoke test of
// AttendanceScreen with the repository and auth state overridden — no network.
import 'package:dio/dio.dart';
// Material тоже экспортирует `Page` (Navigator) — прячем, нам нужен
// пагинационный конверт из core/network/page.dart.
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/core/network/page.dart';
import 'package:kozshifo/features/attendance/data/attendance_repository.dart';
import 'package:kozshifo/features/attendance/domain/attendance_event.dart';
import 'package:kozshifo/features/attendance/domain/attendance_report.dart';
import 'package:kozshifo/features/attendance/presentation/attendance_screen.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';

const _reportJson = <String, dynamic>{
  'date_from': '2026-06-08',
  'date_to': '2026-06-12',
  'work_day_start': '09:00',
  'users': [
    {
      'user_id': 'u-1',
      'full_name': 'Иванова Дилноза',
      'days': [
        {
          'day': '2026-06-08',
          'first_in': '2026-06-08T04:35:00Z',
          'last_out': '2026-06-08T13:00:00Z',
          'worked_minutes': 505,
          'late': true,
        },
        {
          'day': '2026-06-09',
          'first_in': '2026-06-09T03:55:00Z',
          'last_out': null, // день ещё открыт — уход не отмечен
          'worked_minutes': 0,
          'late': false,
        },
      ],
      'days_present': 2,
      'days_absent': 1,
      'total_minutes': 505,
      'late_count': 1,
    },
  ],
};

const _eventJson = <String, dynamic>{
  'id': 'e-1',
  'user_id': 'u-1',
  'user_full_name': 'Иванова Дилноза',
  'branch_id': 'br-1',
  'direction': 'in',
  'occurred_at': '2026-06-08T04:35:00Z',
  'source': 'faceid',
  'note': null,
  'recorded_by_id': null,
  'created_at': '2026-06-08T04:35:01Z',
};

void main() {
  group('AttendanceReport parsing', () {
    test('parses the full snake_case timesheet payload', () {
      final r = AttendanceReport.fromJson(_reportJson);
      expect(r.dateFrom, '2026-06-08');
      expect(r.dateTo, '2026-06-12');
      expect(r.workDayStart, '09:00');

      final u = r.users.single;
      expect(u.fullName, 'Иванова Дилноза');
      expect(u.daysPresent, 2);
      expect(u.daysAbsent, 1);
      expect(u.totalMinutes, 505);
      expect(u.lateCount, 1);

      expect(u.days, hasLength(2));
      expect(u.days.first.firstIn, '2026-06-08T04:35:00Z');
      expect(u.days.first.workedMinutes, 505);
      expect(u.days.first.late, isTrue);
      // Trailing open "in": no last_out, zero worked minutes, not late.
      expect(u.days.last.lastOut, isNull);
      expect(u.days.last.workedMinutes, 0);
      expect(u.days.last.late, isFalse);
    });

    test('users default to an empty list when omitted', () {
      final r = AttendanceReport.fromJson(const {
        'date_from': '2026-06-12',
        'date_to': '2026-06-12',
        'work_day_start': '09:00',
      });
      expect(r.users, isEmpty);
    });

    test('AttendanceEvent parses snake_case and isIn helper works', () {
      final e = AttendanceEvent.fromJson(_eventJson);
      expect(e.userFullName, 'Иванова Дилноза');
      expect(e.direction, 'in');
      expect(e.isIn, isTrue);
      expect(e.source, 'faceid');
      expect(e.note, isNull);
      expect(AttendanceEvent.fromJson(e.toJson()), e);
    });

    test('events page envelope parses through Page.fromJson', () {
      final page = Page.fromJson(const {
        'items': [_eventJson],
        'total': 1,
        'offset': 0,
        'limit': 50,
      }, AttendanceEvent.fromJson);
      expect(page.total, 1);
      expect(page.items.single.id, 'e-1');
    });
  });

  group('formatMinutes', () {
    test('renders «Xч Yм» from worked minutes', () {
      expect(formatMinutes(505), '8ч 25м');
      expect(formatMinutes(60), '1ч 0м');
      expect(formatMinutes(59), '0ч 59м');
      expect(formatMinutes(0), '0ч 0м');
    });
  });

  group('AttendanceScreen', () {
    Widget app() => ProviderScope(
          overrides: [
            attendanceRepositoryProvider
                .overrideWithValue(_FakeAttendanceRepository()),
            authControllerProvider.overrideWith(_FakeAuthController.new),
          ],
          child: const MaterialApp(home: AttendanceScreen()),
        );

    testWidgets('renders the timesheet with totals, absences and lateness',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pump(); // loading frame
      await tester.pump(); // report future resolved

      expect(find.text('Учёт времени'), findsOneWidget);
      expect(find.text('Иванова Дилноза'), findsOneWidget);
      expect(find.text('Итого: 8ч 25м'), findsOneWidget);
      expect(find.text('Пропусков: 1'), findsOneWidget);
      expect(find.text('Опозданий: 1'), findsOneWidget);
      expect(find.textContaining('Начало дня: 09:00'), findsOneWidget);
      // attendance.manage (superuser) — ручная отметка доступна.
      expect(find.widgetWithText(FloatingActionButton, 'Отметить вручную'),
          findsOneWidget);

      // Разворачиваем сотрудника — видна таблица дней и бейдж опоздания.
      await tester.tap(find.text('Иванова Дилноза'));
      await tester.pumpAndSettle();
      expect(find.text('опоздание'), findsOneWidget);
      expect(find.text('8ч 25м'), findsOneWidget); // day row, exact cell text
      expect(find.text('Приход'), findsOneWidget);
      expect(find.text('Уход'), findsOneWidget);
    });

    testWidgets('«Журнал» toggle switches to the raw event log',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Журнал'));
      await tester.pump(); // toggle rebuild + initState load
      await tester.pump(); // events future resolved

      expect(find.text('приход'), findsOneWidget);
      expect(find.text('Face ID'), findsOneWidget);
      expect(find.text('Иванова Дилноза'), findsOneWidget);
    });
  });
}

/// Canned-data repository: no Dio calls ever leave the fake.
class _FakeAttendanceRepository extends AttendanceRepository {
  _FakeAttendanceRepository() : super(Dio());

  @override
  Future<AttendanceReport> report({
    required String dateFrom,
    required String dateTo,
  }) async =>
      AttendanceReport.fromJson(_reportJson);

  @override
  Future<Page<AttendanceEvent>> events({
    required String dateFrom,
    required String dateTo,
    String? userId,
    int offset = 0,
    int limit = 50,
  }) async =>
      Page(
        items: [AttendanceEvent.fromJson(_eventJson)],
        total: 1,
        offset: offset,
        limit: limit,
      );
}

/// Already-authenticated owner; skips the real restore/network in build().
class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        AuthStatus.authenticated,
        AuthUser(
          id: 'u-0',
          email: 'owner@kozshifo.uz',
          fullName: 'Владелец',
          isSuperuser: true,
        ),
      );
}
