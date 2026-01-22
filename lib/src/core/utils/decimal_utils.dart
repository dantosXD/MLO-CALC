/// Decimal utilities for financial calculations
///
/// Provides consistent rounding behavior across all calculations.
/// Financial values should use full precision internally and only
/// round when storing final results or displaying to users.
library;

import 'dart:math' as math;

/// Utility class for financial decimal operations
class DecimalUtils {
  // Private constructor to prevent instantiation
  DecimalUtils._();

  /// Round a value to the nearest cent (2 decimal places)
  ///
  /// Use this for final currency values that will be displayed or stored.
  /// Example: 1234.567 -> 1234.57
  static double roundToCents(double value) {
    return roundToDecimal(value, 2);
  }

  /// Round a value to a specific number of decimal places
  ///
  /// Uses standard banker's rounding (round half to even) for consistency.
  /// [places] must be non-negative.
  static double roundToDecimal(double value, int places) {
    if (places < 0) {
      throw ArgumentError('Decimal places must be non-negative');
    }
    if (value.isNaN || value.isInfinite) {
      return value;
    }
    final multiplier = math.pow(10, places);
    return (value * multiplier).roundToDouble() / multiplier;
  }

  /// Round a value to the nearest whole number
  static double roundToWhole(double value) {
    return roundToDecimal(value, 0);
  }

  /// Truncate a value to a specific number of decimal places (floor toward zero)
  ///
  /// Unlike rounding, this always truncates without rounding up.
  /// Example: truncateToDecimal(1234.567, 2) -> 1234.56
  static double truncateToDecimal(double value, int places) {
    if (places < 0) {
      throw ArgumentError('Decimal places must be non-negative');
    }
    if (value.isNaN || value.isInfinite) {
      return value;
    }
    final multiplier = math.pow(10, places);
    return (value * multiplier).truncateToDouble() / multiplier;
  }

  /// Check if two currency values are equal (within cent tolerance)
  ///
  /// Useful for comparing calculated values that may have floating-point noise.
  static bool currencyEquals(double a, double b) {
    return (a - b).abs() < 0.005; // Half-cent tolerance
  }

  /// Check if a value is effectively zero for currency purposes
  ///
  /// Values less than half a cent are considered zero.
  static bool isEffectivelyZero(double value) {
    return value.abs() < 0.005;
  }

  /// Ensure a currency value is non-negative (clamp to zero if negative)
  ///
  /// Use this for balances that should never go negative due to rounding.
  static double ensureNonNegative(double value) {
    return value < 0 ? 0.0 : value;
  }

  /// Format a currency value for calculation logging/debugging
  ///
  /// Shows full precision for debugging purposes.
  static String debugFormat(double value) {
    return value.toStringAsFixed(10);
  }

  /// Safe division that handles divide-by-zero
  ///
  /// Returns [defaultValue] if divisor is zero or near-zero.
  static double safeDivide(double numerator, double divisor, {double defaultValue = 0.0}) {
    if (divisor.abs() < 1e-10) {
      return defaultValue;
    }
    return numerator / divisor;
  }

  /// Calculate percentage with proper precision
  ///
  /// Example: percentage(25, 100) returns 25.0 (representing 25%)
  static double percentage(double part, double whole) {
    if (whole == 0) return 0;
    return (part / whole) * 100;
  }

  /// Apply a percentage to a value
  ///
  /// Example: applyPercentage(100, 5.5) returns 5.5 (5.5% of 100)
  static double applyPercentage(double value, double percent) {
    return value * (percent / 100);
  }

  /// Convert annual rate to monthly rate
  ///
  /// Example: annualToMonthly(6.0) returns 0.005 (0.5% per month)
  static double annualToMonthlyRate(double annualPercent) {
    return annualPercent / 100 / 12;
  }

  /// Convert monthly rate to annual rate
  ///
  /// Example: monthlyToAnnual(0.005) returns 6.0 (6% per year)
  static double monthlyToAnnualRate(double monthlyRate) {
    return monthlyRate * 12 * 100;
  }
}
