import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loan_ranger/src/core/models/amortization_entry.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/amortization_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/loan_quote_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:provider/provider.dart';

import '../widgets/amortization_chart.dart';

class AmortizationScreen extends StatelessWidget {
  const AmortizationScreen({super.key});

  String _generateCsv(List<AmortizationEntry> data) {
    final buffer = StringBuffer();
    buffer.writeln('Month,Payment,Principal,Interest,Balance');
    for (final entry in data) {
      buffer.writeln(
        '${entry.month},'
        '${CurrencyFormatter.formatNumber(entry.payment, decimals: 2).replaceAll(',', '')},'
        '${CurrencyFormatter.formatNumber(entry.principal, decimals: 2).replaceAll(',', '')},'
        '${CurrencyFormatter.formatNumber(entry.interest, decimals: 2).replaceAll(',', '')},'
        '${CurrencyFormatter.formatNumber(entry.balance, decimals: 2).replaceAll(',', '')}',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final calculatorProvider = Provider.of<CalculatorProvider?>(
      context,
      listen: false,
    );
    final quoteController =
        calculatorProvider?.loanQuoteController ??
        context.read<LoanQuoteController>();
    final amortizationController =
        calculatorProvider?.amortizationController ??
        context.read<AmortizationController>();

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
                        ).colorScheme.secondary.withValues(alpha: 0.50),
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
              child: _PayoffMilestonesCard(
                loanAmount: quoteController.loanAmount ?? 0,
                interestRate: quoteController.interestRate ?? 0,
                termYears: quoteController.termYears ?? 30,
                monthlyPayment: quoteController.payment ?? 0,
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
                                    .withValues(alpha: 0.20)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.20),
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
                                CurrencyFormatter.formatCurrency(entry.payment),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                CurrencyFormatter.formatCurrency(
                                  entry.principal,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                CurrencyFormatter.formatCurrency(
                                  entry.interest,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                CurrencyFormatter.formatCurrency(entry.balance),
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

class _PayoffMilestonesCard extends StatefulWidget {
  const _PayoffMilestonesCard({
    required this.loanAmount,
    required this.interestRate,
    required this.termYears,
    required this.monthlyPayment,
  });

  final double loanAmount;
  final double interestRate;
  final double termYears;
  final double monthlyPayment;

  @override
  State<_PayoffMilestonesCard> createState() => _PayoffMilestonesCardState();
}

class _PayoffMilestonesCardState extends State<_PayoffMilestonesCard> {
  final _extraPaymentController = TextEditingController(text: '100');
  bool _loadingAdvice = false;
  String? _advice;

  @override
  void dispose() {
    _extraPaymentController.dispose();
    super.dispose();
  }

  ({int monthsSaved, double interestSaved, double totalYears}) _computePrepaymentImpact(double extra) {
    if (widget.loanAmount <= 0 || widget.termYears <= 0 || widget.monthlyPayment <= 0) {
      return (monthsSaved: 0, interestSaved: 0.0, totalYears: widget.termYears);
    }

    final r = widget.interestRate / 100 / 12;
    final stdTotalMonths = (widget.termYears * 12).round();
    final stdTotalInterest = (widget.monthlyPayment * stdTotalMonths) - widget.loanAmount;

    double balance = widget.loanAmount;
    double extraTotalInterest = 0;
    int monthsWithExtra = 0;
    final totalMonthly = widget.monthlyPayment + extra;

    while (balance > 0.01 && monthsWithExtra < stdTotalMonths * 2) {
      monthsWithExtra++;
      final interest = balance * r;
      extraTotalInterest += interest;
      final principal = totalMonthly - interest;
      if (principal >= balance) {
        balance = 0;
        break;
      } else {
        balance -= principal;
      }
    }

    final monthsSaved = (stdTotalMonths - monthsWithExtra).clamp(0, stdTotalMonths);
    final interestSaved = (stdTotalInterest - extraTotalInterest).clamp(0.0, double.infinity);
    final newYears = monthsWithExtra / 12;

    return (
      monthsSaved: monthsSaved,
      interestSaved: interestSaved,
      totalYears: newYears,
    );
  }

  Future<void> _fetchMilestoneAdvice({
    required double extra,
    required double monthsSaved,
    required double interestSaved,
  }) async {
    setState(() => _loadingAdvice = true);
    try {
      final nlpService = Provider.of<NlpSettingsProvider?>(context, listen: false)?.calculatorService ??
          NLPCalculatorService();
      final result = await nlpService.generatePayoffMilestones(
        loanAmount: widget.loanAmount,
        interestRate: widget.interestRate,
        termYears: widget.termYears,
        monthlyPayment: widget.monthlyPayment,
        extraMonthlyPrincipal: extra,
        monthsSaved: monthsSaved,
        totalInterestSaved: interestSaved,
      );
      if (!mounted) return;
      setState(() => _advice = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _advice = 'Could not generate milestone advice at this time.');
    } finally {
      if (mounted) setState(() => _loadingAdvice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = double.tryParse(_extraPaymentController.text) ?? 0.0;
    final impact = _computePrepaymentImpact(extra);
    final yearsSaved = (impact.monthsSaved / 12).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payoff Acceleration & Milestones',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'See how adding extra principal each month knocks years off your loan and saves interest.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _extraPaymentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Extra Principal / Month',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _advice = null),
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 4,
                  children: [50, 100, 250].map((amount) {
                    return ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text('+\$$amount'),
                      onPressed: () {
                        _extraPaymentController.text = amount.toString();
                        setState(() => _advice = null);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Time Saved',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        extra > 0 ? '$yearsSaved yrs' : '0 yrs',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        '(${impact.monthsSaved} months)',
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  Column(
                    children: [
                      Text(
                        'Interest Saved',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatCurrency(impact.interestSaved),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const Text(
                        'Total lifetime savings',
                        style: TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: (extra > 0 && !_loadingAdvice)
                  ? () => _fetchMilestoneAdvice(
                        extra: extra,
                        monthsSaved: impact.monthsSaved.toDouble(),
                        interestSaved: impact.interestSaved,
                      )
                  : null,
              icon: _loadingAdvice
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
              label: const Text('✨ AI Prepayment Strategy'),
            ),
            if (_advice != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _advice!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
