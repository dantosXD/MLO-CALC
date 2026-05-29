import 'dart:convert';

import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';

import '../models/calculator_state.dart';

class CalculatorPersistenceService {
  CalculatorPersistenceService({
    required SecureStore secureStore,
    required PreferenceStore legacyStore,
  }) : _secureStore = secureStore,
       _legacyStore = legacyStore;

  static const String _scenarioSessionKey = 'scenarioSession';
  static const List<String> _legacyKeys = <String>[
    'loanAmount',
    'interestRate',
    'termYears',
    'payment',
    'price',
    'downPayment',
    'propertyTax',
    'homeInsurance',
    'mortgageInsurance',
    'monthlyExpenses',
    'annualIncome',
    'monthlyDebt',
    'calculationHistory',
  ];

  final SecureStore _secureStore;
  final PreferenceStore _legacyStore;

  Future<CalculatorStateSnapshot> load() async {
    final sessionJson = await _secureStore.read(_scenarioSessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      try {
        return CalculatorStateSnapshot.fromJsonString(sessionJson);
      } on FormatException {
        // Fall back to the legacy flat snapshot if the secure payload is corrupt.
      } on TypeError {
        // Fall back to the legacy flat snapshot if the secure payload shape changed.
      }
    }

    await _legacyStore.load();
    final snapshot = CalculatorStateSnapshot.fromLegacy(
      loanAmount: _legacyStore.getDouble('loanAmount'),
      interestRate: _legacyStore.getDouble('interestRate'),
      termYears: _legacyStore.getDouble('termYears'),
      payment: _legacyStore.getDouble('payment'),
      price: _legacyStore.getDouble('price'),
      downPayment: _legacyStore.getDouble('downPayment'),
      propertyTax: _legacyStore.getDouble('propertyTax'),
      homeInsurance: _legacyStore.getDouble('homeInsurance'),
      mortgageInsurance: _legacyStore.getDouble('mortgageInsurance'),
      monthlyExpenses: _legacyStore.getDouble('monthlyExpenses'),
      annualIncome: _legacyStore.getDouble('annualIncome'),
      monthlyDebt: _legacyStore.getDouble('monthlyDebt'),
      historyJson: _legacyStore.getString('calculationHistory'),
    );

    await save(snapshot);
    await _removeLegacyKeys();
    return snapshot;
  }

  Future<void> save(CalculatorStateSnapshot snapshot) async {
    final encoded = jsonEncode(snapshot.toJson());
    await _secureStore.write(key: _scenarioSessionKey, value: encoded);
  }

  Future<void> _removeLegacyKeys() async {
    for (final key in _legacyKeys) {
      await _legacyStore.remove(key);
    }
    await _legacyStore.remove(_scenarioSessionKey);
  }
}
