import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page.dart';
import '../domain/patient.dart';

final patientsRepositoryProvider =
    Provider<PatientsRepository>((ref) => PatientsRepository(ref.watch(dioProvider)));

class PatientsRepository {
  PatientsRepository(this._dio);

  final Dio _dio;

  Future<Page<Patient>> list({String? q, int offset = 0, int limit = 50}) async {
    try {
      final resp = await _dio.get('/patients', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        'offset': offset,
        'limit': limit,
      });
      return Page.fromJson(resp.data as Map<String, dynamic>, Patient.fromJson);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Patient> create({
    required String firstName,
    required String lastName,
    String? phone,
    String? branchId,
  }) async {
    try {
      final resp = await _dio.post('/patients', data: {
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'branch_id': ?branchId,
      });
      return Patient.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Current search term (debounced by the screen).
final patientSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final patientsListProvider = FutureProvider.autoDispose<Page<Patient>>((ref) {
  final q = ref.watch(patientSearchProvider);
  return ref.watch(patientsRepositoryProvider).list(q: q);
});
