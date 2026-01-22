import '../../application/providers/comparison_provider.dart';

class ComparisonExporter {
  static String buildCsv(ComparisonData data) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Scenario,Monthly Payment,Total Cost,Total Interest,MI Drop Month,Break-even Months');
    for (final view in data.views) {
      buffer.writeln([
        view.entry.summary.replaceAll(',', ';'),
        view.monthlyPayment?.toStringAsFixed(2) ?? '',
        view.totalCost?.toStringAsFixed(2) ?? '',
        view.totalInterest?.toStringAsFixed(2) ?? '',
        view.miDropMonth?.toString() ?? '',
        view.breakEvenMonths?.toStringAsFixed(1) ?? '',
      ].join(','));
    }
    return buffer.toString();
  }
}
