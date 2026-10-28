import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/refinance/domain/models/refinance.dart';
import 'package:loan_ranger/src/features/refinance/domain/services/refinance_analyzer.dart';

void main() {
  const analyzer = RefinanceAnalyzer();

  RefinanceInputs inputs({
    double currentRate = 7.5,
    double newRate = 6.25,
    double closingCosts = 6000,
    double cashOut = 0,
    double miRate = 0,
    RefiProgram program = RefiProgram.conventional,
  }) => RefinanceInputs(
    currentBalance: 300000,
    currentRate: currentRate,
    currentRemainingYears: 28,
    currentAnnualMiRate: miRate,
    newRate: newRate,
    newTermYears: 30,
    closingCosts: closingCosts,
    cashOut: cashOut,
    program: program,
  );

  test('savings and break-even', () {
    final r = analyzer.analyze(inputs());
    expect(r.monthlySavings, greaterThan(0));
    expect(r.breakEvenMonths, closeTo(6000 / r.monthlySavings, 0.01));
    expect(r.ntbMet, isNull);
    expect(r.ntbReason, isNull);
  });

  test('VA IRRRL fails past 36 months', () {
    final base = analyzer.analyze(inputs(closingCosts: 0));
    final r = analyzer.analyze(
      inputs(
        closingCosts: base.monthlySavings * 40,
        program: RefiProgram.vaIrrrl,
      ),
    );
    expect(r.breakEvenMonths, closeTo(40, 0.01));
    expect(r.ntbMet, false);
    expect(r.ntbReason, contains('36'));
  });

  test('FHA streamline needs 0.5 combined reduction', () {
    final met = analyzer.analyze(
      inputs(
        currentRate: 6.75,
        newRate: 6.25,
        miRate: 0.55,
        program: RefiProgram.fhaStreamline,
      ),
    );
    expect(met.ntbMet, true);
    final notMet = analyzer.analyze(
      inputs(
        currentRate: 6.75,
        newRate: 6.5,
        miRate: 0.55,
        program: RefiProgram.fhaStreamline,
      ),
    );
    expect(notMet.ntbMet, false);
  });

  test('higher new rate never breaks even', () {
    final r = analyzer.analyze(inputs(newRate: 8));
    expect(r.breakEvenMonths, isNull);
  });

  test('cash out raises new payment', () {
    final a = analyzer.analyze(inputs());
    final b = analyzer.analyze(inputs(cashOut: 50000));
    expect(b.newPayment, greaterThan(a.newPayment));
  });

  test('FHA streamline exact 0.50 drop is met despite float error', () {
    final r = analyzer.analyze(
      inputs(
        currentRate: 4.10,
        newRate: 3.60,
        program: RefiProgram.fhaStreamline,
      ),
    );
    expect(r.ntbMet, true);
    expect(r.ntbReason, isNot(contains('only')));
  });

  test('VA IRRRL met well inside 36 months and exactly at 36', () {
    final base = analyzer.analyze(inputs(closingCosts: 0));
    final early = analyzer.analyze(
      inputs(closingCosts: 1000, program: RefiProgram.vaIrrrl),
    );
    expect(early.ntbMet, true);
    final edge = analyzer.analyze(
      inputs(
        closingCosts: base.monthlySavings * 36,
        program: RefiProgram.vaIrrrl,
      ),
    );
    expect(edge.ntbMet, true);
  });
}
