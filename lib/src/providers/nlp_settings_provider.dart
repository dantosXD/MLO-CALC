import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NlpSettingsProvider with ChangeNotifier {
  static const _keyName = 'geminiApiKey';

  String? _apiKey;
  bool _loaded = false;

  NlpSettingsProvider() {
    _load();
  }

  String? get apiKey => _apiKey;
  bool get isLoaded => _loaded;
  bool get hasKey => (_apiKey != null && _apiKey!.isNotEmpty);

  Future<void> setApiKey(String? value) async {
    _apiKey = value?.trim();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_apiKey == null || _apiKey!.isEmpty) {
        await prefs.remove(_keyName);
      } else {
        await prefs.setString(_keyName, _apiKey!);
      }
    } catch (_) {
      // If persisting fails, we still keep the in-memory value.
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(_keyName);
    } catch (_) {
      _apiKey = null;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }
}
