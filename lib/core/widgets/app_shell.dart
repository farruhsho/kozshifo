import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_user.dart';
import '../../features/search/presentation/search_overlay.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'koz_icons.dart';
import 'koz_widgets.dart';

/// Maps a shell route to the prototype line-icon key (KozIcons). Unmapped
/// routes fall back to the destination's Material icon.
const Map<String, String> _navIconKey = {
  '/dashboard': 'dashboard',
  '/reception': 'reception',
  '/worklist': 'worklist',
  '/scheduling': 'schedule',
  '/queue': 'queue',
  '/patients': 'patients',
  '/analytics': 'analytics',
  '/finance': 'finance',
  '/inventory': 'inventory',
  '/optics': 'optics',
  '/lab': 'lab',
  '/notifications': 'notifications',
  '/admin': 'settings',
  '/devices': 'devices',
  '/cameras': 'cameras',
  '/calls': 'calls',
  '/access-control': 'face',
  '/attendance': 'badge',
};

class AppDestination {
  const AppDestination(
    this.icon,
    this.selectedIcon,
    this.label,
    this.route, {
    this.permissions = const <String>[],
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  /// Any-of permission codes that reveal this destination (empty = public).
  final List<String> permissions;

  /// Visible when the user holds ANY of the listed permissions (or it's public).
  bool allowedFor(AuthUser? user) =>
      permissions.isEmpty || permissions.any((p) => user?.can(p) ?? false);
}

/// Single source of truth for shell navigation AND the router's role-aware
/// landing/guard: the first destination the user is allowed to see is their
/// home screen after login. Order = landing priority per role (Финансы sits
/// right after Ресепшен so a Cashier lands on their till).
const kAppDestinations = <AppDestination>[
  AppDestination(
    Icons.dashboard_outlined,
    Icons.dashboard,
    'Дашборд',
    '/dashboard',
    permissions: ['dashboard.view'],
  ),
  AppDestination(
    Icons.point_of_sale_outlined,
    Icons.point_of_sale,
    'Ресепшен',
    '/reception',
    permissions: ['visits.create'],
  ),
  // Doctor's «Приём сегодня» list — gated on exams.write so a doctor lands here
  // (their first allowed destination), not on Scheduling.
  AppDestination(
    Icons.assignment_outlined,
    Icons.assignment,
    'Приём',
    '/worklist',
    permissions: ['exams.write'],
  ),
  AppDestination(
    Icons.calendar_month_outlined,
    Icons.calendar_month,
    'Расписание',
    '/scheduling',
    permissions: ['appointments.read'],
  ),
  AppDestination(
    Icons.payments_outlined,
    Icons.payments,
    'Финансы',
    '/finance',
    // Union of the tabs FinanceScreen gates: till (payments.create), refunds
    // (payments.read), expenses (expenses.read), payroll (payroll.read) — so a
    // read-only finance role both sees the item and is routed here.
    permissions: [
      'payments.create',
      'payments.read',
      'expenses.read',
      'payroll.read',
    ],
  ),
  AppDestination(
    Icons.confirmation_number_outlined,
    Icons.confirmation_number,
    'Очередь',
    '/queue',
    permissions: ['queue.read'],
  ),
  AppDestination(
    Icons.healing_outlined,
    Icons.healing,
    'Операции',
    '/operations',
    permissions: ['operations.read'],
  ),
  AppDestination(
    Icons.people_outline,
    Icons.people,
    'Пациенты',
    '/patients',
    permissions: ['patients.read'],
  ),
  AppDestination(
    Icons.insights_outlined,
    Icons.insights,
    'Аналитика',
    '/analytics',
    permissions: ['dashboard.view'],
  ),
  AppDestination(
    Icons.badge_outlined,
    Icons.badge,
    'Сотрудники',
    '/attendance',
    permissions: ['attendance.read'],
  ),
  AppDestination(
    Icons.call_outlined,
    Icons.call,
    'Звонки',
    '/calls',
    permissions: ['calls.read'],
  ),
  AppDestination(
    Icons.biotech_outlined,
    Icons.biotech,
    'Оборудование',
    '/devices',
    permissions: ['devices.read'],
  ),
  AppDestination(
    Icons.inventory_2_outlined,
    Icons.inventory_2,
    'Склад',
    '/inventory',
    permissions: ['inventory.read'],
  ),
  AppDestination(
    Icons.remove_red_eye_outlined,
    Icons.remove_red_eye,
    'Оптика',
    '/optics',
    permissions: ['optics.read'],
  ),
  AppDestination(
    Icons.science_outlined,
    Icons.science,
    'Лаборатория',
    '/lab',
    permissions: ['lab.read'],
  ),
  AppDestination(
    Icons.videocam_outlined,
    Icons.videocam,
    'Камеры',
    '/cameras',
    permissions: ['cameras.view'],
  ),
  AppDestination(
    Icons.face_outlined,
    Icons.face,
    'Face ID',
    '/access-control',
    permissions: ['access_control.read'],
  ),
  AppDestination(
    Icons.notifications_outlined,
    Icons.notifications,
    'Уведомления',
    '/notifications',
    permissions: ['notifications.read'],
  ),
  AppDestination(
    Icons.medical_services_outlined,
    Icons.medical_services,
    'Услуги',
    '/services',
    // Reception (services.create) manages the catalog from its own menu;
    // director (superuser) sees it too. Diagnost (services.read only) doesn't.
    permissions: ['services.create'],
  ),
  AppDestination(
    Icons.settings_outlined,
    Icons.settings,
    'Администрирование',
    '/admin',
    permissions: ['users.read'],
  ),
];

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '—';
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1);
  }
  return parts[0][0] + parts[1][0];
}

