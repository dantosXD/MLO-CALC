import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';

class HistoryController with ChangeNotifier {
  final CalculationHistory _history = CalculationHistory();

  CalculationHistory get history => _history;
  List<CalculationEntry> get entries => _history.entries;

  void addQuoteEntry({
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
    _history.addEntry(
      CalculationEntry.fromLoanCalculation(
        type: type,
        loanAmount: loanAmount,
        interestRate: interestRate,
        termYears: termYears,
        payment: payment,
        propertyTax: propertyTax,
        homeInsurance: homeInsurance,
        mortgageInsurance: mortgageInsurance,
        monthlyExpenses: monthlyExpenses,
        price: price,
        downPayment: downPayment,
        notes: notes,
      ),
    );
    notifyListeners();
  }

  void addQualificationEntry({
    required double annualIncome,
    required double monthlyDebt,
    required double interestRate,
    required double termYears,
    required double maxLoanAmount,
    String? notes,
  }) {
    _history.addEntry(
      CalculationEntry.fromQualification(
        annualIncome: annualIncome,
        monthlyDebt: monthlyDebt,
        interestRate: interestRate,
        termYears: termYears,
        maxLoanAmount: maxLoanAmount,
        notes: notes,
      ),
    );
    notifyListeners();
  }

  void remove(String id) {
    _history.removeEntry(id);
    notifyListeners();
  }

  void clear() {
    _history.clearAll();
    notifyListeners();
  }

  void replaceFromJson(String? historyJson) {
    if (historyJson == null || historyJson.isEmpty) {
      _history.clearAll();
    } else {
      _history.fromJsonString(historyJson);
    }
    notifyListeners();
  }

  String toJsonString() => _history.toJsonString();
}
