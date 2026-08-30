import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/utils/validators.dart';

void main() {
  group('Validators.validatePhone', () {
    test('valid Indian 10-digit phone numbers', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('+919876543210'), isNull);
      expect(Validators.validatePhone('09876543210'), isNull);
      expect(Validators.validatePhone('98765 43210'), isNull);
    });

    test('invalid phone numbers', () {
      expect(Validators.validatePhone(null), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
      expect(Validators.validatePhone('12345'), isNotNull);
      expect(
        Validators.validatePhone('1234567890'),
        isNotNull,
      ); // Doesn't start with 6-9
      expect(Validators.validatePhone('abcdefghij'), isNotNull);
    });
  });

  group('Validators.validateName', () {
    test('valid names', () {
      expect(Validators.validateName('Ravi Kumar'), isNull);
      expect(Validators.validateName('A. Sharma'), isNull);
      expect(Validators.validateName("O'Connor"), isNull);
    });

    test('invalid names', () {
      expect(Validators.validateName(null), isNotNull);
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('A'), isNotNull);
      expect(Validators.validateName('John123'), isNotNull);
    });
  });

  group('Validators.validateLoanAmount', () {
    test('valid loan amounts within range', () {
      expect(
        Validators.validateLoanAmount(
          value: '10000',
          minAmount: 500,
          maxAmount: 500000,
        ),
        isNull,
      );
      expect(
        Validators.validateLoanAmount(
          value: '10,000',
          minAmount: 500,
          maxAmount: 500000,
        ),
        isNull,
      );
    });

    test('amounts outside range', () {
      expect(
        Validators.validateLoanAmount(
          value: '100',
          minAmount: 500,
          maxAmount: 500000,
        ),
        isNotNull,
      );
      expect(
        Validators.validateLoanAmount(
          value: '600000',
          minAmount: 500,
          maxAmount: 500000,
        ),
        isNotNull,
      );
    });
  });

  group('Validators.validateTenure', () {
    test('valid tenure', () {
      expect(
        Validators.validateTenure(
          value: '12',
          minTenure: 1,
          maxTenure: 36,
          unit: 'months',
        ),
        isNull,
      );
    });

    test('invalid tenure', () {
      expect(
        Validators.validateTenure(
          value: '0',
          minTenure: 1,
          maxTenure: 36,
          unit: 'months',
        ),
        isNotNull,
      );
      expect(
        Validators.validateTenure(
          value: '40',
          minTenure: 1,
          maxTenure: 36,
          unit: 'months',
        ),
        isNotNull,
      );
      expect(
        Validators.validateTenure(
          value: 'abc',
          minTenure: 1,
          maxTenure: 36,
          unit: 'months',
        ),
        isNotNull,
      );
    });
  });
}
