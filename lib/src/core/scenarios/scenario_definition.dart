import 'package:loan_ranger/src/core/scenarios/scenario_field.dart';
import 'package:loan_ranger/src/core/scenarios/scenario_result.dart';

class ScenarioDefinition {
  const ScenarioDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.inputSchema,
    required this.resultSchema,
    this.actions = const <String>[],
    this.shareTemplateIds = const <String>[],
    this.supportedNlpIntents = const <String>[],
  });

  final String id;
  final String title;
  final String category;
  final List<ScenarioField> inputSchema;
  final List<ScenarioResult> resultSchema;
  final List<String> actions;
  final List<String> shareTemplateIds;
  final List<String> supportedNlpIntents;
}
