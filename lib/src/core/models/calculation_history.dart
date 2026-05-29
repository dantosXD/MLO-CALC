/// Calculation history models for storing and managing past calculations
library;

import 'dart:convert';

import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum CalculationEntryType {
  payment,
  loanAmount,
  term,
  interestRate,
  qualification;

  static CalculationEntryType fromJsonValue(Object? value) {
    if (value is CalculationEntryType) {
      return value;
    }

    final raw = value?.toString().trim();
    switch (raw) {
      case 'payment':
        return CalculationEntryType.payment;
      case 'loan_amount':
      case 'loanAmount':
        return CalculationEntryType.loanAmount;
      case 'term':
        return CalculationEntryType.term;
      case 'interest_rate':
      case 'interestRate':
        return CalculationEntryType.interestRate;
      case 'qualification':
        return CalculationEntryType.qualification;
      default:
        return CalculationEntryType.payment;
    }
  }

  String get storageName {
    switch (this) {
      case CalculationEntryType.payment:
        return 'payment';
      case CalculationEntryType.loanAmount:
        return 'loan_amount';
      case CalculationEntryType.term:
        return 'term';
      case CalculationEntryType.interestRate:
        return 'interest_rate';
      case CalculationEntryType.qualification:
        return 'qualification';
    }
  }

  String get title {
    switch (this) {
      case CalculationEntryType.payment:
        return 'Monthly Payment Calculation';
      case CalculationEntryType.loanAmount:
        return 'Loan Amount Calculation';
      case CalculationEntryType.term:
        return 'Loan Term Calculation';
      case CalculationEntryType.interestRate:
        return 'Interest Rate Calculation';
      case CalculationEntryType.qualification:
        return 'Qualification Analysis';
    }
  }
}

class CalculationEntryInputs {
  const CalculationEntryInputs({
    this.loanAmount,
    this.interestRate,
    this.termYears,
    this.payment,
    this.propertyTax,
    this.homeInsurance,
    this.mortgageInsurance,
    this.monthlyExpenses,
    this.price,
    this.downPayment,
    this.annualIncome,
    this.monthlyDebt,
  });

  final double? loanAmount;
  final double? interestRate;
  final double? termYears;
  final double? payment;
  final double? propertyTax;
  final double? homeInsurance;
  final double? mortgageInsurance;
  final double? monthlyExpenses;
  final double? price;
  final double? downPayment;
  final double? annualIncome;
  final double? monthlyDebt;

  factory CalculationEntryInputs.fromJson(Object? raw) {
    return CalculationEntryInputs(
      loanAmount: _readDouble(raw, 'loanAmount'),
      interestRate: _readDouble(raw, 'interestRate'),
      termYears: _readDouble(raw, 'termYears'),
      payment: _readDouble(raw, 'payment'),
      propertyTax: _readDouble(raw, 'propertyTax'),
      homeInsurance: _readDouble(raw, 'homeInsurance'),
      mortgageInsurance: _readDouble(raw, 'mortgageInsurance'),
      monthlyExpenses: _readDouble(raw, 'monthlyExpenses'),
      price: _readDouble(raw, 'price'),
      downPayment: _readDouble(raw, 'downPayment'),
      annualIncome: _readDouble(raw, 'annualIncome'),
      monthlyDebt: _readDouble(raw, 'monthlyDebt'),
    );
  }

  Map<String, double?> toJson() {
    return <String, double?>{
      if (loanAmount != null) 'loanAmount': loanAmount,
      if (interestRate != null) 'interestRate': interestRate,
      if (termYears != null) 'termYears': termYears,
      if (payment != null) 'payment': payment,
      if (propertyTax != null) 'propertyTax': propertyTax,
      if (homeInsurance != null) 'homeInsurance': homeInsurance,
      if (mortgageInsurance != null) 'mortgageInsurance': mortgageInsurance,
      if (monthlyExpenses != null) 'monthlyExpenses': monthlyExpenses,
      if (price != null) 'price': price,
      if (downPayment != null) 'downPayment': downPayment,
      if (annualIncome != null) 'annualIncome': annualIncome,
      if (monthlyDebt != null) 'monthlyDebt': monthlyDebt,
    };
  }

  double? operator [](String key) {
    switch (key) {
      case 'loanAmount':
        return loanAmount;
      case 'interestRate':
        return interestRate;
      case 'termYears':
        return termYears;
      case 'payment':
        return payment;
      case 'propertyTax':
        return propertyTax;
      case 'homeInsurance':
        return homeInsurance;
      case 'mortgageInsurance':
        return mortgageInsurance;
      case 'monthlyExpenses':
        return monthlyExpenses;
      case 'price':
        return price;
      case 'downPayment':
        return downPayment;
      case 'annualIncome':
        return annualIncome;
      case 'monthlyDebt':
        return monthlyDebt;
      default:
        return null;
    }
  }

