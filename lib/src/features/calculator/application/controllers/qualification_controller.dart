import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';
import 'package:loan_ranger/src/core/utils/type_utils.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/loan_quote_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/states/qualification_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/calculation_result.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/calculator_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';

class QualificationController with ChangeNotifier {
  QualificationController({
    required QualificationService qualificationService,
    required LoanQuoteController quoteController,
    required HistoryController historyController,
  }) : _qualificationService = qualificationService,
       _quoteController = quoteController,
       _historyController = historyController;

  final QualificationService _qualificationService;
  final LoanQuoteController _quoteController;
  final HistoryController _historyController;

  QualificationState _state = QualificationState();

  QualificationState get state => _state;
  String? get inputError => _state.calculationError;
  QualifyingRatio get qualRatio1 => _state.qualRatio1;
  QualifyingRatio get qualRatio2 => _state.qualRatio2;
  double? get annualIncome => _state.annualIncome;
  double? get monthlyDebt => _state.monthlyDebt;

  void hydrateFromSnapshot(CalculatorStateSnapshot snapshot) {
    _state = _state.copyWith(
      annualIncome: snapshot.annualIncome,
      monthlyDebt: snapshot.monthlyDebt,
      clearCalculationError: true,
    );
    notifyListeners();
  }

  void restoreFromHistoryEntry(CalculationEntry entry) {
    _state = _state.copyWith(
      annualIncome: TypeUtils.toDouble(entry.inputs['annualIncome']),
      monthlyDebt: TypeUtils.toDouble(entry.inputs['monthlyDebt']),
      clearCalculationError: true,
    );
    notifyListeners();
  }

  void setAnnualIncome({double? value}) {
    _state = value == null
        ? _state.copyWith(clearAnnualIncome: true, clearCalculationError: true)
        : _state.copyWith(annualIncome: value, clearCalculationError: true);
    notifyListeners();
  }

  void setMonthlyDebt({double? value}) {
    _state = value == null
        ? _state.copyWith(clearMonthlyDebt: true, clearCalculationError: true)
        : _state.copyWith(monthlyDebt: value, clearCalculationError: true);
    notifyListeners();
  }

  void setQualRatio1(QualifyingRatio ratio) {
    _state = _state.copyWith(qualRatio1: ratio);
    notifyListeners();
  }

  void setQualRatio2(QualifyingRatio ratio) {
    _state = _state.copyWith(qualRatio2: ratio);
    notifyListeners();
  }

  void setRatio(QualifyingRatio ratio, {bool primary = true}) {
    if (primary) {
      setQualRatio1(ratio);
    } else {
      setQualRatio2(ratio);
    }
  }

  void clearAll() {
    _state = _state.copyWith(
      clearAnnualIncome: true,
      clearMonthlyDebt: true,
      clearCalculationError: true,
    );
    notifyListeners();
  }

  void calculateMaxLoan({bool usePrimaryRatio = true}) {
    if (_state.annualIncome == null ||
        _quoteController.interestRate == null ||
        _quoteController.termYears == null) {
      _state = _state.copyWith(calculationError: 'Need income, rate, term');
      notifyListeners();
      return;
    }

    final ratio = usePrimaryRatio ? _state.qualRatio1 : _state.qualRatio2;
    final result = _qualificationService.calculateMaxLoan(
      ratio: ratio,
      annualIncome: _state.annualIncome!,
      interestRate: _quoteController.interestRate!,
      termYears: _quoteController.termYears!,
      monthlyDebt: _state.monthlyDebt ?? 0,
      monthlyEscrows: _quoteController.monthlyEscrowExpenses,
    );

    switch (result) {
      case CalcFailure(:final error):
        _state = _state.copyWith(
          calculationError: error,
        );
        notifyListeners();
        return;
      case CalcSuccess(:final value):
        final outcome = value;
        _state = _state.copyWith(clearCalculationError: true);
        _quoteController.applyQualificationResult(outcome);
        _historyController.addQualificationEntry(
          annualIncome: _state.annualIncome!,
          monthlyDebt: _state.monthlyDebt ?? 0,
          interestRate: _quoteController.interestRate!,
          termYears: _quoteController.termYears!,
          maxLoanAmount: outcome.loanAmount,
          monthlyPiPayment: outcome.monthlyPiPayment,
        );
        notifyListeners();
    }
  }

  void calculateMinimumIncome({bool usePrimaryRatio = true}) {
    if (_quoteController.loanAmount == null ||
        _quoteController.interestRate == null ||
        _quoteController.termYears == null) {
      _state = _state.copyWith(calculationError: 'Need L/A, Rate, Term');
      notifyListeners();
      return;
    }

    if (_quoteController.payment == null) {
      _quoteController.calculate();
    }
    if (_quoteController.payment == null) {
      _state = _state.copyWith(
        calculationError:
            _quoteController.inputError ?? 'Unable to calculate income',
      );
      notifyListeners();
      return;
    }

    final ratio = usePrimaryRatio ? _state.qualRatio1 : _state.qualRatio2;
    final result = _qualificationService.calculateMinimumIncome(
      ratio: ratio,
      pitiPayment: _quoteController.pitiPayment,
      monthlyDebt: _state.monthlyDebt ?? 0,
    );

    switch (result) {
      case CalcFailure(:final error):
        _state = _state.copyWith(
          calculationError: error,
        );
        notifyListeners();
        return;
      case CalcSuccess(:final value):
        _state = _state.copyWith(
          annualIncome: value,
          clearCalculationError: true,
        );
        _quoteController.presentValue(value);
        notifyListeners();
    }
  }

}
