import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/features/comparison/application/providers/comparison_provider.dart';

void main() {
  group('ComparisonProvider', () {
    test('buildComparison derives metrics', () {
      final entries = [
        CalculationEntry(
          id: 'a',
          timestamp: DateTime.now(),
          type: 'payment',
          inputs: {
            'loanAmount': 300000.0,
            'interestRate': 5.0,
            'termYears': 30.0,
            'price': 360000.0,
            'payment': 1610.0,
          },
          results: {'payment': 1610.0},
        ),
        CalculationEntry(
          id: 'b',
          timestamp: DateTime.now(),
          type: 'payment',
          inputs: {
            'loanAmount': 320000.0,
            'interestRate': 6.2,
            'termYears': 30.0,
            'payment': 1960.0,
            'price': 400000.0,
          },
          results: {'payment': 1960.0},
        ),
      ];

      final comparison = ComparisonData.fromEntries(entries);

      expect(comparison.views.length, 2);
      expect(comparison.baseline.entry.id, anyOf('a', 'b'));
      expect(
        comparison.views.any((view) => view.miDropMonth != null),
        isTrue,
      );
      expect(
        comparison.views
            .where((view) => !view.isBaseline)
            .first
            .breakEvenMonths,
        isNotNull,
      );
    });
  });
}
