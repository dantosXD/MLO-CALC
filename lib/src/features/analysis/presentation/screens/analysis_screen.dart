import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/navigation/app_router.dart';
import 'package:loan_ranger/src/core/utils/advanced_calculations.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/closing_costs_sheet.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/report_service.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

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
    final calculatorProvider = context.read<CalculatorProvider>();

    return AnimatedBuilder(
      animation: Listenable.merge([
        calculatorProvider.loanQuoteController,
        calculatorProvider.amortizationController,
        calculatorProvider.qualificationController,
      ]),
      builder: (context, _) => SingleChildScrollView(
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
                          ? CurrencyFormatter.formatCurrency(
                              calculatorProvider.loanAmount,
                            )
                          : 'Not set',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Interest Rate',
                      value: calculatorProvider.interestRate != null
                          ? CurrencyFormatter.formatPercent(
                              calculatorProvider.interestRate,
                              decimals: 3,
                            )
                          : 'Not set',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Term',
                      value: calculatorProvider.termYears != null
                          ? CurrencyFormatter.formatYears(
                              calculatorProvider.termYears,
                            )
                          : 'Not set',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Monthly Payment',
                      value: calculatorProvider.payment != null
                          ? CurrencyFormatter.formatCurrency(
                              calculatorProvider.payment,
                            )
                          : 'Not set',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Closing Costs',
                      value: CurrencyFormatter.formatCurrency(
                        calculatorProvider.closingCosts.total,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Cash to Close',
                      value: CurrencyFormatter.formatCurrency(
                        calculatorProvider.cashToClose,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            _AdvancedToolsCard(
              onLaunchArm: () => _openArmWizard(context),
              onFutureValue: () =>
                  _showFutureValueSheet(context, calculatorProvider),
              onApr: () => _showAprSheet(context, calculatorProvider),
              onRentVsBuy: () => _openRentVsBuy(context),
              onClosingCosts: () => _openClosingCosts(context),
              onGenerateReport: () async =>
                  _generateReport(context, calculatorProvider),
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
                        onPressed:
                            calculatorProvider.loanAmount != null &&
                                calculatorProvider.interestRate != null &&
                                calculatorProvider.termYears != null
                            ? () {
                                final years = double.tryParse(
                                  _balloonYearsController.text,
                                );
                                if (years != null && years > 0) {
                                  setState(() {
                                    _balloonBalance = calculatorProvider
                                        .calculateRemainingBalance(years);
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid number of years',
                                      ),
                                    ),
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
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.formatCurrency(_balloonBalance),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'after ${_balloonYearsController.text} years',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
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
                        onPressed:
                            calculatorProvider.loanAmount != null &&
                                calculatorProvider.interestRate != null &&
                                calculatorProvider.payment != null
                            ? () {
                                setState(() {
                                  _biWeeklyResults = calculatorProvider
                                      .calculateBiWeeklyConversion();
                                });
                              }
                            : null,
                        icon: const Icon(Icons.analytics),
                        label: const Text('Analyze Bi-Weekly Payments'),
                      ),
                    ),
                    if (_biWeeklyResults != null &&
                        _biWeeklyResults!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ResultRow(
                              label: 'Bi-Weekly Payment',
                              value: CurrencyFormatter.formatCurrency(
                                _biWeeklyResults!['biWeeklyPayment'],
                              ),
                              icon: Icons.payments,
                            ),
                            const Divider(height: 24),
                            _ResultRow(
                              label: 'New Loan Term',
                              value: CurrencyFormatter.formatYears(
                                _biWeeklyResults!['newTermYears'],
                              ),
                              icon: Icons.schedule,
                            ),
                            const Divider(height: 24),
                            _ResultRow(
                              label: 'Interest Saved',
                              value: CurrencyFormatter.formatCurrency(
                                _biWeeklyResults!['interestSaved'],
                              ),
                              icon: Icons.savings,
                              valueColor: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Paying bi-weekly reduces your term by ${CurrencyFormatter.formatYears(calculatorProvider.termYears! - _biWeeklyResults!['newTermYears']!)}!',
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

            const SizedBox(height: 24),

            // Rate Buy-Down & Points Break-Even Card
            _PointsBreakEvenCard(
              loanAmount: calculatorProvider.loanAmount,
              currentRate: calculatorProvider.interestRate,
              termYears: calculatorProvider.termYears,
              currentPayment: calculatorProvider.payment,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport(
    BuildContext context,
    CalculatorProvider provider,
  ) async {
    if (provider.loanAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calculate a loan first to generate a report.'),
        ),
      );
      return;
    }

    final pdfData = await ReportService.generateLoanReport(provider: provider);
    if (!context.mounted) return;
    await Printing.sharePdf(bytes: pdfData, filename: 'loan-estimate.pdf');
  }

  void _openArmWizard(BuildContext context) {
    context.read<AppRouter>().openArmWizard();
  }

  void _openRentVsBuy(BuildContext context) {
    context.read<AppRouter>().openRentVsBuy();
  }

  void _openClosingCosts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ClosingCostsSheet(),
    );
  }

  void _showFutureValueSheet(
    BuildContext context,
    CalculatorProvider provider,
  ) {
    final double? basePrice = provider.price ?? provider.loanAmount;
    if (basePrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set a price or loan amount first.')),
      );
      return;
    }

    final rateController = TextEditingController(text: '3.0');
    final yearsController = TextEditingController(text: '5');
    double? result;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Future Value Projection',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Annual Appreciation Rate (%)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: yearsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Years',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final rate = double.tryParse(rateController.text);
                        final years = double.tryParse(yearsController.text);
                        if (rate == null || years == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter valid rate and term.'),
                            ),
                          );
                          return;
                        }
                        final fv = basePrice * math.pow(1 + rate / 100, years);
                        setModalState(() => result = fv);
                      },
                      child: const Text('Calculate'),
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Projected Value',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatCurrency(result),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAprSheet(BuildContext context, CalculatorProvider provider) {
    if (provider.loanAmount == null ||
        provider.interestRate == null ||
        provider.termYears == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need loan amount, rate, and term first.'),
        ),
      );
      return;
    }

    final feesController = TextEditingController(text: '4500');
    final pointsController = TextEditingController(text: '0');
    double? aprResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'APR Estimator',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: feesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Loan Fees (\$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pointsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Discount Points (%)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final fees = double.tryParse(feesController.text);
                        final points = double.tryParse(pointsController.text);
                        if (fees == null || points == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Provide valid fees and points.'),
                            ),
                          );
                          return;
                        }
                        final apr = AdvancedCalculations.calculateAPR(
                          loanAmount: provider.loanAmount!,
                          interestRate: provider.interestRate!,
                          termYears: provider.termYears!,
                          loanFees: fees,
                          points: points,
                        );
                        setModalState(() => aprResult = apr);
                      },
                      child: const Text('Estimate APR'),
                    ),
                  ),
                  if (aprResult != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'APR ${CurrencyFormatter.formatPercent(aprResult, decimals: 3)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
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
              Text(label, style: Theme.of(context).textTheme.bodySmall),
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

class _AdvancedToolsCard extends StatelessWidget {
  const _AdvancedToolsCard({
    required this.onLaunchArm,
    required this.onFutureValue,
    required this.onApr,
    required this.onRentVsBuy,
    required this.onClosingCosts,
    required this.onGenerateReport,
  });

  final VoidCallback onLaunchArm;
  final VoidCallback onFutureValue;
  final VoidCallback onApr;
  final VoidCallback onRentVsBuy;
  final VoidCallback onClosingCosts;
  final VoidCallback onGenerateReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Advanced Tools', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ToolButton(
                  icon: Icons.picture_as_pdf,
                  title: 'PDF Report',
                  subtitle: 'Share loan estimate',
                  onPressed: onGenerateReport,
                ),
                _ToolButton(
                  icon: Icons.request_quote,
                  title: 'Closing Costs',
                  subtitle: 'Estimate fees & cash to close',
                  onPressed: onClosingCosts,
                ),
                _ToolButton(
                  icon: Icons.auto_graph,
                  title: 'ARM Wizard',
                  subtitle: 'Model adjustable rate scenarios',
                  onPressed: onLaunchArm,
                ),
                _ToolButton(
                  icon: Icons.trending_up,
                  title: 'Future Value',
                  subtitle: 'Project appreciation by rate & term',
                  onPressed: onFutureValue,
                ),
                _ToolButton(
                  icon: Icons.percent,
                  title: 'APR Estimator',
                  subtitle: 'Include fees and points in APR',
                  onPressed: onApr,
                ),
                _ToolButton(
                  icon: Icons.compare_arrows,
                  title: 'Rent vs Buy',
                  subtitle: 'Compare renting vs buying costs',
                  onPressed: onRentVsBuy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // On mobile, use full width minus padding; on larger screens, use fixed width
    final buttonWidth = screenWidth < 600 ? double.infinity : 320.0;

    return SizedBox(
      width: buttonWidth,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsBreakEvenCard extends StatefulWidget {
  const _PointsBreakEvenCard({
    this.loanAmount,
    this.currentRate,
    this.termYears,
    this.currentPayment,
  });

  final double? loanAmount;
  final double? currentRate;
  final double? termYears;
  final double? currentPayment;

  @override
  State<_PointsBreakEvenCard> createState() => _PointsBreakEvenCardState();
}

class _PointsBreakEvenCardState extends State<_PointsBreakEvenCard> {
  final _pointsController = TextEditingController(text: '1.0');
  final _reducedRateController = TextEditingController();

  bool _loadingAdvice = false;
  String? _advice;

  @override
  void initState() {
    super.initState();
    _initReducedRate();
  }

  @override
  void didUpdateWidget(covariant _PointsBreakEvenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRate != widget.currentRate && widget.currentRate != null) {
      _initReducedRate();
    }
  }

  void _initReducedRate() {
    if (widget.currentRate != null && widget.currentRate! > 0.25) {
      _reducedRateController.text = (widget.currentRate! - 0.25).toStringAsFixed(3);
    } else {
      _reducedRateController.text = '6.250';
    }
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _reducedRateController.dispose();
    super.dispose();
  }

  double _calculateMonthlyPayment(double principal, double annualRatePercent, double years) {
    if (principal <= 0 || years <= 0) return 0.0;
    final r = annualRatePercent / 100 / 12;
    final n = years * 12;
    if (r == 0) return principal / n;
    return principal * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  Future<void> _fetchAdvice({
    required double pointsCost,
    required double monthlySavings,
    required int breakEvenMonths,
    required double newRate,
  }) async {
    setState(() => _loadingAdvice = true);
    try {
      final nlpService = Provider.of<NlpSettingsProvider?>(context, listen: false)?.calculatorService ??
          NLPCalculatorService();
      final result = await nlpService.generatePointsBreakEvenAdvice(
        loanAmount: widget.loanAmount ?? 0,
        originalRate: widget.currentRate ?? 0,
        newRate: newRate,
        pointsCost: pointsCost,
        monthlySavings: monthlySavings,
        breakEvenMonths: breakEvenMonths,
      );
      if (!mounted) return;
      setState(() => _advice = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _advice = 'Could not generate advice at this time.');
    } finally {
      if (mounted) setState(() => _loadingAdvice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = widget.loanAmount != null &&
        widget.currentRate != null &&
        widget.termYears != null;

    final points = double.tryParse(_pointsController.text) ?? 1.0;
    final newRate = double.tryParse(_reducedRateController.text) ??
        ((widget.currentRate ?? 6.5) - 0.25);

    final pointsCost = (widget.loanAmount ?? 0) * (points / 100);
    final currentP = widget.currentPayment ??
        _calculateMonthlyPayment(
          widget.loanAmount ?? 0,
          widget.currentRate ?? 0,
          widget.termYears ?? 30,
        );
    final newP = _calculateMonthlyPayment(
      widget.loanAmount ?? 0,
      newRate,
      widget.termYears ?? 30,
    );
    final monthlySavings = currentP - newP;
    final breakEvenMonths = (monthlySavings > 0 && pointsCost > 0)
        ? (pointsCost / monthlySavings).ceil()
        : 0;
    final breakEvenYears = (breakEvenMonths / 12).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rate Buy-Down & Break-Even Copilot',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Analyze the financial return of paying discount points to lower the mortgage interest rate.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (!hasData)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set loan amount, interest rate, and term on the Calculator to run break-even analysis.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pointsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Discount Points',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        helperText: '1.0% = 1 Point',
                      ),
                      onChanged: (_) => setState(() => _advice = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _reducedRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Bought-Down Rate',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        helperText: 'New note rate',
                      ),
                      onChanged: (_) => setState(() => _advice = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _ResultRow(
                      label: 'Upfront Points Cost',
                      value: CurrencyFormatter.formatCurrency(pointsCost),
                      icon: Icons.payments_outlined,
                    ),
                    const SizedBox(height: 8),
                    _ResultRow(
                      label: 'New Monthly P&I',
                      value: CurrencyFormatter.formatCurrency(newP),
                      icon: Icons.calendar_month,
                    ),
                    const SizedBox(height: 8),
                    _ResultRow(
                      label: 'Monthly Payment Savings',
                      value: CurrencyFormatter.formatCurrency(monthlySavings),
                      icon: Icons.trending_down,
                      valueColor: monthlySavings > 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _ResultRow(
                      label: 'Break-Even Period',
                      value: breakEvenMonths > 0
                          ? '$breakEvenMonths mos ($breakEvenYears yrs)'
                          : 'N/A',
                      icon: Icons.timelapse,
                      valueColor: (breakEvenMonths > 0 && breakEvenMonths <= 48)
                          ? Colors.green
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: (monthlySavings > 0 && pointsCost > 0 && !_loadingAdvice)
                    ? () => _fetchAdvice(
                          pointsCost: pointsCost,
                          monthlySavings: monthlySavings,
                          breakEvenMonths: breakEvenMonths,
                          newRate: newRate,
                        )
                    : null,
                icon: _loadingAdvice
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                label: const Text('✨ AI Break-Even Insights'),
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
          ],
        ),
      ),
    );
  }
}
