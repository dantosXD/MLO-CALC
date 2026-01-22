import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _balloonYearsController = TextEditingController();
  double? _balloonBalance;
  Map<String, double>? _biWeeklyResults;

  @override
  void dispose() {
    _balloonYearsController.dispose();
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
          // Loan Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Loan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Loan Amount',
                    value: calculatorProvider.loanAmount != null
                        ? '\$${calculatorProvider.loanAmount!.toStringAsFixed(2)}'
                        : 'Not set',
                  ),
                  const SizedBox(height: 8),
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
                    label: 'Monthly Payment',
                    value: calculatorProvider.payment != null
                        ? '\$${calculatorProvider.payment!.toStringAsFixed(2)}'
                        : 'Not set',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Balloon Payment Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calculate,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Balloon Payment Calculator',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calculate the remaining balance after a specified number of years.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _balloonYearsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Years',
                      border: OutlineInputBorder(),
                      helperText: 'Number of years before balloon payment',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: calculatorProvider.loanAmount != null &&
                              calculatorProvider.interestRate != null &&
                              calculatorProvider.termYears != null
                          ? () {
                              final years = double.tryParse(_balloonYearsController.text);
                              if (years != null && years > 0) {
                                setState(() {
                                  _balloonBalance = calculatorProvider.calculateRemainingBalance(years);
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid number of years')),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculate Balloon Payment'),
                    ),
                  ),
                  if (_balloonBalance != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Remaining Balance',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${_balloonBalance!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'after ${_balloonYearsController.text} years',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bi-Weekly Payment Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bi-Weekly Payment Analysis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'See how bi-weekly payments can save you money and reduce your loan term.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: calculatorProvider.loanAmount != null &&
                              calculatorProvider.interestRate != null &&
                              calculatorProvider.payment != null
                          ? () {
                              setState(() {
                                _biWeeklyResults = calculatorProvider.calculateBiWeeklyConversion();
                              });
                            }
                          : null,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Analyze Bi-Weekly Payments'),
                    ),
                  ),
                  if (_biWeeklyResults != null && _biWeeklyResults!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ResultRow(
                            label: 'Bi-Weekly Payment',
                            value: '\$${_biWeeklyResults!['biWeeklyPayment']!.toStringAsFixed(2)}',
                            icon: Icons.payments,
                          ),
                          const Divider(height: 24),
                          _ResultRow(
                            label: 'New Loan Term',
                            value: '${_biWeeklyResults!['newTermYears']!.toStringAsFixed(1)} years',
                            icon: Icons.schedule,
                          ),
                          const Divider(height: 24),
                          _ResultRow(
                            label: 'Interest Saved',
                            value: '\$${_biWeeklyResults!['interestSaved']!.toStringAsFixed(2)}',
                            icon: Icons.savings,
                            valueColor: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(51),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 20, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Paying bi-weekly reduces your term by ${(calculatorProvider.termYears! - _biWeeklyResults!['newTermYears']!).toStringAsFixed(1)} years!',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
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
              ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
                      color: valueColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
