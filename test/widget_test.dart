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

  testWidgets('Calculator UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Verify that the calculator screen is displayed
    expect(find.byType(CalculatorScreen), findsOneWidget);

    // Verify that the display shows '0' initially.
    expect(getDisplayValue(tester), '0');

    // Verify that the main function buttons are present.
    expect(find.text('L/A'), findsOneWidget);
    expect(find.text('Int'), findsOneWidget);
    expect(find.text('Term'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
  });

  testWidgets('Arithmetic operations test - Addition', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '8');
  });

  testWidgets('Arithmetic operations test - Subtraction', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('9'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('-'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '5');
  });

  testWidgets('Arithmetic operations test - Multiplication', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('6'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('x'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '42');
  });

  testWidgets('Arithmetic operations test - Division', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '4');
  });

   testWidgets('Chained arithmetic operations', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('9'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    // At this point, display is '1', but firstOperand is 9 and operator is +
    await tester.tap(find.text('-')); // This should calculate 9+1=10 first
    await tester.pumpAndSettle();

    // Display should reset to show the intermediate result, which is 10
    expect(getDisplayValue(tester), '10');

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '7');
  });

  testWidgets('Division by zero test', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), 'Error');
  });

  testWidgets('Clear button test', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();

    expect(getDisplayValue(tester), '0');
  });
}
