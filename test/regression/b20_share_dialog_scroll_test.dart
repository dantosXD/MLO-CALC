import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';
import 'package:loan_ranger/src/features/settings/domain/providers/mlo_profile_provider.dart';
import 'package:loan_ranger/src/features/share/application/providers/share_templates_provider.dart';
import 'package:loan_ranger/src/features/share/domain/models/quote_share_data.dart';
import 'package:loan_ranger/src/features/share/presentation/dialogs/share_quote_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async => configureDependencies());

  testWidgets('Share dialog on a short window scrolls instead of overflowing', (
    t,
  ) async {
    t.view.physicalSize = const Size(1000, 500);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);

    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => MloProfileProvider(
              preferenceStore: serviceLocator<PreferenceStore>(),
              secureStore: serviceLocator<SecureStore>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ShareTemplatesProvider(
              preferenceStore: serviceLocator<PreferenceStore>(),
            ),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (c) => TextButton(
              onPressed: () => ShareQuoteDialog.show(
                c,
                data: const QuoteShareData(
                  loanAmount: 360000,
                  interestRate: 6.5,
                  termYears: 30,
                  piPayment: 2275.44,
                  pitiPayment: 2275.44,
                  monthlyTax: 0,
                  monthlyInsurance: 0,
                  monthlyMortgageInsurance: 0,
                  monthlyHoa: 0,
                  cashToClose: 90000,
                  price: 450000,
                  downPayment: 20,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    t.takeException(); // test font (Ahem) causes an unrelated horizontal overflow
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SingleChildScrollView),
      ),
      findsWidgets,
    );
  });
}
