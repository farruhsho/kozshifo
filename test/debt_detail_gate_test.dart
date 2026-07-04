// Кнопка «Погасить» на экране детализации долга гейтится `payments.create`:
// роль с одним лишь `debts.read` (открывает экран) не должна видеть действие,
// POST которого сервер защищает `payments.create` (иначе 403 при тапе).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/debt/data/debt_repository.dart';
import 'package:kozshifo/features/debt/domain/patient_debt_detail.dart';
import 'package:kozshifo/features/debt/presentation/patient_debt_detail_screen.dart';

/// Auth stub — синхронный build(), без сети; список прав задаётся тестом.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._permissions);

  final List<String> _permissions;

  @override
  AuthState build() => AuthState(
        AuthStatus.authenticated,
        AuthUser(
          id: 'u1',
          email: 'user@kozshifo.uz',
          fullName: 'Сотрудник',
          branchId: 'br-1',
          permissions: _permissions,
        ),
      );
}

/// Возвращает один визит с долгом; repay() не должен вызываться в этих тестах.
class _FakeDebtRepository extends DebtRepository {
  _FakeDebtRepository() : super(Dio());

  @override
  Future<PatientDebtDetail> patientDebt(String patientId) async =>
      const PatientDebtDetail(
        patientId: 'p1',
        patientName: 'Пациент Тест',
        phone: '+998901234567',
        totalDebt: '150000',
        visits: [
          DebtVisitRow(
            visitId: 'v1',
            visitNo: 'V-001',
            openedAt: '2026-06-20T09:00:00Z',
            payable: '200000',
            paid: '50000',
            remaining: '150000',
            services: 'Консультация',
            flowStatus: 'open',
          ),
        ],
        payments: [],
      );
}

Widget _harness(List<String> permissions) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(permissions)),
        debtRepositoryProvider.overrideWithValue(_FakeDebtRepository()),
      ],
      child: const MaterialApp(
        home: PatientDebtDetailScreen(patientId: 'p1'),
      ),
    );

void main() {
  group('гейт кнопки «Погасить»', () {
    testWidgets('видна при payments.create', (tester) async {
      await tester.pumpWidget(_harness(const ['debts.read', 'payments.create']));
      await tester.pump();
      await tester.pump();
      expect(find.text('Погасить'), findsOneWidget);
    });

    testWidgets('скрыта при одном лишь debts.read', (tester) async {
      await tester.pumpWidget(_harness(const ['debts.read']));
      await tester.pump();
      await tester.pump();
      expect(find.text('Погасить'), findsNothing);
    });
  });
}
