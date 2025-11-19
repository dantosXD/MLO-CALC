import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/main.dart';
import 'package:loan_ranger/src/providers/calculator_provider.dart';
import 'package:loan_ranger/src/screens/calculator_screen.dart';
import 'package:loan_ranger/src/widgets/animated_display.dart';
import 'package:provider/provider.dart';

void main() {
  // A helper function to wrap the app in providers for testing
  Widget createTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => CalculatorProvider()),
      ],
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
    return find.widgetWithText(ElevatedButton, text);
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

  testWidgets('Arithmetic operations test - Addition', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(findButton('5'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('+'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('3'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '8');
  });

  testWidgets('Arithmetic operations test - Subtraction', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(findButton('9'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('−'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('4'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '5');
  });

  testWidgets('Arithmetic operations test - Multiplication', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(findButton('6'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('×'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('7'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '42');
  });

  testWidgets('Arithmetic operations test - Division', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(findButton('8'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('÷'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('2'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '4');
  });

   testWidgets('Chained arithmetic operations', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(findButton('9'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('+'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('1'));
    await tester.pumpAndSettle();
    // At this point, display is '1', but firstOperand is 9 and operator is +
    await tester.tap(findButton('−')); // This should calculate 9+1=10 first
    await tester.pumpAndSettle();

    // Display should reset to show the intermediate result, which is 10
    expect(getDisplayValue(tester), '10');

    await tester.tap(findButton('3'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '7');
  });

  testWidgets('Division by zero test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(findButton('5'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('÷'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_0')));
    await tester.pumpAndSettle();
    await tester.tap(findButton('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), 'Error');
  });

  testWidgets('Clear button test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(findButton('5'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('+'));
    await tester.pumpAndSettle();
    await tester.tap(findButton('3'));
    await tester.pumpAndSettle();

    await tester.tap(findButton('AC'));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '0');
  });
}
