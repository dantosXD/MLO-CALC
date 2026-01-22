import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/amortization/presentation/screens/amortization_screen.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await configureDependencies();
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
  });

  testWidgets('summary tiles wrap on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => CalculatorProvider(),
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
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => CalculatorProvider(),
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
