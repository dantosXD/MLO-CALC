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

  static final Map<int, NumberFormat> _decimalFormatCache =
      <int, NumberFormat>{};
  static final Map<int, NumberFormat> _percentFormatCache =
      <int, NumberFormat>{};

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
    if (value == null) return '0%';

    final format = _percentFormatCache.putIfAbsent(decimals, () {
      final f = NumberFormat.decimalPattern();
      f.minimumFractionDigits = decimals;
      f.maximumFractionDigits = decimals;
      return f;
    });

    return '${format.format(value)}%';
  }

  /// Format as number with commas: 350,000
  static String formatNumber(double? value, {int decimals = 0}) {
    if (value == null) return '0';

    final format = _decimalFormatCache.putIfAbsent(decimals, () {
      final f = NumberFormat.decimalPattern();
      f.minimumFractionDigits = decimals;
      f.maximumFractionDigits = decimals;
      return f;
    });

    return format.format(value);
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
  /// Use [maxDigits] to control precision (default 4, max 7 for detailed view)
  static String formatCompactCurrency(double? value, {int maxDigits = 4}) {
    if (value == null) return '--';

    final absValue = value.abs();
    final intDigits = absValue.floor().toString().length;
    if (intDigits <= maxDigits) {
      return formatCurrency(value);
    }

    final sign = value < 0 ? '-' : '';
    if (absValue >= 1000000) {
      final scaled = absValue / 1000000;
      final decimals = _compactDecimals(scaled, maxDigits - 1);
      final formatted = _trimTrailingZeros(scaled.toStringAsFixed(decimals));
      return '$sign\$$formatted'
          'M';
    } else if (absValue >= 1000) {
      final scaled = absValue / 1000;
      final decimals = _compactDecimals(scaled, maxDigits - 1);
      final formatted = _trimTrailingZeros(scaled.toStringAsFixed(decimals));
      return '$sign\$$formatted'
          'K';
    }

    return formatCurrency(value);
  }

  static String _trimTrailingZeros(String value) {
    if (!value.contains('.')) return value;
    var out = value;
    out = out.replaceAll(RegExp(r'0+$'), '');
    out = out.replaceAll(RegExp(r'\.$'), '');
    return out;
  }

  static int _compactDecimals(double scaled, int maxDigits) {
    // Keep compact values readable and avoid nonsense like 500.0000K.
    // Rule of thumb:
    // - 100+ => 0 decimals (500K)
    // - 10-99.9 => 1 decimal (12.3K)
    // - <10 => 2 decimals (1.23M)
    int desired;
    if (scaled >= 100) {
      desired = 0;
    } else if (scaled >= 10) {
      desired = 1;
    } else {
      desired = 2;
    }

    final intDigits = scaled.floor().toString().length;
    final allowed = (maxDigits - intDigits).clamp(0, 6);
    return desired.clamp(0, allowed);
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