  CalculationEntryInputs copyWith({
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
    double? annualIncome,
    double? monthlyDebt,
  }) {
    return CalculationEntryInputs(
      loanAmount: loanAmount ?? this.loanAmount,
      interestRate: interestRate ?? this.interestRate,
      termYears: termYears ?? this.termYears,
      payment: payment ?? this.payment,
      propertyTax: propertyTax ?? this.propertyTax,
      homeInsurance: homeInsurance ?? this.homeInsurance,
      mortgageInsurance: mortgageInsurance ?? this.mortgageInsurance,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      price: price ?? this.price,
      downPayment: downPayment ?? this.downPayment,
      annualIncome: annualIncome ?? this.annualIncome,
      monthlyDebt: monthlyDebt ?? this.monthlyDebt,
    );
  }
}

class CalculationEntryResults {
  const CalculationEntryResults({
    this.payment,
    this.loanAmount,
    this.termYears,
    this.interestRate,
    this.maxLoanAmount,
    this.monthlyPiPayment,
  });

  final double? payment;
  final double? loanAmount;
  final double? termYears;
  final double? interestRate;
  final double? maxLoanAmount;
  final double? monthlyPiPayment;

  factory CalculationEntryResults.fromJson(Object? raw) {
    return CalculationEntryResults(
      payment: _readDouble(raw, 'payment'),
      loanAmount: _readDouble(raw, 'loanAmount'),
      termYears: _readDouble(raw, 'termYears'),
      interestRate: _readDouble(raw, 'interestRate'),
      maxLoanAmount: _readDouble(raw, 'maxLoanAmount'),
      monthlyPiPayment: _readDouble(raw, 'monthlyPiPayment'),
    );
  }

  Map<String, double?> toJson() {
    return <String, double?>{
      if (payment != null) 'payment': payment,
      if (loanAmount != null) 'loanAmount': loanAmount,
      if (termYears != null) 'termYears': termYears,
      if (interestRate != null) 'interestRate': interestRate,
      if (maxLoanAmount != null) 'maxLoanAmount': maxLoanAmount,
      if (monthlyPiPayment != null) 'monthlyPiPayment': monthlyPiPayment,
    };
  }

  double? operator [](String key) {
    switch (key) {
      case 'payment':
        return payment;
      case 'loanAmount':
        return loanAmount;
      case 'termYears':
        return termYears;
      case 'interestRate':
        return interestRate;
      case 'maxLoanAmount':
        return maxLoanAmount;
      case 'monthlyPiPayment':
        return monthlyPiPayment;
      default:
        return null;
    }
  }

  CalculationEntryResults copyWith({
    double? payment,
    double? loanAmount,
    double? termYears,
    double? interestRate,
    double? maxLoanAmount,
    double? monthlyPiPayment,
  }) {
    return CalculationEntryResults(
      payment: payment ?? this.payment,
      loanAmount: loanAmount ?? this.loanAmount,
      termYears: termYears ?? this.termYears,
      interestRate: interestRate ?? this.interestRate,
      maxLoanAmount: maxLoanAmount ?? this.maxLoanAmount,
      monthlyPiPayment: monthlyPiPayment ?? this.monthlyPiPayment,
    );
  }
}

/// Represents a single calculation in history
class CalculationEntry {
  final String id;
  final DateTime timestamp;
  final CalculationEntryType type;
  final CalculationEntryInputs inputs;
  final CalculationEntryResults results;
  final String? notes;

  CalculationEntry({
    required this.id,
    required this.timestamp,
    required Object? type,
    required Object? inputs,
    required Object? results,
    this.notes,
  }) : type = CalculationEntryType.fromJsonValue(type),
       inputs = inputs is CalculationEntryInputs
           ? inputs
           : CalculationEntryInputs.fromJson(inputs),
       results = results is CalculationEntryResults
           ? results
           : CalculationEntryResults.fromJson(results);

  /// Create from loan calculation
  factory CalculationEntry.fromLoanCalculation({
    required Object? type,
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
    final id = _uuid.v4();
    final entryType = CalculationEntryType.fromJsonValue(type);

    final inputs = CalculationEntryInputs(
      loanAmount: loanAmount,
      interestRate: interestRate,
      termYears: termYears,
      payment: entryType == CalculationEntryType.loanAmount ? payment : null,
      propertyTax: propertyTax,
      homeInsurance: homeInsurance,
      mortgageInsurance: mortgageInsurance,
      monthlyExpenses: monthlyExpenses,
      price: price,
      downPayment: downPayment,
    );

    final results = switch (entryType) {
      CalculationEntryType.payment => CalculationEntryResults(payment: payment),
      CalculationEntryType.loanAmount => CalculationEntryResults(
        loanAmount: loanAmount,
      ),
      CalculationEntryType.term => CalculationEntryResults(
        termYears: termYears,
      ),
      CalculationEntryType.interestRate => CalculationEntryResults(
        interestRate: interestRate,
      ),
      CalculationEntryType.qualification => CalculationEntryResults(
        maxLoanAmount: loanAmount,
      ),
    };

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
    double? monthlyPiPayment,
    String? notes,
  }) {
    final now = DateTime.now();
    final id = _uuid.v4();

    return CalculationEntry(
      id: id,
      timestamp: now,
      type: CalculationEntryType.qualification,
      inputs: CalculationEntryInputs(
        annualIncome: annualIncome,
        monthlyDebt: monthlyDebt,
        interestRate: interestRate,
        termYears: termYears,
      ),
      results: CalculationEntryResults(
        maxLoanAmount: maxLoanAmount,
        monthlyPiPayment: monthlyPiPayment,
      ),
      notes: notes,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.storageName,
      'inputs': inputs.toJson(),
      'results': results.toJson(),
      'notes': notes,
    };
  }

