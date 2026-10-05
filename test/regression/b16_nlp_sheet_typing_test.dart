import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';
import 'package:loan_ranger/src/core/services/connectivity_service.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/nlp_bottom_sheet.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_cache_service.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  setUpAll(() async => configureDependencies());

  testWidgets('typing shows the send button and Enter submits (not newline)', (
    t,
  ) async {
    await t.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NlpSettingsProvider(
          connectivity: serviceLocator<ConnectivityService>(),
          cache: serviceLocator<NlpCacheService>(),
          calculatorService: serviceLocator<NLPCalculatorService>(),
          secureStore: serviceLocator<SecureStore>(),
          preferenceStore: serviceLocator<PreferenceStore>(),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: NlpBottomSheet(
              nlpService: NLPCalculatorService(),
              speechToText: stt.SpeechToText(),
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.send), findsNothing);
    await t.enterText(find.byType(TextField), '400k at 6.5% for 30 years');
    await t.pump();
    expect(find.byIcon(Icons.send), findsOneWidget);
    final tf = t.widget<TextField>(find.byType(TextField));
    expect(tf.textInputAction, TextInputAction.send);
    expect(tf.keyboardType, TextInputType.text);
  });
}
