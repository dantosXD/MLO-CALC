# Validator Usage Guide

## Quick Reference for Financial Validators

### Import
```dart
import 'package:loan_ranger/src/validators/financial_validators.dart';
```

---

## Basic Usage Pattern

```dart
final result = FinancialValidators.validateInterestRate(userInput);
if (!result.isValid) {
  // Show error to user
  showError(result.errorMessage);
  return;
}
// Proceed with calculation
```

---

## Available Validators

### 1. Interest Rate
```dart
ValidationResult validateInterestRate(double? rate)
```
- **Range:** 0.1% - 30%
- **Example:**
```dart
final result = FinancialValidators.validateInterestRate(5.5);
// result.isValid = true

final badResult = FinancialValidators.validateInterestRate(35);
// badResult.isValid = false
// badResult.errorMessage = "Interest rate too high (maximum 30%)"
```

### 2. Loan Amount
```dart
ValidationResult validateLoanAmount(double? amount)
```
- **Range:** $1,000 - $100,000,000
- **Example:**
```dart
final result = FinancialValidators.validateLoanAmount(350000);
// result.isValid = true

final badResult = FinancialValidators.validateLoanAmount(500);
// badResult.isValid = false
// badResult.errorMessage = "Loan amount too low (minimum $1,000)"
```

### 3. Term Years
```dart
ValidationResult validateTermYears(double? years)
```
- **Range:** 1 - 40 years
- **Example:**
```dart
final result = FinancialValidators.validateTermYears(30);
// result.isValid = true
```

### 4. Payment
```dart
ValidationResult validatePayment(double? payment)
```
- **Range:** > $0, < $1,000,000/month
- **Example:**
```dart
final result = FinancialValidators.validatePayment(2500);
// result.isValid = true
```

### 5. Property Price
```dart
ValidationResult validatePrice(double? price)
```
- **Range:** $10,000 - $200,000,000
- **Example:**
```dart
final result = FinancialValidators.validatePrice(450000);
// result.isValid = true
```

### 6. Down Payment
```dart
ValidationResult validateDownPayment(double? downPayment, double? price)
```
- **Smart Logic:** Values < 100 = percentage, >= 10,000 = flat amount
- **Example:**
```dart
// 20% down payment
final result1 = FinancialValidators.validateDownPayment(20, 400000);
// result1.isValid = true

// $80,000 down payment
final result2 = FinancialValidators.validateDownPayment(80000, 400000);
// result2.isValid = true

// Invalid: 150% down payment
final result3 = FinancialValidators.validateDownPayment(150, 400000);
// result3.isValid = false
```

### 7. Property Tax (Annual)
```dart
ValidationResult validatePropertyTax(double? tax)
```
- **Range:** $0 - $1,000,000/year (optional field, null is valid)
- **Example:**
```dart
final result = FinancialValidators.validatePropertyTax(3600);
// result.isValid = true

final nullResult = FinancialValidators.validatePropertyTax(null);
// nullResult.isValid = true (optional field)
```

### 8. Insurance (Annual)
```dart
ValidationResult validateInsurance(double? insurance)
```
- **Range:** $0 - $100,000/year (optional)
- **Example:**
```dart
final result = FinancialValidators.validateInsurance(1200);
// result.isValid = true
```

### 9. Monthly Expenses
```dart
ValidationResult validateMonthlyExpenses(double? expenses)
```
- **Range:** $0 - $50,000/month (optional)
- **Example:**
```dart
final result = FinancialValidators.validateMonthlyExpenses(500);
// result.isValid = true
```

### 10. Annual Income
```dart
ValidationResult validateAnnualIncome(double? income)
```
- **Range:** $1,000 - $100,000,000/year (optional for some calcs)
- **Example:**
```dart
final result = FinancialValidators.validateAnnualIncome(100000);
// result.isValid = true
```

### 11. Monthly Debt
```dart
ValidationResult validateMonthlyDebt(double? debt)
```
- **Range:** $0 - $500,000/month (optional)
- **Example:**
```dart
final result = FinancialValidators.validateMonthlyDebt(1500);
// result.isValid = true
```

### 12. Payment Sufficiency
```dart
ValidationResult validatePaymentSufficiency(
  double? loanAmount,
  double? interestRate,
  double? payment,
)
```
- **Logic:** Payment must exceed monthly interest to pay off loan
- **Example:**
```dart
final result = FinancialValidators.validatePaymentSufficiency(
  200000,  // loan
  5.0,     // rate
  1200,    // payment
);
// result.isValid = true (payment > monthly interest)

final badResult = FinancialValidators.validatePaymentSufficiency(
  200000,
  10.0,
  500,     // too low
);
// badResult.isValid = false
// badResult.errorMessage = "Payment ($500.00) must exceed minimum interest..."
```

