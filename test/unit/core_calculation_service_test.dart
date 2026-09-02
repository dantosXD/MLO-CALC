import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/calculation_result.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';

class FakeLoanMath extends LoanMath {
  const FakeLoanMath({required this.payment});

  final double payment;

  @override
  double calculatePayment({
    required double loanAmount,
    required double interestRate,
    required double termYears,
    bool interestOnly = false,
  }) {
    return payment;
  }
}

void main() {
  group('CoreCalculationService', () {
    test('calculatePayment fails when math returns 0', () {
      final service = CoreCalculationService(const FakeLoanMath(payment: 0));

      final result = service.calculatePayment(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
      );

      expect(result, isA<CalcFailure<double>>());
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Unable to calculate payment'));
    });

    test('calculatePayment fails when math returns NaN', () {
      final service = CoreCalculationService(
        const FakeLoanMath(payment: double.nan),
      );

      final result = service.calculatePayment(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
      );

      expect(result, isA<CalcFailure<double>>());
      expect(result.isSuccess, isFalse);
    });

    test('calculatePayment fails when math returns Infinity', () {
      final service = CoreCalculationService(
        const FakeLoanMath(payment: double.infinity),
      );

      final result = service.calculatePayment(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
      );

      expect(result, isA<CalcFailure<double>>());
      expect(result.isSuccess, isFalse);
    });

    test('solveInterestRate fails at the zero-interest payment boundary', () {
      final service = CoreCalculationService(const LoanMath());
      final zeroInterestPayment = 300000 / (30 * 12);

      final result = service.solveInterestRate(
        loanAmount: 300000,
        payment: zeroInterestPayment,
        termYears: 30,
      );

      expect(result, isA<CalcFailure<double>>());
      expect(result.error, contains('Payment too low'));
    });

    test('calculatePayment succeeds with cents rounding on valid math', () {
      final service = CoreCalculationService(const LoanMath());
      final result = service.calculatePayment(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
      );

      expect(result, isA<CalcSuccess<double>>());
      expect(result.value, equals(2661.21));
    });

    test('calculateInterestOnlyPayment succeeds and rounds to cents', () {
      final service = CoreCalculationService(const LoanMath());
      final result = service.calculateInterestOnlyPayment(
        loanAmount: 400000,
        interestRate: 6.0,
      );

      expect(result, isA<CalcSuccess<double>>());
      expect(result.value, equals(2000.00));
    });

    test('calculateInterestOnlyPayment fails on non-positive inputs', () {
      final service = CoreCalculationService(const LoanMath());
      final result = service.calculateInterestOnlyPayment(
        loanAmount: 0,
        interestRate: 6.0,
      );

      expect(result, isA<CalcFailure<double>>());
      expect(result.error, contains('Unable to calculate interest-only payment'));
    });

    test('calculateLoanAmount succeeds and rounds to cents', () {
      final service = CoreCalculationService(const LoanMath());
      final result = service.calculateLoanAmount(
        payment: 2661.21,
        interestRate: 7.0,
        termYears: 30,
      );

      expect(result, isA<CalcSuccess<double>>());
      expect(result.value, closeTo(400000.0, 1.0));
    });

    test('calculateTerm succeeds and returns loan term in years', () {
      final service = CoreCalculationService(const LoanMath());
      final result = service.calculateTerm(
        loanAmount: 400000,
        payment: 2661.21,
        interestRate: 7.0,
      );

      expect(result, isA<CalcSuccess<double>>());
      expect(result.value, closeTo(30.0, 0.05));
    });

    test('calculateTerm fails when payment is too low to pay interest', () {
      final service = CoreCalculationService(const LoanMath());
      final result = service.calculateTerm(
        loanAmount: 400000,
        payment: 2000, // Monthly interest at 7% is ~2333
        interestRate: 7.0,
      );

      expect(result, isA<CalcFailure<double>>());
      expect(result.error, contains('Payment too low'));
    });

    test('solveInterestRate converges to expected rate', () {
      final service = CoreCalculationService(const LoanMath());
      final result = service.solveInterestRate(
        loanAmount: 400000,
        payment: 2661.21,
        termYears: 30,
      );

      expect(result, isA<CalcSuccess<double>>());
      expect(result.value, closeTo(7.0, 0.01));
    });
  });
}
