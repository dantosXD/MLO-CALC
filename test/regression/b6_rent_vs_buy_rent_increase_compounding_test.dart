// Regression: BUGLOG B6 — rent-vs-buy break-even simulation applied
// annualRentIncrease as a monthly compound (÷12 per month and applied every
// month), while the yearly projections applied it as an annual step once per
// year (month % 12 == 0). The two simulations therefore diverged on identical
// inputs and produced inconsistent results.
//
// Fix: align the break-even simulation to the annual-step model (rent changes
// once per 12 months at lease renewal), matching how projections already work.
//
// Hand-computed expected value for the break-even test (see inline comments):
//   annual step  → breakEvenMonths ≈ 117
//   monthly compound (bug) → breakEvenMonths ≈ 111
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/rent_vs_buy/domain/models/rent_vs_buy_calculation.dart';
import 'package:loan_ranger/src/features/rent_vs_buy/domain/services/rent_vs_buy_calculator.dart';

const _calc = RentVsBuyCalculator();

// Complex inputs for projection tests (rent trajectory is in projections, not
// the break-even simulation, so compounding bug doesn't affect these).
const _projInputs = RentVsBuyInputs(
  homePrice: 500000,
  downPaymentPercent: 10,
  interestRate: 7.5,
  termYears: 30,
  propertyTaxRate: 1.2,
  homeInsuranceAnnual: 2400,
  hoaMonthly: 200,
  maintenancePercent: 1.0,
  closingCostsPercent: 0,
  pmiRate: 0.5,
  monthlyRent: 1800,
  annualRentIncrease: 12.0,
  rentersInsuranceMonthly: 20,
  homeAppreciationRate: 4.0,
  investmentReturnRate: 7.0,
  marginalTaxRate: 22.0,
  analysisYears: 15,
);

// Minimal inputs for a deterministic break-even test:
//   0% interest → monthly P&I = 80000/360 = 222.22/mo (no interest math)
//   0% appreciation, 0% investment return → netWorthBuying stays ~0
//   rent ($100/mo) < buying ($222/mo) → renting cheaper → equity path
//   Break-even condition: cumulativeRent >= totalUpfrontCost (20000)
//
// Annual step: cumulative after 9 yrs = 17731, cross 20000 at month 117
// Monthly compound (bug): cross at month 111 (rent appears to grow faster)
const _simpleInputs = RentVsBuyInputs(
  homePrice: 100000,
  downPaymentPercent: 20, // $20 000 down, LTV = 80 → no PMI
  interestRate: 0, // 0% → P&I = flat principal paydown
  termYears: 30,
  propertyTaxRate: 0,
  homeInsuranceAnnual: 0,
  hoaMonthly: 0,
  maintenancePercent: 0,
  closingCostsPercent: 0,
  pmiRate: 0,
  monthlyRent: 100, // cheap → equity path
  annualRentIncrease: 12.0,
  rentersInsuranceMonthly: 0,
  homeAppreciationRate: 0,
  investmentReturnRate: 0,
  marginalTaxRate: 0,
  analysisYears: 12,
);

void main() {
  group('B6: rent increase uses annual step, not monthly compound', () {
    // ── Projections tests (annual step already correct, these document it) ──

    test('year-1 projection rent = monthlyRent × (1 + annualRentIncrease%)', () {
      // Annual step: 1800 × 1.12 = 2016.00
      // Monthly compound would give: 1800 × (1.01)^12 ≈ 2028.24 (wrong)
      final result = _calc.calculate(_projInputs);
      expect(
        result.projections.first.rentAtYear,
        closeTo(1800 * 1.12, 0.02),
        reason: 'projections must use annual step, not monthly compound',
      );
    });

    test('year-2 projection rent = year-1 rent × (1 + annualRentIncrease%)', () {
      final result = _calc.calculate(_projInputs);
      expect(
        result.projections[1].rentAtYear,
        closeTo(1800 * 1.12 * 1.12, 0.05),
      );
    });

    // ── Break-even simulation test (this is the regression) ──

    test('break-even simulation uses annual step: breakEvenMonths ≈ 117 not 111', () {
      // With 0% interest/appreciation/return the break-even simplifies to:
      //   netWorthBuying ≈ 0 throughout (equity growth exactly offsets buying costs)
      //   break-even when cumulativeRent >= totalUpfrontCost (20000)
      //
      // Annual step (correct): cumulative rent crosses 20000 at month 117.
      //   Year 1-9 cumulative = 17731 (rent starts $100, grows ×1.12 per year)
      //   Year 10 rent = $277.31/mo; need $2269 more; 2269/277 ≈ 8.2 mo → month 117
      //
      // Monthly compound (bug): 100 × (1.01^N − 1)/0.01 ≥ 20000
      //   ⟹ 1.01^N ≥ 3 ⟹ N ≥ 110.4 → month 111 (6 months too early)
      final result = _calc.calculate(_simpleInputs);
      expect(
        result.breakEvenMonths,
        closeTo(117, 3), // annual step ≈ 117; monthly compound gives 111
        reason: 'break-even must use annual rent step; monthly compound gives 111',
      );
    });
  });
}
