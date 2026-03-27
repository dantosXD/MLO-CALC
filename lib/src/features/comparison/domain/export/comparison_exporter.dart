import 'package:loan_ranger/src/core/utils/formatters.dart';

import '../models/comparison_data.dart';

class ComparisonExporter {
  static String buildCsv(ComparisonData data) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Scenario,Monthly Payment,Total Cost,Total Interest,MI Drop Month,Break-even Months');
    for (final view in data.views) {
      buffer.writeln([
        view.entry.summary.replaceAll(',', ';'),
        view.monthlyPayment == null
            ? ''
            : CurrencyFormatter.formatNumber(view.monthlyPayment, decimals: 2)
                .replaceAll(',', ''),
        view.totalCost == null
            ? ''
            : CurrencyFormatter.formatNumber(view.totalCost, decimals: 2)
                .replaceAll(',', ''),
        view.totalInterest == null
            ? ''
            : CurrencyFormatter.formatNumber(view.totalInterest, decimals: 2)
                .replaceAll(',', ''),
        view.miDropMonth?.toString() ?? '',
        view.breakEvenMonths == null
            ? ''
            : CurrencyFormatter.formatNumber(view.breakEvenMonths, decimals: 1)
                .replaceAll(',', ''),
      ].join(','));
    }
    return buffer.toString();
  }
}
