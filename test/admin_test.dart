// Admin (Owner Control Center) models: snake_case parsing; the backend sends
// user roles as [{id, name}, …] RoleRef objects — we keep only the names.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/admin/data/admin_repository.dart';
import 'package:kozshifo/features/admin/domain/admin_branch.dart';
import 'package:kozshifo/features/admin/domain/admin_role.dart';
import 'package:kozshifo/features/admin/domain/staff_user.dart';
import 'package:kozshifo/features/reception/domain/service.dart';

void main() {
  const userJson = <String, dynamic>{
    'id': 'u-1',
    'email': 'doctor@kozshifo.uz',
    'full_name': 'Иванова Дилноза',
    'phone': '+998901234567',
    'is_active': true,
    'is_superuser': false,
    'branch_id': 'br-1',
    'salary_percent': '12.50',
    'roles': [
      {'id': 'r-1', 'name': 'doctor'},
      {'id': 'r-2', 'name': 'diagnost'},
    ],
  };

  test('StaffUser parses snake_case; role refs collapse to names', () {
    final u = StaffUser.fromJson(userJson);
    expect(u.fullName, 'Иванова Дилноза');
    expect(u.email, 'doctor@kozshifo.uz');
    expect(u.phone, '+998901234567');
    expect(u.branchId, 'br-1');
    expect(u.isActive, isTrue);
    expect(u.isSuperuser, isFalse);
    expect(u.salaryPercent, '12.50'); // Decimal приходит строкой
    expect(u.roles, ['doctor', 'diagnost']);
  });

  test('StaffUser.salaryPercent is null when absent', () {
    final u = StaffUser.fromJson(const {
      'id': 'u-9',
      'email': 'noperc@kozshifo.uz',
      'full_name': 'Без процента',
    });
    expect(u.salaryPercent, isNull);
  });

  test('StaffUser round-trips through its own toJson (roles as strings)', () {
    final u = StaffUser.fromJson(userJson);
    expect(StaffUser.fromJson(u.toJson()), u);
  });

  test('StaffUser defaults: is_active=true, is_superuser=false, roles=[]', () {
    final u = StaffUser.fromJson(const {
      'id': 'u-2',
      'email': 'new@kozshifo.uz',
      'full_name': 'Новый Сотрудник',
    });
    expect(u.isActive, isTrue);
    expect(u.isSuperuser, isFalse);
    expect(u.roles, isEmpty);
    expect(u.branchId, isNull);
    expect(u.phone, isNull);
  });

  const branchJson = <String, dynamic>{
    'id': 'br-1',
    'name': 'Главный филиал',
    'code': 'MAIN',
    'address': 'г. Ташкент, ул. Шифокорлар 1',
    'phone': '+998712001020',
    'is_active': true,
  };

  test('AdminBranch round-trips snake_case JSON', () {
    final b = AdminBranch.fromJson(branchJson);
    expect(b.name, 'Главный филиал');
    expect(b.code, 'MAIN');
    expect(b.address, 'г. Ташкент, ул. Шифокорлар 1');
    expect(b.phone, '+998712001020');
    expect(b.isActive, isTrue);
    expect(AdminBranch.fromJson(b.toJson()), b);
  });

  test('AdminBranch optional fields and is_active default', () {
    final b = AdminBranch.fromJson(const {
      'id': 'br-2',
      'name': 'Филиал Самарканд',
      'code': 'SAM',
    });
    expect(b.address, isNull);
    expect(b.phone, isNull);
    expect(b.isActive, isTrue);
  });

  test('AdminRole parses minimally: name + permission count', () {
    final r = AdminRole.fromJson(const {
      'id': 'r-1',
      'name': 'doctor',
      'description': 'Врач-офтальмолог',
      'is_system': true,
      'permissions': [
        {
          'id': 'p-1',
          'code': 'patients.read',
          'module': 'patients',
          'description': null,
        },
        {
          'id': 'p-2',
          'code': 'exams.update',
          'module': 'exams',
          'description': null,
        },
      ],
    });
    expect(r.name, 'doctor');
    expect(r.permissionCount, 2);
    expect(r.description, 'Врач-офтальмолог');
  });

  // ─── AdminRepository.updateUser: salary_percent set / clear ─────────────────
  group('AdminRepository.updateUser salary_percent', () {
    (AdminRepository, RequestOptions Function()) makeRepo() {
      RequestOptions? captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _CapturingAdapter((options) {
          captured = options;
          // Echo a minimal UserOut so StaffUser.fromJson succeeds.
          return ResponseBody.fromString(
            jsonEncode(const {
              'id': 'u-1',
              'email': 'doctor@kozshifo.uz',
              'full_name': 'Иванова Дилноза',
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });
      return (AdminRepository(dio), () => captured!);
    }

    test('sends salary_percent when provided', () async {
      final (repo, last) = makeRepo();
      await repo.updateUser('u-1', salaryPercent: '30');
      final body = last().data as Map<String, dynamic>;
      expect(body.containsKey('salary_percent'), isTrue);
      expect(body['salary_percent'], '30');
    });

    test('clear sends explicit null', () async {
      final (repo, last) = makeRepo();
      await repo.updateUser('u-1', clearSalaryPercent: true);
      final body = last().data as Map<String, dynamic>;
      // Ключ присутствует и равен null — бэкенд (exclude_unset) так сбрасывает.
      expect(body.containsKey('salary_percent'), isTrue);
      expect(body['salary_percent'], isNull);
    });

    test('omits salary_percent when neither set nor cleared', () async {
      final (repo, last) = makeRepo();
      await repo.updateUser('u-1', isActive: false);
      final body = last().data as Map<String, dynamic>;
      // Не передаём ключ — поле остаётся без изменений на сервере.
      expect(body.containsKey('salary_percent'), isFalse);
      expect(body['is_active'], isFalse);
    });

    // Переназначение ролей из диалога редактирования сотрудника.
    test('sends role_names when roles reassigned', () async {
      final (repo, last) = makeRepo();
      await repo.updateUser('u-1', roleNames: const ['doctor', 'reception']);
      final body = last().data as Map<String, dynamic>;
      expect(body['role_names'], ['doctor', 'reception']);
    });

    test('omits role_names when roles untouched', () async {
      final (repo, last) = makeRepo();
      await repo.updateUser('u-1', salaryPercent: '15');
      final body = last().data as Map<String, dynamic>;
      // Null-aware spread не должен слать ключ, если роли не переданы.
      expect(body.containsKey('role_names'), isFalse);
    });
  });

  // ─── Ф1: cabinet + doctor↔service M2M ───────────────────────────────────────
  test('StaffUser parses cabinet and services', () {
    final u = StaffUser.fromJson(const {
      'id': 'u-1',
      'email': 'd@kozshifo.uz',
      'full_name': 'Доктор',
      'cabinet': 'Каб. 1',
      'services': [
        {'id': 's-1', 'code': 'CONS-01', 'name': 'Консультация'},
        {'id': 's-2', 'code': 'OCT', 'name': 'ОКТ'},
      ],
    });
    expect(u.cabinet, 'Каб. 1');
    expect(u.services.map((s) => s.id).toList(), ['s-1', 's-2']);
    expect(u.services.first.code, 'CONS-01');
    expect(u.services.first.name, 'Консультация');
  });

  test('StaffUser: cabinet null and services empty when absent', () {
    final u = StaffUser.fromJson(const {
      'id': 'u-9',
      'email': 'x@kozshifo.uz',
      'full_name': 'Без клиники',
    });
    expect(u.cabinet, isNull);
    expect(u.services, isEmpty);
  });

  test('Service parses eligible doctors with cabinet', () {
    final s = Service.fromJson(const {
      'id': 's-1',
      'code': 'CONS-01',
      'name': 'Консультация',
      'price': '150000.00',
      'doctors': [
        {'id': 'u-1', 'full_name': 'Доктор А', 'cabinet': 'Каб. 1'},
        {'id': 'u-2', 'full_name': 'Доктор Б', 'cabinet': null},
      ],
    });
    expect(s.doctors.length, 2);
    expect(s.doctors.first.id, 'u-1');
    expect(s.doctors.first.fullName, 'Доктор А');
    expect(s.doctors.first.cabinet, 'Каб. 1');
    expect(s.doctors[1].cabinet, isNull);
  });

  test('Service: doctors empty when absent', () {
    final s = Service.fromJson(const {
      'id': 's-2',
      'code': 'X',
      'name': 'Услуга',
      'price': '0',
    });
    expect(s.doctors, isEmpty);
  });

  group('AdminRepository cabinet, services & doctors payloads', () {
    (AdminRepository, RequestOptions Function()) makeUserRepo() {
      RequestOptions? captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _CapturingAdapter((options) {
          captured = options;
          return ResponseBody.fromString(
            jsonEncode(const {
              'id': 'u-1',
              'email': 'd@kozshifo.uz',
              'full_name': 'Доктор',
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });
      return (AdminRepository(dio), () => captured!);
    }

    (AdminRepository, RequestOptions Function()) makeServiceRepo() {
      RequestOptions? captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _CapturingAdapter((options) {
          captured = options;
          return ResponseBody.fromString(
            jsonEncode(const {
              'id': 's-1',
              'code': 'CONS-01',
              'name': 'Консультация',
              'price': '150000.00',
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });
      return (AdminRepository(dio), () => captured!);
    }

    test('createUser sends cabinet and service_ids', () async {
      final (repo, last) = makeUserRepo();
      await repo.createUser(
        email: 'd@kozshifo.uz',
        fullName: 'Доктор',
        password: 'password1',
        roleNames: const ['doctor'],
        cabinet: 'Каб. 1',
        serviceIds: const ['s-1', 's-2'],
      );
      final body = last().data as Map<String, dynamic>;
      expect(body['cabinet'], 'Каб. 1');
      expect(body['service_ids'], ['s-1', 's-2']);
    });

    test('createUser omits cabinet/service_ids when not given', () async {
      final (repo, last) = makeUserRepo();
      await repo.createUser(
        email: 'd@kozshifo.uz',
        fullName: 'Доктор',
        password: 'password1',
        roleNames: const [],
      );
      final body = last().data as Map<String, dynamic>;
      expect(body.containsKey('cabinet'), isFalse);
      expect(body.containsKey('service_ids'), isFalse);
    });

    test(
      'updateUser sends cabinet + service_ids; clear sends null cabinet',
      () async {
        final (repo, last) = makeUserRepo();
        await repo.updateUser(
          'u-1',
          cabinet: 'Каб. 2',
          serviceIds: const ['s-1'],
        );
        var body = last().data as Map<String, dynamic>;
        expect(body['cabinet'], 'Каб. 2');
        expect(body['service_ids'], ['s-1']);

        await repo.updateUser('u-1', clearCabinet: true, serviceIds: const []);
        body = last().data as Map<String, dynamic>;
        expect(body.containsKey('cabinet'), isTrue);
        expect(body['cabinet'], isNull);
        expect(body['service_ids'], isEmpty);
      },
    );

    test('updateUser omits cabinet/service_ids when untouched', () async {
      final (repo, last) = makeUserRepo();
      await repo.updateUser('u-1', salaryPercent: '10');
      final body = last().data as Map<String, dynamic>;
      expect(body.containsKey('cabinet'), isFalse);
      expect(body.containsKey('service_ids'), isFalse);
    });

    test('createService sends doctor_ids', () async {
      final (repo, last) = makeServiceRepo();
      await repo.createService(
        code: 'CONS-01',
        name: 'Консультация',
        price: '150000',
        doctorIds: const ['u-1', 'u-2'],
      );
      final body = last().data as Map<String, dynamic>;
      expect(body['doctor_ids'], ['u-1', 'u-2']);
    });

    test(
      'updateService sends doctor_ids ([] clears); omits when untouched',
      () async {
        final (repo, last) = makeServiceRepo();
        await repo.updateService('s-1', doctorIds: const ['u-1']);
        var body = last().data as Map<String, dynamic>;
        expect(body['doctor_ids'], ['u-1']);

        await repo.updateService('s-1', doctorIds: const []);
        body = last().data as Map<String, dynamic>;
        expect(body.containsKey('doctor_ids'), isTrue);
        expect(body['doctor_ids'], isEmpty);

        await repo.updateService('s-1', name: 'Новое имя');
        body = last().data as Map<String, dynamic>;
        expect(body.containsKey('doctor_ids'), isFalse);
        expect(body['name'], 'Новое имя');
      },
    );
  });
}

/// Захватывает RequestOptions и возвращает заранее заданный ответ (без сети).
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => _handler(options);

  @override
  void close({bool force = false}) {}
}
