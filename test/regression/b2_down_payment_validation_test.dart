// Regression: BUGLOG B2 — down-payment validator rejected legitimate flat
// dollar amounts ($100–$9,999) because its percent/flat threshold (10000)
// disagreed with the controller's (100). A real $5,000 down payment must be
// accepted; percentages below 100 must still be accepted.
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/validators/financial_validators.dart';

void main() {
  group('B2: validateDownPayment threshold aligned to \$100', () {
    test('accepts a flat \$5,000 down payment against a \$300k price', () {
      final r = FinancialValidators.validateDownPayment(5000, 300000);
      expect(r.isValid, isTrue, reason: r.errorMessage);
    });

    test('accepts a flat \$100 down payment (boundary)', () {
      final r = FinancialValidators.validateDownPayment(100, 300000);
      expect(r.isValid, isTrue, reason: r.errorMessage);
    });

    test('still accepts a 20% down payment (percent path)', () {
      final r = FinancialValidators.validateDownPayment(20, 400000);
      expect(r.isValid, isTrue, reason: r.errorMessage);
    });

    test('rejects a flat amount that meets or exceeds the price', () {
      final r = FinancialValidators.validateDownPayment(300000, 300000);
      expect(r.isValid, isFalse);
      expect(r.errorMessage, contains('exceed'));
    });

    test('rejects a negative down payment', () {
      final r = FinancialValidators.validateDownPayment(-5, 300000);
      expect(r.isValid, isFalse);
    });
  });
}
