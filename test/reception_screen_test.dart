// Render smoke test for ReceptionScreen. Reproduces the «reception freezes»
// report: a layout assertion («RenderBox was not laid out») that loops every
// frame and blanks the body. Mounts the real screen with data providers
// overridden + a reception user, at both a narrow and a wide surface, and
// asserts no exception escapes layout.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kozshifo/app/theme.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/reception/data/reception_repository.dart';
import 'package:kozshifo/features/reception/domain/service.dart';
import 'package:kozshifo/features/reception/presentation/reception_screen.dart';

const _user = AuthUser(
  id: 'u-rec',
  email: 'reception@kozshifo.uz',
  fullName: 'Регистратор Тест',
  branchId: 'b1',
  permissions: [
    'patients.read', 'patients.create',
    'visits.read', 'visits.create', 'visits.update',
    'payments.read', 'payments.create',
    'services.read',
  ],
);

const _services = <Service>[
  Service(id: 's1', code: 'CONS', name: 'Консультация офтальмолога', price: '150000.00', categoryId: 'c1'),
  Service(id: 's2', code: 'ARM', name: 'Авторефрактометрия', price: '50000.00', categoryId: 'c2'),
];

const _categories = <({String id, String name})>[
  (id: 'c1', name: 'Консультации'),
  (id: 'c2', name: 'Диагностика'),
];

Widget _host(List<Override> overrides) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(_user)),
        activeServicesProvider.overrideWith((ref) async => _services),
        serviceCategoriesProvider.overrideWith((ref) async => _categories),
        ...overrides,
      ],
      // The real app theme is essential: its full-width button style
      // (minimumSize) is what triggered «RenderBox was not laid out» on the
      // patient-search Row. The default test theme would not reproduce it.
      child: MaterialApp(theme: KozTheme.light(), home: const ReceptionScreen()),
    );

Future<void> _pumpAt(WidgetTester tester, Size size, List<Override> overrides) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(overrides));
  await tester.pump(); // let the services future resolve into the data state
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ReceptionScreen lays out at a narrow width (no RenderBox assertion)',
      (tester) async {
    await _pumpAt(tester, const Size(700, 900), const []);
    final ex = tester.takeException();
    expect(ex, isNull);
    expect(find.text('Ресепшен'), findsOneWidget);
    // Services are grouped under category headers (matches the prototype).
    expect(find.text('КОНСУЛЬТАЦИИ'), findsOneWidget);
    expect(find.text('ДИАГНОСТИКА'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // unmount → cancels the autosave timer
  });

  testWidgets('ReceptionScreen lays out at a wide width (no RenderBox assertion)',
      (tester) async {
    await _pumpAt(tester, const Size(1280, 900), const []);
    final ex = tester.takeException();
    await tester.pumpWidget(const SizedBox());
    expect(ex, isNull);
  });
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._u);
  final AuthUser _u;

  @override
  AuthState build() => AuthState(AuthStatus.authenticated, _u);
}
