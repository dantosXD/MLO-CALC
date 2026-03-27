import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/main.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/navigation/feature_catalog.dart';
import 'package:loan_ranger/src/features/workspace/presentation/screens/workspace_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await configureDependencies();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'calculator_layout': 'classic',
    });
  });

  testWidgets('workspace dashboard shows pinned tools and templates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: buildAppProviders(),
        child: const MaterialApp(home: WorkspaceDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workspace Dashboard'), findsOneWidget);
    expect(find.text('Pinned Tools'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Purchase Quote'),
      250,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Purchase Quote'), findsOneWidget);
    expect(find.textContaining('Qualification Max Loan'), findsOneWidget);
  });

  testWidgets('workspace dashboard returns calculator id when open is tapped', (
    WidgetTester tester,
  ) async {
    String? selectedFeatureId;

    await tester.pumpWidget(
      MultiProvider(
        providers: buildAppProviders(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      selectedFeatureId = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => const WorkspaceDashboardScreen(),
                        ),
                      );
                    },
                    child: const Text('Open dashboard'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dashboard'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Open').first);
    await tester.pumpAndSettle();

    expect(selectedFeatureId, FeatureCatalog.calculatorId);
  });
}
