import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_shell.dart';
import '../features/access_control/presentation/access_control_screen.dart';
import '../features/admin/presentation/admin_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_user.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/calls/presentation/call_devices_screen.dart';
import '../features/calls/presentation/calls_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/devices/presentation/devices_screen.dart';
import '../features/doctor/presentation/patient_card_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/lab/presentation/lab_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/operations/presentation/operations_screen.dart';
import '../features/patients/presentation/patient_visits_screen.dart';
import '../features/patients/presentation/patients_screen.dart';
import '../features/queue/presentation/queue_screen.dart';
import '../features/reception/presentation/reception_screen.dart';
import '../features/scheduling/presentation/scheduling_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/worklist/presentation/worklist_screen.dart';

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
          GoRoute(path: '/worklist', builder: (_, _) => const WorklistScreen()),
          GoRoute(
            path: '/scheduling',
            builder: (_, _) => const SchedulingScreen(),
          ),
          GoRoute(path: '/queue', builder: (_, _) => const QueueScreen()),
          // Личное рабочее место очереди: одна дорожка (врач «Мой приём» /
          // диагност «Диагностика»), кабинет из профиля. Дорожка выводится из
          // прав внутри экрана (exams.write → врач, иначе диагност).
          GoRoute(
            path: '/my-queue',
            builder: (_, _) => const QueueScreen(personal: true),
          ),
          GoRoute(
            path: '/operations',
            builder: (_, _) => const OperationsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, _) => const AnalyticsScreen(),
          ),
          GoRoute(path: '/lab', builder: (_, _) => const LabScreen()),
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
          GoRoute(path: '/finance', builder: (_, _) => const FinanceScreen()),
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
