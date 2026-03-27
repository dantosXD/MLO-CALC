/// Financial input validation utilities
///
/// Provides validation rules for mortgage calculator inputs to ensure
/// realistic and safe values that prevent calculation errors.
library;

import 'package:loan_ranger/src/core/utils/formatters.dart';

import '../utils/constants.dart';

/// Validation result containing error message if validation fails
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid() : isValid = true, errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// Financial input validators for mortgage calculations
class FinancialValidators {
  // Private constructor to prevent instantiation
  FinancialValidators._();

  /// Validates interest rate
  static ValidationResult validateInterestRate(double? rate) {
    if (rate == null) {
      return const ValidationResult.invalid('Interest rate is required');
    }
    if (rate <= 0) {
      return const ValidationResult.invalid('Interest rate must be positive');
    }
    if (rate < AppConstants.minInterestRate) {
      return const ValidationResult.invalid('Interest rate too low (minimum ${AppConstants.minInterestRate}%)');
    }
    if (rate > AppConstants.maxInterestRate) {
      return const ValidationResult.invalid('Interest rate too high (maximum ${AppConstants.maxInterestRate}%)');
    }
    return const ValidationResult.valid();
  }

  /// Validates loan amount
  static ValidationResult validateLoanAmount(double? amount) {
    if (amount == null) {
      return const ValidationResult.invalid('Loan amount is required');
    }
    if (amount <= 0) {
      return const ValidationResult.invalid('Loan amount must be positive');
    }
    if (amount < AppConstants.minLoanAmount) {
      return const ValidationResult.invalid('Loan amount too low (minimum \$${AppConstants.minLoanAmount})');
    }
    if (amount > AppConstants.maxLoanAmount) {
      return const ValidationResult.invalid('Loan amount too high (maximum \$100M)');
    }
    return const ValidationResult.valid();
  }

  /// Validates term in years
  static ValidationResult validateTermYears(double? years) {
    if (years == null) {
      return const ValidationResult.invalid('Term is required');
    }
    if (years <= 0) {
      return const ValidationResult.invalid('Term must be positive');
    }
    if (years < AppConstants.minTermYears) {
      return const ValidationResult.invalid('Term too short (minimum ${AppConstants.minTermYears} year)');
    }
    if (years > AppConstants.maxTermYears) {
      return const ValidationResult.invalid('Term too long (maximum ${AppConstants.maxTermYears} years)');
    }
    return const ValidationResult.valid();
  }

  /// Validates monthly payment
  static ValidationResult validatePayment(double? payment) {
    if (payment == null) {
      return const ValidationResult.invalid('Payment is required');
    }
    if (payment <= 0) {
      return const ValidationResult.invalid('Payment must be positive');
    }
    if (payment > AppConstants.maxPayment) {
      return const ValidationResult.invalid('Payment too high (maximum \$1M/month)');
    }
    return const ValidationResult.valid();
  }

  /// Validates property price
  static ValidationResult validatePrice(double? price) {
    if (price == null) {
      return const ValidationResult.invalid('Price is required');
    }
    if (price <= 0) {
      return const ValidationResult.invalid('Price must be positive');
    }
    if (price < AppConstants.minPrice) {
      return const ValidationResult.invalid('Price too low (minimum \$${AppConstants.minPrice})');
    }
    if (price > AppConstants.maxPrice) {
      return const ValidationResult.invalid('Price too high (maximum \$200M)');
    }
    return const ValidationResult.valid();
  }

  /// Validates down payment (percentage or amount)
  static ValidationResult validateDownPayment(double? downPayment, double? price) {
    if (downPayment == null) {
      return const ValidationResult.invalid('Down payment is required');
    }
    if (downPayment < 0) {
      return const ValidationResult.invalid('Down payment cannot be negative');
    }

    // Heuristic: values under 100 are percentages, otherwise flat amounts
    // But check for bad percentages (> 100 but < typical min home price)
    if (downPayment > 100 && downPayment < 10000) {
      return const ValidationResult.invalid('Down payment percentage cannot exceed 100%');
    }
    
    // If it's a flat amount (>= 10000)
    if (downPayment >= 10000) {
      if (price != null && downPayment >= price) {
        return const ValidationResult.invalid('Down payment cannot equal or exceed price');
      }
    }
    
    return const ValidationResult.valid();
  }

