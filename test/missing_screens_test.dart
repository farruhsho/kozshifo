// Render smoke tests for the prototype screens added to the shell:
// Analytics, Notifications. Each mounts the real screen
// with its data providers overridden (no network) + a fake authenticated user,
// then asserts a key element renders and that no exception was thrown (catches
// overflow / null-deref / provider-misuse the analyzer cannot see).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/analytics/data/analytics_repository.dart';
import 'package:kozshifo/features/analytics/domain/top_service.dart';
import 'package:kozshifo/features/analytics/presentation/analytics_screen.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/dashboard/data/dashboard_repository.dart';
import 'package:kozshifo/features/dashboard/domain/dashboard_summary.dart';
import 'package:kozshifo/features/dashboard/domain/insight.dart';
import 'package:kozshifo/features/dashboard/domain/lead_source.dart';
import 'package:kozshifo/features/notifications/data/notifications_repository.dart';
import 'package:kozshifo/features/notifications/presentation/notifications_screen.dart';

const _user = AuthUser(
  id: 'u-doc',
  email: 'doc@kozshifo.uz',
  fullName: 'Доктор Тест',
  branchId: 'b1',
  permissions: [
    'dashboard.view', 'exams.write',
    // queue.manage: the doctor calls the next patient / finishes the V-ticket
    // from the queue-driven Приём worklist (TZ §3.3/§7.1.6).
    'queue.read', 'queue.manage',
  ],
);

Widget _host(Widget screen, List<Override> overrides) => ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => _FakeAuth(_user)), ...overrides],
      child: MaterialApp(home: screen),
    );

/// Mount at a realistic desktop content width. These dense screens are
/// desktop-targeted (the live shell always pairs them with a 248px sidebar on a
/// wide window); the default 800×600 test surface is narrower than any real use.
void _desktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Analytics renders KPIs, top services and lead sources', (tester) async {
    _desktop(tester);
    await tester.pumpWidget(_host(const AnalyticsScreen(), [
      dashboardSummaryProvider.overrideWith((ref) async => const DashboardSummary(
            revenueToday: '0', revenueMonth: '184500000', paymentsToday: 0,
            averageCheckToday: '186000', visitsToday: 52, newPatientsToday: 7,
            patientsTotal: 12457, queueWaiting: 0, operationsMonth: 9,
          )),
      topServicesProvider.overrideWith((ref) async => const [
            TopService(service: 'Первичная консультация', revenue: '46800000', count: 312),
            TopService(service: 'ОКТ сетчатки', revenue: '32560000', count: 148),
          ]),
      leadSourcesProvider.overrideWith((ref) async => const LeadSourceReport(total: 30, sources: [
            LeadSourceStat(source: 'instagram', label: 'Instagram', count: 18),
            LeadSourceStat(source: 'referral', label: 'Рекомендация', count: 12),
          ])),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Аналитика'), findsOneWidget);
    expect(find.text('Топ услуг по выручке'), findsOneWidget);
    expect(find.text('Первичная консультация'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notifications renders the live, self-resolving problem set',
      (tester) async {
    _desktop(tester);
    await tester.pumpWidget(_host(const NotificationsScreen(), [
      activeProblemsProvider.overrideWith((ref) async => const [
            Insight(
              code: 'low_stock', severity: 'critical',
              title: 'Дефицит на складе',
              detail: 'Под минимумом: ИОЛ AcrySof IQ', value: '3',
            ),
          ]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Уведомления'), findsOneWidget);
    expect(find.text('Дефицит на складе'), findsOneWidget);
    expect(find.textContaining('Под минимумом'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notifications shows the good state when nothing is wrong',
      (tester) async {
    _desktop(tester);
    await tester.pumpWidget(_host(const NotificationsScreen(), [
      activeProblemsProvider.overrideWith((ref) async => const <Insight>[]),
    ]));
    await tester.pumpAndSettle();

    expect(find.textContaining('Всё в порядке'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._u);
  final AuthUser _u;

  @override
  AuthState build() => AuthState(AuthStatus.authenticated, _u);
}
