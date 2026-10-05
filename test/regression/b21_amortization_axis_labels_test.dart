import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/amortization/presentation/widgets/amortization_chart.dart';

void main() {
  test('sub-\$1k tick spacing keeps labels distinct', () {
    final labels = [
      3000.0,
      2500.0,
      2000.0,
      1500.0,
      1000.0,
      500.0,
      0.0,
    ].map((v) => formatAxisThousands(v, 500)).toList();
    expect(labels.toSet().length, labels.length);
  });
  test('large spacing stays whole-k', () {
    expect(formatAxisThousands(300000, 100000), r'$300k');
  });
}
