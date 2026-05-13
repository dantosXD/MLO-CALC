import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';

CalculatorProvider buildCalculatorProvider() {
  return CalculatorProvider(
    coreCalculationService: serviceLocator<CoreCalculationService>(),
    amortizationService: serviceLocator<AmortizationService>(),
    qualificationService: serviceLocator<QualificationService>(),
    persistenceService: serviceLocator<CalculatorPersistenceService>(),
  );
}

/// Comprehensive test suite for Feature #16: Calculate Maximum Qualifying Loan
///
/// This test file provides detailed verification of the maximum qualifying
/// loan calculation functionality, including edge cases and mathematical
/// correctness.
void main() {
  setUpAll(() async {
    await configureDependencies();
  });
  group('Feature #16: Maximum Qualifying Loan Calculation', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = buildCalculatorProvider();
    });

    test('Calculate max loan with standard inputs', () {
      // Standard scenario: \$100k income, 5% rate, 30-year term
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(
        provider.loanAmount!,
        greaterThan(400000),
        reason: 'Should qualify for >\$400k',
      );
      expect(
        provider.loanAmount!,
        lessThan(450000),
        reason: 'Should qualify for <\$450k',
      );
      expect(provider.payment, isNotNull);
      expect(
        provider.payment!,
        greaterThan(0),
        reason: 'Should have positive payment',
      );
    });

    test('Calculate max loan with high income', () {
      // High income scenario
      provider.setAnnualIncome(value: 250000);
      provider.setInterestRate(value: 6.5);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 1000);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(
        provider.loanAmount!,
        greaterThan(900000),
        reason: 'Should qualify for >\$900k with \$250k income at 6.5%',
      );
      expect(provider.payment, isNotNull);
    });

    test('Calculate max loan with low income', () {
      // Low income scenario
      provider.setAnnualIncome(value: 40000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 200);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(
        provider.loanAmount!,
        lessThan(200000),
        reason: 'Should qualify for <\$200k with \$40k income',
      );
      expect(provider.payment, isNotNull);
    });

    test('Calculate max loan with high existing debt', () {
      // High debt scenario - debt limits qualifying amount
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 2000);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      // With \$2000 monthly debt, should qualify for LESS than with \$500 debt
      expect(
        provider.loanAmount!,
        lessThan(380000),
        reason: 'High debt should reduce qualifying amount',
      );
      expect(provider.payment, isNotNull);
    });

    test('Calculate max loan with zero existing debt', () {
      // No debt scenario - should qualify for more
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 0);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      // With \$0 debt, should qualify for MORE than with \$500 debt
      expect(
        provider.loanAmount!,
        greaterThan(430000),
        reason: 'No debt should increase qualifying amount',
      );
      expect(provider.payment, isNotNull);
    });

    test('Calculate max loan with 15-year term', () {
      // Shorter term = higher payments = lower qualifying amount
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 15);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(
        provider.loanAmount!,
        lessThan(350000),
        reason: '15-year term should reduce qualifying amount',
      );
      expect(provider.payment, isNotNull);
    });

    test('Calculate max loan with higher interest rate', () {
      // Higher rate = higher payments = lower qualifying amount
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 7.5);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(
        provider.loanAmount!,
        lessThan(380000),
        reason: '7.5% rate should reduce qualifying amount',
      );
      expect(provider.payment, isNotNull);
    });

    test('Calculate max loan with FHA ratio (31/43)', () {
      // FHA allows higher DTI ratios
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      // Set FHA ratio
      provider.setQualRatio1(
        const QualifyingRatio(
          id: 'fha',
          name: 'FHA',
          housingRatio: 31,
          debtRatio: 43,
          isBuiltIn: true,
        ),
      );

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      // FHA (31/43) should allow MORE than conventional (28/36)
      expect(
        provider.loanAmount!,
        greaterThan(470000),
        reason: 'FHA ratios should allow higher loan amount',
      );
      expect(provider.payment, isNotNull);
    });

    test('Error when annual income is missing', () {
      // Missing income
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      // Should not crash, but loan amount should remain null
      expect(provider.loanAmount, isNull);
    });

    test('Error when interest rate is missing', () {
      // Missing rate
      provider.setAnnualIncome(value: 100000);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNull);
    });

    test('Error when term is missing', () {
      // Missing term
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNull);
    });

    test('Verify DTI constraint calculation (mathematical correctness)', () {
      // Specific test to verify DTI formulas
      provider.setAnnualIncome(value: 120000); // \$10,000/month
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 1000);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(provider.payment, isNotNull);

      // Verify payment doesn't exceed housing ratio
      final monthlyIncome = 120000 / 12; // \$10,000
      final maxHousingPayment =
          monthlyIncome * 0.28; // \$2,800 (28% housing ratio)

      expect(
        provider.payment!,
        lessThanOrEqualTo(maxHousingPayment),
        reason: 'Payment should not exceed 28% housing ratio',
      );

      // Verify total debt doesn't exceed back-end ratio
      final totalDebt = provider.payment! + 1000; // Payment + existing debt
      final maxTotalDebt = monthlyIncome * 0.36; // \$3,600 (36% debt ratio)

      expect(
        totalDebt,
        lessThanOrEqualTo(maxTotalDebt),
        reason: 'Total debt should not exceed 36% back-end ratio',
      );
    });

    test('History entry is created after calculation', () {
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      // Verify history was updated
      expect(provider.history.entries, isNotEmpty);
      expect(provider.history.entries.length, greaterThan(0));

      // Most recent entry should be a qualification type
      final latestEntry = provider.history.entries.last;
      expect(latestEntry.type, CalculationEntryType.qualification);
      expect(latestEntry.results['maxLoanAmount'], provider.loanAmount);
    });
  });

  group('Feature #16: Edge Cases and Boundaries', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = buildCalculatorProvider();
    });

    test('Very low interest rate (1%)', () {
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 1.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(
        provider.loanAmount!,
        greaterThan(550000),
        reason: 'Low rate should increase qualifying amount',
      );
    });

    test('Very high interest rate (10%)', () {
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 10.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(
        provider.loanAmount!,
        lessThan(280000),
        reason: 'High rate should decrease qualifying amount',
      );
    });

    test('Short term (10 years)', () {
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 10);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(
        provider.loanAmount!,
        lessThan(250000),
        reason: '10-year term should significantly reduce qualifying amount',
      );
    });

    test('Long term (40 years)', () {
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 40);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(
        provider.loanAmount!,
        greaterThan(450000),
        reason: '40-year term should increase qualifying amount',
      );
    });

    test('Income with cents', () {
      provider.setAnnualIncome(value: 98765.43);
      provider.setInterestRate(value: 5.5);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500.25);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(provider.payment, isNotNull);
    });

    test('Zero monthly debt', () {
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 0);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
    });
  });
}
