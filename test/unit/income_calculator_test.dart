import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/income/domain/models/income.dart';
import 'package:loan_ranger/src/features/income/domain/services/income_calculator.dart';

ScheduleCYear _c(double np) => ScheduleCYear(netProfit: np);

void main() {
  const calc = IncomeCalculator();

  test('ScheduleCYear.adjusted adds back and subtracts nonrecurring', () {
    const y = ScheduleCYear(
      netProfit: 50000,
      depreciation: 5000,
      depletion: 1000,
      businessUseOfHome: 2000,
      amortization: 500,
      nonrecurring: 3500,
    );
    expect(y.adjusted, 55000);
  });

  group('selfEmployedMonthly', () {
    test('increasing averages two years', () {
      expect(
        calc.selfEmployedMonthly(priorYear: _c(60000), recentYear: _c(72000)),
        5500,
      );
    });
    test('declining uses recent year only', () {
      expect(
        calc.selfEmployedMonthly(priorYear: _c(72000), recentYear: _c(60000)),
        5000,
      );
    });
    test('floors at 0', () {
      expect(
        calc.selfEmployedMonthly(priorYear: _c(-5000), recentYear: _c(-1000)),
        0,
      );
    });
  });

  group('variableMonthly', () {
    test('increasing, no ytd', () {
      expect(
        calc.variableMonthly(
          priorYear: 24000,
          recentYear: 30000,
          ytd: 0,
          ytdMonths: 0,
        ),
        2250,
      );
    });
    test('weak ytd lowers it', () {
      expect(
        calc.variableMonthly(
          priorYear: 24000,
          recentYear: 30000,
          ytd: 9000,
          ytdMonths: 6,
        ),
        1500,
      );
    });
    test('declining uses recent / 12', () {
      expect(
        calc.variableMonthly(
          priorYear: 36000,
          recentYear: 24000,
          ytd: 0,
          ytdMonths: 0,
        ),
        2000,
      );
    });
  });

  test('rentalMonthly', () {
    expect(calc.rentalMonthly(grossMonthlyRent: 2000, monthlyPitia: 1200), 300);
    expect(
      calc.rentalMonthly(grossMonthlyRent: 1200, monthlyPitia: 1200),
      -300,
    );
  });

  test('studentLoanMonthly', () {
    double f(StudentLoanAgency a, [double pay = 0]) => calc.studentLoanMonthly(
      agency: a,
      balance: 40000,
      reportedPayment: pay,
    );
    expect(f(StudentLoanAgency.fannie), 400);
    expect(f(StudentLoanAgency.freddie), 200);
    expect(f(StudentLoanAgency.fha), 200);
    expect(f(StudentLoanAgency.usda), 200);
    expect(f(StudentLoanAgency.va), closeTo(166.67, 0.01));
    for (final a in StudentLoanAgency.values) {
      expect(f(a, 250), 250);
    }
  });
}
