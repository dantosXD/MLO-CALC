import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';

/// Unit conversion modes for various calculator inputs
enum TimeUnit { monthly, annual }
enum AmountUnit { percentage, dollar }
enum TermUnit { years, months }

/// Provider for unit conversion preferences
class UnitConversionProvider with ChangeNotifier {
  static const String _taxInsuranceKey = 'unit_tax_insurance';
  static const String _downPaymentKey = 'unit_down_payment';
  static const String _termKey = 'unit_term';

  UnitConversionProvider({PreferenceStore? preferenceStore})
      : _preferences = preferenceStore ?? PreferenceStore();

  final PreferenceStore _preferences;

  TimeUnit _taxInsuranceUnit = TimeUnit.annual;
  AmountUnit _downPaymentUnit = AmountUnit.percentage;
  TermUnit _termUnit = TermUnit.years;

  // Getters
  TimeUnit get taxInsuranceUnit => _taxInsuranceUnit;
  AmountUnit get downPaymentUnit => _downPaymentUnit;
  TermUnit get termUnit => _termUnit;

  // Convenience getters
  bool get isTaxInsuranceMonthly => _taxInsuranceUnit == TimeUnit.monthly;
  bool get isTaxInsuranceAnnual => _taxInsuranceUnit == TimeUnit.annual;
  bool get isDownPaymentPercent => _downPaymentUnit == AmountUnit.percentage;
  bool get isDownPaymentDollar => _downPaymentUnit == AmountUnit.dollar;
  bool get isTermYears => _termUnit == TermUnit.years;
  bool get isTermMonths => _termUnit == TermUnit.months;

  // Toggle methods
  void toggleTaxInsuranceUnit() {
    _taxInsuranceUnit = _taxInsuranceUnit == TimeUnit.annual
        ? TimeUnit.monthly
        : TimeUnit.annual;
    _save();
    notifyListeners();
  }

  void toggleDownPaymentUnit() {
    _downPaymentUnit = _downPaymentUnit == AmountUnit.percentage
        ? AmountUnit.dollar
        : AmountUnit.percentage;
    _save();
    notifyListeners();
  }

  void toggleTermUnit() {
    _termUnit = _termUnit == TermUnit.years
        ? TermUnit.months
        : TermUnit.years;
    _save();
    notifyListeners();
  }

  // Setters
  void setTaxInsuranceUnit(TimeUnit unit) {
    if (_taxInsuranceUnit != unit) {
      _taxInsuranceUnit = unit;
      _save();
      notifyListeners();
    }
  }

  void setDownPaymentUnit(AmountUnit unit) {
    if (_downPaymentUnit != unit) {
      _downPaymentUnit = unit;
      _save();
      notifyListeners();
    }
  }

  void setTermUnit(TermUnit unit) {
    if (_termUnit != unit) {
      _termUnit = unit;
      _save();
      notifyListeners();
    }
  }

  // Conversion utilities
  /// Convert tax/insurance value to annual (for storage/calculation)
  double toAnnual(double value) {
    return _taxInsuranceUnit == TimeUnit.monthly ? value * 12 : value;
  }

  /// Convert annual value to display unit
  double fromAnnual(double annual) {
    return _taxInsuranceUnit == TimeUnit.monthly ? annual / 12 : annual;
  }

  /// Convert down payment to dollar amount
  double toDownPaymentDollars(double value, double homePrice) {
    if (_downPaymentUnit == AmountUnit.percentage) {
      return homePrice * (value / 100);
    }
    return value;
  }

  /// Convert down payment to percentage
  double toDownPaymentPercent(double value, double homePrice) {
    if (_downPaymentUnit == AmountUnit.dollar && homePrice > 0) {
      return (value / homePrice) * 100;
    }
    return value;
  }

  /// Convert term to years (for calculation)
  double toYears(double value) {
    return _termUnit == TermUnit.months ? value / 12 : value;
  }

  /// Convert years to display unit
  double fromYears(double years) {
    return _termUnit == TermUnit.months ? years * 12 : years;
  }

  // Labels for UI
  String get taxInsuranceLabel => 
      _taxInsuranceUnit == TimeUnit.monthly ? '/month' : '/year';
  
  String get downPaymentLabel => 
      _downPaymentUnit == AmountUnit.percentage ? '%' : '\$';
  
  String get termLabel => 
      _termUnit == TermUnit.years ? 'years' : 'months';

  Future<void> load() async {
    try {
      await _preferences.load();

      final taxIns = _preferences.getString(_taxInsuranceKey);
      if (taxIns == 'monthly') _taxInsuranceUnit = TimeUnit.monthly;
      
      final downPmt = _preferences.getString(_downPaymentKey);
      if (downPmt == 'dollar') _downPaymentUnit = AmountUnit.dollar;
      
      final term = _preferences.getString(_termKey);
      if (term == 'months') _termUnit = TermUnit.months;
      
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await _preferences.load();
      await _preferences.setString(
        _taxInsuranceKey,
          _taxInsuranceUnit == TimeUnit.monthly ? 'monthly' : 'annual');
      await _preferences.setString(
        _downPaymentKey,
        _downPaymentUnit == AmountUnit.dollar ? 'dollar' : 'percentage',
      );
      await _preferences.setString(
        _termKey,
        _termUnit == TermUnit.months ? 'months' : 'years',
      );
    } catch (_) {}
  }
}

/// Widget for displaying a unit toggle button
class UnitToggleButton extends StatelessWidget {
  final String label;
  final String currentUnit;
  final VoidCallback onToggle;
  final bool compact;

  const UnitToggleButton({
    super.key,
    required this.label,
    required this.currentUnit,
    required this.onToggle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(50),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentUnit,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.swap_horiz,
              size: compact ? 12 : 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented button for unit selection
class UnitSegmentedButton<T> extends StatelessWidget {
  final T value;
  final List<({T value, String label})> options;
  final ValueChanged<T> onChanged;

  const UnitSegmentedButton({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: options.map((opt) => ButtonSegment<T>(
        value: opt.value,
        label: Text(opt.label, style: const TextStyle(fontSize: 11)),
      )).toList(),
      selected: {value},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
