import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/providers/calculator_provider.dart';

void main() {
  group('CalculatorProvider - Payment Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate monthly payment - standard 30-year mortgage', () {
      provider.setLoanAmount(value: 350000);
      provider.setInterestRate();
      provider.inputDigit('5');
      provider.inputDecimal();
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      // Expected payment: $1,987.54
      expect(provider.payment, isNotNull);
      expect(provider.payment!, closeTo(1987.54, 0.01));
    });

    test('Calculate monthly payment - 15-year mortgage', () {
      provider.setLoanAmount(value: 250000);
      provider.setInterestRate();
      provider.inputDigit('4');
      provider.inputDecimal();
      provider.inputDigit('2');
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('1');
      provider.inputDigit('5');
      provider.setTermYears();

      // Expected payment: approximately $1,879
      expect(provider.payment, isNotNull);
      expect(provider.payment!, closeTo(1879, 10));
    });

    test('Calculate payment with zero interest rate shows error', () {
      provider.setLoanAmount(value: 100000);
      provider.inputDigit('0');
      provider.setInterestRate();
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.setTermYears();

      expect(provider.displayValue, 'Error');
    });

    test('Calculate payment with negative term shows error', () {
      provider.setLoanAmount(value: 100000);
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('0');
      provider.setTermYears();

      expect(provider.displayValue, 'Error');
    });
  });

  group('CalculatorProvider - Loan Amount Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate loan amount from payment', () {
      provider.inputDigit('2');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPayment();

      provider.clearAll();
      provider.inputDigit('5');
      provider.inputDecimal();
      provider.inputDigit('5');
      provider.setInterestRate();

      provider.clearAll();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      // Should calculate loan amount around $352,000
      expect(provider.loanAmount, isNotNull);
      expect(provider.loanAmount!, closeTo(352000, 1000));
    });

    test('Calculate loan amount - verify formula inverse', () {
      // First calculate payment
      provider.setLoanAmount(value: 300000);
      provider.inputDigit('6');
      provider.setInterestRate();
      provider.inputDigit('2');
      provider.inputDigit('5');
      provider.setTermYears();

      final calculatedPayment = provider.payment;

      // Now calculate loan amount from that payment
      provider.clearAll();
      provider.inputDigit(calculatedPayment!.toStringAsFixed(2));
      provider.setPayment();
      provider.inputDigit('6');
      provider.setInterestRate();
      provider.inputDigit('2');
      provider.inputDigit('5');
      provider.setTermYears();

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
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('1');
      provider.inputDigit('2');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPayment();

      // Should calculate term around 30 years
      expect(provider.termYears, isNotNull);
      expect(provider.termYears!, closeTo(30, 1));
    });

    test('Calculate term - payment too low shows error', () {
      provider.setLoanAmount(value: 200000);
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.setInterestRate();
      provider.inputDigit('5');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPayment();

      // Payment $500 with 10% interest on $200k loan won't work
      expect(provider.displayValue, 'Error');
    });
  });

  group('CalculatorProvider - Interest Rate Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate interest rate using Newton\'s method', () {
      provider.setLoanAmount(value: 300000);
      provider.inputDigit('1');
      provider.inputDigit('9');
      provider.inputDigit('8');
      provider.inputDigit('7');
      provider.inputDecimal();
      provider.inputDigit('5');
      provider.inputDigit('4');
      provider.setPayment();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      // Should calculate rate around 5.5%
      expect(provider.interestRate, isNotNull);
      expect(provider.interestRate!, closeTo(5.5, 0.1));
    });

    test('Calculate interest rate - verify convergence', () {
      provider.setLoanAmount(value: 150000);
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPayment();
      provider.inputDigit('1');
      provider.inputDigit('5');
      provider.setTermYears();

      // Should converge to a reasonable rate
      expect(provider.interestRate, isNotNull);
      expect(provider.interestRate!, greaterThan(0));
      expect(provider.interestRate!, lessThan(20));
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
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      final piPayment = provider.payment!;

      // Add property tax ($3,600/year = $300/month)
      provider.inputDigit('3');
      provider.inputDigit('6');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPropertyTax();

      // Add home insurance ($1,200/year = $100/month)
      provider.inputDigit('1');
      provider.inputDigit('2');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setHomeInsurance();

      // Add mortgage insurance ($1,800/year = $150/month)
      provider.inputDigit('1');
      provider.inputDigit('8');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setMortgageInsurance();

      // Add monthly expenses (HOA $200)
      provider.inputDigit('2');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setMonthlyExpenses();

      final expectedPiti = piPayment + 300 + 100 + 150 + 200;
      expect(provider.pitiPayment, closeTo(expectedPiti, 0.01));
    });

    test('Toggle between P&I and PITI display', () {
      provider.setLoanAmount(value: 200000);
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      final piPayment = provider.payment!;

      provider.inputDigit('3');
      provider.inputDigit('6');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPropertyTax();

      // Initially should show P&I
      expect(provider.displayMode, 'pi');

      // Toggle to PITI
      provider.togglePitiDisplay();
      expect(provider.displayMode, 'piti');
      expect(double.parse(provider.displayValue), greaterThan(piPayment));

      // Toggle back to P&I
      provider.togglePitiDisplay();
      expect(provider.displayMode, 'pi');
      expect(double.parse(provider.displayValue), closeTo(piPayment, 0.01));
    });
  });

  group('CalculatorProvider - Down Payment Calculations', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Calculate loan amount from price and percentage down payment', () {
      provider.inputDigit('4');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPrice();

      provider.inputDigit('2');
      provider.inputDigit('0');
      provider.setDownPayment(); // 20%

      // Loan amount should be 80% of $400,000 = $320,000
      expect(provider.loanAmount, closeTo(320000, 0.01));
    });

    test('Calculate loan amount from price and flat down payment', () {
      provider.inputDigit('5');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPrice();

      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setDownPayment(); // $100,000

      // Loan amount should be $500,000 - $100,000 = $400,000
      expect(provider.loanAmount, closeTo(400000, 0.01));
    });
  });

  group('CalculatorProvider - Amortization Schedule', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    test('Generate amortization schedule - verify length', () {
      provider.setLoanAmount(value: 200000);
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      provider.generateAmortizationSchedule();

      // 30 years * 12 months = 360 payments
      expect(provider.amortizationData.length, 360);
    });

    test('Amortization schedule - first payment breakdown', () {
      provider.setLoanAmount(value: 100000);
      provider.inputDigit('6');
      provider.setInterestRate();
      provider.inputDigit('1');
      provider.inputDigit('5');
      provider.setTermYears();

      provider.generateAmortizationSchedule();

      final firstPayment = provider.amortizationData[0];

      // First month interest = $100,000 * (6%/12) = $500
      expect(firstPayment.interest, closeTo(500, 1));

      // Principal should be payment - interest
      expect(firstPayment.principal, closeTo(firstPayment.payment - firstPayment.interest, 0.01));

      // Balance should decrease
      expect(firstPayment.balance, lessThan(100000));
    });

    test('Amortization schedule - final payment clears balance', () {
      provider.setLoanAmount(value: 150000);
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('2');
      provider.inputDigit('0');
      provider.setTermYears();

      provider.generateAmortizationSchedule();

      final finalPayment = provider.amortizationData.last;

      // Final balance should be zero (or very close)
      expect(finalPayment.balance, closeTo(0, 0.01));
    });

    test('Amortization schedule - total payments equal loan + interest', () {
      provider.setLoanAmount(value: 200000);
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      provider.generateAmortizationSchedule();

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
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      final balance = provider.calculateRemainingBalance(5);

      // After 5 years, should still owe most of the loan
      expect(balance, greaterThan(250000));
      expect(balance, lessThan(300000));
    });

    test('Remaining balance after full term is zero', () {
      provider.setLoanAmount(value: 200000);
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('1');
      provider.inputDigit('5');
      provider.setTermYears();

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
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      final monthlyPayment = provider.payment!;
      final biWeeklyData = provider.calculateBiWeeklyConversion();

      expect(biWeeklyData['biWeeklyPayment'], closeTo(monthlyPayment / 2, 0.01));
    });

    test('Bi-weekly conversion should save interest', () {
      provider.setLoanAmount(value: 300000);
      provider.inputDigit('5');
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

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
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();
      provider.setMonthlyDebt(value: 500);

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      // With $100k income, should qualify for a reasonable loan
      expect(provider.loanAmount, isNotNull);
      expect(provider.loanAmount!, greaterThan(100000));
      expect(provider.loanAmount!, lessThan(500000));
    });

    test('Calculate minimum required income', () {
      provider.setLoanAmount(value: 300000);
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();
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
      provider.inputDigit('5');
      provider.setInterestRate();
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      provider.clearAll();

      expect(provider.loanAmount, isNull);
      expect(provider.interestRate, isNull);
      expect(provider.termYears, isNull);
      expect(provider.payment, isNull);
      expect(provider.displayValue, '0');
    });

    test('Switching to arithmetic mode clears financial state', () {
      provider.setLoanAmount(value: 200000);
      provider.inputDigit('5');
      provider.setInterestRate();

      provider.performOperation('+');

      expect(provider.loanAmount, isNull);
      expect(provider.interestRate, isNull);
    });
  });
}
