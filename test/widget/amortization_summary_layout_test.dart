import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/providers/calculator_provider.dart';
import 'package:loan_ranger/src/screens/amortization_screen.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  final binding =
      TestWidgetsFlutterBinding.ensureInitialized()
          as TestWidgetsFlutterBinding;

  tearDown(() {
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  testWidgets('summary tiles wrap on narrow screens', (tester) async {
    binding.window.physicalSizeTestValue = const Size(360, 800);
    binding.window.devicePixelRatioTestValue = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => CalculatorProvider(persistState: false),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const Scaffold(body: AmortizationScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loan-summary-wrap')), findsOneWidget);

    final first = tester.getTopLeft(find.text('Loan Amount'));
    final third = tester.getTopLeft(find.text('Term'));

    expect(third.dy, greaterThan(first.dy));
  });

  testWidgets('summary tiles stay on a single row on wide screens', (
    tester,
  ) async {
    binding.window.physicalSizeTestValue = const Size(1280, 800);
    binding.window.devicePixelRatioTestValue = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => CalculatorProvider(persistState: false),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const Scaffold(body: AmortizationScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final first = tester.getTopLeft(find.text('Loan Amount'));
    final third = tester.getTopLeft(find.text('Term'));

    expect((third.dy - first.dy).abs(), lessThan(1.0));
  });
}
