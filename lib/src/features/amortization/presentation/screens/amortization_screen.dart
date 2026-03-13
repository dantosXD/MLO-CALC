import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/amortization_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/loan_quote_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/core/models/amortization_entry.dart';
import '../widgets/amortization_chart.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';

class AmortizationScreen extends StatelessWidget {
  const AmortizationScreen({super.key});

  String _generateCsv(List<AmortizationEntry> data) {
    final buffer = StringBuffer();
    buffer.writeln('Month,Payment,Principal,Interest,Balance');
    for (final entry in data) {
      buffer.writeln(
        '${entry.month},'
        '${entry.payment.toStringAsFixed(2)},'
        '${entry.principal.toStringAsFixed(2)},'
        '${entry.interest.toStringAsFixed(2)},'
        '${entry.balance.toStringAsFixed(2)}',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final calculatorProvider = context.read<CalculatorProvider>();
    final quoteController = calculatorProvider.loanQuoteController;
    final amortizationController = calculatorProvider.amortizationController;

    return AnimatedBuilder(
      animation: Listenable.merge([quoteController, amortizationController]),
      builder: (context, _) {
        // When no data, show scrollable content
        if (amortizationController.amortizationData.isEmpty) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildSummaryCard(
                  context,
                  quoteController,
                  amortizationController,
                ),
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withAlpha(128),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No amortization schedule generated',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter loan details and press "Generate"',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        }

        // When data exists, use nested scroll view for chart + table
        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _buildSummaryCard(
                context,
                quoteController,
                amortizationController,
              ),
            ),
            SliverToBoxAdapter(
              child: AmortizationChart(
                data: amortizationController.amortizationData,
              ),
            ),
          ],
          body: Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Month',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: amortizationController.amortizationData.length,
                    itemBuilder: (context, index) {
                      final entry =
                          amortizationController.amortizationData[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withAlpha(51)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withAlpha(51),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
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
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    LoanQuoteController quoteController,
    AmortizationController amortizationController,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loan Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final summaryData = [
                  (
                    label: 'Loan Amount',
                    value: CurrencyFormatter.formatCurrency(
                      quoteController.loanAmount,
                    ),
                  ),
                  (
                    label: 'Interest Rate',
                    value: CurrencyFormatter.formatPercent(
                      quoteController.interestRate,
                    ),
                  ),
                  (
                    label: 'Term',
                    value: CurrencyFormatter.formatYears(
                      quoteController.termYears,
                    ),
                  ),
                  (
                    label: 'Payment',
                    value: CurrencyFormatter.formatCurrency(
                      quoteController.payment,
                    ),
                  ),
                ];

                final double maxWidth = constraints.maxWidth;
                const double minTileWidth = 180;
                final int columns = maxWidth ~/ minTileWidth;
                final int resolvedColumns = columns.clamp(
                  1,
                  summaryData.length,
                );
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        quoteController.loanAmount != null &&
                            quoteController.interestRate != null &&
                            quoteController.termYears != null &&
                            !amortizationController.isComputingAmortization
                        ? () => amortizationController.generateSchedule()
                        : null,
                    icon: amortizationController.isComputingAmortization
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.table_chart),
                    label: Text(
                      amortizationController.isComputingAmortization
                          ? 'Generating...'
                          : 'Generate',
                    ),
                  ),
                ),
                if (amortizationController.amortizationData.isNotEmpty &&
                    !amortizationController.isComputingAmortization) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      final csv = _generateCsv(
                        amortizationController.amortizationData,
                      );
                      Clipboard.setData(ClipboardData(text: csv));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Schedule copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy CSV'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
