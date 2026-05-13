import 'package:flutter/foundation.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';

class MloProfileProvider with ChangeNotifier {
  MloProfileProvider({required PreferenceStore preferenceStore})
    : _prefs = preferenceStore;

  final PreferenceStore _prefs;

  // MLO identity
  String mloName = '';
  String mloNmls = '';
  String mloCompany = '';
  String mloPhone = '';
  String mloEmail = '';

  // Legal disclaimer appended to all shared quotes
  String disclaimerText =
      'Estimates only. Not a loan offer. Taxes/insurance/MI may vary.';

  // Calculator prefill defaults (null = no default)
  double? defaultInterestRate;
  double? defaultTermYears;
  double? defaultDownPaymentPct; // percent of purchase price, e.g. 20.0
  double? defaultPropertyTaxRate; // annual % of home value, e.g. 1.2
  double? defaultInsuranceRate; // annual % of home value, e.g. 0.5

  // Branding — stored as raw ARGB int (Color.value)
  int accentColorValue = 0xFF0891B2; // default = primaryTeal

  static const String _keyName = 'mlo_name';
  static const String _keyNmls = 'mlo_nmls';
  static const String _keyCompany = 'mlo_company';
  static const String _keyPhone = 'mlo_phone';
  static const String _keyEmail = 'mlo_email';
  static const String _keyDisclaimer = 'mlo_disclaimer';
  static const String _keyDefaultRate = 'mlo_default_rate';
  static const String _keyDefaultTerm = 'mlo_default_term';
  static const String _keyDefaultDownPct = 'mlo_default_down_pct';
  static const String _keyDefaultTaxRate = 'mlo_default_tax_rate';
  static const String _keyDefaultInsRate = 'mlo_default_ins_rate';
  static const String _keyAccentColor = 'mlo_accent_color';

  Future<void> load() async {
    try {
      await _prefs.load();
      mloName = _prefs.getString(_keyName) ?? '';
      mloNmls = _prefs.getString(_keyNmls) ?? '';
      mloCompany = _prefs.getString(_keyCompany) ?? '';
      mloPhone = _prefs.getString(_keyPhone) ?? '';
      mloEmail = _prefs.getString(_keyEmail) ?? '';
      disclaimerText =
          _prefs.getString(_keyDisclaimer) ??
          'Estimates only. Not a loan offer. Taxes/insurance/MI may vary.';
      defaultInterestRate = _prefs.getDouble(_keyDefaultRate);
      defaultTermYears = _prefs.getDouble(_keyDefaultTerm);
      defaultDownPaymentPct = _prefs.getDouble(_keyDefaultDownPct);
      defaultPropertyTaxRate = _prefs.getDouble(_keyDefaultTaxRate);
      defaultInsuranceRate = _prefs.getDouble(_keyDefaultInsRate);

      final savedColor = _prefs.getString(_keyAccentColor);
      if (savedColor != null) {
        accentColorValue = int.tryParse(savedColor) ?? 0xFF0891B2;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('MloProfileProvider.load error: $e');
    }
  }

  Future<void> saveProfile({
    required String name,
    required String nmls,
    required String company,
    required String phone,
    required String email,
  }) async {
    mloName = name;
    mloNmls = nmls;
    mloCompany = company;
    mloPhone = phone;
    mloEmail = email;
    notifyListeners();
    await _prefs.setString(_keyName, name);
    await _prefs.setString(_keyNmls, nmls);
    await _prefs.setString(_keyCompany, company);
    await _prefs.setString(_keyPhone, phone);
    await _prefs.setString(_keyEmail, email);
  }

  Future<void> saveDisclaimer(String text) async {
    disclaimerText = text;
    notifyListeners();
    await _prefs.setString(_keyDisclaimer, text);
  }

  Future<void> saveCalculatorDefaults({
    double? interestRate,
    double? termYears,
    double? downPaymentPct,
    double? propertyTaxRate,
    double? insuranceRate,
  }) async {
    defaultInterestRate = interestRate;
    defaultTermYears = termYears;
    defaultDownPaymentPct = downPaymentPct;
    defaultPropertyTaxRate = propertyTaxRate;
    defaultInsuranceRate = insuranceRate;
    notifyListeners();

    await _saveOptionalDouble(_keyDefaultRate, interestRate);
    await _saveOptionalDouble(_keyDefaultTerm, termYears);
    await _saveOptionalDouble(_keyDefaultDownPct, downPaymentPct);
    await _saveOptionalDouble(_keyDefaultTaxRate, propertyTaxRate);
    await _saveOptionalDouble(_keyDefaultInsRate, insuranceRate);
  }

  Future<void> setAccentColor(int colorValue) async {
    accentColorValue = colorValue;
    notifyListeners();
    await _prefs.setString(_keyAccentColor, colorValue.toString());
  }

  Future<void> _saveOptionalDouble(String key, double? value) async {
    if (value != null) {
      await _prefs.setDouble(key, value);
    } else {
      await _prefs.remove(key);
    }
  }

  Map<String, String> toTokenMap() {
    return {
      'mlo_name': mloName,
      'mlo_nmls': mloNmls.isNotEmpty ? 'NMLS# $mloNmls' : '',
      'mlo_company': mloCompany,
      'mlo_phone': mloPhone,
      'mlo_email': mloEmail,
      'disclaimer': disclaimerText,
    };
  }
}
