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
  });
}
