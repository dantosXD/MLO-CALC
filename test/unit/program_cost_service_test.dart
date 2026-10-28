import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/loan_programs/domain/models/loan_program.dart';
import 'package:loan_ranger/src/features/loan_programs/domain/services/program_cost_service.dart';

LoanProgram p(String id) =>
    DefaultLoanPrograms.programs.firstWhere((e) => e.id == id);

void main() {
  const svc = ProgramCostService();

  test('FHA finances UFMIP and charges 0.55% annual', () {
    final c = svc.compute(
      program: p('fha_30'),
      price: 400000,
      downPayment: 14000,
      termYears: 30,
    );
    expect(c.baseLoan, 386000);
    expect(c.upfrontFee, closeTo(6755, 0.001));
    expect(c.totalLoan, closeTo(392755, 0.001));
    expect(c.annualMi, closeTo(2160.15, 0.01));
    expect(c.miMonths, isNull);
  });

  test('VA funding fee and exemption', () {
    final c = svc.compute(
      program: p('va_30'),
      price: 400000,
      downPayment: 0,
      termYears: 30,
    );
    expect(c.upfrontFee, closeTo(8600, 0.001));
    expect(c.annualMi, 0);
    final e = svc.compute(
      program: p('va_30'),
      price: 400000,
      downPayment: 0,
      termYears: 30,
      eligibility: const BorrowerEligibility(vaExempt: true),
    );
    expect(e.upfrontFee, 0);
  });

  test('Conventional MI only above 80% LTV', () {
    final a = svc.compute(
      program: p('conventional_30'),
      price: 400000,
      downPayment: 80000,
      termYears: 30,
    );
    expect(a.annualMi, 0);
    final b = svc.compute(
      program: p('conventional_30'),
      price: 400000,
      downPayment: 20000,
      termYears: 30,
    );
    expect(b.annualMi, closeTo(b.baseLoan * 0.005, 0.001));
  });

  test('Conventional over conforming limit flags exceedsLimit', () {
    final c = svc.compute(
      program: p('conventional_30'),
      price: 1000000,
      downPayment: 100000,
      termYears: 30,
    );
    expect(c.exceedsLimit, isTrue);
  });

  test('Jumbo has no MI or fee', () {
    final c = svc.compute(
      program: p('jumbo_30'),
      price: 1000000,
      downPayment: 100000,
      termYears: 30,
    );
    expect(c.annualMi, 0);
    expect(c.upfrontFee, 0);
    expect(c.exceedsLimit, isFalse);
  });
}
