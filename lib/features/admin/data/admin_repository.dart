import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../../reception/domain/service.dart';
import '../domain/admin_branch.dart';
import '../domain/admin_role.dart';
import '../domain/staff_user.dart';

/// Service-category reference for the create-service dropdown.
typedef CategoryRef = ({String id, String name});

final adminRepositoryProvider = Provider<AdminRepository>(
    (ref) => AdminRepository(ref.watch(dioProvider)));

/// Owner Control Center: services & prices, branches, staff users.
/// Money/price decimals are passed as strings — the server owns decimal math.
class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  // ── Services & prices ──────────────────────────────────────────────────────

  /// Full price list (Page envelope; one 200-item page covers the catalog —
  /// searchable pickers are tracked in AGENTS.md §7 leftovers).
  Future<List<Service>> services({String? q}) async {
    try {
      final resp = await _dio.get('/services', queryParameters: {
        'q': ?q,
        'offset': 0,
        'limit': 200,
      });
      return Page.fromJson(resp.data as Map<String, dynamic>, Service.fromJson)
          .items;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<CategoryRef>> categories() async {
    try {
      final resp = await _dio.get('/service-categories');
      return [
        for (final e in resp.data as List<dynamic>)
          (
            id: (e as Map<String, dynamic>)['id'] as String,
            name: e['name'] as String,
          ),
      ];
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Service> createService({
    required String code,
    required String name,
    required String price,
    int? durationMinutes,
    String? description,
    String? categoryId,
  }) async {
    try {
      final resp = await _dio.post('/services', data: {
        'code': code,
        'name': name,
        'price': price,
        'duration_minutes': ?durationMinutes,
        'description': ?description,
        'category_id': ?categoryId,
      });
      return Service.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// PATCH with exclude-unset semantics: only the provided keys are sent.
  Future<Service> updateService(
    String id, {
    String? name,
    String? price,
    bool? isActive,
  }) async {
    try {
      final resp = await _dio.patch('/services/$id', data: {
        'name': ?name,
        'price': ?price,
        'is_active': ?isActive,
      });
      return Service.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ── Branches ───────────────────────────────────────────────────────────────

  Future<List<AdminBranch>> branches() async {
    try {
      final resp = await _dio.get('/branches'); // plain list, no Page envelope
      return (resp.data as List<dynamic>)
          .map((e) => AdminBranch.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<AdminBranch> createBranch({
    required String name,
    required String code,
    String? address,
    String? phone,
  }) async {
    try {
      final resp = await _dio.post('/branches', data: {
        'name': name,
        'code': code,
        'address': ?address,
        'phone': ?phone,
      });
      return AdminBranch.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Backend `BranchUpdate` has no `code` — the code is immutable.
  Future<AdminBranch> updateBranch(
    String id, {
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    try {
      final resp = await _dio.patch('/branches/$id', data: {
        'name': ?name,
        'address': ?address,
        'phone': ?phone,
        'is_active': ?isActive,
      });
      return AdminBranch.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ── Staff users ────────────────────────────────────────────────────────────

  Future<List<StaffUser>> users() async {
    try {
      final resp = await _dio.get('/users', queryParameters: {
        'offset': 0,
        'limit': 200, // backend max page size for /users
      });
      return Page.fromJson(
              resp.data as Map<String, dynamic>, StaffUser.fromJson)
          .items;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<StaffUser> createUser({
    required String email,
    required String fullName,
    required String password,
    required List<String> roleNames,
    String? branchId,
  }) async {
    try {
      final resp = await _dio.post('/users', data: {
        'email': email,
        'full_name': fullName,
        'password': password,
        'role_names': roleNames,
        'branch_id': ?branchId,
      });
      return StaffUser.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// PATCH /users/{id} with exclude-unset semantics on the backend.
  ///
  /// [salaryPercent] sets the doctor's percent-pay (decimal string, "0".."100").
  /// To CLEAR percent pay (take a doctor off percent-based salary) pass
  /// [clearSalaryPercent] = true — the backend treats explicit `null` as «clear»,
  /// and Dart's null-aware map spread (`?`) can't emit an explicit null, so the
  /// clear path needs its own flag rather than `salaryPercent: null`.
  Future<StaffUser> updateUser(
    String id, {
    bool? isActive,
    List<String>? roleNames,
    String? salaryPercent,
    bool clearSalaryPercent = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'is_active': ?isActive,
        'role_names': ?roleNames,
      };
      // Explicit null clears the percent (backend uses exclude_unset, so a
      // present null means "set to null" while omission leaves it unchanged).
      if (clearSalaryPercent) {
        body['salary_percent'] = null;
      } else if (salaryPercent != null) {
        body['salary_percent'] = salaryPercent;
      }
      final resp = await _dio.patch('/users/$id', data: body);
      return StaffUser.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ── Roles (display + assignment only) ─────────────────────────────────────

  Future<List<AdminRole>> roles() async {
    try {
      final resp = await _dio.get('/roles');
      return (resp.data as List<dynamic>)
          .map((e) => AdminRole.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final adminServicesProvider = FutureProvider.autoDispose<List<Service>>(
    (ref) => ref.watch(adminRepositoryProvider).services());

final adminCategoriesProvider = FutureProvider.autoDispose<List<CategoryRef>>(
    (ref) => ref.watch(adminRepositoryProvider).categories());

final adminBranchesProvider = FutureProvider.autoDispose<List<AdminBranch>>(
    (ref) => ref.watch(adminRepositoryProvider).branches());

final adminUsersProvider = FutureProvider.autoDispose<List<StaffUser>>(
    (ref) => ref.watch(adminRepositoryProvider).users());

final adminRolesProvider = FutureProvider.autoDispose<List<AdminRole>>(
    (ref) => ref.watch(adminRepositoryProvider).roles());
