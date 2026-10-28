import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';

void main() {
  test('money/percent helpers dash for null, NaN, infinite', () {
    for (final v in [null, double.nan, double.infinity]) {
      expect(formatMoneyOrDash(v), '—');
      expect(formatPercentOrDash(v), '—');
    }
  });

  test('money/percent helpers format values', () {
    expect(formatMoneyOrDash(1234.5), '\$1,234.50');
    expect(formatMoneyOrDash(1234.5, decimals: 0), '\$1,235');
    expect(formatPercentOrDash(12.34), '12.3%');
    expect(formatPercentOrDash(6.5, digits: 3), '6.500%');
  });
}
