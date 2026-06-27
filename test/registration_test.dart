// Patient registration: the create payload carries the structured CRM fields,
// and the dialog surfaces the lead-source dropdown + collapsible advanced data.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/patients/data/patients_repository.dart';
import 'package:kozshifo/features/patients/presentation/patients_screen.dart';
import 'package:kozshifo/features/reception/data/reception_repository.dart';
import 'package:kozshifo/features/reception/domain/patient_summary.dart';

void main() {
  group('PatientsRepository.create', () {
    test('sends the structured CRM fields as snake_case, omits empties', () async {
      late RequestOptions captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _CapturingAdapter((options) {
          captured = options;
          return ResponseBody.fromString(
            jsonEncode(const {
              'id': 'p-1', 'mrn': 'P-1', 'first_name': 'Бек',
              'last_name': 'Алиев', 'full_name': 'Алиев Бек',
            }),
            201,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });
      final repo = PatientsRepository(dio);

      await repo.create(
        lastName: 'Алиев',
        firstName: 'Бек',
        middleName: 'Рустамович',
        birthDate: '1990-05-17',
        gender: 'male',
        phone: '+998901112233',
        phone2: '+998910000000',
        leadSource: 'instagram',
        passport: 'AA1234567',
        pinfl: '12345678901234',
        profession: 'Инженер',
        workplace: '  ', // whitespace-only → omitted
      );

      final body = captured.data as Map<String, dynamic>;
      expect(body['last_name'], 'Алиев');
      expect(body['middle_name'], 'Рустамович');
      expect(body['birth_date'], '1990-05-17');
      expect(body['gender'], 'male');
      expect(body['phone2'], '+998910000000');
      expect(body['lead_source'], 'instagram');
      expect(body['passport'], 'AA1234567');
      expect(body['pinfl'], '12345678901234');
      expect(body['profession'], 'Инженер');
      // Whitespace-only / unset optional fields are not sent.
      expect(body.containsKey('workplace'), isFalse);
      expect(body.containsKey('address'), isFalse);
    });
  });

  group('RegisterPatientDialog', () {
    testWidgets('shows lead-source dropdown and collapsible advanced fields',
        (tester) async {
      // Tall surface so the whole dialog fits and the actions bar doesn't
      // obscure the expander at the bottom.
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_FakeAuthController.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Center(child: RegisterPatientDialog())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Basics + the first-class lead-source field are visible immediately.
      expect(find.text('Регистрация пациента'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Фамилия'), findsOneWidget);
      expect(find.text('Источник клиента'), findsOneWidget);

      // Advanced fields are hidden until the section is expanded.
      expect(find.text('ПИНФЛ'), findsNothing);
      await tester.ensureVisible(find.text('Расширенные данные'));
      await tester.tap(find.text('Расширенные данные'));
      await tester.pumpAndSettle();
      expect(find.text('ПИНФЛ'), findsOneWidget);
      expect(find.text('Паспорт'), findsOneWidget);
    });

    testWidgets('warns about likely duplicates before creating a new patient',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_FakeAuthController.new),
            receptionRepositoryProvider.overrideWithValue(_FakeReception()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Center(child: RegisterPatientDialog())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Фамилия'), 'Алиев');
      await tester.enterText(find.widgetWithText(TextFormField, 'Имя'), 'Бек');

      // Регион обязателен; выбор Ферганской открывает обязательный «Район».
      await tester.ensureVisible(find.text('— выберите регион —'));
      await tester.tap(find.text('— выберите регион —'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ферганская').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('— выберите район / город —'));
      await tester.tap(find.text('— выберите район / город —'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('г. Фергана').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
      // Not pumpAndSettle: the save button shows a spinner (infinite animation)
      // while the confirm dialog is open, so settle would time out — pump frames.
      await tester.pump(); // _save runs the (mocked) duplicate check
      await tester.pump(const Duration(milliseconds: 400)); // dialog animates in

      // The anti-duplicate confirmation surfaces BEFORE any patient is created.
      expect(find.text('Возможные дубликаты'), findsOneWidget);
      expect(find.text('Всё равно создать'), findsOneWidget);
      expect(find.text('Алиев Бек'), findsOneWidget);
    });
  });
}

class _FakeReception extends ReceptionRepository {
  _FakeReception() : super(Dio());

  @override
  Future<List<DuplicateCandidate>> findDuplicates({
    String? lastName,
    String? firstName,
    String? phone,
    String? birthDate,
  }) async =>
      const [
        DuplicateCandidate(
          id: 'p-9',
          patientNo: '00000009',
          fullName: 'Алиев Бек',
          birthDate: '1990-05-17',
          phone: '+998 90 111 22 33',
          reason: 'телефон',
        ),
      ];
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this._handler);
  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        AuthStatus.authenticated,
        AuthUser(
          id: 'u-1',
          email: 'reception@kozshifo.uz',
          fullName: 'Ресепшен',
          branchId: 'b-1',
          permissions: ['patients.create'],
        ),
      );
}
