// Smart-search models: snake_case parsing of the three sections,
// the isEmpty helper, and the flow_status default for older backends.
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/search/domain/search_results.dart';

void main() {
  const json = <String, dynamic>{
    'patients': [
      {
        'id': 'p1',
        'mrn': 'MRN-000001',
        'full_name': 'Иванов Иван',
        'phone': '+998901234567',
      },
    ],
    'visits': [
      {
        'id': 'v1',
        'visit_no': 'V-000010',
        'patient_id': 'p1',
        'patient_name': 'Иванов Иван',
        'flow_status': 'waiting_doctor',
        'status': 'open',
      },
    ],
    'receipts': [
      {
        'payment_id': 'pay1',
        'receipt_no': 'R-000123',
        'amount': '150000.00',
        'visit_id': 'v1',
        'patient_id': 'p1',
      },
    ],
  };

  test('SearchResults round-trips the backend payload', () {
    final r = SearchResults.fromJson(json);
    expect(r.patients.single.fullName, 'Иванов Иван');
    expect(r.patients.single.mrn, 'MRN-000001');
    expect(r.patients.single.phone, '+998901234567');
    expect(r.visits.single.visitNo, 'V-000010');
    expect(r.visits.single.patientId, 'p1');
    expect(r.visits.single.flowStatus, 'waiting_doctor');
    expect(r.receipts.single.receiptNo, 'R-000123');
    expect(r.receipts.single.amount, '150000.00');
    expect(r.isEmpty, isFalse);
    expect(SearchResults.fromJson(r.toJson()), r);
  });

  test('missing sections default to empty lists and isEmpty is true', () {
    final r = SearchResults.fromJson(const <String, dynamic>{});
    expect(r.patients, isEmpty);
    expect(r.visits, isEmpty);
    expect(r.receipts, isEmpty);
    expect(r.isEmpty, isTrue);
  });

  test('isEmpty is false when only one section has hits', () {
    final r = SearchResults.fromJson(const {
      'patients': <dynamic>[],
      'visits': <dynamic>[],
      'receipts': [
        {'payment_id': 'pay1', 'receipt_no': 'R-000001', 'amount': '10000.00'},
      ],
    });
    expect(r.isEmpty, isFalse);
    // Optional receipt links are nullable — a detached payment still renders.
    expect(r.receipts.single.visitId, isNull);
    expect(r.receipts.single.patientId, isNull);
  });

  test('SearchVisit flow_status defaults to registered when omitted', () {
    final v = SearchVisit.fromJson(const {
      'id': 'v1',
      'visit_no': 'V-000010',
      'patient_id': 'p1',
      'patient_name': 'Иванов Иван',
      'status': 'open',
    });
    expect(v.flowStatus, 'registered');
  });

  test('SearchPatient phone is optional', () {
    final p = SearchPatient.fromJson(const {
      'id': 'p1',
      'mrn': 'MRN-000002',
      'full_name': 'Каримова Дилноза',
    });
    expect(p.phone, isNull);
  });
}
