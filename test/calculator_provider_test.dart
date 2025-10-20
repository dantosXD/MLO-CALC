import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/providers/calculator_provider.dart';
import 'dart:math';

void main() {
  group('CalculatorProvider - Payment Calculation', () {
    test('Calculate monthly payment correctly', () {
      final provider = CalculatorProvider();

      // Set loan amount: $300,000
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setLoanAmount();

      // Set interest rate: 5%
      provider.inputDigit('5');
      provider.setInterestRate();

      // Set term: 30 years
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      // Expected payment calculation
      final p = 300000.0;
      final r = 5.0 / 100 / 12;
      final n = 30.0 * 12;
      final expectedPayment = p * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);

      expect(provider.payment, isNotNull);
      expect(provider.payment, closeTo(expectedPayment, 0.01));
    });

    test('Calculate loan amount from payment', () {
      final provider = CalculatorProvider();

      // Set payment: $1,610.46
      provider.inputDigit('1');
      provider.inputDigit('6');
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.inputDecimal();
      provider.inputDigit('4');
      provider.inputDigit('6');
      provider.setPayment();

      // Set interest rate: 5%
      provider.inputDigit('5');
      provider.setInterestRate();

      // Set term: 30 years
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      expect(provider.loanAmount, isNotNull);
      expect(provider.loanAmount, closeTo(300000, 1));
    });

    test('Calculate term from loan amount and payment', () {
      final provider = CalculatorProvider();

      // Set loan amount: $300,000
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setLoanAmount();

      // Set interest rate: 5%
      provider.inputDigit('5');
      provider.setInterestRate();

      // Set payment: $1,610.46
      provider.inputDigit('1');
      provider.inputDigit('6');
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.inputDecimal();
      provider.inputDigit('4');
      provider.inputDigit('6');
      provider.setPayment();

      expect(provider.termYears, isNotNull);
      expect(provider.termYears, closeTo(30, 0.1));
    });

    test('Calculate interest rate from loan amount, payment, and term', () {
      final provider = CalculatorProvider();

      // Set loan amount: $300,000
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setLoanAmount();

      // Set payment: $1,610.46
      provider.inputDigit('1');
      provider.inputDigit('6');
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.inputDecimal();
      provider.inputDigit('4');
      provider.inputDigit('6');
      provider.setPayment();

      // Set term: 30 years
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      expect(provider.interestRate, isNotNull);
      expect(provider.interestRate, closeTo(5.0, 0.01));
    });
  });

  group('CalculatorProvider - Arithmetic Operations', () {
    test('Addition', () {
      final provider = CalculatorProvider();
      provider.inputDigit('5');
      provider.performOperation('+');
      provider.inputDigit('3');
      provider.calculateResult();
      expect(provider.displayValue, '8');
    });

    test('Subtraction', () {
      final provider = CalculatorProvider();
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.performOperation('-');
      provider.inputDigit('3');
      provider.calculateResult();
      expect(provider.displayValue, '7');
    });

    test('Multiplication', () {
      final provider = CalculatorProvider();
      provider.inputDigit('6');
      provider.performOperation('x');
      provider.inputDigit('7');
      provider.calculateResult();
      expect(provider.displayValue, '42');
    });

    test('Division', () {
      final provider = CalculatorProvider();
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.performOperation('/');
      provider.inputDigit('2');
      provider.calculateResult();
      expect(provider.displayValue, '5');
    });

    test('Division by zero shows error', () {
      final provider = CalculatorProvider();
      provider.inputDigit('5');
      provider.performOperation('/');
      provider.inputDigit('0');
      provider.calculateResult();
      expect(provider.displayValue, 'Error');
    });
  });

  group('CalculatorProvider - PITI Calculations', () {
    test('Calculate PITI payment', () {
      final provider = CalculatorProvider();

      // Set loan amount and calculate payment
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setLoanAmount();

      provider.inputDigit('5');
      provider.setInterestRate();

      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      final piPayment = provider.payment!;

      // Set property tax: $3,600/year
      provider.inputDigit('3');
      provider.inputDigit('6');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPropertyTax();

      // Set home insurance: $1,200/year
      provider.inputDigit('1');
      provider.inputDigit('2');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setHomeInsurance();

      // Calculate PITI
      final expectedPITI = piPayment + (3600 / 12) + (1200 / 12);

      expect(provider.pitiPayment, closeTo(expectedPITI, 0.01));
    });

    test('Auto-calculate loan amount from price and down payment percentage', () {
      final provider = CalculatorProvider();

      // Set price: $400,000
      provider.inputDigit('4');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPrice();

      // Set down payment: 20% (value < 100 treated as percentage)
      provider.inputDigit('2');
      provider.inputDigit('0');
      provider.setDownPayment();

      // Expected loan amount: $400,000 - 20% = $320,000
      expect(provider.loanAmount, closeTo(320000, 0.01));
    });

    test('Auto-calculate loan amount from price and down payment amount', () {
      final provider = CalculatorProvider();

      // Set price: $400,000
      provider.inputDigit('4');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setPrice();

      // Set down payment: $80,000 (value >= 100 treated as amount)
      provider.inputDigit('8');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setDownPayment();

      // Expected loan amount: $400,000 - $80,000 = $320,000
      expect(provider.loanAmount, closeTo(320000, 0.01));
    });
  });

  group('CalculatorProvider - Amortization Schedule', () {
    test('Generate amortization schedule', () {
      final provider = CalculatorProvider();

      // Set up a simple loan
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setLoanAmount();

      provider.inputDigit('5');
      provider.setInterestRate();

      provider.inputDigit('5');
      provider.setTermYears();

      provider.generateAmortizationSchedule();

      expect(provider.amortizationData, isNotEmpty);
      expect(provider.amortizationData.length, equals(60)); // 5 years * 12 months

      // Check first payment
      final firstEntry = provider.amortizationData.first;
      expect(firstEntry.month, equals(1));
      expect(firstEntry.balance, lessThan(100000));

      // Check last payment
      final lastEntry = provider.amortizationData.last;
      expect(lastEntry.month, equals(60));
      expect(lastEntry.balance, closeTo(0, 0.01)); // Should be paid off
    });

    test('Calculate remaining balance (balloon payment)', () {
      final provider = CalculatorProvider();

      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setLoanAmount();

      provider.inputDigit('5');
      provider.setInterestRate();

      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.setTermYears();

      // Calculate remaining balance after 5 years
      final balance = provider.calculateRemainingBalance(5);

      expect(balance, greaterThan(0));
      expect(balance, lessThan(100000));
    });
  });

  group('CalculatorProvider - Qualification Calculations', () {
    test('Calculate maximum qualifying loan amount', () {
      final provider = CalculatorProvider();

      // Set annual income: $100,000
      provider.inputDigit('1');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setAnnualIncome();

      // Set monthly debt: $500
      provider.inputDigit('5');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setMonthlyDebt();

      // Set rate and term
      provider.inputDigit('5');
      provider.setInterestRate();

      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      provider.calculateMaxQualifyingLoan(useRatio1: true);

      expect(provider.loanAmount, isNotNull);
      expect(provider.loanAmount, greaterThan(0));
    });

    test('Calculate minimum required income', () {
      final provider = CalculatorProvider();

      // Set loan amount: $300,000
      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setLoanAmount();

      // Set rate and term
      provider.inputDigit('5');
      provider.setInterestRate();

      provider.inputDigit('3');
      provider.inputDigit('0');
      provider.setTermYears();

      // Set monthly debt
      provider.inputDigit('5');
      provider.inputDigit('0');
      provider.inputDigit('0');
      provider.setMonthlyDebt();

      provider.calculateMinimumIncome(useRatio1: true);

      expect(provider.annualIncome, isNotNull);
      expect(provider.annualIncome, greaterThan(0));
    });
  });
}
