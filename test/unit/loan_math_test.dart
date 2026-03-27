import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';

void main() {
  const loanMath = LoanMath();

  group('LoanMath', () {
    test('calculatePayment returns the known reference value', () {
      final payment = loanMath.calculatePayment(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
      );

      expect(payment, closeTo(2661.21, 0.01));
    });

    test('calculatePayment returns 0 for zero loan amount without throwing', () {
      final payment = loanMath.calculatePayment(
        loanAmount: 0,
        interestRate: 7.0,
        termYears: 30,
      );

      expect(payment, equals(0));
    });

    test('calculateInterestRate converges for a known payment', () {
      final payment = loanMath.calculatePayment(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
      );

      final rate = loanMath.calculateInterestRate(
        loanAmount: 400000,
        payment: payment,
        termYears: 30,
      );

      expect(rate, closeTo(7.0, 0.01));
    });

    test('calculateInterestRate handles the zero-interest boundary', () {
      final zeroInterestPayment = 300000 / (30 * 12);

      final rate = loanMath.calculateInterestRate(
        loanAmount: 300000,
        payment: zeroInterestPayment,
        termYears: 30,
      );

      expect(rate, greaterThanOrEqualTo(0));
      expect(rate, lessThan(0.05));
    });
  });
}
