import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_shell.dart';
import '../features/access_control/presentation/access_control_screen.dart';
import '../features/admin/presentation/admin_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/audit/presentation/audit_log_screen.dart';
import '../features/monitoring/presentation/monitoring_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_user.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/calls/presentation/call_devices_screen.dart';
import '../features/calls/presentation/calls_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/debt/presentation/debts_screen.dart';
import '../features/debt/presentation/patient_debt_detail_screen.dart';
import '../features/devices/presentation/devices_screen.dart';
import '../features/doctor/presentation/patient_card_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/operations/presentation/operations_screen.dart';
import '../features/patients/presentation/patient_history_screen.dart';
import '../features/patients/presentation/patient_visits_screen.dart';
import '../features/patients/presentation/patients_screen.dart';
import '../features/queue/presentation/queue_screen.dart';
import '../features/reception/presentation/reception_screen.dart';
import '../features/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/reception',
            builder: (_, _) => const ReceptionScreen(),
          ),
          GoRoute(path: '/queue', builder: (_, _) => const QueueScreen()),
          // Личное рабочее место очереди: одна дорожка (врач «Мой приём» /
          // диагност «Диагностика»), кабинет из профиля. Дорожка выводится из
          // прав внутри экрана (exams.write → врач, иначе диагност).
          GoRoute(
            path: '/my-queue',
            builder: (_, _) => const QueueScreen(personal: true),
          ),
          // Процедурный кабинет: личная дорожка «Лечение» (Л-талоны) —
          // вызвать/принять/завершить курс лечения. Бэкенд-lifecycle уже есть.
          GoRoute(
            path: '/treatment-queue',
            builder: (_, _) =>
                const QueueScreen(personal: true, track: 'treatment'),
          ),
          GoRoute(
            path: '/operations',
            builder: (_, _) => const OperationsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, _) => const AnalyticsScreen(),
          ),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(path: '/patients', builder: (_, _) => const PatientsScreen()),
          GoRoute(
            path: '/patients/:id/card',
            builder: (_, state) =>
                PatientCardScreen(patientId: state.pathParameters['id']!),
          ),
          // Standalone visit history (Ф5). Under the /patients prefix, so the
          // redirect guard inherits the Пациенты destination's patients.read gate.
          GoRoute(
            path: '/patients/:id/visits',
            builder: (_, state) =>
                PatientVisitsScreen(patientId: state.pathParameters['id']!),
          ),
          // Consolidated patient history grouped into 5 sections (Приёмы/
          // Диагностика/Лечение/Операции/Финансы). Under /patients → inherits
          // the patients.read redirect guard.
          GoRoute(
            path: '/patients/:id/history',
            builder: (_, state) =>
                PatientHistoryScreen(patientId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/finance', builder: (_, _) => const FinanceScreen()),
          GoRoute(path: '/debts', builder: (_, _) => const DebtsScreen()),
          // Detail under the /debts prefix → inherits the Долги destination's
          // debts.read redirect guard (same pattern as /patients/:id/*).
          GoRoute(
            path: '/debts/:id',
            builder: (_, state) =>
                PatientDebtDetailScreen(patientId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/attendance',
            builder: (_, _) => const AttendanceScreen(),
          ),
          GoRoute(path: '/calls', builder: (_, _) => const CallsScreen()),
          GoRoute(
              path: '/calls/devices',
              builder: (_, _) => const CallDevicesScreen()),
          GoRoute(path: '/devices', builder: (_, _) => const DevicesScreen()),
          GoRoute(
            path: '/inventory',
            builder: (_, _) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/access-control',
            builder: (_, _) => const AccessControlScreen(),
          ),
          GoRoute(path: '/services', builder: (_, _) => const ServicesScreen()),
          GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
          GoRoute(path: '/audit', builder: (_, _) => const AuditLogScreen()),
          GoRoute(path: '/monitoring', builder: (_, _) => const MonitoringScreen()),
        ],
      ),
    ],
  );
});

/// Role-aware home: the first shell destination this user may see
/// (kAppDestinations order = priority). Falls back to /patients so an
/// account with no nav permissions still lands somewhere harmless.
String homeFor(AuthUser? user) {
  for (final d in kAppDestinations) {
    if (d.allowedFor(user)) return d.route;
  }
  return '/patients';
}

/// Bridges Riverpod auth state into GoRouter: re-evaluates redirects whenever
/// the auth status changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authControllerProvider);
    final loc = state.matchedLocation;

    switch (auth.status) {
      case AuthStatus.unknown:
        return loc == '/splash' ? null : '/splash';
      case AuthStatus.unauthenticated:
        return loc == '/login' ? null : '/login';
      case AuthStatus.authenticated:
        final user = auth.user;
        if (loc == '/login' || loc == '/splash') return homeFor(user);
        // Permission guard: navigating to a screen the user may not see
        // (deep link, stale bookmark) sends them home instead of a 403 page.
        for (final d in kAppDestinations) {
          if (loc == d.route || loc.startsWith('${d.route}/')) {
            return d.allowedFor(user) ? null : homeFor(user);
          }
        }
        return null;
    }
  }
}
