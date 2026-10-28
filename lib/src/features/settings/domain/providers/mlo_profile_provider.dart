import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/brand_header.dart';

class MloProfileProvider with ChangeNotifier {
  MloProfileProvider({
    required PreferenceStore preferenceStore,
    required SecureStore secureStore,
  }) : _prefs = preferenceStore,
       _secureStore = secureStore;

  final PreferenceStore _prefs;
  final SecureStore _secureStore;

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

  // Branding links + cached logo (non-PII)
  String applyUrl = '';
  String logoUrl = '';
  String logoBytesBase64 = '';

  static const String _keyApplyUrl = 'mlo_apply_url';
  static const String _keyLogoUrl = 'mlo_logo_url';
  static const String _keyLogoB64 = 'mlo_logo_b64';
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
      // PII fields — read from SecureStore
      mloName = await _secureStore.read(_keyName) ?? '';
      mloNmls = await _secureStore.read(_keyNmls) ?? '';
      mloPhone = await _secureStore.read(_keyPhone) ?? '';
      mloEmail = await _secureStore.read(_keyEmail) ?? '';
      // Non-PII fields — read from PreferenceStore
      mloCompany = _prefs.getString(_keyCompany) ?? '';
      disclaimerText =
          _prefs.getString(_keyDisclaimer) ??
          'Estimates only. Not a loan offer. Taxes/insurance/MI may vary.';
      applyUrl = _prefs.getString(_keyApplyUrl) ?? '';
      logoUrl = _prefs.getString(_keyLogoUrl) ?? '';
      logoBytesBase64 = _prefs.getString(_keyLogoB64) ?? '';
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
      if (kDebugMode) {
        debugPrint('MloProfileProvider.load error: $e');
      }
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
    // PII fields — write to SecureStore
    await _secureStore.write(key: _keyName, value: name);
    await _secureStore.write(key: _keyNmls, value: nmls);
    await _secureStore.write(key: _keyPhone, value: phone);
    await _secureStore.write(key: _keyEmail, value: email);
    // Non-PII — write to PreferenceStore
    await _prefs.setString(_keyCompany, company);
  }

  Future<void> saveDisclaimer(String text) async {
    disclaimerText = text;
    notifyListeners();
    await _prefs.setString(_keyDisclaimer, text);
  }

  Future<void> saveBranding({
    required String applyUrl,
    required String logoUrl,
  }) async {
    this.applyUrl = applyUrl;
    this.logoUrl = logoUrl;
    notifyListeners();
    await _prefs.setString(_keyApplyUrl, applyUrl);
    await _prefs.setString(_keyLogoUrl, logoUrl);
  }

  // ponytail: logo comes from a URL because no image-picker dependency is
  // installed; add file_selector if MLOs ask to pick a file.
  Future<bool> refreshLogo({http.Client? client}) async {
    if (logoUrl.isEmpty) return false;
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse(logoUrl))
          .timeout(const Duration(seconds: 10));
      final n = res.bodyBytes.length;
      if (res.statusCode != 200 || n == 0 || n > 500 * 1024) return false;
      logoBytesBase64 = base64Encode(res.bodyBytes);
      notifyListeners();
      await _prefs.setString(_keyLogoB64, logoBytesBase64);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (client == null) c.close();
    }
  }

  BrandInfo toBrandInfo() {
    Uint8List? logo;
    try {
      if (logoBytesBase64.isNotEmpty) logo = base64Decode(logoBytesBase64);
    } catch (_) {}
    return BrandInfo(
      name: mloName,
      nmls: mloNmls,
      company: mloCompany,
      phone: mloPhone,
      email: mloEmail,
      applyUrl: applyUrl,
      disclaimer: disclaimerText,
      logo: logo,
      accentColor: accentColorValue,
    );
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
      'applyUrl': applyUrl,
      // Label included so an empty URL leaves no dangling "Apply:".
      'apply_line': applyUrl.isNotEmpty ? 'Apply: $applyUrl' : '',
    };
  }
}
