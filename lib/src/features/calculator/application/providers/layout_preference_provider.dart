import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalculatorLayout { classic, modern }

class LayoutPreferenceProvider extends ChangeNotifier {
  static const String _layoutKey = 'calculator_layout';
  
  CalculatorLayout _layout = CalculatorLayout.classic;
  bool _isLoaded = false;

  CalculatorLayout get layout => _layout;
  bool get isModern => _layout == CalculatorLayout.modern;
  bool get isLoaded => _isLoaded;

  LayoutPreferenceProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLayout = prefs.getString(_layoutKey);
      if (savedLayout == 'modern') {
        _layout = CalculatorLayout.modern;
      } else {
        _layout = CalculatorLayout.classic;
      }
    } catch (e) {
      debugPrint('Error loading layout preference: $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLayout(CalculatorLayout layout) async {
    if (_layout == layout) return;
    
    _layout = layout;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_layoutKey, layout == CalculatorLayout.modern ? 'modern' : 'classic');
    } catch (e) {
      debugPrint('Error saving layout preference: $e');
    }
  }

  Future<void> toggleLayout() async {
    await setLayout(_layout == CalculatorLayout.classic 
        ? CalculatorLayout.modern 
        : CalculatorLayout.classic);
  }
}
