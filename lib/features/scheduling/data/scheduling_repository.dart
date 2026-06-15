import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/appointment.dart';

/// Staff member for the calendar columns (mirrors backend `SchedStaffOut`).
typedef SchedStaff = ({String id, String fullName, List<String> roles});

/// Patient option for the booking picker.
typedef PatientOption = ({String id, String name, String mrn});

final schedulingRepositoryProvider = Provider<SchedulingRepository>(
    (ref) => SchedulingRepository(ref.watch(dioProvider)));

class SchedulingRepository {
  SchedulingRepository(this._dio);

  final Dio _dio;

  Future<List<Appointment>> day({required String branchId, required String date}) async {
    try {
      final resp = await _dio.get('/appointments',
          queryParameters: {'branch_id': branchId, 'date': date});
      return (resp.data as List<dynamic>)
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<SchedStaff>> staff(String branchId) async {
    try {
      final resp = await _dio.get('/appointments/staff',
          queryParameters: {'branch_id': branchId});
      return [
        for (final e in resp.data as List<dynamic>)
          (
            id: (e as Map<String, dynamic>)['id'] as String,
            fullName: e['full_name'] as String,
            roles: [for (final r in e['roles'] as List<dynamic>) r as String],
          ),
      ];
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Appointment> book({
    required String branchId,
    required String patientId,
    String? doctorId,
    required String startsAt,
    int durationMin = 30,
    String? service,
    String? cabinet,
  }) async {
    try {
      final resp = await _dio.post('/appointments', data: {
        'branch_id': branchId,
        'patient_id': patientId,
        'doctor_id': ?doctorId,
        'starts_at': startsAt,
        'duration_min': durationMin,
        'service': ?service,
        'cabinet': ?cabinet,
      });
      return Appointment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Appointment> reschedule(String id,
      {required String startsAt, int? durationMin, String? doctorId}) async {
    try {
      final resp = await _dio.post('/appointments/$id/reschedule', data: {
        'starts_at': startsAt,
        'duration_min': ?durationMin,
        'doctor_id': ?doctorId,
      });
      return Appointment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Appointment> setStatus(String id, String status) async {
    try {
      final resp = await _dio.post('/appointments/$id/status', data: {'status': status});
      return Appointment.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<PatientOption>> searchPatients(String q) async {
    try {
      final resp = await _dio.get('/patients',
          queryParameters: {'q': ?q.isEmpty ? null : q, 'limit': 20});
      final items = (resp.data as Map<String, dynamic>)['items'] as List<dynamic>;
      return [
        for (final e in items)
          (
            id: (e as Map<String, dynamic>)['id'] as String,
            name: [e['last_name'], e['first_name'], e['middle_name']]
                .where((x) => x != null && (x as String).isNotEmpty)
                .join(' '),
            mrn: (e['mrn'] as String?) ?? '',
          ),
      ];
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final scheduleProvider = FutureProvider.autoDispose
    .family<List<Appointment>, ({String branchId, String date})>((ref, key) =>
        ref.watch(schedulingRepositoryProvider).day(branchId: key.branchId, date: key.date));

final schedStaffProvider = FutureProvider.autoDispose
    .family<List<SchedStaff>, String>((ref, branchId) =>
        ref.watch(schedulingRepositoryProvider).staff(branchId));

final patientSearchProvider = FutureProvider.autoDispose
    .family<List<PatientOption>, String>((ref, q) =>
        ref.watch(schedulingRepositoryProvider).searchPatients(q));
