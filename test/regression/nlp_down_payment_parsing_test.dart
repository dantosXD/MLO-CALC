import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';

void main() {
  CalculationRequest p(String s) => NLPCalculatorService.parseLocally(s);

  test('"20% down at 6.5%" keeps rate 6.5 and down 20', () {
    final r = p(r'$400k home 20% down at 6.5% for 30 years');
    expect(r.interestRate, 6.5);
    expect(r.downPayment, 20);
    expect(r.price, 400000);
    expect(r.termYears, 30);
  });

  test('percent down after rate is captured as down payment', () {
    final r = p('350000 loan at 6.5% for 30 years with 3.5% down');
    expect(r.interestRate, 6.5);
    expect(r.downPayment, 3.5);
    expect(r.loanAmount, 350000);
  });

  test('"down payment 20000" is not mistaken for the monthly payment', () {
    final r = p('down payment 20000 on a 400k house at 6.5%');
    expect(r.payment, isNull);
    expect(r.downPayment, 20000);
  });

  test('real monthly payment still parsed', () {
    final r = p(r'payment of $2,500 how much loan at 6% 30 years');
    expect(r.payment, 2500);
    expect(r.action, 'calculate_loan_amount');
  });
}
