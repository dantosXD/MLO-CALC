import 'dart:convert';

import 'package:loan_ranger/src/core/scenarios/scenario_catalog.dart';
import 'package:loan_ranger/src/core/utils/type_utils.dart';

class ScenarioStateSnapshot {
  const ScenarioStateSnapshot({
    required this.scenarioId,
    this.inputs = const <String, double?>{},
    this.results = const <String, double?>{},
    this.metadata = const <String, Object?>{},
  });

  final String scenarioId;
  final Map<String, double?> inputs;
  final Map<String, double?> results;
  final Map<String, Object?> metadata;

  factory ScenarioStateSnapshot.fromJson(Map<String, dynamic> json) {
    return ScenarioStateSnapshot(
      scenarioId: json['scenarioId'] as String,
      inputs: _toNullableDoubleMap(json['inputs']),
      results: _toNullableDoubleMap(json['results']),
      metadata: _toMetadataMap(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scenarioId': scenarioId,
      'inputs': _sanitizeNumbers(inputs),
      'results': _sanitizeNumbers(results),
      'metadata': metadata,
    };
  }

  double? value(String key) {
    return inputs[key] ?? results[key];
  }

  static Map<String, double?> _toNullableDoubleMap(Object? raw) {
    if (raw is! Map) {
      return const <String, double?>{};
    }

    return raw.map<String, double?>((Object? key, Object? value) {
      return MapEntry<String, double?>(key.toString(), TypeUtils.toDouble(value));
    });
  }

  static Map<String, Object?> _toMetadataMap(Object? raw) {
    if (raw is! Map) {
      return const <String, Object?>{};
    }

    return raw.map<String, Object?>((Object? key, Object? value) {
      return MapEntry<String, Object?>(key.toString(), value);
    });
  }

  static Map<String, double> _sanitizeNumbers(Map<String, double?> source) {
    return Map<String, double>.fromEntries(
      source.entries
          .where((MapEntry<String, double?> entry) {
            return entry.value != null;
          })
          .map((MapEntry<String, double?> entry) {
            return MapEntry<String, double>(entry.key, entry.value!);
          }),
    );
  }
}

class CalculatorStateSnapshot {
  static const int currentSchemaVersion = 2;

  const CalculatorStateSnapshot({
    this.schemaVersion = currentSchemaVersion,
    this.activeScenarioId = ScenarioCatalog.purchaseQuoteId,
    this.scenarios = const <String, ScenarioStateSnapshot>{},
    this.historyJson,
  });

  final int schemaVersion;
  final String activeScenarioId;
  final Map<String, ScenarioStateSnapshot> scenarios;
  final String? historyJson;

  factory CalculatorStateSnapshot.fromJsonString(String source) {
    return CalculatorStateSnapshot.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }

  factory CalculatorStateSnapshot.fromJson(Map<String, dynamic> json) {
    final rawScenarios = json['scenarios'];
    final scenarios = rawScenarios is Map
        ? rawScenarios.map<String, ScenarioStateSnapshot>((
            Object? key,
            Object? value,
          ) {
            final scenarioJson = value is Map<String, dynamic>
                ? value
                : Map<String, dynamic>.from(value as Map);
            return MapEntry<String, ScenarioStateSnapshot>(
              key.toString(),
              ScenarioStateSnapshot.fromJson(scenarioJson),
            );
          })
        : const <String, ScenarioStateSnapshot>{};

    return CalculatorStateSnapshot(
      schemaVersion: _toInt(json['schemaVersion']) ?? currentSchemaVersion,
      activeScenarioId:
          json['activeScenarioId'] as String? ??
          ScenarioCatalog.purchaseQuoteId,
      scenarios: scenarios,
      historyJson: json['historyJson'] as String?,
    );
  }

