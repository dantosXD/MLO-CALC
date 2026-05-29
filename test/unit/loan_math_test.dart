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

    test(
      'calculatePayment returns 0 for zero loan amount without throwing',
      () {
        final payment = loanMath.calculatePayment(
          loanAmount: 0,
          interestRate: 7.0,
          termYears: 30,
        );

        expect(payment, equals(0));
      },
    );

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

  group('LoanMath edge cases', () {
    const math = LoanMath();

    test(
      'calculatePayment with zero interest rate returns 0 (guard clause)',
      () {
        // The production guard `interestRate <= 0` returns 0 for zero rate.
        final payment = math.calculatePayment(
          loanAmount: 120000,
          interestRate: 0.0,
          termYears: 10,
        );
        expect(payment, equals(0.0));
      },
    );

    test(
      'calculatePayment with interestOnly flag returns loanAmount * monthlyRate',
      () {
        // 400000 * (6.0 / 100 / 12) = 2000.0
        final payment = math.calculatePayment(
          loanAmount: 400000,
          interestRate: 6.0,
          termYears: 30,
          interestOnly: true,
        );
        expect(payment, closeTo(2000.0, 0.01));
      },
    );

    test('calculateInterestOnlyPayment returns loanAmount * monthlyRate', () {
      // 400000 * (6.0 / 100 / 12) = 2000.0
      final payment = math.calculateInterestOnlyPayment(
        loanAmount: 400000,
        interestRate: 6.0,
      );
      expect(payment, closeTo(2000.0, 0.01));
    });

    test('calculatePayment with very large loan amount does not overflow', () {
      final payment = math.calculatePayment(
        loanAmount: 10000000, // $10M
        interestRate: 7.0,
        termYears: 30,
      );
      expect(payment.isFinite, isTrue);
      expect(payment, greaterThan(0));
    });

    test('calculateTerm returns finite years for standard inputs', () {
      // calculateTerm returns years; with a sufficient payment it should converge.
      final years = math.calculateTerm(
        loanAmount: 300000,
        interestRate: 7.0,
        payment: 2000,
      );
      expect(years.isFinite, isTrue);
      expect(years, greaterThan(0));
    });
  });
}
