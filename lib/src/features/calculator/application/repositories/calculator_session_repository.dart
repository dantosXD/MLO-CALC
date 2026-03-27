import 'package:loan_ranger/src/core/scenarios/scenario_catalog.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/states/loan_quote_state.dart';
import 'package:loan_ranger/src/features/calculator/application/states/qualification_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/calculator_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';

class CalculatorSessionRepository {
  CalculatorSessionRepository({
    required CalculatorPersistenceService persistenceService,
  }) : _persistenceService = persistenceService;

  final CalculatorPersistenceService _persistenceService;

  Future<CalculatorStateSnapshot> load() {
    return _persistenceService.load();
  }

  Future<void> save({
    required LoanQuoteState quoteState,
    required QualificationState qualificationState,
    required HistoryController historyController,
  }) {
    final purchaseQuoteScenario = ScenarioStateSnapshot(
      scenarioId: ScenarioCatalog.purchaseQuoteId,
      inputs: <String, double?>{
        'loanAmount': quoteState.loanAmount,
        'interestRate': quoteState.interestRate,
        'termYears': quoteState.termYears,
        'price': quoteState.price,
        'downPayment': quoteState.downPayment,
        'propertyTax': quoteState.propertyTax,
        'homeInsurance': quoteState.homeInsurance,
        'mortgageInsurance': quoteState.mortgageInsurance,
        'monthlyExpenses': quoteState.monthlyExpenses,
      },
      results: <String, double?>{
        'payment': quoteState.payment,
        'pitiPayment': quoteState.payment == null
            ? null
            : quoteState.pitiPayment,
        'cashToClose': quoteState.cashToClose,
        'displayPayment': quoteState.displayPayment,
        'presentedValue': quoteState.presentedValue,
      },
      metadata: <String, Object?>{
        'displayMode': quoteState.displayMode.name,
        'isInterestOnly': quoteState.isInterestOnly,
      },
    );
    final qualificationScenario = ScenarioStateSnapshot(
      scenarioId: ScenarioCatalog.qualificationMaxLoanId,
      inputs: <String, double?>{
        'annualIncome': qualificationState.annualIncome,
        'monthlyDebt': qualificationState.monthlyDebt,
        'interestRate': quoteState.interestRate,
        'termYears': quoteState.termYears,
      },
      metadata: <String, Object?>{
        'primaryRatio': qualificationState.qualRatio1.name,
        'secondaryRatio': qualificationState.qualRatio2.name,
      },
    );
    final snapshot = CalculatorStateSnapshot(
      activeScenarioId: _resolveActiveScenarioId(
        quoteState: quoteState,
        qualificationState: qualificationState,
      ),
      scenarios: <String, ScenarioStateSnapshot>{
        ScenarioCatalog.purchaseQuoteId: purchaseQuoteScenario,
        ScenarioCatalog.qualificationMaxLoanId: qualificationScenario,
      },
      historyJson: historyController.toJsonString(),
    );
    return _persistenceService.save(snapshot);
  }

  String _resolveActiveScenarioId({
    required LoanQuoteState quoteState,
    required QualificationState qualificationState,
  }) {
    final hasQuoteValues =
        quoteState.loanAmount != null ||
        quoteState.payment != null ||
        quoteState.price != null ||
        quoteState.downPayment != null;
    final hasQualificationValues =
        qualificationState.annualIncome != null ||
        qualificationState.monthlyDebt != null;

    if (hasQualificationValues && !hasQuoteValues) {
      return ScenarioCatalog.qualificationMaxLoanId;
    }

    return ScenarioCatalog.purchaseQuoteId;
  }
}
