import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/main.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
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
}