String _roleLabel(List<String> roles) {
  if (roles.isEmpty) return 'Сотрудник';
  const m = {
    'Superadmin': 'Суперадмин',
    'Director': 'Директор',
    'Reception': 'Регистратура',
    'Doctor': 'Врач',
    'Diagnost': 'Диагност',
    'Cashier': 'Касса',
    'Warehouse': 'Склад',
  };
  return m[roles.first] ?? roles.first;
}

/// App chrome: the dark-teal «Clinic OS» sidebar + the routed page body.
/// Hosts the global hotkeys: Ctrl+K / Ctrl+F open Smart Search anywhere
/// inside the shell (when the user can read patients). Each routed screen keeps
/// its own Scaffold/AppBar (they inherit the new AppBarTheme).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final canSearch = user?.can('patients.read') ?? false;

    final destinations = [
      for (final d in kAppDestinations)
        if (d.allowedFor(user)) d,
    ];

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
        // The Focus keeps a focused node inside the shell at all times, so the
        // bindings above stay live app-wide even when an inner field has focus.
        child: Focus(
          autofocus: true,
          child: Row(
            children: [
              _Sidebar(
                location: location,
                destinations: destinations,
                user: user,
                canSearch: canSearch,
                onSearch: openSearch,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.location,
    required this.destinations,
    required this.user,
    required this.canSearch,
    required this.onSearch,
  });

  final String location;
  final List<AppDestination> destinations;
  final AuthUser? user;
  final bool canSearch;
  final VoidCallback onSearch;

  bool _isActive(AppDestination d) =>
      location == d.route || location.startsWith('${d.route}/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(gradient: AppColors.sidebarGradient),
      child: SafeArea(
        child: Column(
          children: [
            // brand
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.mint, AppColors.tealDark],
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const KozIcon('eye', size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "KO'Z SHIFO",
                        style: AppTypography.number(16.5, color: Colors.white),
                      ),
                      const Text(
                        'CLINIC OS',
                        style: TextStyle(
                          color: AppColors.sidebarSub,
                          fontSize: 10.5,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 4, 22, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'МЕНЮ',
                  style: TextStyle(
                    color: Color(0xFF4F8278),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final d in destinations)
                    _NavItem(
                      d: d,
                      active: _isActive(d),
                      onTap: () => context.go(d.route),
                    ),
                ],
              ),
            ),
            if (canSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: _SideButton(
                  icon: Icons.search,
                  label: 'Поиск  ⌘K',
                  onTap: onSearch,
                ),
              ),
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  InitialsAvatar(
                    _initialsOf(user?.fullName ?? '—'),
                    size: 38,
                    fontSize: 14,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.fullName ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          _roleLabel(user?.roles ?? const []),
                          style: const TextStyle(
                            color: AppColors.sidebarSub,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Выйти',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.logout,
                      size: 18,
                      color: AppColors.sidebarSub,
                    ),
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.d, required this.active, required this.onTap});

  final AppDestination d;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.sidebarItemActive : AppColors.sidebarItem;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: active ? AppColors.sidebarActiveBg : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              // reserve the 2px accent always so the row never shifts.
              border: Border(
                left: BorderSide(
                  color: active ? AppColors.sidebarAccent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(11, 11, 13, 11),
            child: Row(
              children: [
                _navIconKey.containsKey(d.route)
                    ? KozIcon(_navIconKey[d.route]!, size: 19, color: color)
                    : Icon(
                        active ? d.selectedIcon : d.icon,
                        size: 19,
                        color: color,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    d.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              const KozIcon('search', size: 18, color: Color(0xFFC7DAD5)),
              const SizedBox(width: 11),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFC7DAD5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
