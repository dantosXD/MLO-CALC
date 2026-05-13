import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/features/rent_vs_buy/domain/models/rent_vs_buy_calculation.dart';
import 'package:loan_ranger/src/features/rent_vs_buy/domain/services/rent_vs_buy_calculator.dart';

const _calculator = RentVsBuyCalculator();
const _loanMath = LoanMath();

RentVsBuyInputs _buildInputs({
  required double downPaymentPercent,
  required double interestRate,
  required double termYears,
  double monthlyRent = 0,
  double closingCostsPercent = 0,
  double pmiRate = 0.5,
  double analysisYears = 10,
}) {
  return RentVsBuyInputs(
    homePrice: 100000,
    downPaymentPercent: downPaymentPercent,
    interestRate: interestRate,
    termYears: termYears,
    propertyTaxRate: 0,
    homeInsuranceAnnual: 0,
    hoaMonthly: 0,
    maintenancePercent: 0,
    closingCostsPercent: closingCostsPercent,
    pmiRate: pmiRate,
    monthlyRent: monthlyRent,
    annualRentIncrease: 0,
    rentersInsuranceMonthly: 0,
    homeAppreciationRate: 0,
    investmentReturnRate: 0,
    marginalTaxRate: 0,
    analysisYears: analysisYears.round(),
  );
}

void main() {
  group('RentVsBuyCalculator', () {
    test('keeps PMI off at exactly 80% LTV and applies it at 80.01%', () {
      final exact80 = _calculator.calculate(
        _buildInputs(downPaymentPercent: 20, interestRate: 0, termYears: 30),
      );

      final over80 = _calculator.calculate(
        _buildInputs(downPaymentPercent: 19.99, interestRate: 0, termYears: 30),
      );

      expect(exact80.buyingCosts.pmi, equals(0));
      expect(over80.buyingCosts.pmi, greaterThan(0));
    });

    test('computes the expected break-even month when buying is cheaper', () {
      final result = _calculator.calculate(
        _buildInputs(
          downPaymentPercent: 20,
          interestRate: 0,
          termYears: 30,
          monthlyRent: 1000,
          closingCostsPercent: 0,
        ),
      );

      expect(result.monthlySavings, closeTo(777.78, 0.01));
      expect(result.breakEvenMonths, equals(26));
    });

    test('uses the zero-rate monthly payment path without truncation', () {
      final result = _calculator.calculate(
        _buildInputs(downPaymentPercent: 20, interestRate: 0, termYears: 30),
      );

      expect(result.buyingCosts.principalAndInterest, closeTo(222.22, 0.01));
    });

    test('preserves fractional term years end-to-end', () {
      final inputs = _buildInputs(
        downPaymentPercent: 0,
        interestRate: 6.0,
        termYears: 30.5,
      );
      final result = _calculator.calculate(inputs);
      final expected = _loanMath.calculatePayment(
        loanAmount: inputs.loanAmount,
        interestRate: 6.0,
        termYears: 30.5,
      );

      expect(result.buyingCosts.principalAndInterest, closeTo(expected, 0.01));
      expect(
        result.buyingCosts.principalAndInterest,
        isNot(
          closeTo(
            _loanMath.calculatePayment(
              loanAmount: inputs.loanAmount,
              interestRate: 6.0,
              termYears: 30,
            ),
            0.01,
          ),
        ),
      );
    });
  });
}
