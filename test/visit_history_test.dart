// VisitSummary enrichment for the «История визитов» panel: full-payload parsing
// (money + billed items + emergency), the debt/discount/emergency getters, and
// backward-compatible parsing of the minimal picker payload (defaults intact).
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/doctor/domain/visit_summary.dart';

void main() {
  group('VisitSummary visit-history enrichment', () {
    test('parses the full /visits payload (money + items + priority)', () {
      final v = VisitSummary.fromJson(const {
        'id': 'v1',
        'visit_no': 'V-20260616-0007',
        'status': 'open',
        'flow_status': 'in_doctor',
        'opened_at': '2026-06-16T09:00:00Z',
        'closed_at': null,
        'branch_id': 'br-1',
        'visit_type': 'surgery',
        'total_amount': '250000.00',
        'paid_amount': '200000.00',
        'discount_value': '50000.00',
        'discount_reason': 'Пенсионер',
        'payable': '200000.00',
        'balance': '0.00',
        'priority': 100,
        'items': [
          {'service_name': 'Консультация', 'quantity': 1, 'total': '150000.00'},
          {'service_name': 'Биометрия', 'quantity': 2, 'total': '100000.00'},
        ],
      });

      expect(v.visitType, 'surgery');
      expect(v.totalAmount, '250000.00');
      expect(v.payable, '200000.00');
      expect(v.items, hasLength(2));
      expect(v.items.first.serviceName, 'Консультация');
      expect(v.items[1].quantity, 2);
      expect(v.isEmergency, isTrue);
      expect(v.hasDiscount, isTrue);
      expect(v.hasDebt, isFalse); // balance 0.00 — fully covered
    });

    test('debt getter: a positive balance owes money', () {
      final v = VisitSummary.fromJson(const {
        'id': 'v2',
        'visit_no': 'V-2',
        'status': 'open',
        'opened_at': '2026-06-16T09:00:00Z',
        'balance': '50000.00',
      });
      expect(v.hasDebt, isTrue);
      expect(v.isEmergency, isFalse); // priority defaults to 0
      expect(v.hasDiscount, isFalse);
    });

    test('minimal picker payload still parses with safe defaults', () {
      final v = VisitSummary.fromJson(const {
        'id': 'v3',
        'visit_no': 'V-3',
        'status': 'open',
        'opened_at': '2026-06-16T09:00:00Z',
      });
      expect(v.flowStatus, 'registered');
      expect(v.visitType, 'consultation');
      expect(v.totalAmount, '0');
      expect(v.balance, '0');
      expect(v.items, isEmpty);
      expect(v.hasDebt, isFalse);
      expect(v.label, 'V-3 · 2026-06-16'); // open → no status suffix
    });
  });
}
