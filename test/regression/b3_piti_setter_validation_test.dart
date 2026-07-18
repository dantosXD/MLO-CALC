// Regression: BUGLOG B3 — PITI setters skipped validation.
//
// setPropertyTax/setHomeInsurance/setMortgageInsurance/setMonthlyExpenses wrote
// straight to state without calling the existing FinancialValidators, so
// negative values were silently accepted and flowed into PITI. They must
// reject invalid input and surface it via inputError, like the other setters.
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/loan_quote_controller.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  late LoanQuoteController controller;

  setUp(() {
    controller = LoanQuoteController(
      coreCalculationService: serviceLocator<CoreCalculationService>(),
      historyController: HistoryController(),
    );
  });

  group('B3: PITI setters validate input', () {
    test('setPropertyTax rejects a negative value and surfaces an error', () {
      controller.setPropertyTax(value: -5000);
      expect(controller.propertyTax, isNull);
      expect(controller.inputError, isNotNull);
      expect(controller.inputError, contains('Property tax'));
    });

    test('setHomeInsurance rejects a negative value', () {
      controller.setHomeInsurance(value: -1);
      expect(controller.homeInsurance, isNull);
      expect(controller.inputError, isNotNull);
    });

    test('setMonthlyExpenses rejects a negative value', () {
      controller.setMonthlyExpenses(value: -100);
      expect(controller.monthlyExpenses, isNull);
      expect(controller.inputError, isNotNull);
    });

    test('valid PITI values are still accepted and clear any error', () {
      controller.setPropertyTax(value: 3600);
      controller.setHomeInsurance(value: 1200);
      controller.setMonthlyExpenses(value: 150);
      expect(controller.propertyTax, 3600);
      expect(controller.homeInsurance, 1200);
      expect(controller.monthlyExpenses, 150);
      expect(controller.inputError, isNull);
    });
  });
}
