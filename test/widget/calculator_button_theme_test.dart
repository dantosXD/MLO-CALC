import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/calculator_button.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';

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

    final elevatedButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );

    final background = elevatedButton.style?.backgroundColor?.resolve({});
    final foreground = elevatedButton.style?.foregroundColor?.resolve({});

    expect(background, testBackgroundColor);
    expect(foreground, testForegroundColor);
  });

  testWidgets('CalculatorButton long press does not trigger normal onPressed', (
    tester,
  ) async {
    var tapCount = 0;
    var longPressCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: Row(
            children: [
              CalculatorButton(
                text: 'L/A',
                onPressed: () => tapCount++,
                onLongPress: () => longPressCount++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(CalculatorButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tapCount, 0);
    expect(longPressCount, 1);
  });

  testWidgets('CalculatorButton double tap does not trigger normal onPressed', (
    tester,
  ) async {
    var tapCount = 0;
    var doubleTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: Row(
            children: [
              CalculatorButton(
                text: 'Pmt',
                onPressed: () => tapCount++,
                onDoubleTap: () => doubleTapCount++,
              ),
            ],
          ),
        ),
      ),
    );

    final button = find.byType(CalculatorButton);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tapCount, 0);
    expect(doubleTapCount, 1);
  });
}

void noop() {}
