import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label, this.route,
      {this.permission});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  /// Permission code required to see this destination (null = visible to all).
  final String? permission;
}

const _allDestinations = <_Destination>[
  _Destination(Icons.dashboard_outlined, Icons.dashboard, 'Дашборд', '/dashboard'),
  _Destination(Icons.point_of_sale_outlined, Icons.point_of_sale, 'Ресепшен',
      '/reception', permission: 'visits.create'),
  _Destination(Icons.people_outline, Icons.people, 'Пациенты', '/patients'),
  _Destination(Icons.biotech_outlined, Icons.biotech, 'Оборудование', '/devices',
      permission: 'devices.read'),
];

/// App chrome: a navigation rail + the routed page body.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final extended = MediaQuery.sizeOf(context).width >= 920;

    final destinations = [
      for (final d in _allDestinations)
        if (d.permission == null || (user?.can(d.permission!) ?? false)) d,
    ];

    int? selected;
    for (var i = 0; i < destinations.length; i++) {
      if (location.startsWith(destinations[i].route)) selected = i;
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: selected,
            onDestinationSelected: (i) => context.go(destinations[i].route),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.remove_red_eye_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 30),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (extended && user != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(user.fullName,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      IconButton(
                        tooltip: 'Выйти',
                        icon: const Icon(Icons.logout),
                        onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
