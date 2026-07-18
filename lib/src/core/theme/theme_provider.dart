import 'package:flutter/material.dart';

import '../persistence/preference_store.dart';

class ThemeProvider with ChangeNotifier {
  ThemeProvider({PreferenceStore? preferenceStore})
    : _preferenceStore = preferenceStore;

  static const String _themeModeKey = 'themeMode';

  final PreferenceStore? _preferenceStore;

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  /// Restore the persisted theme mode. Safe to call when no store is wired
  /// (the default constructor), in which case it is a no-op.
  Future<void> load() async {
    final store = _preferenceStore;
    if (store == null) return;
    await store.load();
    final raw = store.getString(_themeModeKey);
    _themeMode = raw == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    final store = _preferenceStore;
    if (store == null) return;
    await store.setString(
      _themeModeKey,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
