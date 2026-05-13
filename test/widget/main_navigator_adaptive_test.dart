import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/main.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await configureDependencies();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'calculator_layout': 'classic'});
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
  });

  Widget createTestableWidget(Widget child) {
    return MultiProvider(
      providers: buildAppProviders(),
      child: MaterialApp(home: child),
    );
  }

  testWidgets('uses NavigationBar on compact layouts', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createTestableWidget(const MainNavigator()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('uses NavigationRail on wide layouts', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createTestableWidget(const MainNavigator()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