  /// Create from JSON
  factory CalculationEntry.fromJson(Map<String, dynamic> json) {
    return CalculationEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: CalculationEntryType.fromJsonValue(json['type']),
      inputs: CalculationEntryInputs.fromJson(json['inputs']),
      results: CalculationEntryResults.fromJson(json['results']),
      notes: json['notes'] as String?,
    );
  }

  /// Get a human-readable title for this calculation
  String get title => type.title;

  /// Get a summary of the calculation
  String get summary {
    final buffer = StringBuffer();

    switch (type) {
      case CalculationEntryType.payment:
        buffer.write(
          '${CurrencyFormatter.formatCurrency(loanAmount, showDecimals: false)} '
          'at ${CurrencyFormatter.formatPercent(interestRate, decimals: 3)} '
          'for ${CurrencyFormatter.formatYears(termYears)} '
          '→ ${CurrencyFormatter.formatCurrency(monthlyPayment)}/mo',
        );
        break;
      case CalculationEntryType.loanAmount:
        buffer.write(
          '${CurrencyFormatter.formatCurrency(inputs.payment)}/mo '
          'at ${CurrencyFormatter.formatPercent(interestRate, decimals: 3)} '
          'for ${CurrencyFormatter.formatYears(termYears)} '
          '→ ${CurrencyFormatter.formatCurrency(loanAmount, showDecimals: false)} loan',
        );
        break;
      case CalculationEntryType.term:
        buffer.write(
          '${CurrencyFormatter.formatCurrency(loanAmount, showDecimals: false)} '
          'loan at ${CurrencyFormatter.formatPercent(interestRate, decimals: 3)} '
          '→ ${CurrencyFormatter.formatYears(termYears)}',
        );
        break;
      case CalculationEntryType.interestRate:
        buffer.write(
          '${CurrencyFormatter.formatCurrency(loanAmount, showDecimals: false)} '
          'loan at ${CurrencyFormatter.formatCurrency(monthlyPayment)}/mo '
          '→ ${CurrencyFormatter.formatPercent(interestRate, decimals: 3)}',
        );
        break;
      case CalculationEntryType.qualification:
        buffer.write(
          'Income: ${CurrencyFormatter.formatCurrency(annualIncome, showDecimals: false)} '
          '→ Max loan: ${CurrencyFormatter.formatCurrency(results.maxLoanAmount, showDecimals: false)}',
        );
        break;
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
    return inputs.loanAmount ?? results.loanAmount ?? results.maxLoanAmount;
  }

  /// Get interest rate for comparison
  double? get interestRate {
    return inputs.interestRate ?? results.interestRate;
  }

  /// Get term in years for comparison
  double? get termYears {
    return inputs.termYears ?? results.termYears;
  }

  /// Get monthly payment for comparison
  double? get monthlyPayment {
    return inputs.payment ?? results.payment ?? results.monthlyPiPayment;
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
  double? get propertyTax => inputs.propertyTax;
  double? get homeInsurance => inputs.homeInsurance;
  double? get mortgageInsurance => inputs.mortgageInsurance;
  double? get monthlyExpenses => inputs.monthlyExpenses;
  double? get price => inputs.price;
  double? get downPayment => inputs.downPayment;
  double? get annualIncome => inputs.annualIncome;
  double? get monthlyDebt => inputs.monthlyDebt;

  /// Calculate total monthly PITI payment
  double? get pitiPayment {
    final payment = monthlyPayment;
    if (payment == null) return null;

    final piti =
        payment +
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
  final List<CalculationEntry> _entries = <CalculationEntry>[];
  static const int maxEntries = 100;

  /// Add a new calculation to history
  void addEntry(CalculationEntry entry) {
    _entries.insert(0, entry);

    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
  }

  /// Get all entries
  List<CalculationEntry> get entries => List.unmodifiable(_entries);

  /// Get entries of a specific type
  List<CalculationEntry> getEntriesByType(CalculationEntryType type) {
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
    final List<Map<String, dynamic>> jsonList = _entries
        .map((e) => e.toJson())
        .toList();
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
    } catch (_) {
      // Keep the app usable if history parsing fails.
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

double? _readDouble(Object? raw, String key) {
  if (raw is! Map) {
    return null;
  }

  final value = raw[key];
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}
