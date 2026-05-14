import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';

/// Mirrors the fixed _formatDisplayValue logic from ModernCalculator.
String formatDisplayValue(String rawValue) {
  final double? numValue = double.tryParse(rawValue);
  if (numValue == null) return rawValue;

  final dotIndex = rawValue.indexOf('.');
  if (dotIndex == -1) {
    return CurrencyFormatter.formatNumber(numValue, decimals: 0);
  }

  final sign = numValue < 0 ? '-' : '';
  final intFormatted = CurrencyFormatter.formatNumber(
    numValue.truncateToDouble().abs(),
    decimals: 0,
  );
  final decimalPart = rawValue.substring(dotIndex);
  return '$sign$intFormatted$decimalPart';
}

void main() {
  group('ModernCalculator _formatDisplayValue — decimal precision', () {
    test('5.125 is not rounded to 5.13', () {
      expect(formatDisplayValue('5.125'), '5.125');
    });

    test('5.1250 preserves trailing zero typed by user', () {
      expect(formatDisplayValue('5.1250'), '5.1250');
    });

    test('whole number shows no decimal', () {
      expect(formatDisplayValue('5'), '5');
    });

    test('integer formatting adds commas', () {
      expect(formatDisplayValue('1000000'), '1,000,000');
    });

    test('large number with decimals keeps exact decimal', () {
      expect(formatDisplayValue('1234567.875'), '1,234,567.875');
    });

    test('negative number preserves decimal', () {
      expect(formatDisplayValue('-5.125'), '-5.125');
    });

    test('trailing decimal preserved while typing', () {
      expect(formatDisplayValue('5.'), '5.');
    });

    test('Error string passes through unchanged', () {
      expect(formatDisplayValue('Error'), 'Error');
    });
  });
}
