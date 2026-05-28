import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';

void main() {
  group('CalculationEntry ID uniqueness', () {
    test('fromLoanCalculation generates unique IDs on rapid calls', () {
      const iterations = 100;
      final ids = <String>{};

      for (var i = 0; i < iterations; i++) {
        final entry = CalculationEntry.fromLoanCalculation(
          type: CalculationEntryType.payment,
          loanAmount: 400000.0,
          interestRate: 7.0,
          termYears: 30.0,
          payment: 2661.21,
        );
        ids.add(entry.id);
      }

      expect(
        ids.length,
        equals(iterations),
        reason:
            'All $iterations rapid fromLoanCalculation calls must produce unique IDs',
      );
    });

    test('fromQualification generates unique IDs on rapid calls', () {
      const iterations = 100;
      final ids = <String>{};

      for (var i = 0; i < iterations; i++) {
        final entry = CalculationEntry.fromQualification(
          annualIncome: 120000.0,
          monthlyDebt: 500.0,
          interestRate: 7.0,
          termYears: 30.0,
          maxLoanAmount: 400000.0,
        );
        ids.add(entry.id);
      }

      expect(
        ids.length,
        equals(iterations),
        reason:
            'All $iterations rapid fromQualification calls must produce unique IDs',
      );
    });

    test('IDs from different factory constructors are all unique', () {
      final ids = <String>{};

      for (var i = 0; i < 50; i++) {
        ids.add(
          CalculationEntry.fromLoanCalculation(
            type: CalculationEntryType.payment,
            loanAmount: 400000.0,
            interestRate: 7.0,
            termYears: 30.0,
            payment: 2661.21,
          ).id,
        );
        ids.add(
          CalculationEntry.fromQualification(
            annualIncome: 120000.0,
            monthlyDebt: 500.0,
            interestRate: 7.0,
            termYears: 30.0,
            maxLoanAmount: 400000.0,
          ).id,
        );
      }

      expect(
        ids.length,
        equals(100),
        reason: '100 mixed factory calls must all produce unique IDs',
      );
    });
  });
}
