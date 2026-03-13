/// Calculation history models for storing and managing past calculations
library;

import 'dart:convert';

import 'package:loan_ranger/src/core/utils/formatters.dart';

/// Represents a single calculation in history
class CalculationEntry {
  final String id;
  final DateTime timestamp;
  final String type; // 'payment', 'loan_amount', 'term', 'interest_rate', 'qualification'
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> results;
  final String? notes;

  CalculationEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.inputs,
    required this.results,
    this.notes,
  });

  /// Create from loan calculation
  factory CalculationEntry.fromLoanCalculation({
    required String type,
    double? loanAmount,
    double? interestRate,
    double? termYears,
    double? payment,
    double? propertyTax,
    double? homeInsurance,
    double? mortgageInsurance,
    double? monthlyExpenses,
    double? price,
    double? downPayment,
    String? notes,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}';

    final inputs = <String, dynamic>{};
    final results = <String, dynamic>{};

    // Store inputs
    if (loanAmount != null) inputs['loanAmount'] = loanAmount;
    if (interestRate != null) inputs['interestRate'] = interestRate;
    if (termYears != null) inputs['termYears'] = termYears;
    if (payment != null && type == 'loan_amount') {
      inputs['payment'] = payment;
    }
    if (propertyTax != null) inputs['propertyTax'] = propertyTax;
    if (homeInsurance != null) inputs['homeInsurance'] = homeInsurance;
    if (mortgageInsurance != null) inputs['mortgageInsurance'] = mortgageInsurance;
    if (monthlyExpenses != null) inputs['monthlyExpenses'] = monthlyExpenses;
    if (price != null) inputs['price'] = price;
    if (downPayment != null) inputs['downPayment'] = downPayment;

    // Store results based on type
    switch (type) {
      case 'payment':
        if (payment != null) results['payment'] = payment;
        break;
      case 'loan_amount':
        if (loanAmount != null) results['loanAmount'] = loanAmount;
        break;
      case 'term':
        if (termYears != null) results['termYears'] = termYears;
        break;
      case 'interest_rate':
        if (interestRate != null) results['interestRate'] = interestRate;
        break;
    }

    return CalculationEntry(
      id: id,
      timestamp: now,
      type: type,
      inputs: inputs,
      results: results,
      notes: notes,
    );
  }

  /// Create from qualification calculation
  factory CalculationEntry.fromQualification({
    required double annualIncome,
    required double monthlyDebt,
    required double interestRate,
    required double termYears,
    required double maxLoanAmount,
    String? notes,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}';

    return CalculationEntry(
      id: id,
      timestamp: now,
      type: 'qualification',
      inputs: {
        'annualIncome': annualIncome,
        'monthlyDebt': monthlyDebt,
        'interestRate': interestRate,
        'termYears': termYears,
      },
      results: {
        'maxLoanAmount': maxLoanAmount,
      },
      notes: notes,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'inputs': inputs,
      'results': results,
      'notes': notes,
    };
  }

  /// Create from JSON
  factory CalculationEntry.fromJson(Map<String, dynamic> json) {
    return CalculationEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      inputs: Map<String, dynamic>.from(json['inputs'] as Map),
      results: Map<String, dynamic>.from(json['results'] as Map),
      notes: json['notes'] as String?,
    );
  }

  /// Get a human-readable title for this calculation
  String get title {
    switch (type) {
      case 'payment':
        return 'Monthly Payment Calculation';
      case 'loan_amount':
        return 'Loan Amount Calculation';
      case 'term':
        return 'Loan Term Calculation';
      case 'interest_rate':
        return 'Interest Rate Calculation';
      case 'qualification':
        return 'Qualification Analysis';
      default:
        return 'Calculation';
    }
  }

  /// Get a summary of the calculation
  String get summary {
    final buffer = StringBuffer();

    switch (type) {
      case 'payment':
        final loan = inputs['loanAmount'];
        final rate = inputs['interestRate'];
        final term = inputs['termYears'];
        final payment = results['payment'];
        buffer.write(
          '${CurrencyFormatter.formatCurrency((loan as num?)?.toDouble(), showDecimals: false)} '
          'at ${CurrencyFormatter.formatPercent((rate as num?)?.toDouble(), decimals: 3)} '
          'for ${CurrencyFormatter.formatYears((term as num?)?.toDouble())} '
          '→ ${CurrencyFormatter.formatCurrency((payment as num?)?.toDouble())}/mo',
        );
        break;
      case 'loan_amount':
        final payment = inputs['payment'];
        final rate = inputs['interestRate'];
        final term = inputs['termYears'];
        final loan = results['loanAmount'];
        buffer.write(
          '${CurrencyFormatter.formatCurrency((payment as num?)?.toDouble())}/mo '
          'at ${CurrencyFormatter.formatPercent((rate as num?)?.toDouble(), decimals: 3)} '
          'for ${CurrencyFormatter.formatYears((term as num?)?.toDouble())} '
          '→ ${CurrencyFormatter.formatCurrency((loan as num?)?.toDouble(), showDecimals: false)} loan',
        );
        break;
      case 'qualification':
        final income = inputs['annualIncome'];
        final maxLoan = results['maxLoanAmount'];
        buffer.write(
          'Income: ${CurrencyFormatter.formatCurrency((income as num?)?.toDouble(), showDecimals: false)} '
          '→ Max loan: ${CurrencyFormatter.formatCurrency((maxLoan as num?)?.toDouble(), showDecimals: false)}',
        );
        break;
      default:
        buffer.write('Calculation');
    }

    return buffer.toString();
  }

  /// Copy with new notes
  CalculationEntry copyWith({String? notes}) {
    return CalculationEntry(
      id: id,
      timestamp: timestamp,
      type: type,
      inputs: inputs,
      results: results,
      notes: notes ?? this.notes,
    );
  }

  /// Get loan amount for comparison (from inputs or results)
  double? get loanAmount {
    return (inputs['loanAmount'] ?? results['loanAmount']) as double?;
  }

  /// Get interest rate for comparison
  double? get interestRate {
    return (inputs['interestRate'] ?? results['interestRate']) as double?;
  }

  /// Get term in years for comparison
  double? get termYears {
    final term = (inputs['termYears'] ?? results['termYears']);
    return term != null ? (term as num).toDouble() : null;
  }

  /// Get monthly payment for comparison
  double? get monthlyPayment {
    return (inputs['payment'] ?? results['payment']) as double?;
  }

  /// Calculate total amount paid over loan life
  double? get totalPaid {
    final payment = monthlyPayment;
    final term = termYears;
    if (payment == null || term == null) return null;
    return payment * term * 12;
  }

  /// Calculate total interest paid
  double? get totalInterest {
    final total = totalPaid;
    final loan = loanAmount;
    if (total == null || loan == null) return null;
    return total - loan;
  }

  /// Calculate total principal (same as loan amount)
  double? get totalPrincipal => loanAmount;

  /// Calculate interest-to-principal ratio
  double? get interestToPrincipalRatio {
    final interest = totalInterest;
    final principal = totalPrincipal;
    if (interest == null || principal == null || principal == 0) return null;
    return interest / principal;
  }

  /// Get PITI components
  double? get propertyTax => inputs['propertyTax'] as double?;
  double? get homeInsurance => inputs['homeInsurance'] as double?;
  double? get mortgageInsurance => inputs['mortgageInsurance'] as double?;
  double? get monthlyExpenses => inputs['monthlyExpenses'] as double?;
  double? get price => inputs['price'] as double?;
  double? get downPayment => inputs['downPayment'] as double?;

  /// Calculate total monthly PITI payment
  double? get pitiPayment {
    final payment = monthlyPayment;
    if (payment == null) return null;

    final piti = payment +
        ((propertyTax ?? 0) / 12) +
        ((homeInsurance ?? 0) / 12) +
        ((mortgageInsurance ?? 0) / 12) +
        (monthlyExpenses ?? 0);

    return piti;
  }

  /// Check if this calculation is comparable (has required loan fields)
  bool get isComparable {
    return loanAmount != null &&
        interestRate != null &&
        termYears != null &&
        monthlyPayment != null;
  }
}

