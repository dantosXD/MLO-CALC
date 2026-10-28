import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/government_fees.dart';

void main() {
  group('GovernmentFees', () {
    const fees = GovernmentFees();

    double mip(double loan, double ltv, double term) =>
        fees.fhaAnnualMipRate(baseLoan: loan, ltv: ltv, termYears: term);

    double va(
      double down,
      VaUse use,
      VaPurpose purpose, {
      bool exempt = false,
    }) => fees.vaFundingFeeRate(
      downPaymentPercent: down,
      use: use,
      purpose: purpose,
      exempt: exempt,
    );

    test('FHA upfront / USDA constants', () {
      expect(fees.fhaUpfrontMipRate(), 1.75);
      expect(fees.usdaUpfrontRate(), 1.00);
      expect(fees.usdaAnnualRate(), 0.35);
    });

    test('FHA annual MIP, >15y', () {
      expect(mip(300000, 96.5, 30), 0.55);
      expect(mip(300000, 95, 30), 0.50);
      expect(mip(726200, 96.5, 30), 0.55);
      expect(mip(726201, 96.5, 30), 0.75);
      expect(mip(726201, 95, 30), 0.70);
    });

    test('FHA annual MIP, <=15y', () {
      expect(mip(800000, 78, 15), 0.15);
      expect(mip(800000, 85, 15), 0.40);
      expect(mip(800000, 91, 15), 0.65);
      expect(mip(300000, 90, 15), 0.15);
      expect(mip(300000, 91, 15), 0.40);
    });

    test('FHA MIP months', () {
      expect(fees.fhaMipMonths(ltv: 90), 132);
      expect(fees.fhaMipMonths(ltv: 90.01), isNull);
    });

    test('VA funding fee', () {
      expect(va(0, VaUse.first, VaPurpose.purchase), 2.15);
      expect(va(4.99, VaUse.first, VaPurpose.purchase), 2.15);
      expect(va(5, VaUse.first, VaPurpose.purchase), 1.50);
      expect(va(10, VaUse.first, VaPurpose.purchase), 1.25);
      expect(va(0, VaUse.subsequent, VaPurpose.purchase), 3.30);
      expect(va(5, VaUse.subsequent, VaPurpose.purchase), 1.50);
      expect(va(10, VaUse.subsequent, VaPurpose.purchase), 1.25);
      expect(va(0, VaUse.first, VaPurpose.irrrl), 0.50);
      expect(va(0, VaUse.first, VaPurpose.cashOutRefi), 2.15);
      expect(va(20, VaUse.subsequent, VaPurpose.cashOutRefi), 3.30);
      expect(va(0, VaUse.first, VaPurpose.purchase, exempt: true), 0);
      expect(va(0, VaUse.first, VaPurpose.irrrl, exempt: true), 0);
    });

    test('2026 loan limits', () {
      expect(LoanLimits2026.conformingBaseline, 832750.0);
      expect(LoanLimits2026.highCostCeiling, 1249125.0);
      expect(LoanLimits2026.fhaFloor, 541287.0);
      expect(LoanLimits2026.fhaCeiling, 1249125.0);
    });
  });
}
