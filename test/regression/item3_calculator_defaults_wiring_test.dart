import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';

CalculatorProvider _build() => CalculatorProvider(
      coreCalculationService: serviceLocator<CoreCalculationService>(),
      amortizationService: serviceLocator<AmortizationService>(),
      qualificationService: serviceLocator<QualificationService>(),
      persistenceService: serviceLocator<CalculatorPersistenceService>(),
    );

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  group('Item 3: MLO calculator defaults wiring', () {
    late CalculatorProvider provider;
    setUp(() => provider = _build());

    test('downPaymentPct default applied when no prior down payment', () {
      provider.applyDefaultsIfEmpty(downPaymentPct: 20.0);
      expect(provider.downPayment, 20.0);
    });

    test('downPaymentPct default does not override an already-set down payment', () {
      provider.setDownPayment(value: 50000);
      provider.applyDefaultsIfEmpty(downPaymentPct: 20.0);
      expect(provider.downPayment, 50000);
    });

    test('propertyTaxRate default auto-applied as monthly dollars when price set', () {
      // 1.2% annual of $300k = $3,600/yr = $300/mo
      provider.applyDefaultsIfEmpty(propertyTaxRate: 1.2);
      provider.setPrice(value: 300000);
      expect(provider.propertyTax, closeTo(300, 0.01));
    });

    test('insuranceRate default auto-applied as monthly dollars when price set', () {
      // 0.5% annual of $300k = $1,500/yr = $125/mo
      provider.applyDefaultsIfEmpty(insuranceRate: 0.5);
      provider.setPrice(value: 300000);
      expect(provider.homeInsurance, closeTo(125, 0.01));
    });

    test('propertyTaxRate default does not override already-set tax', () {
      provider.setPropertyTax(value: 400);
      provider.applyDefaultsIfEmpty(propertyTaxRate: 1.2);
      provider.setPrice(value: 300000);
      expect(provider.propertyTax, 400);
    });

    test('insuranceRate default does not override already-set insurance', () {
      provider.setHomeInsurance(value: 200);
      provider.applyDefaultsIfEmpty(insuranceRate: 0.5);
      provider.setPrice(value: 300000);
      expect(provider.homeInsurance, 200);
    });

    test('all 5 defaults applied together in bootstrap scenario', () {
      provider.applyDefaultsIfEmpty(
        interestRate: 6.5,
        termYears: 30,
        downPaymentPct: 20.0,
        propertyTaxRate: 1.2,
        insuranceRate: 0.5,
      );
      provider.setPrice(value: 300000);

      expect(provider.interestRate, 6.5);
      expect(provider.termYears, 30);
      expect(provider.downPayment, 20.0);
      expect(provider.propertyTax, closeTo(300, 0.01));
      expect(provider.homeInsurance, closeTo(125, 0.01));
    });
  });
}
