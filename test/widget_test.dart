// Unit tests for pure app logic (no plugins / network required).
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/core/utils/formatters.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';

void main() {
  group('formatMoney', () {
    test('formats a decimal string with grouping and currency', () {
      expect(formatMoney('150000.00'), contains('150'));
      expect(formatMoney('150000.00'), endsWith('сум'));
    });

    test('falls back to zero for null/garbage', () {
      expect(formatMoney(null), startsWith('0'));
      expect(formatMoney('abc'), startsWith('0'));
    });
  });

  group('AuthUser.can', () {
    const base = AuthUser(id: '1', email: 'a@b.c', fullName: 'A');

    test('grants only listed permissions', () {
      final u = base.copyWith(permissions: ['patients.read']);
      expect(u.can('patients.read'), isTrue);
      expect(u.can('patients.create'), isFalse);
    });

    test('superuser can do anything', () {
      final u = base.copyWith(isSuperuser: true);
      expect(u.can('anything.at.all'), isTrue);
    });
  });
}
