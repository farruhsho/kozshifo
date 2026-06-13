// Live employee-control roster: AttendanceStatus parsing + the «Сейчас» view
// renders presence and the Face ID integration banner.
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/core/network/page.dart';
import 'package:kozshifo/features/attendance/data/attendance_repository.dart';
import 'package:kozshifo/features/attendance/domain/attendance_event.dart';
import 'package:kozshifo/features/attendance/domain/attendance_report.dart';
import 'package:kozshifo/features/attendance/domain/attendance_status.dart';
import 'package:kozshifo/features/attendance/presentation/attendance_screen.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';

const _statusJson = <String, dynamic>{
  'as_of': '2026-06-13T08:00:00Z',
  'work_day_start': '09:00',
  'integration_enabled': true,
  'total_staff': 2,
  'present_count': 1,
  'left_count': 0,
  'absent_count': 1,
  'late_count': 1,
  'staff': [
    {
      'user_id': 'u-1',
      'full_name': 'Доктор Исмоилов',
      'role': 'Doctor',
      'status': 'present',
      'last_direction': 'in',
      'last_event_at': '2026-06-13T04:10:00Z',
      'first_in': '2026-06-13T04:10:00Z',
      'late': true,
      'worked_minutes': 230,
    },
    {
      'user_id': 'u-2',
      'full_name': 'Кассир Каримов',
      'role': 'Cashier',
      'status': 'absent',
      'last_direction': null,
      'last_event_at': null,
      'first_in': null,
      'late': false,
      'worked_minutes': 0,
    },
  ],
};

void main() {
  test('AttendanceStatus parses roster + counts', () {
    final s = AttendanceStatus.fromJson(_statusJson);
    expect(s.integrationEnabled, isTrue);
    expect(s.presentCount, 1);
    expect(s.absentCount, 1);
    expect(s.staff, hasLength(2));
    expect(s.staff.first.isPresent, isTrue);
    expect(s.staff.first.late, isTrue);
    expect(s.staff.last.isAbsent, isTrue);
  });

  testWidgets('«Сейчас» view shows Face ID banner, roster and counts',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(_FakeRepo()),
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const MaterialApp(home: AttendanceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Сотрудники'), findsOneWidget); // app bar
    expect(find.textContaining('Face ID подключён'), findsOneWidget);
    expect(find.text('На работе: 1'), findsOneWidget);
    expect(find.text('Доктор Исмоилов'), findsOneWidget);
    expect(find.text('Кассир Каримов'), findsOneWidget);
    expect(find.text('на работе'), findsOneWidget);
    expect(find.text('отсутствует'), findsOneWidget);
    expect(find.text('опоздание'), findsOneWidget);
  });

  testWidgets('amber banner when Face ID is not configured', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider
              .overrideWithValue(_FakeRepo(integration: false)),
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const MaterialApp(home: AttendanceScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Face ID не настроен'), findsOneWidget);
  });
}

class _FakeRepo implements AttendanceRepository {
  _FakeRepo({this.integration = true});
  final bool integration;

  @override
  Future<AttendanceStatus> status() async =>
      AttendanceStatus.fromJson({..._statusJson, 'integration_enabled': integration});

  @override
  Future<AttendanceReport> report({required String dateFrom, required String dateTo}) async =>
      AttendanceReport.fromJson({
        'date_from': dateFrom, 'date_to': dateTo,
        'work_day_start': '09:00', 'users': const [],
      });

  @override
  Future<Page<AttendanceEvent>> events({
    required String dateFrom,
    required String dateTo,
    String? userId,
    int offset = 0,
    int limit = 50,
  }) async =>
      Page(items: const [], total: 0, offset: offset, limit: limit);

  @override
  Future<AttendanceEvent> createEvent({
    required String userId,
    required String direction,
    required DateTime occurredAt,
    String? note,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Uint8List> reportCsv({required String dateFrom, required String dateTo}) async =>
      Uint8List(0);
}

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        AuthStatus.authenticated,
        AuthUser(
          id: 'dir',
          email: 'director@kozshifo.uz',
          fullName: 'Директор',
          isSuperuser: true,
          permissions: ['attendance.read', 'attendance.manage'],
        ),
      );
}
