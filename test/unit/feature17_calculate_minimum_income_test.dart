import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  group('Feature #17: Calculate Minimum Required Income', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate minimum income with standard inputs', () {
      // Arrange: Set up a typical loan scenario
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      // Act: Calculate minimum income
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require significant income for $300k loan
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, greaterThan(0));

      // Verify it's a reasonable amount (at least $50k/year for $300k loan)
      expect(provider.annualIncome!, greaterThan(50000));
    });

    test('Calculate minimum income with high loan amount', () {
      // Arrange: Large loan requiring high income
      provider.setLoanAmount(value: 600000);
      provider.setInterestRate(value: 6.5);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 1000);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require very high income
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, greaterThan(100000));
    });

    test('Calculate minimum income with low loan amount', () {
      // Arrange: Small loan requiring lower income
      provider.setLoanAmount(value: 150000);
      provider.setInterestRate(value: 5.5);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 200);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require lower income
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, lessThan(60000));
    });

    test('Calculate minimum income with high existing debt', () {
      // Arrange: Loan with significant monthly debt
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 2000); // High debt

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require higher income due to debt
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, greaterThan(60000));
    });

    test('Calculate minimum income with zero existing debt', () {
      // Arrange: Loan with no other debt
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 0);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require lower income without debt
      expect(provider.annualIncome, isNotNull);
      // Payment is ~$1,799, so front-end DTI: 1799 / 0.28 * 12 ≈ $77,085
      expect(provider.annualIncome!, greaterThan(75000));
      expect(provider.annualIncome!, lessThan(80000));
    });

    test('Calculate minimum income with 15-year term', () {
      // Arrange: Shorter term = higher payments = higher income needed
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 5.5);
      provider.setTermYears(value: 15);
      provider.setMonthlyDebt(value: 500);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require higher income due to higher payments
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, greaterThan(60000));
    });

    test('Calculate minimum income with FHA ratio (31/43)', () {
      // Arrange: Use FHA ratios
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);
      provider.setQualRatio2(QualifyingRatio(
        id: 'fha',
        name: 'FHA',
        housingRatio: 31,
        debtRatio: 43,
      ));

      // Act: Use ratio 2 (FHA)
      provider.calculateMinimumIncome(useRatio1: false);

      // Assert: Should calculate income with FHA ratios
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, greaterThan(0));
    });

    test('Error when loan amount is missing', () {
      // Arrange: Missing loan amount
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should have error
      expect(provider.inputError, isNotNull);
      expect(provider.inputError, contains('Need L/A, Rate, Term'));
      expect(provider.annualIncome, isNull);
    });

    test('Error when interest rate is missing', () {
      // Arrange: Missing interest rate
      provider.setLoanAmount(value: 300000);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should have error
      expect(provider.inputError, isNotNull);
      expect(provider.inputError, contains('Need L/A, Rate, Term'));
    });

    test('Error when term is missing', () {
      // Arrange: Missing term
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setMonthlyDebt(value: 500);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should have error
      expect(provider.inputError, isNotNull);
      expect(provider.inputError, contains('Need L/A, Rate, Term'));
    });

    test('Calculate minimum income with very low interest rate', () {
      // Arrange: Low rate = lower payment = lower income needed
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 3.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require lower income with lower rate
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, lessThan(60000));
    });

    test('Calculate minimum income with very high interest rate', () {
      // Arrange: High rate = higher payment = higher income needed
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 9.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require higher income with higher rate
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, greaterThan(70000));
    });

    test('Calculate minimum income with short term (10 years)', () {
      // Arrange: Very short term
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 10);
      provider.setMonthlyDebt(value: 500);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require very high income
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, greaterThan(80000));
    });

    test('Calculate minimum income with long term (40 years)', () {
      // Arrange: Long term
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 40);
      provider.setMonthlyDebt(value: 500);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require lower income with longer term
      expect(provider.annualIncome, isNotNull);
      // Longer term reduces payment, but not drastically
      expect(provider.annualIncome!, greaterThan(65000));
      expect(provider.annualIncome!, lessThan(75000));
    });

    test('Verify front-end DTI constraint is used correctly', () {
      // This test verifies the mathematical formula:
      // minIncomeFront = (pitiPayment / (housingRatio / 100)) * 12

      // Arrange
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 0); // Zero debt to isolate front-end DTI

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should use front-end ratio (28%)
      expect(provider.annualIncome, isNotNull);

      // Manual verification: Payment ≈ $1,799 for $300k at 6% for 30 years
      // Front-end DTI: 1799 / 0.28 ≈ $6,425/month = $77,100/year
      // Our result should be close to this
      expect(provider.annualIncome!, greaterThan(75000));
      expect(provider.annualIncome!, lessThan(85000));
    });

    test('Verify back-end DTI constraint is used when debt is high', () {
      // This test verifies that back-end DTI takes precedence when debt is high
      // minIncomeBack = ((pitiPayment + monthlyDebt) / (debtRatio / 100)) * 12

      // Arrange
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 3000); // Very high debt

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should use back-end ratio (36%) due to high debt
      expect(provider.annualIncome, isNotNull);

      // With $3k debt + $1.8k payment = $4.8k total
      // Back-end DTI: 4800 / 0.36 ≈ $13,333/month = $160,000/year
      expect(provider.annualIncome!, greaterThan(140000));
    });

    test('Minimum income calculation uses MAX of front-end and back-end constraints', () {
      // The service should return the higher of the two constraints
      // This ensures the borrower qualifies under BOTH ratios

      // Arrange
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 1000);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert: Should require income to satisfy both ratios
      expect(provider.annualIncome, isNotNull);

      // Payment ≈ $1,799
      // Front-end: 1799 / 0.28 * 12 ≈ $77,100
      // Back-end: (1799 + 1000) / 0.36 * 12 ≈ $92,630
      // Should use the higher value (back-end in this case)
      expect(provider.annualIncome!, greaterThan(90000));
    });

    test('Calculate minimum income - income updates after calculation', () {
      // Verify that the annualIncome field is actually updated
      // Arrange
      provider.setLoanAmount(value: 250000);
      provider.setInterestRate(value: 5.5);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 300);

      // Act
      provider.calculateMinimumIncome(useRatio1: true);

      // Assert
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, greaterThan(0));
      // The income should be persisted in the provider state
      final calculatedIncome = provider.annualIncome;
      expect(calculatedIncome, isNotNull);
    });
  });
}