/// Manages calculation history storage and retrieval
class CalculationHistory {
  final List<CalculationEntry> _entries = [];
  static const int maxEntries = 100;

  /// Add a new calculation to history
  void addEntry(CalculationEntry entry) {
    _entries.insert(0, entry); // Add to beginning (most recent first)

    // Limit history size
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
  }

  /// Get all entries
  List<CalculationEntry> get entries => List.unmodifiable(_entries);

  /// Get entries of a specific type
  List<CalculationEntry> getEntriesByType(String type) {
    return _entries.where((e) => e.type == type).toList();
  }

  /// Get entries from a specific date range
  List<CalculationEntry> getEntriesByDateRange(DateTime start, DateTime end) {
    return _entries
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  /// Remove an entry by ID
  void removeEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
  }

  /// Clear all history
  void clearAll() {
    _entries.clear();
  }

  /// Export history to JSON string
  String toJsonString() {
    final List<Map<String, dynamic>> jsonList =
        _entries.map((e) => e.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Import history from JSON string
  void fromJsonString(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      _entries.clear();
      for (final json in jsonList) {
        _entries.add(CalculationEntry.fromJson(json as Map<String, dynamic>));
      }
    } catch (e) {
      // Handle parse errors gracefully
      // print('Error parsing calculation history: $e');
    }
  }

  /// Search entries by notes or summary
  List<CalculationEntry> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _entries.where((e) {
      final notesMatch = e.notes?.toLowerCase().contains(lowerQuery) ?? false;
      final summaryMatch = e.summary.toLowerCase().contains(lowerQuery);
      return notesMatch || summaryMatch;
    }).toList();
  }
}
