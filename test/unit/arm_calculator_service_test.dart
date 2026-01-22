import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/features/arm/domain/models/arm_scenario.dart';
import 'package:loan_ranger/src/features/arm/domain/services/arm_calculator_service.dart';

void main() {
  group('ArmCalculatorService', () {
    final service = ArmCalculatorService(const LoanMath());

    test('creates schedule that respects caps', () {
      final scenario = ArmScenario(
        loanAmount: 400000,
        termYears: 30,
        initialRate: 4.25,
        initialFixedYears: 5,
        adjustmentFrequencyYears: 1,
        rateChangePerAdjustment: 1.5,
        periodicCap: 2,
        lifetimeCap: 9,
        lifetimeFloor: 2,
      );

      final result = service.calculateSchedule(scenario);

      expect(result.periods.length, greaterThan(1));
      expect(result.periods.first.rate, equals(4.25));
      expect(result.periods.last.rate, lessThanOrEqualTo(9));
      expect(result.totalPaid, greaterThan(result.totalInterest));
    });

    test('handles downward adjustments with floor', () {
      final scenario = ArmScenario(
        loanAmount: 350000,
        termYears: 30,
        initialRate: 6,
        initialFixedYears: 3,
        adjustmentFrequencyYears: 1,
        rateChangePerAdjustment: -2,
        periodicCap: 2,
        lifetimeCap: 8,
        lifetimeFloor: 3,
      );

      final result = service.calculateSchedule(scenario);

      expect(result.periods.length, greaterThan(3));
      expect(result.periods.last.rate, greaterThanOrEqualTo(3));
    });
  });
}
