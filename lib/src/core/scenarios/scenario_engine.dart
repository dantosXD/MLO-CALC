abstract class ScenarioEngine {
  const ScenarioEngine();

  String get scenarioId;

  Map<String, double?> evaluate(Map<String, double?> inputs);
}
