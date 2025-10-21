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

/// Financial helper utilities for ratios and PMI calculations
///
/// DEPRECATED: For validation of financial inputs, use FinancialValidators from
/// lib/src/validators/financial_validators.dart instead. The validation methods
/// in this class are kept for backward compatibility but will be removed in future versions.
class FinancialHelpers {
  // Private constructor to prevent instantiation
  FinancialHelpers._();

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

  /// Determine if PMI (Private Mortgage Insurance) is required
  /// PMI typically required when LTV > 80%
  static bool isPMIRequired(double loanAmount, double propertyValue) {
    return FinancialHelpers.calculateLTV(loanAmount, propertyValue) > 80;
  }

  /// Estimate monthly PMI based on LTV ratio
  /// Typical PMI rates: 0.5% - 1.5% annually depending on LTV
  static double estimateMonthlyPMI(double loanAmount, double propertyValue) {
    final ltv = FinancialHelpers.calculateLTV(loanAmount, propertyValue);
    if (ltv <= 80) return 0;

    double annualPMIRate;
    if (ltv > 95) {
      annualPMIRate = 0.015; // 1.5% for high LTV
    } else if (ltv > 90) {
      annualPMIRate = 0.01; // 1.0% for moderate-high LTV
    } else {
      annualPMIRate = 0.005; // 0.5% for low-moderate LTV
    }

    return (loanAmount * annualPMIRate) / 12;
  }
}
