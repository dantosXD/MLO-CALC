// Regression: BUGLOG B4 — theme mode was never persisted.
//
// ThemeProvider held _themeMode in memory only, so dark mode reset to light on
// every restart. It must persist the selected mode via PreferenceStore and
// restore it on load(), while still supporting a no-store default constructor.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('B4: theme mode persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('toggled dark mode survives into a freshly loaded provider', () async {
      final store = PreferenceStore();
      final provider = ThemeProvider(preferenceStore: store);
      await provider.load();
      expect(provider.themeMode, ThemeMode.light);

      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);

      // A new provider backed by the same store must restore dark mode.
      final restored = ThemeProvider(preferenceStore: store);
      await restored.load();
      expect(restored.themeMode, ThemeMode.dark);
    });

    test('default constructor (no store) still works and does not throw',
        () async {
      final provider = ThemeProvider();
      await provider.load();
      expect(provider.themeMode, ThemeMode.light);
      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
    });
  });
}
