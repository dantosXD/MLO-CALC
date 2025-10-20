import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _currencyFormatNoDecimals = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  /// Format as currency with symbol and decimals: $350,000.00
  static String formatCurrency(double? value, {bool showDecimals = true}) {
    if (value == null) return '\$0.00';
    if (showDecimals) {
      return _currencyFormat.format(value);
    } else {
      return _currencyFormatNoDecimals.format(value);
    }
  }

  /// Format as percentage: 5.25%
  static String formatPercent(double? value, {int decimals = 2}) {
    if (value == null) return '0.00%';
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format as number with commas: 350,000
  static String formatNumber(double? value, {int decimals = 0}) {
    if (value == null) return '0';
    if (decimals == 0) {
      return _numberFormat.format(value.round());
    } else {
      return _numberFormat.format(value);
    }
  }

  /// Format years: 30 years or 5.5 years
  static String formatYears(double? value) {
    if (value == null) return '0 years';
    if (value == value.toInt()) {
      return '${value.toInt()} ${value == 1 ? 'year' : 'years'}';
    } else {
      return '${value.toStringAsFixed(2)} years';
    }
  }

  /// Format months: 360 months
  static String formatMonths(int? value) {
    if (value == null) return '0 months';
    return '$value ${value == 1 ? 'month' : 'months'}';
  }

  /// Compact currency format for display: $350K or $1.2M
  static String formatCompactCurrency(double? value) {
    if (value == null) return '\$0';
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return formatCurrency(value, showDecimals: false);
    }
  }

  /// Parse currency string to double
  static double? parseCurrency(String value) {
    try {
      String cleaned = value.replaceAll(RegExp(r'[\$,\s]'), '');
      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Parse percentage string to double
  static double? parsePercent(String value) {
    try {
      String cleaned = value.replaceAll(RegExp(r'[%\s]'), '');
      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Format display value based on context
  static String formatDisplayValue(
    String rawValue, {
    String context = 'number',
    bool isError = false,
  }) {
    if (isError) return rawValue;

    final double? numValue = double.tryParse(rawValue);
    if (numValue == null) return rawValue;

    switch (context) {
      case 'currency':
        return formatCurrency(numValue);
      case 'percent':
        return formatPercent(numValue);
      case 'years':
        return formatYears(numValue);
      default:
        return formatNumber(numValue, decimals: 2);
    }
  }
}

class ValidationHelper {
  /// Validate loan amount (reasonable range: $1,000 - $100,000,000)
  static String? validateLoanAmount(double? value) {
    if (value == null) return null;
    if (value < 1000) return 'Loan amount too small (min: \$1,000)';
    if (value > 100000000) return 'Loan amount too large (max: \$100M)';
    return null;
  }

  /// Validate interest rate (reasonable range: 0.1% - 30%)
  static String? validateInterestRate(double? value) {
    if (value == null) return null;
    if (value <= 0) return 'Interest rate must be positive';
    if (value > 30) return 'Interest rate seems unusually high (>30%)';
    return null;
  }

  /// Validate term (reasonable range: 1 - 50 years)
  static String? validateTerm(double? value) {
    if (value == null) return null;
    if (value <= 0) return 'Term must be positive';
    if (value > 50) return 'Term too long (max: 50 years)';
    return null;
  }

  /// Validate payment ratio (warn if payment > 50% of monthly income)
  static String? validatePaymentRatio(double payment, double monthlyIncome) {
    if (monthlyIncome <= 0) return null;
    double ratio = (payment / monthlyIncome) * 100;
    if (ratio > 50) {
      return 'Warning: Payment is ${ratio.toStringAsFixed(1)}% of monthly income';
    } else if (ratio > 36) {
      return 'Note: Payment is ${ratio.toStringAsFixed(1)}% of monthly income';
    }
    return null;
  }

  /// Calculate debt-to-income ratio
  static double calculateDTI(double totalMonthlyDebt, double monthlyIncome) {
    if (monthlyIncome <= 0) return 0;
    return (totalMonthlyDebt / monthlyIncome) * 100;
  }

  /// Calculate loan-to-value ratio
  static double calculateLTV(double loanAmount, double propertyValue) {
    if (propertyValue <= 0) return 0;
    return (loanAmount / propertyValue) * 100;
  }
}
