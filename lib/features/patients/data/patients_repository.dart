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

  Future<Patient> getById(String id) async {
    try {
      final resp = await _dio.get('/patients/$id');
      return Patient.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Создаёт пациента. На бэкенд (PatientCreate) уходит только то, что заполнено
  /// или выбрано — пустые/нулевые поля опускаются, чтобы не слать `null`.
  Future<Patient> create({
    required String firstName,
    required String lastName,
    String? middleName,
    String? birthDate,
    String? gender,
    String? phone,
    String? phone2,
    String? passport,
    String? pinfl,
    String? leadSource,
    String? workplace,
    String? profession,
    String? address,
    String? region,
    String? district,
    String? notes,
    String? branchId,
  }) async {
    String? clean(String? v) {
      if (v == null) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    try {
      final resp = await _dio.post('/patients', data: {
        'first_name': firstName,
        'last_name': lastName,
        if (clean(middleName) != null) 'middle_name': clean(middleName),
        if (clean(birthDate) != null) 'birth_date': clean(birthDate),
        if (clean(gender) != null) 'gender': clean(gender),
        if (clean(phone) != null) 'phone': clean(phone),
        if (clean(phone2) != null) 'phone2': clean(phone2),
        if (clean(address) != null) 'address': clean(address),
        if (clean(passport) != null) 'passport': clean(passport),
        if (clean(pinfl) != null) 'pinfl': clean(pinfl),
        if (clean(leadSource) != null) 'lead_source': clean(leadSource),
        if (clean(workplace) != null) 'workplace': clean(workplace),
        if (clean(profession) != null) 'profession': clean(profession),
        'region': ?clean(region),
        'district': ?clean(district),
        if (clean(notes) != null) 'notes': clean(notes),
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

final patientByIdProvider = FutureProvider.autoDispose.family<Patient, String>(
    (ref, id) => ref.watch(patientsRepositoryProvider).getById(id));
