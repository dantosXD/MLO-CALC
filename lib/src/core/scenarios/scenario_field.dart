enum ScenarioFieldType {
  currency,
  percent,
  years,
  monthlyCurrency,
  annualCurrency,
  decimal,
  integer,
}

class ScenarioField {
  const ScenarioField({
    required this.key,
    required this.type,
    required this.label,
    this.unit,
    this.isRequired = false,
  });

  final String key;
  final ScenarioFieldType type;
  final String label;
  final String? unit;
  final bool isRequired;
}
