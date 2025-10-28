import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../widgets/amortization_chart.dart';
import '../utils/formatters.dart';

class AmortizationScreen extends StatelessWidget {
  const AmortizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calculatorProvider = Provider.of<CalculatorProvider>(context);

    return Column(
      children: [
        // Summary Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final summaryData = [
                      (
                        label: 'Loan Amount',
                        value: CurrencyFormatter.formatCurrency(
                          calculatorProvider.loanAmount,
                        ),
                      ),
                      (
                        label: 'Interest Rate',
                        value: CurrencyFormatter.formatPercent(
                          calculatorProvider.interestRate,
                        ),
                      ),
                      (
                        label: 'Term',
                        value: CurrencyFormatter.formatYears(
                          calculatorProvider.termYears,
                        ),
                      ),
                      (
                        label: 'Payment',
                        value: CurrencyFormatter.formatCurrency(
                          calculatorProvider.payment,
                        ),
                      ),
                    ];

                    final double maxWidth = constraints.maxWidth;
                    const double minTileWidth = 180;
                    final int columns = maxWidth ~/ minTileWidth;
                    final int resolvedColumns = columns.clamp(1, summaryData.length);
                    final double spacing = 16;
                    final double tileWidth = resolvedColumns == 1
                        ? maxWidth
                        : (maxWidth - spacing * (resolvedColumns - 1)) /
                            resolvedColumns;

                    return Wrap(
                      key: const Key('loan-summary-wrap'),
                      spacing: spacing,
                      runSpacing: 12,
                      children: [
                        for (final item in summaryData)
                          SizedBox(
                            width: tileWidth.clamp(160.0, maxWidth),
                            child: _SummaryItem(
                              label: item.label,
                              value: item.value,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: calculatorProvider.loanAmount != null &&
                            calculatorProvider.interestRate != null &&
                            calculatorProvider.termYears != null
                        ? () => calculatorProvider.generateAmortizationSchedule()
                        : null,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Generate Schedule'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Chart Visualization
        if (calculatorProvider.amortizationData.isNotEmpty)
          AmortizationChart(data: calculatorProvider.amortizationData),

        // Amortization Table
        Expanded(
          child: calculatorProvider.amortizationData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary.withAlpha(128),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No amortization schedule generated',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter loan details and press "Generate Schedule"',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : Card(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Month',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Payment',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Principal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Interest',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Balance',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Table Content
                      Expanded(
                        child: ListView.builder(
                          itemCount: calculatorProvider.amortizationData.length,
                          itemBuilder: (context, index) {
                            final entry = calculatorProvider.amortizationData[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(51)
                                    : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).dividerColor.withAlpha(51),
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${entry.month}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '\$${entry.payment.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '\$${entry.principal.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '\$${entry.interest.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '\$${entry.balance.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: entry.balance == 0
                                            ? Theme.of(context).colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
