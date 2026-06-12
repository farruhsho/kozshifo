import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_shell.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/devices/presentation/devices_screen.dart';
import '../features/doctor/presentation/patient_card_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
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
          GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/reception', builder: (_, _) => const ReceptionScreen()),
          GoRoute(path: '/queue', builder: (_, _) => const QueueScreen()),
          GoRoute(path: '/patients', builder: (_, _) => const PatientsScreen()),
          GoRoute(
            path: '/patients/:id/card',
            builder: (_, state) =>
                PatientCardScreen(patientId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/devices', builder: (_, _) => const DevicesScreen()),
          GoRoute(path: '/inventory', builder: (_, _) => const InventoryScreen()),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod auth state into GoRouter: re-evaluates redirects whenever
/// the auth status changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final status = _ref.read(authControllerProvider).status;
    final loc = state.matchedLocation;

    switch (status) {
      case AuthStatus.unknown:
        return loc == '/splash' ? null : '/splash';
      case AuthStatus.unauthenticated:
        return loc == '/login' ? null : '/login';
      case AuthStatus.authenticated:
        return (loc == '/login' || loc == '/splash') ? '/dashboard' : null;
    }
  }
}
