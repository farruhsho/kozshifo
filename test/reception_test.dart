// Reception models: snake_case parsing + display-only cart pre-total.
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/reception/domain/payment_result.dart';
import 'package:kozshifo/features/reception/domain/service.dart';

void main() {
  test('Service parses backend snake_case payload', () {
    final s = Service.fromJson(const {
      'id': 's1',
      'code': 'CONS',
      'name': 'Консультация офтальмолога',
      'price': '150000.00',
      'duration_minutes': 20,
      'is_active': true,
      'category_id': 'c1',
    });
    expect(s.price, '150000.00'); // money stays a string
    expect(s.durationMinutes, 20);
    expect(s.isActive, isTrue);
  });

  test('cartTotalValue sums price strings × qty (display only)', () {
    final total = cartTotalValue([('150000.00', 1), ('50000.00', 2)]);
    expect(total, 250000.0);
    expect(cartTotalValue(const []), 0);
    expect(cartTotalValue([('garbage', 3)]), 0);
  });

  test('PaymentResult parses receipt + ticket', () {
    final r = PaymentResult.fromJson(const {
      'payment': {
        'id': 'p1',
        'receipt_no': 'R-20260612-00001',
        'amount': '150000.00',
        'method': 'cash',
        'created_at': '2026-06-12T10:00:00Z',
      },
      'visit_status': 'open',
      'visit_balance': '0.00',
      'queue_ticket_number': 'A-001',
    });
    expect(r.payment.receiptNo, startsWith('R-'));
    expect(r.visitBalance, '0.00');
    expect(r.queueTicketNumber, 'A-001');
  });
}
