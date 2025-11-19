/// Provider for managing calculation comparison state
library;

import 'package:flutter/foundation.dart';
import '../models/calculation_history.dart';

/// Manages selection and comparison of calculation entries
class ComparisonProvider extends ChangeNotifier {
  final Set<String> _selectedIds = {};
  static const int maxSelections = 3;

  /// Get currently selected IDs
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  /// Check if an entry is selected
  bool isSelected(String id) => _selectedIds.contains(id);

  /// Get number of selected entries
  int get selectionCount => _selectedIds.length;

  /// Check if comparison is available (2+ selections)
  bool get canCompare => _selectedIds.length >= 2;

  /// Check if max selections reached
  bool get isMaxSelected => _selectedIds.length >= maxSelections;

  /// Toggle selection for an entry
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      if (_selectedIds.length < maxSelections) {
        _selectedIds.add(id);
      }
    }
    notifyListeners();
  }

  /// Clear all selections
  void clearSelections() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// Select multiple entries
  void selectMultiple(List<String> ids) {
    _selectedIds.clear();
    final limitedIds = ids.take(maxSelections);
    _selectedIds.addAll(limitedIds);
    notifyListeners();
  }

  /// Get selected entries from history
  List<CalculationEntry> getSelectedEntries(List<CalculationEntry> allEntries) {
    return allEntries
        .where((entry) => _selectedIds.contains(entry.id))
        .toList();
  }

  /// Get comparison data for selected entries
  ComparisonData? getComparisonData(List<CalculationEntry> allEntries) {
    final selected = getSelectedEntries(allEntries);
    if (selected.length < 2) return null;

    return ComparisonData(entries: selected);
  }
}

/// Holds comparison data and calculations
class ComparisonData {
  final List<CalculationEntry> entries;

  ComparisonData({required this.entries});

  /// Get the entry with lowest total cost
  CalculationEntry? get lowestCost {
    final comparable = entries.where((e) => e.isComparable && e.totalPaid != null);
    if (comparable.isEmpty) return null;

    return comparable.reduce((a, b) =>
        a.totalPaid! < b.totalPaid! ? a : b);
  }

  /// Get the entry with lowest monthly payment
  CalculationEntry? get lowestPayment {
    final comparable = entries.where((e) => e.isComparable && e.monthlyPayment != null);
    if (comparable.isEmpty) return null;

    return comparable.reduce((a, b) =>
        a.monthlyPayment! < b.monthlyPayment! ? a : b);
  }

  /// Get the entry with lowest interest
  CalculationEntry? get lowestInterest {
    final comparable = entries.where((e) => e.isComparable && e.totalInterest != null);
    if (comparable.isEmpty) return null;

    return comparable.reduce((a, b) =>
        a.totalInterest! < b.totalInterest! ? a : b);
  }

  /// Get the entry with shortest term
  CalculationEntry? get shortestTerm {
    final comparable = entries.where((e) => e.isComparable && e.termYears != null);
    if (comparable.isEmpty) return null;

    return comparable.reduce((a, b) =>
        a.termYears! < b.termYears! ? a : b);
  }

  /// Calculate difference between two values
  static double? calculateDifference(double? value1, double? value2) {
    if (value1 == null || value2 == null) return null;
    return value2 - value1;
  }

  /// Calculate percentage difference
  static double? calculatePercentageDifference(double? value1, double? value2) {
    if (value1 == null || value2 == null || value1 == 0) return null;
    return ((value2 - value1) / value1) * 100;
  }

  /// Get comparison summary statistics
  ComparisonSummary get summary {
    final comparable = entries.where((e) => e.isComparable).toList();

    if (comparable.isEmpty) {
      return ComparisonSummary(
        count: entries.length,
        comparableCount: 0,
      );
    }

    // Calculate ranges
    final payments = comparable.map((e) => e.monthlyPayment!).toList();
    final totalCosts = comparable.map((e) => e.totalPaid!).toList();
    final interests = comparable.map((e) => e.totalInterest!).toList();

    return ComparisonSummary(
      count: entries.length,
      comparableCount: comparable.length,
      minPayment: payments.reduce((a, b) => a < b ? a : b),
      maxPayment: payments.reduce((a, b) => a > b ? a : b),
      minTotalCost: totalCosts.reduce((a, b) => a < b ? a : b),
      maxTotalCost: totalCosts.reduce((a, b) => a > b ? a : b),
      minInterest: interests.reduce((a, b) => a < b ? a : b),
      maxInterest: interests.reduce((a, b) => a > b ? a : b),
    );
  }
}

/// Summary statistics for comparison
class ComparisonSummary {
  final int count;
  final int comparableCount;
  final double? minPayment;
  final double? maxPayment;
  final double? minTotalCost;
  final double? maxTotalCost;
  final double? minInterest;
  final double? maxInterest;

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

  double? get paymentRange =>
      (minPayment != null && maxPayment != null)
          ? maxPayment! - minPayment!
          : null;

  double? get totalCostRange =>
      (minTotalCost != null && maxTotalCost != null)
          ? maxTotalCost! - minTotalCost!
          : null;

  double? get interestRange =>
      (minInterest != null && maxInterest != null)
          ? maxInterest! - minInterest!
          : null;
}
