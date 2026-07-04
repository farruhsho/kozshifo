import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:typed_data';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/patient_summary.dart';
import '../domain/payment_result.dart';
import '../domain/reception_visit.dart';
import '../domain/service.dart';

final receptionRepositoryProvider =
    Provider<ReceptionRepository>((ref) => ReceptionRepository(ref.watch(dioProvider)));

class ReceptionRepository {
  ReceptionRepository(this._dio);

  final Dio _dio;

  Future<List<Service>> services() async {
    try {
      final resp = await _dio.get('/services', queryParameters: {'limit': 200});
      return (resp.data['items'] as List<dynamic>)
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .where((s) => s.isActive)
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Service categories (id + name) — used to group the price list on the
  /// reception screen (Консультации / Диагностика / Процедуры …).
  Future<List<({String id, String name})>> serviceCategories() async {
    try {
      final resp = await _dio.get('/service-categories');
      return [
        for (final e in resp.data as List<dynamic>)
          (id: (e as Map<String, dynamic>)['id'] as String, name: e['name'] as String),
      ];
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ReceptionVisit> createVisit({
    required String patientId,
    required String branchId,
    required List<({String serviceId, int quantity})> items,
    String? doctorId,
  }) async {
    try {
      final resp = await _dio.post('/visits', data: {
        'patient_id': patientId,
        'branch_id': branchId,
        // Лечащий/выбранный врач: V-талон маршрутизируется к нему (бэкенд также
        // падает обратно на patient.primary_doctor_id, если не передан).
        'doctor_id': ?doctorId,
        'items': [
          for (final it in items)
            {'service_id': it.serviceId, 'quantity': it.quantity},
        ],
      });
      return ReceptionVisit.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Врачи, которых ресепшен может назначить визиту (services.read — без
  /// users.read). Используется пикером «Назначить другого врача».
  Future<List<({String id, String fullName, bool isActive})>> doctors() async {
    try {
      final resp = await _dio.get('/services/assignable-doctors');
      return [
        for (final e in resp.data as List<dynamic>)
          (
            id: (e as Map<String, dynamic>)['id'] as String,
            fullName: e['full_name'] as String,
            isActive: e['is_active'] as bool,
          ),
      ];
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Sets / replaces the reception discount on an open visit — percent XOR
  /// amount, with a mandatory reason — or removes it ([clear] = true).
  /// Money math stays on the server: the response is the recalculated visit
  /// (discount_value / payable / balance). 409 — visit closed or the discount
  /// would drop payable below what is already paid; 422 — validation.
  Future<ReceptionVisit> setDiscount({
    required String visitId,
    String? percent,
    String? amount,
    String? reason,
    bool clear = false,
  }) async {
    try {
      final resp = await _dio.post(
        '/visits/$visitId/discount',
        data: clear
            ? const {'clear': true}
            : {
                'discount_percent': ?percent,
                'discount_amount': ?amount,
                'discount_reason': reason,
              },
      );
      return ReceptionVisit.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Aborts an unpaid open visit (patient declined / wrong services billed).
  Future<void> cancelVisit(String visitId) async {
    try {
      await _dio.post('/visits/$visitId/cancel');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Ручное закрытие визита оператором (терминальный flow + долга нет).
  /// Авто-закрытие делает бэкенд; кнопка нужна, когда авто-условие не
  /// сработало / для явного действия ресепшена.
  Future<void> closeVisit(String visitId) async {
    try {
      await _dio.post('/visits/$visitId/close');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<PaymentResult> takePayment({
    required String visitId,
    required String amount,
    String method = 'cash',
    String? room,
    // Куда направить пациента после полной оплаты:
    //   diagnostic — на диагностику (D-талон, по умолчанию)
    //   doctor     — «Направлен к врачу» (талон врача выдаётся сразу)
    //   hold       — «Ожидает назначения» (талон не выдаётся)
    String referralIntent = 'diagnostic',
  }) async {
    try {
      final resp = await _dio.post('/payments', data: {
        'visit_id': visitId,
        'amount': amount,
        'method': method,
        'room': ?room,
        'referral_intent': referralIntent,
      });
      return PaymentResult.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// «Направить к врачу» — issues a doctor-track ticket for a registered or held
  /// («Ожидает назначения») visit, optionally pinning [doctorId] (when the
  /// suggested лечащий is absent). Returns the ticket number (e.g. «С-001»).
  Future<String> referToDoctor({
    required String visitId,
    String? doctorId,
    String? room,
  }) async {
    try {
      final resp = await _dio.post('/queue/refer-to-doctor', data: {
        'visit_id': visitId,
        'doctor_id': ?doctorId,
        'room': ?room,
      });
      return resp.data['ticket_number'] as String;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Marks/clears EMERGENCY intake on a visit («ЭКСТРЕННО»). A reason is
  /// required when [emergency] is true. Returns the updated visit (priority set).
  Future<ReceptionVisit> setEmergency({
    required String visitId,
    required bool emergency,
    String? reason,
  }) async {
    try {
      final resp = await _dio.post('/visits/$visitId/priority',
          data: {'emergency': emergency, 'reason': ?reason});
      return ReceptionVisit.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Issues a «талон на лечение» — queues the patient onto the TV board's
  /// «Лечение» track for a course of treatment. The room may be omitted (the
  /// backend mints the ticket without a fixed room). [visitId] ties the ticket
  /// to the patient's visit only when an open visit is on screen; otherwise it
  /// is omitted and the backend picks the visit itself. Returns the ticket
  /// number (e.g. «Л-001»).
  Future<String> issueTreatmentTicket({
    required String patientId,
    required String branchId,
    String? visitId,
    String? room,
  }) async {
    try {
      final resp = await _dio.post('/queue/treatment-ticket', data: {
        'patient_id': patientId,
        'branch_id': branchId,
        'visit_id': ?visitId,
        'room': ?room,
      });
      return resp.data['ticket_number'] as String;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// At-a-glance patient history for the reception panel.
  Future<PatientSummary> patientSummary(String patientId) async {
    try {
      final resp = await _dio.get('/patients/$patientId/summary');
      return PatientSummary.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Likely existing matches BEFORE creating a new patient (anti-duplicate).
  Future<List<DuplicateCandidate>> findDuplicates({
    String? lastName,
    String? firstName,
    String? phone,
    String? birthDate,
  }) async {
    try {
      final resp = await _dio.get('/patients/duplicates', queryParameters: {
        'last_name': ?lastName,
        'first_name': ?firstName,
        'phone': ?phone,
        'birth_date': ?birthDate,
      });
      return (resp.data as List<dynamic>)
          .map((e) => DuplicateCandidate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Receipt PDF bytes (чек) — the UI opens/prints them (web: blob URL).
  Future<Uint8List> receiptPdf(String paymentId) async {
    try {
      final resp = await _dio.get<List<int>>(
        '/payments/$paymentId/receipt.pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data ?? const []);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Reception history panel for a selected patient.
final patientSummaryProvider = FutureProvider.autoDispose
    .family<PatientSummary, String>((ref, patientId) =>
        ref.watch(receptionRepositoryProvider).patientSummary(patientId));

/// Врачи для пикера «Назначить другого врача» (services.read).
final receptionDoctorsProvider = FutureProvider.autoDispose<
        List<({String id, String fullName, bool isActive})>>(
    (ref) => ref.watch(receptionRepositoryProvider).doctors());

final activeServicesProvider = FutureProvider.autoDispose<List<Service>>(
    (ref) => ref.watch(receptionRepositoryProvider).services());

/// Categories (id + name) for grouping the reception price list. Best-effort:
/// if it fails, the services screen falls back to a single «Прочее» group.
final serviceCategoriesProvider =
    FutureProvider.autoDispose<List<({String id, String name})>>(
        (ref) => ref.watch(receptionRepositoryProvider).serviceCategories());
