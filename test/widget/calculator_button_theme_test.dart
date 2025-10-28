import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:loan_ranger/src/theme/calculator_palette.dart';
import 'package:loan_ranger/src/widgets/calculator_button.dart';

void main() {
  testWidgets('CalculatorButton applies variant colors from palette', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: Row(
            children: [
              CalculatorButton(
                text: 'AC',
                variant: CalculatorButtonVariant.destructive,
                onPressed: noop,
              ),
            ],
          ),
        ),
      ),
    );

    final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    final context = tester.element(find.byType(ElevatedButton));
    final palette = Theme.of(context).extension<CalculatorPalette>()!;
    final expected = palette.colorsForVariant(CalculatorButtonVariant.destructive);

    final background = elevatedButton.style?.backgroundColor?.resolve({});
    final foreground = elevatedButton.style?.foregroundColor?.resolve({});

    expect(background, expected.background);
    expect(foreground, expected.foreground);
  });
}

void noop() {}
