import 'package:flutter_test/flutter_test.dart';
import 'package:quickcart/utils/validators.dart';
import 'package:quickcart/utils/password_helper.dart';

void main() {
  group('Validators', () {
    test('validateName returns error for empty name', () {
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('   '), isNotNull);
    });

    test('validateName returns null for valid name', () {
      expect(Validators.validateName('Desh Kumar'), isNull);
    });

    test('validateEmail returns error for empty email', () {
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('validateEmail returns error for invalid email', () {
      expect(Validators.validateEmail('notanemail'), isNotNull);
      expect(Validators.validateEmail('missing@domain'), isNotNull);
      expect(Validators.validateEmail('@nodomain.com'), isNotNull);
    });

    test('validateEmail returns null for valid email', () {
      expect(Validators.validateEmail('desh@gmail.com'), isNull);
      expect(Validators.validateEmail('user.name@domain.co'), isNull);
    });

    test('validatePassword returns error for empty password', () {
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('validatePassword returns error for short password', () {
      expect(Validators.validatePassword('123'), isNotNull);
      expect(Validators.validatePassword('abc'), isNotNull);
    });

    test('validatePassword returns null for valid password', () {
      expect(Validators.validatePassword('password123'), isNull);
      expect(Validators.validatePassword('123456'), isNull);
    });

    test('validatePhone returns error for invalid phone', () {
      expect(Validators.validatePhone('123'), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
      expect(Validators.validatePhone('12345678901'), isNotNull);
    });

    test('validatePhone returns null for valid 10-digit phone', () {
      expect(Validators.validatePhone('9876543210'), isNull);
    });
  });

  group('PasswordHelper', () {
    test('hashPassword returns a non-empty string', () {
      final hash = PasswordHelper.hashPassword('mypassword');
      expect(hash, isNotEmpty);
    });

    test('same password always produces same hash', () {
      final hash1 = PasswordHelper.hashPassword('quickcart123');
      final hash2 = PasswordHelper.hashPassword('quickcart123');
      expect(hash1, equals(hash2));
    });

    test('different passwords produce different hashes', () {
      final hash1 = PasswordHelper.hashPassword('password1');
      final hash2 = PasswordHelper.hashPassword('password2');
      expect(hash1, isNot(equals(hash2)));
    });

    test('hash is 64 characters long (SHA-256)', () {
      final hash = PasswordHelper.hashPassword('testpassword');
      expect(hash.length, equals(64));
    });

    test('plain text password is not stored in hash', () {
      const password = 'mysecretpassword';
      final hash = PasswordHelper.hashPassword(password);
      expect(hash.contains(password), isFalse);
    });
  });
  group('Password Match Logic', () {
    String? confirmPasswordValidator(String? value, String password) {
      if (value == null || value.isEmpty) return 'Please confirm your password';
      if (value != password) return 'Passwords do not match';
      return null;
    }

    test('returns error when confirm password is empty', () {
      expect(confirmPasswordValidator('', 'password123'), isNotNull);
    });

    test('returns error when passwords do not match', () {
      expect(
        confirmPasswordValidator('wrongpassword', 'password123'),
        isNotNull,
      );
    });

    test('returns null when passwords match', () {
      expect(
        confirmPasswordValidator('password123', 'password123'),
        isNull,
      );
    });
  });

  group('Discount Calculation', () {
    int discountPercent(double price, double original) {
      return (((original - price) / original) * 100).round();
    }

    test('calculates correct discount percentage', () {
      expect(discountPercent(1299, 2199), equals(41));
      expect(discountPercent(599, 999), equals(40));
      expect(discountPercent(349, 499), equals(30));
    });

    test('returns 0 when price equals original', () {
      expect(discountPercent(999, 999), equals(0));
    });
  });

  group('Cart Total Calculation', () {
    double calculateTotal(List<Map<String, dynamic>> items) {
      return items.fold(
        0,
        (sum, item) => sum + (item['price'] as double) * (item['qty'] as int),
      );
    }

    test('calculates correct total for single item', () {
      final items = [
        {'price': 1299.0, 'qty': 1},
      ];
      expect(calculateTotal(items), equals(1299.0));
    });

    test('calculates correct total for multiple items', () {
      final items = [
        {'price': 1299.0, 'qty': 2},
        {'price': 599.0, 'qty': 1},
      ];
      expect(calculateTotal(items), equals(3197.0));
    });

    test('returns 0 for empty cart', () {
      expect(calculateTotal([]), equals(0));
    });

    test('calculates correct total with quantity more than 1', () {
      final items = [
        {'price': 999.0, 'qty': 3},
      ];
      expect(calculateTotal(items), equals(2997.0));
    });
  });

  group('Coupon Logic', () {
    const coupons = {
      'SAVE10': {'type': 'percent', 'value': 10},
      'FLAT50': {'type': 'flat', 'value': 50},
      'SAVE20': {'type': 'percent', 'value': 20},
    };

    double applyDiscount(String code, double subtotal) {
      if (!coupons.containsKey(code)) return 0;
      final coupon = coupons[code]!;
      final value = (coupon['value'] as num).toDouble();
      if (coupon['type'] == 'percent') {
        return subtotal * (value / 100);
      }
      return value;
    }

    test('SAVE10 gives 10 percent off', () {
      expect(applyDiscount('SAVE10', 1000), equals(100.0));
    });

    test('FLAT50 gives flat 50 off', () {
      expect(applyDiscount('FLAT50', 1000), equals(50.0));
    });

    test('SAVE20 gives 20 percent off', () {
      expect(applyDiscount('SAVE20', 500), equals(100.0));
    });

    test('invalid coupon gives 0 discount', () {
      expect(applyDiscount('INVALID', 1000), equals(0));
    });
  });
}