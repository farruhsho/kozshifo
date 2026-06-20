import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/cabinet.dart';

final cabinetRepositoryProvider = Provider<CabinetRepository>(
    (ref) => CabinetRepository(ref.watch(dioProvider)));

class CabinetRepository {
  CabinetRepository(this._dio);

  final Dio _dio;

  Future<List<Cabinet>> list(String branchId, {bool includeInactive = false}) async {
    try {
      final resp = await _dio.get('/cabinets', queryParameters: {
        'branch_id': branchId,
        'include_inactive': includeInactive,
      });
      return [
        for (final e in resp.data as List)
          Cabinet.fromJson(e as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Cabinet> create(
      {required String branchId, required String name, String? kind}) async {
    try {
      final resp = await _dio.post('/cabinets',
          data: {'branch_id': branchId, 'name': name, 'kind': ?kind});
      return Cabinet.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Cabinet> update(String id,
      {String? name, String? kind, bool? isActive}) async {
    try {
      final resp = await _dio.patch('/cabinets/$id',
          data: {'name': ?name, 'kind': ?kind, 'is_active': ?isActive});
      return Cabinet.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Active cabinets of a branch (for the «Мой кабинет» login picker / admin list).
final cabinetsProvider = FutureProvider.autoDispose
    .family<List<Cabinet>, String>(
        (ref, branchId) => ref.watch(cabinetRepositoryProvider).list(branchId));

/// All cabinets incl. inactive — for the admin management tab.
final allCabinetsProvider = FutureProvider.autoDispose.family<List<Cabinet>, String>(
    (ref, branchId) =>
        ref.watch(cabinetRepositoryProvider).list(branchId, includeInactive: true));

/// The cabinet the staff member chose at login («Мой кабинет»). Session-scoped
/// (re-picked each login, per the brief: «При входе обязательно отображается
/// выбор кабинета»). All patient calls go to this room.
final selectedCabinetProvider = StateProvider<String?>((ref) => null);
