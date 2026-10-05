import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/animated_display.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async => configureDependencies());

  testWidgets(
    'light theme with custom accent: display value is not white-on-pale',
    (t) async {
      final provider = CalculatorProvider(
        coreCalculationService: serviceLocator<CoreCalculationService>(),
        amortizationService: serviceLocator<AmortizationService>(),
        qualificationService: serviceLocator<QualificationService>(),
        persistenceService: serviceLocator<CalculatorPersistenceService>(),
      );
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(accent: const Color(0xFF0B6E4F)),
          home: ChangeNotifierProvider.value(
            value: provider,
            child: const Scaffold(
              body: SizedBox(
                height: 300,
                child: AnimatedDisplay(displayValue: '1234'),
              ),
            ),
          ),
        ),
      );
      final c = t.widget<Text>(find.text('1,234')).style!.color!;
      expect(c.computeLuminance(), lessThan(0.4));
    },
  );
}
