import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';

class QualificationScreen extends StatefulWidget {
  const QualificationScreen({super.key});

  @override
  State<QualificationScreen> createState() => _QualificationScreenState();
}

class _QualificationScreenState extends State<QualificationScreen> {
  final _incomeController = TextEditingController();
  final _debtController = TextEditingController();
  bool _useRatio1 = true;

  @override
  void dispose() {
    _incomeController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculatorProvider = Provider.of<CalculatorProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Qualifying Ratios Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qualifying Ratios',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: true,
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Conventional'),
                            Text(
                              '${calculatorProvider.qualRatio1.housingRatio}% / ${calculatorProvider.qualRatio1.debtRatio}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('FHA/VA'),
                            Text(
                              '${calculatorProvider.qualRatio2.housingRatio}% / ${calculatorProvider.qualRatio2.debtRatio}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                    selected: {_useRatio1},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() {
                        _useRatio1 = selected.first;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Format: Housing Ratio / Total Debt Ratio',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Borrower Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Borrower Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Annual Income',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      helperText: 'Gross annual income',
                    ),
                    onChanged: (value) {
                      final income = double.tryParse(value);
                      calculatorProvider.setAnnualIncome(value: income);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _debtController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Debt Payments',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      helperText: 'Total monthly debt obligations',
                    ),
                    onChanged: (value) {
                      final debt = double.tryParse(value);
                      calculatorProvider.setMonthlyDebt(value: debt);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Loan Parameters Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loan Parameters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Interest Rate',
                    value: calculatorProvider.interestRate != null
                        ? '${calculatorProvider.interestRate!.toStringAsFixed(3)}%'
                        : 'Not set',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Term',
                    value: calculatorProvider.termYears != null
                        ? '${calculatorProvider.termYears!.toStringAsFixed(0)} years'
                        : 'Not set',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Loan Amount',
                    value: calculatorProvider.loanAmount != null
                        ? '\$${calculatorProvider.loanAmount!.toStringAsFixed(2)}'
                        : 'Not set',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set these values in the Calculator tab',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Calculation Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: calculatorProvider.annualIncome != null &&
                          calculatorProvider.interestRate != null &&
                          calculatorProvider.termYears != null
                      ? () {
                          calculatorProvider.calculateMaxQualifyingLoan(
                            useRatio1: _useRatio1,
                          );
                          _showResultDialog(
                            context,
                            'Maximum Qualifying Loan',
                            'Based on your income and debt ratios, you qualify for a maximum loan amount of:',
                            calculatorProvider.loanAmount,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Max Loan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: calculatorProvider.loanAmount != null &&
                          calculatorProvider.interestRate != null &&
                          calculatorProvider.termYears != null
                      ? () {
                          calculatorProvider.calculateMinimumIncome(
                            useRatio1: _useRatio1,
                          );
                          _showResultDialog(
                            context,
                            'Minimum Required Income',
                            'To qualify for this loan, you need a minimum annual income of:',
                            calculatorProvider.annualIncome,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Min Income'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Results Card
          if (calculatorProvider.payment != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Loan Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Monthly P&I Payment',
                      value: '\$${calculatorProvider.payment!.toStringAsFixed(2)}',
                      valueColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    if (calculatorProvider.pitiPayment > calculatorProvider.payment!)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _InfoRow(
                          label: 'Monthly PITI Payment',
                          value: '\$${calculatorProvider.pitiPayment.toStringAsFixed(2)}',
                          valueColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, String title, String message, double? value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              value != null ? '\$${value.toStringAsFixed(2)}' : 'N/A',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
