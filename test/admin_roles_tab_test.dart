// Widget tests for the «Роли» tab of AdminScreen: visibility gated by roles.read,
// «Новая роль» only under roles.create, and system roles are not deletable.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/admin/data/admin_repository.dart';
import 'package:kozshifo/features/admin/domain/admin_branch.dart';
import 'package:kozshifo/features/admin/domain/admin_role.dart';
import 'package:kozshifo/features/admin/presentation/admin_screen.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';

void main() {
  // Роли: одна системная (защищена) + одна пользовательская (удаляемая/правимая).
  final roles = [
    const AdminRole(
      id: 'r-sys',
      name: 'director',
      isSystem: true,
      permissionCodes: ['roles.read', 'roles.create'],
      description: 'Владелец системы',
    ),
    const AdminRole(
      id: 'r-cust',
      name: 'reception',
      isSystem: false,
      permissionCodes: ['patients.read'],
    ),
  ];

  const perms = <PermissionRef>[
    (code: 'patients.read', module: 'patients', description: 'Просмотр'),
    (code: 'visits.create', module: 'visits', description: null),
  ];

  Widget harness(AuthUser user) => ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuth(user)),
          adminRolesProvider.overrideWith((ref) async => roles),
          adminPermissionsProvider.overrideWith((ref) async => perms),
          // Первая вкладка (Филиалы) строится сразу — держим её пустой.
          adminBranchesProvider
              .overrideWith((ref) async => const <AdminBranch>[]),
        ],
        child: const MaterialApp(home: AdminScreen()),
      );

  Future<void> openRolesTab(WidgetTester tester, AuthUser user) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(user));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Роли'));
    await tester.pumpAndSettle();
  }

  testWidgets('«Роли» tab hidden without roles.read', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      harness(
        const AuthUser(
          id: 'u-1',
          email: 'v@kozshifo.uz',
          fullName: 'Viewer',
          permissions: ['branches.read'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Tab, 'Роли'), findsNothing);
    // Другие вкладки на месте — length согласован без «Роли».
    expect(find.widgetWithText(Tab, 'Филиалы'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Диагнозы'), findsOneWidget);
  });

  testWidgets('«Роли» tab visible with roles.read', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      harness(
        const AuthUser(
          id: 'u-1',
          email: 'v@kozshifo.uz',
          fullName: 'Viewer',
          permissions: ['roles.read'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Tab, 'Роли'), findsOneWidget);
  });

  testWidgets('tab visible with roles.read; lists system + custom roles',
      (tester) async {
    await openRolesTab(
      tester,
      const AuthUser(
        id: 'u-1',
        email: 'v@kozshifo.uz',
        fullName: 'Viewer',
        permissions: ['roles.read'],
      ),
    );
    expect(find.text('director'), findsOneWidget);
    expect(find.text('reception'), findsOneWidget);
    expect(find.text('системная'), findsOneWidget);
  });

  testWidgets('«Новая роль» hidden without roles.create', (tester) async {
    await openRolesTab(
      tester,
      const AuthUser(
        id: 'u-1',
        email: 'v@kozshifo.uz',
        fullName: 'Viewer',
        permissions: ['roles.read'],
      ),
    );
    expect(find.text('Новая роль'), findsNothing);
  });

  testWidgets('«Новая роль» shown with roles.create', (tester) async {
    await openRolesTab(
      tester,
      const AuthUser(
        id: 'u-1',
        email: 'a@kozshifo.uz',
        fullName: 'Admin',
        permissions: ['roles.read', 'roles.create'],
      ),
    );
    expect(find.text('Новая роль'), findsOneWidget);
  });

  testWidgets('delete button only on custom role, never on system role',
      (tester) async {
    await openRolesTab(
      tester,
      const AuthUser(
        id: 'u-1',
        email: 'a@kozshifo.uz',
        fullName: 'Admin',
        permissions: ['roles.read', 'roles.delete'],
      ),
    );
    // Ровно одна кнопка удаления — у пользовательской роли; системная защищена.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);

  final AuthUser _user;

  @override
  AuthState build() => AuthState(AuthStatus.authenticated, _user);
}
