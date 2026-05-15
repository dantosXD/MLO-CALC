import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';
import 'package:loan_ranger/src/core/scenarios/scenario_catalog.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/repositories/calculator_session_repository.dart';
import 'package:loan_ranger/src/features/calculator/application/states/loan_quote_state.dart';
import 'package:loan_ranger/src/features/calculator/application/states/qualification_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Calculator session persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'loads legacy flat preferences into versioned scenario snapshots',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'loanAmount': 275000.0,
          'interestRate': 5.875,
          'termYears': 30.0,
          'payment': 1626.0,
          'price': 340000.0,
          'downPayment': 65000.0,
          'propertyTax': 4200.0,
          'homeInsurance': 1500.0,
          'mortgageInsurance': 900.0,
          'monthlyExpenses': 180.0,
          'annualIncome': 132000.0,
          'monthlyDebt': 640.0,
          'calculationHistory': '{"entries":[]}',
        });

        final service = CalculatorPersistenceService(
          secureStore: InMemorySecureStore(),
        );
        final snapshot = await service.load();

        expect(snapshot.schemaVersion, 2);
        expect(snapshot.activeScenarioId, ScenarioCatalog.purchaseQuoteId);
        expect(snapshot.loanAmount, 275000.0);
        expect(snapshot.payment, 1626.0);
        expect(snapshot.annualIncome, 132000.0);
        expect(snapshot.monthlyDebt, 640.0);
        expect(snapshot.historyJson, '{"entries":[]}');

        final purchaseScenario = snapshot.scenarioById(
          ScenarioCatalog.purchaseQuoteId,
        );
        final qualificationScenario = snapshot.scenarioById(
          ScenarioCatalog.qualificationMaxLoanId,
        );

        expect(purchaseScenario, isNotNull);
        expect(purchaseScenario!.inputs['price'], 340000.0);
        expect(purchaseScenario.results['payment'], 1626.0);
        expect(qualificationScenario, isNotNull);
        expect(qualificationScenario!.inputs['annualIncome'], 132000.0);
        expect(qualificationScenario.inputs['monthlyDebt'], 640.0);
      },
    );

    test(
      'saves and reloads scenario sessions through the repository',
      () async {
        final historyController = HistoryController();
        historyController.addQuoteEntry(
          type: 'payment',
          loanAmount: 310000.0,
          interestRate: 6.125,
          termYears: 30.0,
          payment: 1884.0,
          price: 395000.0,
          downPayment: 85000.0,
        );

        final repository = CalculatorSessionRepository(
          persistenceService: CalculatorPersistenceService(
            secureStore: InMemorySecureStore(),
          ),
        );

        await repository.save(
          quoteState: const LoanQuoteState(
            loanAmount: 310000.0,
            interestRate: 6.125,
            termYears: 30.0,
            payment: 1884.0,
            price: 395000.0,
            downPayment: 85000.0,
            propertyTax: 4800.0,
            homeInsurance: 1440.0,
            mortgageInsurance: 960.0,
            monthlyExpenses: 225.0,
            displayMode: PaymentDisplayMode.piti,
            presentedValue: 2489.0,
          ),
          qualificationState: QualificationState(
            annualIncome: 145000.0,
            monthlyDebt: 725.0,
          ),
          historyController: historyController,
        );

        // Session data is written to SecureStore, not SharedPreferences.
        // Verify only that legacy flat keys are absent.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('loanAmount'), isNull);

        final snapshot = await repository.load();
        final purchaseScenario = snapshot.scenarioById(
          ScenarioCatalog.purchaseQuoteId,
        );
        final qualificationScenario = snapshot.scenarioById(
          ScenarioCatalog.qualificationMaxLoanId,
        );

        expect(snapshot.activeScenarioId, ScenarioCatalog.purchaseQuoteId);
        expect(snapshot.loanAmount, 310000.0);
        expect(snapshot.payment, 1884.0);
        expect(snapshot.propertyTax, 4800.0);
        expect(snapshot.annualIncome, 145000.0);
        expect(snapshot.monthlyDebt, 725.0);
        expect(snapshot.historyJson, historyController.toJsonString());
        expect(purchaseScenario, isNotNull);
        expect(purchaseScenario!.results['cashToClose'], 85000.0);
        expect(purchaseScenario.metadata['displayMode'], 'piti');
        expect(qualificationScenario, isNotNull);
        expect(qualificationScenario!.inputs['interestRate'], 6.125);
        expect(qualificationScenario.metadata['primaryRatio'], isNotNull);
      },
    );
  });
}
