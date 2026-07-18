// Regression: BUGLOG B5 — ARM _nextRate applied the lifetime floor AFTER the
// lifetime cap, so a misconfigured floor > cap could silently push the rate
// above the declared maximum. Fix: apply floor first, cap last — cap is the
// hard ceiling and always wins.
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/features/arm/domain/models/arm_scenario.dart';
import 'package:loan_ranger/src/features/arm/domain/services/arm_calculator_service.dart';

ArmCalculatorService _service() => ArmCalculatorService(const LoanMath());

ArmScenario _scenario({
  double initialRate = 3.0,
  double rateChange = 5.0,
  double periodicCap = 0,
  double lifetimeCap = 4.0,
  double lifetimeFloor = 0.0,
}) => ArmScenario(
  loanAmount: 200000,
  termYears: 30,
  initialRate: initialRate,
  initialFixedYears: 1,
  adjustmentFrequencyYears: 1,
  rateChangePerAdjustment: rateChange,
  periodicCap: periodicCap,
  lifetimeCap: lifetimeCap,
  lifetimeFloor: lifetimeFloor,
);

void main() {
  group('B5: ARM lifetime cap is a hard ceiling over floor', () {
    test('cap wins when floor > cap (misconfigured: floor 5%, cap 4%)', () {
      // raw = 3 + 5 = 8 → capped to 4 → floor would push to 5 (BUG)
      // Fix: floor applied before cap → cap stays at 4
      final result = _service().calculateSchedule(
        _scenario(lifetimeCap: 4.0, lifetimeFloor: 5.0),
      );
      expect(result.periods.length, greaterThan(1));
      expect(result.periods[1].rate, 4.0,
          reason: 'cap (4%) must win over misconfigured floor (5%)');
    });

    test('floor constrains rate when well-configured below cap', () {
      // rate = 3 - 5 = -2, floored to 2, cap = 8 (not reached)
      final result = _service().calculateSchedule(
        _scenario(
          initialRate: 5.0,
          rateChange: -5.0,
          lifetimeCap: 8.0,
          lifetimeFloor: 2.0,
        ),
      );
      expect(result.periods.length, greaterThan(1));
      expect(result.periods[1].rate, 2.0,
          reason: 'floor (2%) should constrain a rate that would go to 0%');
    });

    test('lifetime cap of 0 is unconstrained — rate can rise freely', () {
      // cap = 0 means "no cap"; rate = 3 + 10 = 13, no ceiling
      final result = _service().calculateSchedule(
        _scenario(rateChange: 10.0, lifetimeCap: 0, lifetimeFloor: 0),
      );
      expect(result.periods.length, greaterThan(1));
      expect(result.periods[1].rate, closeTo(13.0, 0.001),
          reason: 'cap 0 = unconstrained; rate should reach 3 + 10 = 13%');
    });

    test('periodic cap of 0 is unconstrained — large adjustment applies fully', () {
      // periodicCap = 0 → full 8% jump applies; still bounded by lifetimeCap
      final result = _service().calculateSchedule(
        _scenario(rateChange: 8.0, periodicCap: 0, lifetimeCap: 0),
      );
      expect(result.periods.length, greaterThan(1));
      expect(result.periods[1].rate, closeTo(11.0, 0.001));
    });
  });
}
