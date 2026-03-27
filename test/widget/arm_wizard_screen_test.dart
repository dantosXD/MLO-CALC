import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/arm/domain/services/arm_calculator_service.dart';
import 'package:loan_ranger/src/features/arm/domain/services/arm_preset_service.dart';
import 'package:loan_ranger/src/features/arm/presentation/screens/arm_wizard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await configureDependencies();
  });

  testWidgets('renders the ARM wizard shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ArmWizardScreen(
          calculator: serviceLocator<ArmCalculatorService>(),
          presetStorage: serviceLocator<ArmPresetStorage>(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ARM Wizard'), findsOneWidget);
    expect(find.text('Next'), findsWidgets);
  });

  testWidgets('generates an ARM schedule', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ArmWizardScreen(
          calculator: serviceLocator<ArmCalculatorService>(),
          presetStorage: serviceLocator<ArmPresetStorage>(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate schedule'));
    await tester.pumpAndSettle();

    expect(find.text('ARM Schedule'), findsOneWidget);
    expect(find.textContaining('Months '), findsWidgets);
  });
}
