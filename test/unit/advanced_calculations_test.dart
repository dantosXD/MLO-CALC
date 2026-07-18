import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/utils/advanced_calculations.dart';

void main() {
  group('AdvancedCalculations.calculateAPR', () {
    test('no fees or points → APR equals nominal rate', () {
      final apr = AdvancedCalculations.calculateAPR(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
        loanFees: 0,
        points: 0,
      );
      expect(apr, closeTo(7.0, 0.01));
    });

    test('with fees and points → APR exceeds nominal rate', () {
      // $2k fees + 1 point ($4k) on $400k loan → APR ≈ 7.196%
      final apr = AdvancedCalculations.calculateAPR(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
        loanFees: 2000,
        points: 1.0,
      );
      expect(apr, greaterThan(7.0));
      expect(apr, closeTo(7.196, 0.05));
    });

    test('returns finite positive value for standard inputs', () {
      final apr = AdvancedCalculations.calculateAPR(
        loanAmount: 250000,
        interestRate: 6.5,
        termYears: 15,
        loanFees: 1500,
        points: 0.5,
      );
      expect(apr.isFinite, isTrue);
      expect(apr, greaterThan(0));
    });

    test('higher fees produce higher APR', () {
      final aprLowFees = AdvancedCalculations.calculateAPR(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
        loanFees: 1000,
        points: 0,
      );
      final aprHighFees = AdvancedCalculations.calculateAPR(
        loanAmount: 400000,
        interestRate: 7.0,
        termYears: 30,
        loanFees: 5000,
        points: 0,
      );
      expect(aprHighFees, greaterThan(aprLowFees));
    });
  });

  group('AdvancedCalculations.calculatePointsBreakEven', () {
    test('positive months when discounted rate is lower than original', () {
      // Buy 1 point to reduce rate from 7.0% to 6.875% on $400k, 30yr
      final months = AdvancedCalculations.calculatePointsBreakEven(
        loanAmount: 400000,
        originalRate: 7.0,
        discountedRate: 6.875,
        termYears: 30,
        pointsCost: 4000,
      );
      expect(months.isFinite, isTrue);
      expect(months, greaterThan(0));
    });

    test('returns infinity when rates are equal (no savings)', () {
      final months = AdvancedCalculations.calculatePointsBreakEven(
        loanAmount: 400000,
        originalRate: 7.0,
        discountedRate: 7.0,
        termYears: 30,
        pointsCost: 4000,
      );
      expect(months, equals(double.infinity));
    });

    test('returns infinity when discounted rate is higher than original', () {
      final months = AdvancedCalculations.calculatePointsBreakEven(
        loanAmount: 400000,
        originalRate: 7.0,
        discountedRate: 7.25,
        termYears: 30,
        pointsCost: 4000,
      );
      expect(months, equals(double.infinity));
    });

    test('larger rate reduction results in faster break-even', () {
      final monthsBig = AdvancedCalculations.calculatePointsBreakEven(
        loanAmount: 400000,
        originalRate: 7.0,
        discountedRate: 6.5,
        termYears: 30,
        pointsCost: 4000,
      );
      final monthsSmall = AdvancedCalculations.calculatePointsBreakEven(
        loanAmount: 400000,
        originalRate: 7.0,
        discountedRate: 6.875,
        termYears: 30,
        pointsCost: 4000,
      );
      expect(monthsBig, lessThan(monthsSmall));
    });
  });

  group('AdvancedCalculations.calculateOddDaysInterest', () {
    test('0 days → 0 interest', () {
      final interest = AdvancedCalculations.calculateOddDaysInterest(
        loanAmount: 300000,
        interestRate: 6.5,
        daysUntilFirstPayment: 0,
      );
      expect(interest, equals(0.0));
    });

    test('15 days at 6.5% on 300k — matches 365-day daily rate formula', () {
      // 300000 * (0.065 / 365) * 15 = 801.37 (365-day year)
      final interest = AdvancedCalculations.calculateOddDaysInterest(
        loanAmount: 300000,
        interestRate: 6.5,
        daysUntilFirstPayment: 15,
      );
      expect(interest, closeTo(801.37, 1.00));
    });

    test('interest scales linearly with days', () {
      final interest30 = AdvancedCalculations.calculateOddDaysInterest(
        loanAmount: 300000,
        interestRate: 6.5,
        daysUntilFirstPayment: 30,
      );
      final interest15 = AdvancedCalculations.calculateOddDaysInterest(
        loanAmount: 300000,
        interestRate: 6.5,
        daysUntilFirstPayment: 15,
      );
      // 30 days should be approximately twice 15 days (allowing for rounding)
      expect(interest30, closeTo(interest15 * 2, 1.00));
    });

    test('interest scales with loan amount', () {
      final interest400k = AdvancedCalculations.calculateOddDaysInterest(
        loanAmount: 400000,
        interestRate: 6.5,
        daysUntilFirstPayment: 15,
      );
      final interest200k = AdvancedCalculations.calculateOddDaysInterest(
        loanAmount: 200000,
        interestRate: 6.5,
        daysUntilFirstPayment: 15,
      );
      expect(interest400k, closeTo(interest200k * 2, 1.00));
    });
  });

  group('AdvancedCalculations.calculateFutureEquity', () {
    test('returns finite positive value for standard inputs', () {
      final equity = AdvancedCalculations.calculateFutureEquity(
        initialValue: 500000,
        loanAmount: 400000,
        appreciationRate: 3.0,
        interestRate: 7.0,
        termYears: 30,
        years: 10,
      );
      expect(equity.isFinite, isTrue);
      expect(equity, greaterThan(0));
    });

    test('positive appreciation grows equity compared to 0% appreciation', () {
      final equityWith3Pct = AdvancedCalculations.calculateFutureEquity(
        initialValue: 500000,
        loanAmount: 400000,
        appreciationRate: 3.0,
        interestRate: 7.0,
        termYears: 30,
        years: 10,
      );
      final equityWith0Pct = AdvancedCalculations.calculateFutureEquity(
        initialValue: 500000,
        loanAmount: 400000,
        appreciationRate: 0.0,
        interestRate: 7.0,
        termYears: 30,
        years: 10,
      );
      expect(equityWith3Pct, greaterThan(equityWith0Pct));
    });

    test('equity increases over time with positive appreciation', () {
      final equity5yr = AdvancedCalculations.calculateFutureEquity(
        initialValue: 500000,
        loanAmount: 400000,
        appreciationRate: 3.0,
        interestRate: 7.0,
        termYears: 30,
        years: 5,
      );
      final equity10yr = AdvancedCalculations.calculateFutureEquity(
        initialValue: 500000,
        loanAmount: 400000,
        appreciationRate: 3.0,
        interestRate: 7.0,
        termYears: 30,
        years: 10,
      );
      expect(equity10yr, greaterThan(equity5yr));
    });

    test('equity at year 0 equals initial down payment (value minus loan)', () {
      final equity = AdvancedCalculations.calculateFutureEquity(
        initialValue: 500000,
        loanAmount: 400000,
        appreciationRate: 0.0,
        interestRate: 7.0,
        termYears: 30,
        years: 0,
      );
      // At year 0: value=500000, balance=400000, equity=100000
      expect(equity, closeTo(100000, 1.00));
    });

    test('full-term equity equals property value (loan fully paid)', () {
      // After full term, balance should be ~0
      final equity = AdvancedCalculations.calculateFutureEquity(
        initialValue: 400000,
        loanAmount: 400000,
        appreciationRate: 0.0,
        interestRate: 7.0,
        termYears: 30,
        years: 30,
      );
      // With 0% appreciation and 100% LTV loan, after 30 years equity ≈ property value
      expect(equity, closeTo(400000, 5.00));
    });
  });
}
