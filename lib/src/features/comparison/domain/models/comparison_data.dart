import 'dart:math' as math;

import 'package:loan_ranger/src/core/models/calculation_history.dart';

class ComparisonData {
  ComparisonData({required this.views, required this.summary});

  final List<ComparisonEntryView> views;
  final ComparisonSummary summary;

  ComparisonEntryView get baseline =>
      views.firstWhere((view) => view.isBaseline, orElse: () => views.first);

  static ComparisonData fromEntries(List<CalculationEntry> entries) {
    final views = entries.map(_buildView).toList();

    final ComparisonEntryView? baseline = views
        .where((view) => view.totalCost != null)
        .fold<ComparisonEntryView?>(null, (prev, curr) {
          if (prev == null) return curr;
          if (curr.totalCost != null && curr.totalCost! < prev.totalCost!) {
            return curr;
          }
          return prev;
        });

    final ComparisonEntryView? resolvedBaseline =
        baseline ?? (views.isNotEmpty ? views.first : null);

    final decoratedViews = views.map((view) {
      if (resolvedBaseline == null) return view;
      final breakEven = view.entry.id == resolvedBaseline.entry.id
          ? null
          : _estimateBreakEvenMonths(resolvedBaseline, view);
      return view.copyWith(
        isBaseline: view.entry.id == resolvedBaseline.entry.id,
        breakEvenMonths: breakEven,
      );
    }).toList();

    return ComparisonData(
      views: decoratedViews,
      summary: ComparisonSummary.fromViews(decoratedViews),
    );
  }

  static ComparisonEntryView _buildView(CalculationEntry entry) {
    return ComparisonEntryView(
      entry: entry,
      monthlyPayment: entry.monthlyPayment,
      totalCost: entry.totalPaid,
      totalInterest: entry.totalInterest,
      termYears: entry.termYears,
      miDropMonth: _estimateMiDropMonth(entry),
      pitiPayment: entry.pitiPayment,
      isBaseline: false,
    );
  }
}

class ComparisonEntryView {
  const ComparisonEntryView({
    required this.entry,
    required this.monthlyPayment,
    required this.totalCost,
    required this.totalInterest,
    required this.termYears,
    required this.miDropMonth,
    required this.pitiPayment,
    required this.isBaseline,
    this.breakEvenMonths,
  });

  final CalculationEntry entry;
  final double? monthlyPayment;
  final double? totalCost;
  final double? totalInterest;
  final double? termYears;
  final int? miDropMonth;
  final double? pitiPayment;
  final bool isBaseline;
  final double? breakEvenMonths;

  ComparisonEntryView copyWith({bool? isBaseline, double? breakEvenMonths}) {
    return ComparisonEntryView(
      entry: entry,
      monthlyPayment: monthlyPayment,
      totalCost: totalCost,
      totalInterest: totalInterest,
      termYears: termYears,
      miDropMonth: miDropMonth,
      pitiPayment: pitiPayment,
      isBaseline: isBaseline ?? this.isBaseline,
      breakEvenMonths: breakEvenMonths ?? this.breakEvenMonths,
    );
  }
}

class ComparisonSummary {
  ComparisonSummary({
    required this.count,
    required this.comparableCount,
    this.minPayment,
    this.maxPayment,
    this.minTotalCost,
    this.maxTotalCost,
    this.minInterest,
    this.maxInterest,
  });

  final int count;
  final int comparableCount;
  final double? minPayment;
  final double? maxPayment;
  final double? minTotalCost;
  final double? maxTotalCost;
  final double? minInterest;
  final double? maxInterest;

  double? get paymentRange => _range(minPayment, maxPayment);
  double? get totalCostRange => _range(minTotalCost, maxTotalCost);
  double? get interestRange => _range(minInterest, maxInterest);

  static ComparisonSummary fromViews(List<ComparisonEntryView> views) {
    final comparable = views.where(
      (view) =>
          view.monthlyPayment != null &&
          view.totalCost != null &&
          view.totalInterest != null,
    );

    if (comparable.isEmpty) {
      return ComparisonSummary(count: views.length, comparableCount: 0);
    }

    double minPayment = double.infinity;
    double maxPayment = 0;
    double minTotalCost = double.infinity;
    double maxTotalCost = 0;
    double minInterest = double.infinity;
    double maxInterest = 0;

    for (final view in comparable) {
      minPayment = math.min(minPayment, view.monthlyPayment!);
      maxPayment = math.max(maxPayment, view.monthlyPayment!);
      minTotalCost = math.min(minTotalCost, view.totalCost!);
      maxTotalCost = math.max(maxTotalCost, view.totalCost!);
      minInterest = math.min(minInterest, view.totalInterest!);
      maxInterest = math.max(maxInterest, view.totalInterest!);
    }

    return ComparisonSummary(
      count: views.length,
      comparableCount: comparable.length,
      minPayment: minPayment.isFinite ? minPayment : null,
      maxPayment: maxPayment == 0 ? null : maxPayment,
      minTotalCost: minTotalCost.isFinite ? minTotalCost : null,
      maxTotalCost: maxTotalCost == 0 ? null : maxTotalCost,
      minInterest: minInterest.isFinite ? minInterest : null,
      maxInterest: maxInterest == 0 ? null : maxInterest,
    );
  }

  static double? _range(double? min, double? max) {
    if (min == null || max == null) return null;
    return max - min;
  }
}

double? _estimateBreakEvenMonths(
  ComparisonEntryView baseline,
  ComparisonEntryView candidate,
) {
  if (baseline.totalCost == null ||
      candidate.totalCost == null ||
      baseline.monthlyPayment == null ||
      candidate.monthlyPayment == null) {
    return null;
  }

  final double costDelta = candidate.totalCost! - baseline.totalCost!;
  final double paymentDelta =
      baseline.monthlyPayment! - candidate.monthlyPayment!;

  if (paymentDelta.abs() < 1e-6) return null;

  return (costDelta.abs() / paymentDelta.abs()).clamp(0, 1000);
}

int? _estimateMiDropMonth(CalculationEntry entry) {
  final double? price = entry.price;
  final double? loanAmount = entry.loanAmount;
  final double? rate = entry.interestRate;
  final double? termYears = entry.termYears;
  final double? payment = entry.monthlyPayment;

  if (price == null ||
      loanAmount == null ||
      rate == null ||
      termYears == null ||
      payment == null) {
    return null;
  }

  final double targetBalance = price * 0.8;
  final double monthlyRate = rate / 100 / 12;
  final int totalMonths = (termYears * 12).round();
  double balance = loanAmount;

  for (int month = 1; month <= totalMonths; month++) {
    final double interestPaid = monthlyRate > 0 ? balance * monthlyRate : 0;
    final double principalPaid = payment - interestPaid;
    if (principalPaid <= 0) {
      break; // payment doesn't cover interest; MI never drops
    }
    balance -= principalPaid;
    if (balance <= targetBalance) {
      return month;
    }
    if (balance <= 0) break;
  }

  return null;
}
