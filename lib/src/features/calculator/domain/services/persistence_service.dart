import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculator_state.dart';

class CalculatorPersistenceService {
  static const String _scenarioSessionKey = 'scenarioSession';

  Future<CalculatorStateSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final scenarioSession = prefs.getString(_scenarioSessionKey);
    if (scenarioSession != null && scenarioSession.isNotEmpty) {
      try {
        return CalculatorStateSnapshot.fromJsonString(scenarioSession);
      } on FormatException {
        // Fall back to the legacy flat snapshot if the new session payload is corrupt.
      } on TypeError {
        // Fall back to the legacy flat snapshot if the new session payload shape changed.
      }
    }

    return CalculatorStateSnapshot.fromLegacy(
      loanAmount: prefs.getDouble('loanAmount'),
      interestRate: prefs.getDouble('interestRate'),
      termYears: prefs.getDouble('termYears'),
      payment: prefs.getDouble('payment'),
      price: prefs.getDouble('price'),
      downPayment: prefs.getDouble('downPayment'),
      propertyTax: prefs.getDouble('propertyTax'),
      homeInsurance: prefs.getDouble('homeInsurance'),
      mortgageInsurance: prefs.getDouble('mortgageInsurance'),
      monthlyExpenses: prefs.getDouble('monthlyExpenses'),
      annualIncome: prefs.getDouble('annualIncome'),
      monthlyDebt: prefs.getDouble('monthlyDebt'),
      historyJson: prefs.getString('calculationHistory'),
    );
  }

  Future<void> save(CalculatorStateSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scenarioSessionKey, jsonEncode(snapshot.toJson()));
  }
}