  factory CalculatorStateSnapshot.fromLegacy({
    double? loanAmount,
    double? interestRate,
    double? termYears,
    double? payment,
    double? price,
    double? downPayment,
    double? propertyTax,
    double? homeInsurance,
    double? mortgageInsurance,
    double? monthlyExpenses,
    double? annualIncome,
    double? monthlyDebt,
    String? historyJson,
  }) {
    final purchaseQuoteScenario = _buildScenario(
      scenarioId: ScenarioCatalog.purchaseQuoteId,
      inputs: <String, double?>{
        'loanAmount': loanAmount,
        'interestRate': interestRate,
        'termYears': termYears,
        'price': price,
        'downPayment': downPayment,
        'propertyTax': propertyTax,
        'homeInsurance': homeInsurance,
        'mortgageInsurance': mortgageInsurance,
        'monthlyExpenses': monthlyExpenses,
      },
      results: <String, double?>{'payment': payment},
    );
    final qualificationScenario = _buildScenario(
      scenarioId: ScenarioCatalog.qualificationMaxLoanId,
      inputs: <String, double?>{
        'annualIncome': annualIncome,
        'monthlyDebt': monthlyDebt,
        'interestRate': interestRate,
        'termYears': termYears,
      },
    );

    final scenarios = <String, ScenarioStateSnapshot>{
      if (purchaseQuoteScenario != null)
        purchaseQuoteScenario.scenarioId: purchaseQuoteScenario,
      if (qualificationScenario != null)
        qualificationScenario.scenarioId: qualificationScenario,
    };

    return CalculatorStateSnapshot(
      activeScenarioId:
          qualificationScenario != null && purchaseQuoteScenario == null
          ? ScenarioCatalog.qualificationMaxLoanId
          : ScenarioCatalog.purchaseQuoteId,
      scenarios: scenarios,
      historyJson: historyJson,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'activeScenarioId': activeScenarioId,
      'scenarios': scenarios.map<String, dynamic>((
        String key,
        ScenarioStateSnapshot scenario,
      ) {
        return MapEntry<String, dynamic>(key, scenario.toJson());
      }),
      'historyJson': historyJson,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  ScenarioStateSnapshot? scenarioById(String scenarioId) =>
      scenarios[scenarioId];

  double? get loanAmount =>
      _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'loanAmount');

  double? get interestRate =>
      _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'interestRate') ??
      _scenarioValue(ScenarioCatalog.qualificationMaxLoanId, 'interestRate');

  double? get termYears =>
      _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'termYears') ??
      _scenarioValue(ScenarioCatalog.qualificationMaxLoanId, 'termYears');

  double? get payment =>
      _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'payment');

  double? get price => _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'price');

  double? get downPayment =>
      _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'downPayment');

  double? get propertyTax =>
      _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'propertyTax');

  double? get homeInsurance =>
      _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'homeInsurance');

  double? get mortgageInsurance =>
      _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'mortgageInsurance');

  double? get monthlyExpenses =>
      _scenarioValue(ScenarioCatalog.purchaseQuoteId, 'monthlyExpenses');

  double? get annualIncome =>
      _scenarioValue(ScenarioCatalog.qualificationMaxLoanId, 'annualIncome');

  double? get monthlyDebt =>
      _scenarioValue(ScenarioCatalog.qualificationMaxLoanId, 'monthlyDebt');

  Map<String, double> toDoubleMap() {
    return <String, double>{
      if (loanAmount != null) 'loanAmount': loanAmount!,
      if (interestRate != null) 'interestRate': interestRate!,
      if (termYears != null) 'termYears': termYears!,
      if (payment != null) 'payment': payment!,
      if (price != null) 'price': price!,
      if (downPayment != null) 'downPayment': downPayment!,
      if (propertyTax != null) 'propertyTax': propertyTax!,
      if (homeInsurance != null) 'homeInsurance': homeInsurance!,
      if (mortgageInsurance != null) 'mortgageInsurance': mortgageInsurance!,
      if (monthlyExpenses != null) 'monthlyExpenses': monthlyExpenses!,
      if (annualIncome != null) 'annualIncome': annualIncome!,
      if (monthlyDebt != null) 'monthlyDebt': monthlyDebt!,
    };
  }

  double? _scenarioValue(String scenarioId, String key) {
    return scenarios[scenarioId]?.value(key);
  }

  static ScenarioStateSnapshot? _buildScenario({
    required String scenarioId,
    Map<String, double?> inputs = const <String, double?>{},
    Map<String, double?> results = const <String, double?>{},
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final sanitizedInputs = _withoutNullValues(inputs);
    final sanitizedResults = _withoutNullValues(results);
    if (sanitizedInputs.isEmpty &&
        sanitizedResults.isEmpty &&
        metadata.isEmpty) {
      return null;
    }

    return ScenarioStateSnapshot(
      scenarioId: scenarioId,
      inputs: sanitizedInputs,
      results: sanitizedResults,
      metadata: metadata,
    );
  }

  static Map<String, double?> _withoutNullValues(Map<String, double?> source) {
    return Map<String, double?>.fromEntries(
      source.entries.where((MapEntry<String, double?> entry) {
        return entry.value != null;
      }),
    );
  }
}

int? _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}