### 13. Numeric Input
```dart
ValidationResult validateNumericInput(String input)
```
- **Validates:** String can be parsed as number
- **Example:**
```dart
final result = FinancialValidators.validateNumericInput("123.45");
// result.isValid = true

final badResult = FinancialValidators.validateNumericInput("abc");
// badResult.isValid = false
// badResult.errorMessage = "Please enter a valid number"
```

### 14. Input Length
```dart
ValidationResult validateInputLength(String input)
```
- **Max Length:** 15 characters
- **Example:**
```dart
final result = FinancialValidators.validateInputLength("12345");
// result.isValid = true

final badResult = FinancialValidators.validateInputLength("1234567890123456");
// badResult.isValid = false
// badResult.errorMessage = "Input too long (maximum 15 characters)"
```

---

## Integration Examples

### Example 1: Validate Before Calculation
```dart
void setLoanAmount(String input) {
  // Validate numeric input
  final numericValidation = FinancialValidators.validateNumericInput(input);
  if (!numericValidation.isValid) {
    setState(() {
      errorMessage = numericValidation.errorMessage;
    });
    return;
  }

  final amount = double.parse(input);

  // Validate loan amount range
  final amountValidation = FinancialValidators.validateLoanAmount(amount);
  if (!amountValidation.isValid) {
    setState(() {
      errorMessage = amountValidation.errorMessage;
    });
    return;
  }

  // Clear error and proceed
  setState(() {
    errorMessage = null;
    loanAmount = amount;
  });
}
```

### Example 2: Validate Multiple Fields
```dart
bool validateAllInputs() {
  final validations = [
    FinancialValidators.validateLoanAmount(loanAmount),
    FinancialValidators.validateInterestRate(interestRate),
    FinancialValidators.validateTermYears(termYears),
  ];

  for (final validation in validations) {
    if (!validation.isValid) {
      showError(validation.errorMessage!);
      return false;
    }
  }

  return true;
}
```

### Example 3: Real-Time Validation
```dart
TextField(
  onChanged: (value) {
    final validation = FinancialValidators.validateNumericInput(value);
    setState(() {
      inputError = validation.isValid ? null : validation.errorMessage;
    });
  },
  decoration: InputDecoration(
    errorText: inputError,
  ),
)
```

### Example 4: Form Validation
```dart
final formKey = GlobalKey<FormState>();

TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Interest rate is required';
    }

    final numValidation = FinancialValidators.validateNumericInput(value);
    if (!numValidation.isValid) {
      return numValidation.errorMessage;
    }

    final rate = double.parse(value);
    final rateValidation = FinancialValidators.validateInterestRate(rate);

    return rateValidation.isValid ? null : rateValidation.errorMessage;
  },
)
```

---

## Testing

All validators have comprehensive unit tests in `test/unit/financial_validators_test.dart`:

```bash
flutter test test/unit/financial_validators_test.dart
```

**Test Coverage:** 35 tests, 100% passing ✓

---

## Error Messages

All error messages are user-friendly and actionable:

- ✅ "Interest rate too high (maximum 30%)"
- ✅ "Loan amount too low (minimum $1,000)"
- ✅ "Term too long (maximum 40 years)"
- ✅ "Down payment cannot equal or exceed price"
- ✅ "Payment ($X.XX) must exceed minimum interest ($Y.YY) to pay off loan"

---

## Best Practices

1. **Always validate user input** before performing calculations
2. **Show validation errors immediately** for better UX
3. **Use appropriate validators** for each field type
4. **Clear errors** when validation passes
5. **Test edge cases** with the provided unit tests

---

## Common Patterns

### Pattern 1: Required Field
```dart
final validation = FinancialValidators.validateLoanAmount(amount);
if (!validation.isValid) {
  return validation.errorMessage; // "Loan amount is required"
}
```

### Pattern 2: Optional Field
```dart
final validation = FinancialValidators.validatePropertyTax(tax);
// null is valid for optional fields
```

### Pattern 3: Dependent Validation
```dart
// First validate all individual fields
final loanValid = FinancialValidators.validateLoanAmount(loan).isValid;
final rateValid = FinancialValidators.validateInterestRate(rate).isValid;
final pmtValid = FinancialValidators.validatePayment(payment).isValid;

// Then validate their relationship
if (loanValid && rateValid && pmtValid) {
  final sufficiency = FinancialValidators.validatePaymentSufficiency(
    loan, rate, payment
  );
  // Check if payment is sufficient
}
```

---

## See Also

- `lib/src/validators/financial_validators.dart` - Source code
- `test/unit/financial_validators_test.dart` - Test examples
- `lib/src/providers/calculator_provider.dart` - Integration example

---

**Last Updated:** January 2025
**Test Status:** 35/35 passing ✓
**Analyzer Status:** 0 issues ✓
