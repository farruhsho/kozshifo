// Reports screen smoke test: renders the tab bar + financial KPIs + export
// control for a director, with every report provider stubbed (no real Dio).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/reports/data/reports_repository.dart';
import 'package:kozshifo/features/reports/domain/reports.dart';
import 'package:kozshifo/features/reports/presentation/reports_screen.dart';

void main() {
  testWidgets('reports screen shows tabs, financial KPIs and an export control',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuth.new),
        financialReportProvider.overrideWith((ref, range) async =>
            FinancialReport.fromJson(const {
              'date_from': '2026-06-01', 'date_to': '2026-06-19',
              'income': '500000', 'expenses': '100000', 'profit': '400000',
              'by_method': [{'label': 'Наличные', 'amount': '500000'}],
              'by_category': [{'label': 'Аренда', 'amount': '100000'}],
            })),
        byDoctorReportProvider.overrideWith((ref, range) async => const []),
        byDiagnosticianReportProvider.overrideWith((ref, range) async => const []),
        byPatientReportProvider.overrideWith((ref, range) async => const []),
        byRegionReportProvider.overrideWith((ref, range) async => const []),
        profitByRegionReportProvider.overrideWith((ref, range) async => const []),
        byOperationReportProvider.overrideWith((ref, range) async =>
            OperationsReport.fromJson(const {
              'count': 0, 'revenue': '0', 'cogs': '0', 'profit': '0', 'by_surgeon': [],
            })),
      ],
      child: const MaterialApp(home: ReportsScreen()),
    ));
    await tester.pumpAndSettle();

    // Tab bar + the active financial tab.
    expect(find.text('Отчёты'), findsOneWidget);
    expect(find.text('Финансы'), findsOneWidget);
    expect(find.text('Врачи'), findsOneWidget);
    expect(find.text('Пациенты'), findsOneWidget);
    expect(find.text('Экспорт'), findsWidgets);
    // Financial KPI labels render.
    expect(find.text('Прибыль'), findsOneWidget);
  });
}

class _FakeAuth extends AuthController {
  @override
  AuthState build() => const AuthState(
        AuthStatus.authenticated,
        AuthUser(
          id: 'u-dir',
          email: 'director@kozshifo.uz',
          fullName: 'Директор',
          permissions: ['reports.view', 'dashboard.view'],
        ),
      );
}
