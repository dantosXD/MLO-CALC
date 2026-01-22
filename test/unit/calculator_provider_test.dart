import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';

void main() {
  setUpAll(() async {
    await configureDependencies();
  });
  group('CalculatorProvider - Payment Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate monthly payment - standard 30-year mortgage', () {
      provider.setLoanAmount(value: 350000);
      provider.setInterestRate(value: 5.5);
      provider.setTermYears(value: 30);

      // Expected payment: $1,987.26 (correct calculation for 350k @ 5.5% for 30 years)
      expect(provider.payment, isNotNull);
      expect(provider.payment!, closeTo(1987.26, 0.01));
    });

    test('Calculate monthly payment - 15-year mortgage', () {
      provider.setLoanAmount(value: 250000);
      provider.setInterestRate(value: 4.25);
      provider.setTermYears(value: 15);

      // Expected payment: approximately $1,879
      expect(provider.payment, isNotNull);
      expect(provider.payment!, closeTo(1879, 10));
    });

    test('Calculate payment with zero interest rate shows error', () {
      provider.setLoanAmount(value: 100000);
      provider.setInterestRate(value: 0);
      
      // Error should be shown immediately after invalid interest rate
      expect(provider.inputError, contains('positive'));
    });

    test('Calculate payment with negative term shows error', () {
      provider.setLoanAmount(value: 100000);
      provider.setInterestRate(value: 5);
      provider.setTermYears(value: 0);

      // Error should be shown immediately after invalid term
      expect(provider.inputError, contains('positive'));
    });
  });

  group('CalculatorProvider - Loan Amount Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate loan amount from payment', () {
      provider.setPayment(value: 2000);
      provider.setInterestRate(value: 5.5);
      provider.setTermYears(value: 30);

      // Should calculate loan amount around $352,000
      expect(provider.loanAmount, isNotNull);
      expect(provider.loanAmount!, closeTo(352000, 1000));
    });

    test('Calculate loan amount - verify formula inverse', () {
      // First calculate payment
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 6.25);
      provider.setTermYears(value: 30);

      final calculatedPayment = provider.payment;
      expect(calculatedPayment, isNotNull);

      // Now calculate loan amount from that payment
      provider.clearAll();
      
      provider.setPayment(value: calculatedPayment);
      provider.setInterestRate(value: 6.25);
      provider.setTermYears(value: 30);

      // Should get back original loan amount
      expect(provider.loanAmount, closeTo(300000, 1));
    });
  });

  group('CalculatorProvider - Term Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate term from loan amount and payment', () {
      provider.setLoanAmount(value: 200000);
      provider.setInterestRate(value: 5.0);
      provider.setPayment(value: 1074); // Approx payment for 30 years

      // Should calculate term around 30 years
      expect(provider.termYears, isNotNull);
      expect(provider.termYears!, closeTo(30, 1));
    });

    test('Calculate term - payment too low shows error', () {
      provider.setLoanAmount(value: 200000);
      provider.setInterestRate(value: 10);
      provider.setPayment(value: 500);

      // Payment $500 with 10% interest on $200k loan won't work
      // Interest only payment is 200000 * 0.10 / 12 = 1666.66
      // It might not return a result or might set an error
      // The current implementation sets error in result but doesn't set termYears
      expect(provider.termYears, isNull);
      // In the new implementation we might not surface the error via inputError unless we validate manually
      // But _calculateTerm sets _calculationError
      // Let's check _calculationError via inputError getter
      expect(provider.inputError, isNotNull);
    });
  });

  group('CalculatorProvider - Interest Rate Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate interest rate using Newton\'s method', () {
      provider.setLoanAmount(value: 300000);
      provider.setPayment(value: 1703);
      provider.setTermYears(value: 30);

      // Should calculate rate around 5.5%
      expect(provider.interestRate, isNotNull);
      expect(provider.interestRate!, closeTo(5.5, 0.1));
    });

    test('Calculate interest rate - verify convergence', () {
      provider.setLoanAmount(value: 150000);
      provider.setPayment(value: 1000);
      provider.setTermYears(value: 15);

      // Should converge to a reasonable rate
      expect(provider.interestRate, isNotNull);
      expect(provider.interestRate!, greaterThan(0));
      expect(provider.interestRate!, lessThan(20));
    });

    test('Interest rate solver surfaces payment too low error', () {
      provider.setLoanAmount(value: 250000);
      provider.setTermYears(value: 30);
      provider.setPayment(value: 500);

      provider.calculate();

      expect(provider.inputError, contains('Payment too low'));
    });
  });

  group('CalculatorProvider - PITI Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate PITI payment with all components', () {
      // Set up loan calculation first
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);

      final piPayment = provider.payment!;

      // Add property tax ($3,600/year = $300/month)
      provider.setPropertyTax(value: 3600);

      // Add home insurance ($1,200/year = $100/month)
      provider.setHomeInsurance(value: 1200);

      // Add mortgage insurance ($1,800/year = $150/month)
      provider.setMortgageInsurance(value: 1800);

      // Add monthly expenses (HOA $200)
      provider.setMonthlyExpenses(value: 200);

      final expectedPiti = piPayment + 300 + 100 + 150 + 200;
      expect(provider.pitiPayment, closeTo(expectedPiti, 0.01));
    });
  });

  group('CalculatorProvider - Down Payment Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate loan amount from price and percentage down payment', () {
      provider.setPrice(value: 400000);
      provider.setDownPayment(value: 20); // 20%

      // Loan amount should be 80% of $400,000 = $320,000
      expect(provider.loanAmount, closeTo(320000, 0.01));
    });

    test('Calculate loan amount from price and flat down payment', () {
      provider.setPrice(value: 500000);
      provider.setDownPayment(value: 100000); // $100,000

      // Loan amount should be $500,000 - $100,000 = $400,000
      expect(provider.loanAmount, closeTo(400000, 0.01));
    });
  });

  group('CalculatorProvider - Amortization Schedule', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Generate amortization schedule - verify length', () async {
      provider.setLoanAmount(value: 200000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);

      await provider.generateAmortizationSchedule();

      // 30 years * 12 months = 360 payments
      expect(provider.amortizationData.length, 360);
    });

    test('Amortization schedule - first payment breakdown', () async {
      provider.setLoanAmount(value: 100000);
      provider.setInterestRate(value: 6.0);
      provider.setTermYears(value: 15);

      await provider.generateAmortizationSchedule();

      final firstPayment = provider.amortizationData[0];

      // First month interest = $100,000 * (6%/12) = $500
      expect(firstPayment.interest, closeTo(500, 1));

      // Principal should be payment - interest
      expect(firstPayment.principal, closeTo(firstPayment.payment - firstPayment.interest, 0.01));

      // Balance should decrease
      expect(firstPayment.balance, lessThan(100000));
    });

    test('Amortization schedule - final payment clears balance', () async {
      provider.setLoanAmount(value: 150000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 20);

      await provider.generateAmortizationSchedule();

      final finalPayment = provider.amortizationData.last;

      // Final balance should be zero (or very close)
      expect(finalPayment.balance, closeTo(0, 0.01));
    });

    test('Amortization schedule - total payments equal loan + interest', () async {
      provider.setLoanAmount(value: 200000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);

      await provider.generateAmortizationSchedule();

      double totalPrincipal = 0;
      double totalInterest = 0;

      for (var entry in provider.amortizationData) {
        totalPrincipal += entry.principal;
        totalInterest += entry.interest;
      }

      // Total principal should equal loan amount
      expect(totalPrincipal, closeTo(200000, 1));

      // Total interest should be positive
      expect(totalInterest, greaterThan(0));
    });
  });

  group('CalculatorProvider - Remaining Balance (Balloon)', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate remaining balance after 5 years', () {
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);

      final balance = provider.calculateRemainingBalance(5);

      // After 5 years, should still owe most of the loan
      expect(balance, greaterThan(250000));
      expect(balance, lessThan(300000));
    });

    test('Remaining balance after full term is zero', () {
      provider.setLoanAmount(value: 200000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 15);

      final balance = provider.calculateRemainingBalance(15);

      expect(balance, closeTo(0, 10));
    });
  });

  group('CalculatorProvider - Bi-Weekly Conversion', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Bi-weekly payment should be half of monthly', () {
      provider.setLoanAmount(value: 250000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);

      final monthlyPayment = provider.payment!;
      final biWeeklyData = provider.calculateBiWeeklyConversion();

      expect(biWeeklyData['biWeeklyPayment'], closeTo(monthlyPayment / 2, 0.01));
    });

    test('Bi-weekly conversion should save interest', () {
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 5.5);
      provider.setTermYears(value: 30);

      final biWeeklyData = provider.calculateBiWeeklyConversion();

      // Should save interest
      expect(biWeeklyData['interestSaved'], greaterThan(0));

      // Should pay off faster
      expect(biWeeklyData['newTermYears'], lessThan(30));
    });
  });

  group('CalculatorProvider - Qualification Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate maximum qualifying loan amount', () {
      provider.setAnnualIncome(value: 100000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      // With $100k income, should qualify for a reasonable loan
      expect(provider.loanAmount, isNotNull);
      expect(provider.loanAmount!, greaterThan(100000));
      expect(provider.loanAmount!, lessThan(500000));
    });

    test('Calculate minimum required income', () {
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);
      provider.setMonthlyDebt(value: 500);

      provider.calculateMinimumIncome(useRatio1: true);

      // Should require significant income for $300k loan
      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome!, greaterThan(50000));
    });
  });

  group('CalculatorProvider - Edge Cases', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Clear all resets all state', () {
      provider.setLoanAmount(value: 300000);
      provider.setInterestRate(value: 5.0);
      provider.setTermYears(value: 30);

      provider.clearAll();

      expect(provider.loanAmount, isNull);
      expect(provider.interestRate, isNull);
      expect(provider.termYears, isNull);
      expect(provider.payment, isNull);
    });
  });
}
