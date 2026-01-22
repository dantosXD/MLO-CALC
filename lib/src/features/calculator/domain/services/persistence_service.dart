import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculator_state.dart';

class CalculatorPersistenceService {
  static const List<String> _doubleKeys = [
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
  ];

  Future<CalculatorStateSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return CalculatorStateSnapshot(
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
    final map = snapshot.toDoubleMap();

    for (final key in _doubleKeys) {
      if (map.containsKey(key)) {
        await prefs.setDouble(key, map[key]!);
      } else {
        await prefs.remove(key);
      }
    }

    if (snapshot.historyJson != null) {
      await prefs.setString('calculationHistory', snapshot.historyJson!);
    } else {
      await prefs.remove('calculationHistory');
    }
  }
}
