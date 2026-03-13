import 'package:loan_ranger/src/core/scenarios/scenario_field.dart';

class ScenarioResult {
  const ScenarioResult({
    required this.key,
    required this.type,
    required this.label,
  });

  final String key;
  final ScenarioFieldType type;
  final String label;
}
