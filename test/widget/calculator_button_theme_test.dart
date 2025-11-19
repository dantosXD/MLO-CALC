import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:loan_ranger/src/widgets/calculator_button.dart';

void main() {
  testWidgets('CalculatorButton applies custom colors', (tester) async {
    const testBackgroundColor = Colors.red;
    const testForegroundColor = Colors.white;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: Row(
            children: [
              CalculatorButton(
                text: 'AC',
                backgroundColor: testBackgroundColor,
                foregroundColor: testForegroundColor,
                onPressed: noop,
              ),
            ],
          ),
        ),
      ),
    );

    final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    final background = elevatedButton.style?.backgroundColor?.resolve({});
    final foreground = elevatedButton.style?.foregroundColor?.resolve({});

    expect(background, testBackgroundColor);
    expect(foreground, testForegroundColor);
  });
}

void noop() {}
