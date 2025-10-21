import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/validators/financial_validators.dart';

void main() {
  group('FinancialValidators - Interest Rate', () {
    test('Valid interest rates pass validation', () {
      expect(FinancialValidators.validateInterestRate(0.1).isValid, isTrue);
      expect(FinancialValidators.validateInterestRate(5.5).isValid, isTrue);
      expect(FinancialValidators.validateInterestRate(30).isValid, isTrue);
    });

    test('Null interest rate fails', () {
      final result = FinancialValidators.validateInterestRate(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('required'));
    });

    test('Negative interest rate fails', () {
      final result = FinancialValidators.validateInterestRate(-1);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('positive'));
    });

    test('Zero interest rate fails', () {
      final result = FinancialValidators.validateInterestRate(0);
      expect(result.isValid, isFalse);
    });

    test('Too low interest rate fails', () {
      final result = FinancialValidators.validateInterestRate(0.05);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('too low'));
    });

    test('Too high interest rate fails', () {
      final result = FinancialValidators.validateInterestRate(35);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('too high'));
    });
  });

  group('FinancialValidators - Loan Amount', () {
    test('Valid loan amounts pass validation', () {
      expect(FinancialValidators.validateLoanAmount(1000).isValid, isTrue);
      expect(FinancialValidators.validateLoanAmount(250000).isValid, isTrue);
      expect(FinancialValidators.validateLoanAmount(100000000).isValid, isTrue);
    });

    test('Null loan amount fails', () {
      final result = FinancialValidators.validateLoanAmount(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('required'));
    });

    test('Too low loan amount fails', () {
      final result = FinancialValidators.validateLoanAmount(500);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('too low'));
    });

    test('Too high loan amount fails', () {
      final result = FinancialValidators.validateLoanAmount(150000000);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('too high'));
    });
  });

  group('FinancialValidators - Term Years', () {
    test('Valid terms pass validation', () {
      expect(FinancialValidators.validateTermYears(1).isValid, isTrue);
      expect(FinancialValidators.validateTermYears(15).isValid, isTrue);
      expect(FinancialValidators.validateTermYears(30).isValid, isTrue);
      expect(FinancialValidators.validateTermYears(40).isValid, isTrue);
    });

    test('Too short term fails', () {
      final result = FinancialValidators.validateTermYears(0.5);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('too short'));
    });

    test('Too long term fails', () {
      final result = FinancialValidators.validateTermYears(50);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('too long'));
    });
  });

  group('FinancialValidators - Payment', () {
    test('Valid payments pass validation', () {
      expect(FinancialValidators.validatePayment(500).isValid, isTrue);
      expect(FinancialValidators.validatePayment(2500).isValid, isTrue);
      expect(FinancialValidators.validatePayment(10000).isValid, isTrue);
    });

    test('Zero payment fails', () {
      final result = FinancialValidators.validatePayment(0);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('positive'));
    });

    test('Unrealistic payment fails', () {
      final result = FinancialValidators.validatePayment(2000000);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('too high'));
    });
  });

  group('FinancialValidators - Down Payment', () {
    test('Valid percentage down payments pass', () {
      expect(FinancialValidators.validateDownPayment(20, 400000).isValid, isTrue);
      expect(FinancialValidators.validateDownPayment(3.5, 300000).isValid, isTrue);
      expect(FinancialValidators.validateDownPayment(50, 500000).isValid, isTrue);
    });

    test('Valid flat down payments pass', () {
      expect(FinancialValidators.validateDownPayment(50000, 250000).isValid, isTrue);
      expect(FinancialValidators.validateDownPayment(100000, 500000).isValid, isTrue);
    });

    test('Down payment exceeding price fails', () {
      final result = FinancialValidators.validateDownPayment(300000, 250000);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('exceed'));
    });

    test('Negative down payment fails', () {
      final result = FinancialValidators.validateDownPayment(-10, 300000);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('negative'));
    });

    test('Over 100% down payment fails', () {
      final result = FinancialValidators.validateDownPayment(150, 300000);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('exceed 100%'));
    });
  });

  group('FinancialValidators - Payment Sufficiency', () {
    test('Sufficient payment passes', () {
      final result = FinancialValidators.validatePaymentSufficiency(
        200000, // loan
        5.0,    // rate
        1200,   // payment
      );
      expect(result.isValid, isTrue);
    });

    test('Insufficient payment fails', () {
      final result = FinancialValidators.validatePaymentSufficiency(
        200000, // loan
        6.0,    // rate
        900,    // payment (less than monthly interest)
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('exceed minimum interest'));
    });

    test('Missing values allow validation to pass', () {
      expect(FinancialValidators.validatePaymentSufficiency(null, 5.0, 1000).isValid, isTrue);
      expect(FinancialValidators.validatePaymentSufficiency(200000, null, 1000).isValid, isTrue);
      expect(FinancialValidators.validatePaymentSufficiency(200000, 5.0, null).isValid, isTrue);
    });
  });

  group('FinancialValidators - Numeric Input', () {
    test('Valid numeric strings pass', () {
      expect(FinancialValidators.validateNumericInput('123').isValid, isTrue);
      expect(FinancialValidators.validateNumericInput('45.67').isValid, isTrue);
      expect(FinancialValidators.validateNumericInput('0.5').isValid, isTrue);
    });

    test('Empty string fails', () {
      final result = FinancialValidators.validateNumericInput('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('enter a value'));
    });

    test('Non-numeric string fails', () {
      final result = FinancialValidators.validateNumericInput('abc');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('valid number'));
    });
  });

  group('FinancialValidators - Input Length', () {
    test('Normal length inputs pass', () {
      expect(FinancialValidators.validateInputLength('12345').isValid, isTrue);
      expect(FinancialValidators.validateInputLength('123456789012345').isValid, isTrue);
    });

    test('Too long input fails', () {
      final result = FinancialValidators.validateInputLength('1234567890123456');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('too long'));
    });
  });

  group('FinancialValidators - Optional Fields', () {
    test('Null optional fields pass', () {
      expect(FinancialValidators.validatePropertyTax(null).isValid, isTrue);
      expect(FinancialValidators.validateInsurance(null).isValid, isTrue);
      expect(FinancialValidators.validateMonthlyExpenses(null).isValid, isTrue);
      expect(FinancialValidators.validateMonthlyDebt(null).isValid, isTrue);
    });

    test('Valid optional field values pass', () {
      expect(FinancialValidators.validatePropertyTax(3600).isValid, isTrue);
      expect(FinancialValidators.validateInsurance(1200).isValid, isTrue);
      expect(FinancialValidators.validateMonthlyExpenses(500).isValid, isTrue);
      expect(FinancialValidators.validateMonthlyDebt(1000).isValid, isTrue);
    });

    test('Negative optional field values fail', () {
      expect(FinancialValidators.validatePropertyTax(-100).isValid, isFalse);
      expect(FinancialValidators.validateInsurance(-50).isValid, isFalse);
      expect(FinancialValidators.validateMonthlyExpenses(-200).isValid, isFalse);
      expect(FinancialValidators.validateMonthlyDebt(-500).isValid, isFalse);
    });
  });

  group('FinancialValidators - Income', () {
    test('Valid income passes', () {
      expect(FinancialValidators.validateAnnualIncome(50000).isValid, isTrue);
      expect(FinancialValidators.validateAnnualIncome(150000).isValid, isTrue);
    });

    test('Too low income fails', () {
      final result = FinancialValidators.validateAnnualIncome(500);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('too low'));
    });

    test('Null income passes for optional scenarios', () {
      expect(FinancialValidators.validateAnnualIncome(null).isValid, isTrue);
    });
  });
}