  /// Validates annual property tax
  static ValidationResult validatePropertyTax(double? tax) {
    if (tax == null) return const ValidationResult.valid(); // Optional
    if (tax < 0) {
      return const ValidationResult.invalid('Property tax cannot be negative');
    }
    if (tax > AppConstants.maxPropertyTax) {
      return const ValidationResult.invalid('Property tax too high (maximum \$1M/year)');
    }
    return const ValidationResult.valid();
  }

  /// Validates annual insurance
  static ValidationResult validateInsurance(double? insurance) {
    if (insurance == null) return const ValidationResult.valid(); // Optional
    if (insurance < 0) {
      return const ValidationResult.invalid('Insurance cannot be negative');
    }
    if (insurance > AppConstants.maxInsurance) {
      return const ValidationResult.invalid('Insurance too high (maximum \$100K/year)');
    }
    return const ValidationResult.valid();
  }

  /// Validates monthly expenses (HOA, etc.)
  static ValidationResult validateMonthlyExpenses(double? expenses) {
    if (expenses == null) return const ValidationResult.valid(); // Optional
    if (expenses < 0) {
      return const ValidationResult.invalid('Monthly expenses cannot be negative');
    }
    if (expenses > AppConstants.maxMonthlyExpenses) {
      return const ValidationResult.invalid('Monthly expenses too high (maximum \$50K/month)');
    }
    return const ValidationResult.valid();
  }

  /// Validates annual income
  static ValidationResult validateAnnualIncome(double? income) {
    if (income == null) return const ValidationResult.valid(); // Optional for some calculations
    if (income <= 0) {
      return const ValidationResult.invalid('Annual income must be positive');
    }
    if (income < AppConstants.minAnnualIncome) {
      return const ValidationResult.invalid('Annual income too low (minimum \$${AppConstants.minAnnualIncome})');
    }
    if (income > AppConstants.maxAnnualIncome) {
      return const ValidationResult.invalid('Annual income too high (maximum \$100M)');
    }
    return const ValidationResult.valid();
  }

  /// Validates monthly debt
  static ValidationResult validateMonthlyDebt(double? debt) {
    if (debt == null) return const ValidationResult.valid(); // Optional
    if (debt < 0) {
      return const ValidationResult.invalid('Monthly debt cannot be negative');
    }
    if (debt > AppConstants.maxMonthlyDebt) {
      return const ValidationResult.invalid('Monthly debt too high (maximum \$500K/month)');
    }
    return const ValidationResult.valid();
  }

  /// Validates that payment can actually pay off the loan
  /// (Payment must be greater than monthly interest)
  static ValidationResult validatePaymentSufficiency(
    double? loanAmount,
    double? interestRate,
    double? payment,
  ) {
    if (loanAmount == null || interestRate == null || payment == null) {
      return const ValidationResult.valid(); // Can't validate without all values
    }

    final monthlyRate = interestRate / 100 / 12;
    final minimumPayment = loanAmount * monthlyRate;

    if (payment <= minimumPayment) {
      return ValidationResult.invalid(
        'Payment (${CurrencyFormatter.formatCurrency(payment)}) must exceed minimum interest '
        '(${CurrencyFormatter.formatCurrency(minimumPayment)}) to pay off loan',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validates input string can be parsed as a valid number
  static ValidationResult validateNumericInput(String input) {
    if (input.isEmpty) {
      return const ValidationResult.invalid('Please enter a value');
    }

    final value = double.tryParse(input);
    if (value == null) {
      return const ValidationResult.invalid('Please enter a valid number');
    }

    return const ValidationResult.valid();
  }

  /// Validates input length to prevent overflow
  static ValidationResult validateInputLength(String input) {
    if (input.length > AppConstants.maxInputLength) {
      return const ValidationResult.invalid('Input too long (maximum ${AppConstants.maxInputLength} characters)');
    }
    return const ValidationResult.valid();
  }
}
