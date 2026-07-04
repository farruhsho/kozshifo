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
    expect(r.id, 'r-1');
    expect(r.isSystem, isTrue);
    expect(r.permissionCodes, ['patients.read', 'exams.update']);
  });

  test('AdminRole: id null, is_system false, no permissions → empty codes', () {
    final r = AdminRole.fromJson(const {'name': 'custom'});
    expect(r.id, isNull);
    expect(r.isSystem, isFalse);
    expect(r.permissionCodes, isEmpty);
    expect(r.permissionCount, 0);
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
      // No pay configured → pay fields are omitted (not sent as null).
      expect(body.containsKey('consult_salary_type'), isFalse);
      expect(body.containsKey('operation_salary_type'), isFalse);
    });

    test('createUser sends doctor pay (consult + operation)', () async {
      final (repo, last) = makeUserRepo();
      await repo.createUser(
        email: 'd@kozshifo.uz',
        fullName: 'Доктор',
        password: 'password1',
        roleNames: const ['doctor'],
        consultSalaryType: 'percent',
        consultSalaryValue: '30',
        operationSalaryType: 'fixed',
        operationSalaryValue: '50000',
      );
      final body = last().data as Map<String, dynamic>;
      expect(body['consult_salary_type'], 'percent');
      expect(body['consult_salary_value'], '30');
      expect(body['operation_salary_type'], 'fixed');
      expect(body['operation_salary_value'], '50000');
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

  // ─── Roles & permissions (RBAC editor) ──────────────────────────────────────
  group('AdminRepository roles & permissions', () {
    (AdminRepository, RequestOptions Function()) makeRoleRepo() {
      RequestOptions? captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _CapturingAdapter((options) {
          captured = options;
          // Echo a minimal RoleOut so AdminRole.fromJson succeeds.
          return ResponseBody.fromString(
            jsonEncode(const {
              'id': 'r-1',
              'name': 'reception',
              'is_system': false,
              'permissions': [],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });
      return (AdminRepository(dio), () => captured!);
    }

    test('permissionsCatalog parses code/module/description', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _CapturingAdapter((_) {
          return ResponseBody.fromString(
            jsonEncode(const [
              {
                'id': 'p-1',
                'code': 'patients.read',
                'module': 'patients',
                'description': 'Просмотр пациентов',
              },
              {
                'id': 'p-2',
                'code': 'visits.create',
                'module': 'visits',
                'description': null,
              },
            ]),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });
      final perms = await AdminRepository(dio).permissionsCatalog();
      expect(perms.length, 2);
      expect(perms.first.code, 'patients.read');
      expect(perms.first.module, 'patients');
      expect(perms.first.description, 'Просмотр пациентов');
      expect(perms[1].description, isNull);
    });

    test('createRole sends name + permission_codes', () async {
      final (repo, last) = makeRoleRepo();
      await repo.createRole(
        name: 'reception',
        permissionCodes: const ['patients.read', 'visits.create'],
        description: 'Регистратура',
      );
      final opts = last();
      expect(opts.method, 'POST');
      expect(opts.path, '/roles');
      final body = opts.data as Map<String, dynamic>;
      expect(body['name'], 'reception');
      expect(body['permission_codes'], ['patients.read', 'visits.create']);
      expect(body['description'], 'Регистратура');
    });

    test('createRole omits description when null', () async {
      final (repo, last) = makeRoleRepo();
      await repo.createRole(name: 'reception', permissionCodes: const []);
      final body = last().data as Map<String, dynamic>;
      expect(body.containsKey('description'), isFalse);
      expect(body['permission_codes'], isEmpty);
    });

    test('updateRole sends permission_codes ([] clears)', () async {
      final (repo, last) = makeRoleRepo();
      await repo.updateRole('r-1', permissionCodes: const ['patients.read']);
      var opts = last();
      expect(opts.method, 'PATCH');
      expect(opts.path, '/roles/r-1');
      expect((opts.data as Map<String, dynamic>)['permission_codes'],
          ['patients.read']);

      await repo.updateRole('r-1', permissionCodes: const []);
      final body = last().data as Map<String, dynamic>;
      expect(body.containsKey('permission_codes'), isTrue);
      expect(body['permission_codes'], isEmpty);
    });

    test('updateRole omits permission_codes when untouched', () async {
      final (repo, last) = makeRoleRepo();
      await repo.updateRole('r-1', description: 'Новое описание');
      final body = last().data as Map<String, dynamic>;
      expect(body.containsKey('permission_codes'), isFalse);
      expect(body['description'], 'Новое описание');
    });

    test('deleteRole issues DELETE /roles/{id}', () async {
      final (repo, last) = makeRoleRepo();
      await repo.deleteRole('r-1');
      final opts = last();
      expect(opts.method, 'DELETE');
      expect(opts.path, '/roles/r-1');
    });
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
