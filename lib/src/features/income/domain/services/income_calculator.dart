import 'dart:math' as math;

import '../models/income.dart';

class IncomeCalculator {
  const IncomeCalculator();

  double selfEmployedMonthly({
    required ScheduleCYear priorYear,
    required ScheduleCYear recentYear,
  }) => math.max(0, _trend(priorYear.adjusted, recentYear.adjusted));

  /// Two-year trend; a weaker year-to-date pace lowers the result.
  double variableMonthly({
    required double priorYear,
    required double recentYear,
    required double ytd,
    required int ytdMonths,
  }) {
    var m = _trend(priorYear, recentYear);
    if (ytdMonths > 0) m = math.min(m, ytd / ytdMonths);
    return math.max(0, m);
  }

  double _trend(double prior, double recent) =>
      recent >= prior ? (prior + recent) / 24 : recent / 12;

  /// 75% of gross rent less PITIA; negative means a monthly debt.
  double rentalMonthly({
    required double grossMonthlyRent,
    required double monthlyPitia,
  }) => 0.75 * grossMonthlyRent - monthlyPitia;

  double studentLoanMonthly({
    required StudentLoanAgency agency,
    required double balance,
    required double reportedPayment,
  }) {
    if (reportedPayment > 0) return reportedPayment;
    return switch (agency) {
      StudentLoanAgency.fannie => balance * 0.01,
      StudentLoanAgency.va => balance * 0.05 / 12,
      _ => balance * 0.005,
    };
  }
}
