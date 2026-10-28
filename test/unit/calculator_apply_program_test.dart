import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/loan_programs/domain/models/loan_program.dart';

import 'calculator_provider_test.dart' show buildCalculatorProvider;

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  test('applyLoanProgram(FHA) sets financed loan and annual MI', () {
    final provider = buildCalculatorProvider();
    provider.setPrice(value: 400000);
    provider.setDownPayment(value: 14000);
    provider.setTermYears(value: 30);
    provider.setInterestRate(value: 6.5);
    provider.applyLoanProgram(
      DefaultLoanPrograms.programs.firstWhere((e) => e.id == 'fha_30'),
    );
    expect(provider.loanAmount, closeTo(392755, 0.001));
    expect(provider.mortgageInsurance, closeTo(2160.15, 0.01));
  });

  test('applyLoanProgram without price does nothing', () {
    final provider = buildCalculatorProvider();
    provider.applyLoanProgram(
      DefaultLoanPrograms.programs.firstWhere((e) => e.id == 'fha_30'),
    );
    expect(provider.loanAmount, isNull);
  });
}
