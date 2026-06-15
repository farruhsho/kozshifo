// Clinical models: snake_case parsing, decimal strings stay String, RU labels.
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/clinical/domain/operation.dart';
import 'package:kozshifo/features/clinical/domain/operation_type.dart';
import 'package:kozshifo/features/clinical/domain/treatment.dart';

void main() {
  const operationTypeJson = <String, dynamic>{
    'id': 'ot-1',
    'code': 'PHACO',
    'name': 'Факоэмульсификация катаракты + ИОЛ',
    'service_id': 'svc-9',
    'price': '5000000.00',
    'duration_minutes': 40,
    'is_active': true,
    'description': 'Ультразвуковое удаление хрусталика',
    'consumables': [
      {'product_id': 'prod-1', 'product_name': 'ИОЛ моноблок', 'quantity': '1.000'},
      {'product_id': 'prod-2', 'product_name': 'Вискоэластик', 'quantity': '2.000'},
    ],
  };

  test('OperationType round-trips with consumables; price stays String', () {
    final t = OperationType.fromJson(operationTypeJson);
    expect(t.code, 'PHACO');
    expect(t.serviceId, 'svc-9');
    expect(t.price, '5000000.00');
    expect(t.price, isA<String>());
    expect(t.durationMinutes, 40);
    expect(t.consumables, hasLength(2));
    expect(t.consumables.first.productId, 'prod-1');
    expect(t.consumables.first.productName, 'ИОЛ моноблок');
    expect(t.consumables.first.quantity, '1.000');
    expect(t.consumables.first.quantity, isA<String>());
    expect(OperationType.fromJson(t.toJson()), t);
  });

  test('OperationType defaults: is_active true, consumables empty', () {
    final t = OperationType.fromJson({...operationTypeJson}
      ..remove('is_active')
      ..remove('consumables'));
    expect(t.isActive, isTrue);
    expect(t.consumables, isEmpty);
  });

  const operationJson = <String, dynamic>{
    'id': 'op-1',
    'visit_id': 'v-1',
    'patient_id': 'p-1',
    'patient_name': 'Иванов Иван',
    'referring_doctor_id': 'u-1',
    'referring_doctor_name': 'Доктор Окулист',
    'surgeon_id': null,
    'surgeon_name': null,
    'operation_type_id': 'ot-1',
    'type_name': 'Факоэмульсификация катаракты + ИОЛ',
    'eye': 'od',
    'status': 'referred',
    'price': null,
    'scheduled_at': null,
    'performed_at': null,
    'completed_at': null,
    'notes': 'под местной анестезией',
    'result': null,
    'created_at': '2026-06-12T10:00:00Z',
  };

  test('Operation parses; isReferred + eyeLabel/statusLabel helpers', () {
    final op = Operation.fromJson(operationJson);
    expect(op.operationTypeId, 'ot-1');
    expect(op.patientName, 'Иванов Иван');
    expect(op.isReferred, isTrue);
    expect(op.isOpen, isTrue);
    expect(op.eyeLabel, 'правый глаз');
    expect(op.statusLabel, 'направлен');
    expect(Operation.fromJson(op.toJson()), op);

    final os = op.copyWith(eye: 'os');
    expect(os.eyeLabel, 'левый глаз');
    final ou = op.copyWith(eye: 'ou');
    expect(ou.eyeLabel, 'оба глаза');
  });

  test('Operation priority: parses urgent, defaults to normal when omitted', () {
    final urgent = Operation.fromJson({...operationJson, 'priority': 'urgent'});
    expect(urgent.priority, 'urgent');
    expect(urgent.isUrgent, isTrue);
    expect(Operation.fromJson(urgent.toJson()), urgent);

    // operationJson has no 'priority' key — the model must default it.
    final op = Operation.fromJson(operationJson);
    expect(op.priority, 'normal');
  });

  test('Operation lifecycle labels: scheduled / performed / completed', () {
    final scheduled = Operation.fromJson({
      ...operationJson,
      'status': 'scheduled',
      'price': '5000000.00',
      'scheduled_at': '2026-07-01T09:00:00Z',
      'surgeon_id': 's-1',
      'surgeon_name': 'Жаррох Жарроев',
    });
    expect(scheduled.isScheduled, isTrue);
    expect(scheduled.isOpen, isTrue);
    expect(scheduled.statusLabel, 'запланирована');
    expect(scheduled.price, '5000000.00');
    expect(scheduled.surgeonName, 'Жаррох Жарроев');

    final performed = Operation.fromJson({
      ...operationJson,
      'status': 'performed',
      'performed_at': '2026-07-01T12:30:00Z',
    });
    expect(performed.isPerformed, isTrue);
    expect(performed.isOpen, isFalse);
    expect(performed.statusLabel, 'выполнена');

    final completed = Operation.fromJson({
      ...operationJson,
      'status': 'completed',
      'result': 'Без осложнений',
    });
    expect(completed.statusLabel, 'завершена');
    expect(completed.result, 'Без осложнений');

    final cancelled = Operation.fromJson({...operationJson, 'status': 'cancelled'});
    expect(cancelled.statusLabel, 'отменена');
    expect(cancelled.isOpen, isFalse);
  });

  const medicationJson = <String, dynamic>{
    'id': 'tr-1',
    'visit_id': 'v-1',
    'patient_id': 'p-1',
    'doctor_id': 'u-1',
    'kind': 'medication',
    'name': 'Тропикамид 1%',
    'product_id': 'prod-3',
    'quantity': '5.000',
    'instructions': 'по 1 капле 3 раза в день',
    'status': 'prescribed',
    'performed_at': null,
    'created_at': '2026-06-12T10:05:00Z',
  };

  test('Treatment medication parses; quantity stays String; labels', () {
    final t = Treatment.fromJson(medicationJson);
    expect(t.isMedication, isTrue);
    expect(t.isPrescribed, isTrue);
    expect(t.productId, 'prod-3');
    expect(t.quantity, '5.000');
    expect(t.quantity, isA<String>());
    expect(t.kindLabel, 'Медикамент');
    expect(t.statusLabel, 'назначено');
    expect(Treatment.fromJson(t.toJson()), t);
  });

  test('Treatment procedure: nullable product fields; status labels', () {
    final t = Treatment.fromJson(const {
      'id': 'tr-2',
      'visit_id': 'v-1',
      'patient_id': 'p-1',
      'doctor_id': null,
      'kind': 'procedure',
      'name': 'Промывание слёзных путей',
      'product_id': null,
      'quantity': null,
      'instructions': null,
      'status': 'done',
      'performed_at': '2026-06-12T11:00:00Z',
      'created_at': '2026-06-12T10:10:00Z',
    });
    expect(t.isMedication, isFalse);
    expect(t.productId, isNull);
    expect(t.kindLabel, 'Процедура');
    expect(t.statusLabel, 'выполнено');

    // The backend's terminal status is always 'done'; a dispensed medication
    // must read «выдано» while a done procedure reads «выполнено».
    expect(Treatment.fromJson({...medicationJson, 'status': 'done'}).statusLabel,
        'выдано');
    expect(Treatment.fromJson({...medicationJson, 'status': 'cancelled'}).statusLabel,
        'отменено');
  });
}
