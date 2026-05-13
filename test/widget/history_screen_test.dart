import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/features/comparison/application/providers/comparison_provider.dart';
import 'package:loan_ranger/src/features/history/presentation/screens/history_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await configureDependencies();
  });

  testWidgets('renders the empty history state', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => buildCalculatorProvider()),
          ChangeNotifierProvider(create: (_) => ComparisonProvider()),
        ],
        child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No history yet'), findsOneWidget);
    expect(find.text('Perform a calculation to see it here.'), findsOneWidget);
  });
}
