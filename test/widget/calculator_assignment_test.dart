import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/main.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/theme/theme_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_display_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/layout_preference_provider.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/animated_display.dart';
import 'package:loan_ranger/src/features/comparison/application/providers/comparison_provider.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:loan_ranger/src/features/loan_programs/application/providers/loan_programs_provider.dart';
import 'package:loan_ranger/src/core/utils/unit_conversion.dart';
import 'package:loan_ranger/src/core/services/analytics_service.dart';
import 'package:loan_ranger/src/features/qualification/application/providers/qualifying_ratios_provider.dart';
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
    await configureDependencies();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'calculator_layout': 'classic',
    });
  });

  Widget createTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LayoutPreferenceProvider()),
        ChangeNotifierProvider(create: (context) => CalculatorDisplayNotifier()),
        ChangeNotifierProvider(create: (context) => buildCalculatorProvider()),
        ChangeNotifierProvider(create: (context) => ComparisonProvider()),
        ChangeNotifierProvider(
          create: (context) => NlpSettingsProvider(
            calculatorService: serviceLocator<NLPCalculatorService>(),
          ),
        ),
        ChangeNotifierProvider(create: (context) => LoanProgramsProvider()),
        ChangeNotifierProvider(create: (context) => UnitConversionProvider()),
        Provider(create: (context) => AnalyticsService()),
        ChangeNotifierProvider(create: (context) => QualifyingRatiosProvider()),
      ],
      child: const LoanRangerApp(),
    );
  }

  String getDisplayValue(WidgetTester tester) {
    final animatedDisplay = tester.widget<AnimatedDisplay>(
      find.byKey(const ValueKey('display')),
    );
    return animatedDisplay.displayValue;
  }

  Finder findButton(String text) {
    // Special case for '0' button which is a custom _ZeroButton widget
    if (text == '0') {
      return find.byKey(const Key('btn_0'));
    }
    return find.bySemanticsLabel(text);
  }

  Future<void> tapButton(WidgetTester tester, String text) async {
    await tester.tap(findButton(text).first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('Display clears after assigning Price', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Input 500000
    await tapButton(tester, '5');
    await tapButton(tester, '0');
    await tapButton(tester, '0');
    await tapButton(tester, '0');
    await tapButton(tester, '0');
    await tapButton(tester, '0');

    expect(getDisplayValue(tester), '500000');

    // Assign to Price
    await tapButton(tester, 'Price');

    // Display should be cleared to 0
    expect(getDisplayValue(tester), '0');
  });

  testWidgets('Display clears after assigning Loan Amount', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Input 400000
    await tapButton(tester, '4');
    await tapButton(tester, '0');
    await tapButton(tester, '0');
    await tapButton(tester, '0');
    await tapButton(tester, '0');
    await tapButton(tester, '0');

    expect(getDisplayValue(tester), '400000');

    // Assign to L/A
    await tapButton(tester, 'L/A');

    // Display should be cleared to 0
    expect(getDisplayValue(tester), '0');
  });

  testWidgets('Assignment does nothing when display is 0', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Display starts at 0
    expect(getDisplayValue(tester), '0');

    // Try assigning to L/A - should do nothing since display is 0
    await tapButton(tester, 'L/A');

    // Display should remain 0 (no calculation result should overwrite it)
    expect(getDisplayValue(tester), '0');
  });

  testWidgets('Display clears after assigning Interest Rate', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Input 6.5
    await tapButton(tester, '6');
    await tapButton(tester, '.');
    await tapButton(tester, '5');

    expect(getDisplayValue(tester), '6.5');

    // Assign to Int
    await tapButton(tester, 'Int');

    // Display should be cleared to 0
    expect(getDisplayValue(tester), '0');
  });
}
