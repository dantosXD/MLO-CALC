import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';

CalculatorProvider buildCalculatorProvider() {
  return CalculatorProvider(
    coreCalculationService: serviceLocator<CoreCalculationService>(),
    amortizationService: serviceLocator<AmortizationService>(),
    qualificationService: serviceLocator<QualificationService>(),
    persistenceService: serviceLocator<CalculatorPersistenceService>(),
  );
}

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  late CalculatorProvider provider;

  setUp(() {
    provider = buildCalculatorProvider();
  });

  group('CalculatorProvider explicit clear methods', () {
    test('clearPrice resets price to null', () {
      provider.setPrice(value: 500000);
      expect(provider.price, 500000);

      provider.clearPrice();
      expect(provider.price, isNull);
    });

    test('clearDownPayment resets downPayment and downPaymentPercentage', () {
      provider.setPrice(value: 400000);
      provider.setDownPayment(value: 80000);
      expect(provider.downPayment, 80000);
      expect(provider.downPaymentPercentage, 20.0);

      provider.clearDownPayment();
      expect(provider.downPayment, isNull);
      expect(provider.downPaymentPercentage, isNull);
    });

    test('clearPropertyTax resets propertyTax to null', () {
      provider.setPropertyTax(value: 6000);
      expect(provider.propertyTax, 6000);

      provider.clearPropertyTax();
      expect(provider.propertyTax, isNull);
    });

    test('clearHomeInsurance resets homeInsurance to null', () {
      provider.setHomeInsurance(value: 1800);
      expect(provider.homeInsurance, 1800);

      provider.clearHomeInsurance();
      expect(provider.homeInsurance, isNull);
    });

    test('clearMonthlyExpenses resets monthlyExpenses to null', () {
      provider.setMonthlyExpenses(value: 350);
      expect(provider.monthlyExpenses, 350);

      provider.clearMonthlyExpenses();
      expect(provider.monthlyExpenses, isNull);
    });
  });
}
