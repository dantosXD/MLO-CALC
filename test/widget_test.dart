import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/main.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/presentation/screens/calculator_screen.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/animated_display.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/calculator_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'calculator_layout': 'classic'});
  });
  // A helper function to wrap the app in providers for testing
  Widget createTestableWidget() {
    return MultiProvider(
      providers: buildAppProviders(),
      child: const LoanRangerApp(),
    );
  }

  // A helper function to get display value
  String getDisplayValue(WidgetTester tester) {
    final animatedDisplay = tester.widget<AnimatedDisplay>(
      find.byKey(const ValueKey('display')),
    );
    return animatedDisplay.displayValue;
  }

  // Helper to find calculator buttons (avoids finding text in display)
  Finder findButton(String text) {
    return find.widgetWithText(CalculatorButton, text);
  }

  // Helper to safely tap buttons that might have custom hit test behavior
  Future<void> tapButton(WidgetTester tester, String text) async {
    await tester.tap(findButton(text), warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('Calculator UI smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Verify that the calculator screen is displayed
    expect(find.byType(CalculatorScreen), findsOneWidget);

    // Verify that the display shows '0' initially.
    expect(getDisplayValue(tester), '0');

    // Verify that the main function buttons are present.
    expect(findButton('L/A'), findsOneWidget);
    expect(findButton('Int'), findsOneWidget);
    expect(findButton('Term'), findsOneWidget);
    expect(findButton('='), findsOneWidget);
  });

  testWidgets('Arithmetic operations test - Addition', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tapButton(tester, '5');
    await tapButton(tester, '+');
    await tapButton(tester, '3');
    await tapButton(tester, '=');

    expect(getDisplayValue(tester), '8');
  });

  testWidgets('Arithmetic operations test - Subtraction', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tapButton(tester, '9');
    await tapButton(tester, '−');
    await tapButton(tester, '4');
    await tapButton(tester, '=');

    expect(getDisplayValue(tester), '5');
  });

  testWidgets('Arithmetic operations test - Multiplication', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tapButton(tester, '6');
    await tapButton(tester, '×');
    await tapButton(tester, '7');
    await tapButton(tester, '=');

    expect(getDisplayValue(tester), '42');
  });

  testWidgets('Arithmetic operations test - Division', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tapButton(tester, '8');
    await tapButton(tester, '÷');
    await tapButton(tester, '2');
    await tapButton(tester, '=');

    expect(getDisplayValue(tester), '4');
  });

  testWidgets('Chained arithmetic operations', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tapButton(tester, '9');
    await tapButton(tester, '+');
    await tapButton(tester, '1');
    // At this point, display is '1', but firstOperand is 9 and operator is +
    await tapButton(tester, '−'); // This should calculate 9+1=10 first

    // Display should reset to show the intermediate result, which is 10
    expect(getDisplayValue(tester), '10');

    await tapButton(tester, '3');
    await tapButton(tester, '=');

    expect(getDisplayValue(tester), '7');
  });

  testWidgets('Division by zero test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tapButton(tester, '5');
    await tapButton(tester, '÷');
    await tester.tap(find.byKey(const Key('btn_0')), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tapButton(tester, '=');

    expect(getDisplayValue(tester), 'Error');
  });

  testWidgets('Clear button test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tapButton(tester, '5');
    await tapButton(tester, '+');
    await tapButton(tester, '3');

    await tapButton(tester, 'AC');

    // Allow the save timer (750ms) to complete
    await tester.pump(const Duration(milliseconds: 800));

    expect(getDisplayValue(tester), '0');
  });
}
