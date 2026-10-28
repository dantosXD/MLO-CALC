import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/closing_costs.dart';

void main() {
  const c = ClosingCosts(
    originationFee: 1,
    discountPoints: 2,
    processingFee: 4,
    underwritingFee: 8,
    appraisalFee: 16,
    creditReportFee: 32,
    floodCertificationFee: 64,
    titleInsuranceLender: 128,
    titleInsuranceOwner: 256,
    settlementFee: 512,
    recordingFees: 1024,
    transferTaxes: 2048,
    prepaidInterest: 4096,
    prepaidHomeInsurance: 8192,
    prepaidPropertyTaxes: 16384,
    initialEscrow: 32768,
    otherFees: 65536,
  );

  test('bySection groups fields per LE section', () {
    final s = c.bySection;
    expect(s[LeSection.a], 1 + 2 + 4 + 8);
    expect(s[LeSection.b], 16 + 32 + 64);
    expect(s[LeSection.c], 128 + 512);
    expect(s[LeSection.e], 1024 + 2048);
    expect(s[LeSection.f], 4096 + 8192 + 16384);
    expect(s[LeSection.g], 32768);
    expect(s[LeSection.h], 256 + 65536);
    expect(
      s.values.fold<double>(0, (a, b) => a + b),
      c.total + c.initialEscrow,
    );
  });

  test('prepaidFinanceCharges excludes appraisal', () {
    expect(c.prepaidFinanceCharges, 1 + 2 + 4 + 8 + 512 + 4096);
    expect(
      c.copyWith(appraisalFee: 999).prepaidFinanceCharges,
      c.prepaidFinanceCharges,
    );
  });

  test('apr exceeds note rate with finance charges', () {
    final apr = const ClosingCosts(
      originationFee: 4000,
    ).apr(loanAmount: 300000, interestRate: 6.5, termYears: 30);
    expect(apr, greaterThan(6.5));
    expect(apr, lessThan(6.7));
  });

  test('json round trip and legacy json without initialEscrow', () {
    expect(ClosingCosts.fromJson(c.toJson()).initialEscrow, 32768);
    final legacy = c.toJson()..remove('initialEscrow');
    expect(ClosingCosts.fromJson(legacy).initialEscrow, 0);
  });
}
