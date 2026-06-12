import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/search/presentation/search_overlay.dart';
import '../theme/theme_controller.dart';

class AppDestination {
  const AppDestination(
    this.icon,
    this.selectedIcon,
    this.label,
    this.route, {
    this.permission,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  /// Permission code required to see this destination (null = visible to all).
  final String? permission;
}

/// Single source of truth for shell navigation AND the router's role-aware
/// landing/guard: the first destination the user is allowed to see is their
/// home screen after login.
const kAppDestinations = <AppDestination>[
  AppDestination(
    Icons.dashboard_outlined,
    Icons.dashboard,
    'Дашборд',
    '/dashboard',
    permission: 'dashboard.view',
  ),
  AppDestination(
    Icons.point_of_sale_outlined,
    Icons.point_of_sale,
    'Ресепшен',
    '/reception',
    permission: 'visits.create',
  ),
  AppDestination(
    Icons.confirmation_number_outlined,
    Icons.confirmation_number,
    'Очередь',
    '/queue',
    permission: 'queue.read',
  ),
  AppDestination(
    Icons.people_outline,
    Icons.people,
    'Пациенты',
    '/patients',
    permission: 'patients.read',
  ),
  AppDestination(
    Icons.payments_outlined,
    Icons.payments,
    'Финансы',
    '/finance',
    permission: 'expenses.read',
  ),
  AppDestination(
    Icons.badge_outlined,
    Icons.badge,
    'Учёт времени',
    '/attendance',
    permission: 'attendance.read',
  ),
  AppDestination(
    Icons.call_outlined,
    Icons.call,
    'Звонки',
    '/calls',
    permission: 'calls.read',
  ),
  AppDestination(
    Icons.biotech_outlined,
    Icons.biotech,
    'Оборудование',
    '/devices',
    permission: 'devices.read',
  ),
  AppDestination(
    Icons.inventory_2_outlined,
    Icons.inventory_2,
    'Склад',
    '/inventory',
    permission: 'inventory.read',
  ),
  AppDestination(
    Icons.settings_outlined,
    Icons.settings,
    'Администрирование',
    '/admin',
    permission: 'users.read',
  ),
];

/// App chrome: a navigation rail + the routed page body.
/// Hosts the global hotkeys: Ctrl+K / Ctrl+F open Smart Search anywhere
/// inside the shell (when the user can read patients).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final themeMode = ref.watch(themeModeProvider);
    final extended = MediaQuery.sizeOf(context).width >= 920;
    final canSearch = user?.can('patients.read') ?? false;

    final destinations = [
      for (final d in kAppDestinations)
        if (d.permission == null || (user?.can(d.permission!) ?? false)) d,
    ];

    int? selected;
    for (var i = 0; i < destinations.length; i++) {
      if (location.startsWith(destinations[i].route)) selected = i;
    }

    void openSearch() => showSearchOverlay(context, ref);

    return Scaffold(
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          if (canSearch) ...{
            const SingleActivator(LogicalKeyboardKey.keyK, control: true):
                openSearch,
            const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                openSearch,
          },
        },
        // The Focus keeps a focused node inside the shell at all times, so
        // the bindings above are live app-wide; an inner text field that gets
        // focus still bubbles unhandled keys (like Ctrl+K) up to here.
        child: Focus(
          autofocus: true,
          child: Builder(
            builder: (context) {
              final leading = Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                    if (canSearch)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: IconButton(
                          tooltip: 'Поиск (Ctrl+K)',
                          icon: const Icon(Icons.search),
                          onPressed: openSearch,
                        ),
                      ),
                  ],
                ),
              );
              final trailing = Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (extended && user != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              user.fullName,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Тема: ${themeModeLabel(themeMode)}',
                          icon: const Icon(Icons.brightness_6),
                          onPressed: () =>
                              ref.read(themeModeProvider.notifier).cycle(),
                        ),
                        IconButton(
                          tooltip: 'Выйти',
                          icon: const Icon(Icons.logout),
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .logout(),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              // NavigationRail asserts >= 2 destinations; single-screen roles
              // (e.g. Склад) get a slim bar with the same leading/trailing.
              final Widget rail = destinations.length >= 2
                  ? NavigationRail(
                      extended: extended,
                      selectedIndex: selected,
                      onDestinationSelected: (i) =>
                          context.go(destinations[i].route),
                      leading: leading,
                      destinations: [
                        for (final d in destinations)
                          NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.selectedIcon),
                            label: Text(d.label),
                          ),
                      ],
                      trailing: trailing,
                    )
                  : SizedBox(
                      width: 80,
                      child: Column(
                        children: [
                          leading,
                          if (destinations.isNotEmpty)
                            IconButton(
                              tooltip: destinations.first.label,
                              isSelected: true,
                              icon: Icon(destinations.first.selectedIcon),
                              onPressed: () =>
                                  context.go(destinations.first.route),
                            ),
                          trailing,
                        ],
                      ),
                    );

              return Row(
                children: [
                  rail,
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
