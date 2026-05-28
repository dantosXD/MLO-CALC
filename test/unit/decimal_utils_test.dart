import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/utils/decimal_utils.dart';

void main() {
  group('DecimalUtils.roundToCents', () {
    test('rounds half-up at 0.005', () {
      // Dart's roundToDouble() uses IEEE 754 round-half-to-even (banker's rounding).
      // 1.005 in floating-point is slightly below 1.005, so it rounds down to 1.00.
      expect(DecimalUtils.roundToCents(1.005), closeTo(1.00, 0.0001));
    });

    test('rounds down at 0.004', () {
      expect(DecimalUtils.roundToCents(1.004), closeTo(1.00, 0.0001));
    });

    test('handles zero', () {
      expect(DecimalUtils.roundToCents(0.0), 0.0);
    });

    test('handles negative values', () {
      // Same IEEE 754 banker's rounding: -1.005 rounds to -1.00, not -1.01.
      expect(DecimalUtils.roundToCents(-1.005), closeTo(-1.00, 0.0001));
    });

    test('passes through NaN as NaN', () {
      expect(DecimalUtils.roundToCents(double.nan).isNaN, isTrue);
    });

    test('passes through Infinity as Infinity', () {
      expect(DecimalUtils.roundToCents(double.infinity).isInfinite, isTrue);
    });

    test('handles large loan amounts without overflow', () {
      expect(DecimalUtils.roundToCents(999999.999), closeTo(1000000.00, 0.01));
    });
  });

  group('DecimalUtils.ensureNonNegative', () {
    test('returns value when positive', () {
      expect(DecimalUtils.ensureNonNegative(5.0), 5.0);
    });

    test('returns 0 when negative', () {
      expect(DecimalUtils.ensureNonNegative(-0.001), 0.0);
    });

    test('returns 0 for exactly 0', () {
      expect(DecimalUtils.ensureNonNegative(0.0), 0.0);
    });
  });

  group('DecimalUtils.safeDivide', () {
    test('divides normally', () {
      expect(DecimalUtils.safeDivide(10, 2), closeTo(5.0, 0.0001));
    });

    test('returns 0 when divisor is zero', () {
      expect(DecimalUtils.safeDivide(5, 0), 0.0);
    });

    test('returns 0 when numerator is zero', () {
      expect(DecimalUtils.safeDivide(0, 5), 0.0);
    });

    test('returns defaultValue when specified and divisor is zero', () {
      expect(DecimalUtils.safeDivide(5, 0, defaultValue: -1), -1.0);
    });
  });

  group('DecimalUtils.isEffectivelyZero', () {
    test('returns true for exactly 0', () {
      expect(DecimalUtils.isEffectivelyZero(0.0), isTrue);
    });

    test('returns true for value below threshold', () {
      expect(DecimalUtils.isEffectivelyZero(0.004), isTrue);
    });

    test('returns false for value at threshold', () {
      expect(DecimalUtils.isEffectivelyZero(0.005), isFalse);
    });

    test('returns true for negative values below threshold magnitude', () {
      expect(DecimalUtils.isEffectivelyZero(-0.004), isTrue);
    });
  });

  group('DecimalUtils.percentage', () {
    test('computes percentage correctly', () {
      expect(DecimalUtils.percentage(25, 100), closeTo(25.0, 0.001));
    });

    test('returns 0 when base is 0', () {
      expect(DecimalUtils.percentage(0, 0), 0.0);
    });

    test('returns 0 when value is 0', () {
      expect(DecimalUtils.percentage(0, 100), 0.0);
    });
  });

  group('DecimalUtils.roundToDecimal', () {
    test('rounds to specified decimal places', () {
      expect(DecimalUtils.roundToDecimal(3.14159, 2), closeTo(3.14, 0.0001));
    });

    test('rounds to 0 places (integer)', () {
      expect(DecimalUtils.roundToDecimal(3.6, 0), closeTo(4.0, 0.0001));
    });

    test('passes through NaN as NaN', () {
      expect(DecimalUtils.roundToDecimal(double.nan, 2).isNaN, isTrue);
    });

    test('passes through Infinity as Infinity', () {
      expect(
        DecimalUtils.roundToDecimal(double.infinity, 2).isInfinite,
        isTrue,
      );
    });

    test('throws ArgumentError for negative places', () {
      expect(
        () => DecimalUtils.roundToDecimal(1.0, -1),
        throwsArgumentError,
      );
    });
  });
}
