import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:provider/provider.dart';

import '../../domain/models/rent_vs_buy_calculation.dart';

import '../../domain/services/rent_vs_buy_calculator.dart';

final NumberFormat _currency = NumberFormat.simpleCurrency();

class RentVsBuyScreen extends StatefulWidget {
  const RentVsBuyScreen({super.key});

  @override
  State<RentVsBuyScreen> createState() => _RentVsBuyScreenState();
}

class _RentVsBuyScreenState extends State<RentVsBuyScreen> {
  final _calculator = const RentVsBuyCalculator();

  // Input Controllers
  final _homePriceController = TextEditingController(text: '400000');
  final _downPaymentController = TextEditingController(text: '20');
  final _interestRateController = TextEditingController(text: '6.5');
  final _termController = TextEditingController(text: '30');
  final _propertyTaxController = TextEditingController(text: '1.2');
  final _homeInsuranceController = TextEditingController(text: '1800');
  final _hoaController = TextEditingController(text: '0');
  final _maintenanceController = TextEditingController(text: '1');
  final _closingCostsController = TextEditingController(text: '3');
  final _pmiRateController = TextEditingController(text: '0.5');
  final _monthlyRentController = TextEditingController(text: '2000');
  final _rentIncreaseController = TextEditingController(text: '3');
  final _rentersInsuranceController = TextEditingController(text: '25');
  final _appreciationController = TextEditingController(text: '3');
  final _investmentReturnController = TextEditingController(text: '7');
  final _taxRateController = TextEditingController(text: '22');

  int _analysisYears = 10;
  RentVsBuyCalculation? _result;
  bool _showMethodology = false;

  // Cached FlSpot lists — updated only when _result changes.
  RentVsBuyCalculation? _cachedResult;
  List<FlSpot> _buyingSpots = const [];
  List<FlSpot> _rentingSpots = const [];

  @override
  void dispose() {
    _homePriceController.dispose();
    _downPaymentController.dispose();
    _interestRateController.dispose();
    _termController.dispose();
    _propertyTaxController.dispose();
    _homeInsuranceController.dispose();
    _hoaController.dispose();
    _maintenanceController.dispose();
    _closingCostsController.dispose();
    _pmiRateController.dispose();
    _monthlyRentController.dispose();
    _rentIncreaseController.dispose();
    _rentersInsuranceController.dispose();
    _appreciationController.dispose();
    _investmentReturnController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  void _calculate() {
    final inputs = RentVsBuyInputs(
      homePrice: double.tryParse(_homePriceController.text) ?? 400000,
      downPaymentPercent: double.tryParse(_downPaymentController.text) ?? 20,
      interestRate: double.tryParse(_interestRateController.text) ?? 6.5,
      termYears: double.tryParse(_termController.text) ?? 30,
      propertyTaxRate: double.tryParse(_propertyTaxController.text) ?? 1.2,
      homeInsuranceAnnual:
          double.tryParse(_homeInsuranceController.text) ?? 1800,
      hoaMonthly: double.tryParse(_hoaController.text) ?? 0,
      maintenancePercent: double.tryParse(_maintenanceController.text) ?? 1,
      closingCostsPercent: double.tryParse(_closingCostsController.text) ?? 3,
      pmiRate: double.tryParse(_pmiRateController.text) ?? 0.5,
      monthlyRent: double.tryParse(_monthlyRentController.text) ?? 2000,
      annualRentIncrease: double.tryParse(_rentIncreaseController.text) ?? 3,
      rentersInsuranceMonthly:
          double.tryParse(_rentersInsuranceController.text) ?? 25,
      homeAppreciationRate: double.tryParse(_appreciationController.text) ?? 3,
      investmentReturnRate:
          double.tryParse(_investmentReturnController.text) ?? 7,
      marginalTaxRate: double.tryParse(_taxRateController.text) ?? 22,
      analysisYears: _analysisYears,
    );

    setState(() {
      _result = _calculator.calculate(inputs);
    });
    _updateSpotCache(_result!);
  }

  void _updateSpotCache(RentVsBuyCalculation result) {
    if (identical(result, _cachedResult)) return;
    _cachedResult = result;
    _buyingSpots = result.projections
        .map((p) => FlSpot(p.year.toDouble(), p.netWorthBuying))
        .toList();
    _rentingSpots = result.projections
        .map((p) => FlSpot(p.year.toDouble(), p.netWorthRenting))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent vs Buy Analysis'),
        actions: [
          IconButton(
            icon: Icon(
              _showMethodology ? Icons.visibility_off : Icons.visibility,
            ),
            tooltip: _showMethodology ? 'Hide Methodology' : 'Show Methodology',
            onPressed: () =>
                setState(() => _showMethodology = !_showMethodology),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input Sections
          _buildInputSection(),

          const SizedBox(height: 16),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate'),
            ),
          ),

          // Results
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildResultsSummary(_result!),
            const SizedBox(height: 16),
            _AiRentVsBuyMemoCard(
              homePrice: double.tryParse(_homePriceController.text) ?? 400000,
              monthlyRent: double.tryParse(_monthlyRentController.text) ?? 2000,
              breakEvenYear: (_result!.breakEvenMonths / 12).ceil(),
              netWealthDifference: _result!.projections.isNotEmpty
                  ? (_result!.projections.last.netWorthBuying -
                      _result!.projections.last.netWorthRenting)
                  : (_result!.monthlySavings * _analysisYears * 12),
              analysisYears: _analysisYears,
            ),
            const SizedBox(height: 16),
            _buildCostComparison(_result!),
            const SizedBox(height: 16),
            _buildProjectionsChart(_result!),
            if (_showMethodology) ...[
              const SizedBox(height: 16),
              _buildMethodologySection(_result!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('Inputs'),
        subtitle: const Text('Tap to expand/collapse'),
        initiallyExpanded: _result == null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Purchase Details
                _SectionLabel('Purchase Details'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _homePriceController,
                        label: 'Home Price',
                        prefix: '\$',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InputField(
                        controller: _downPaymentController,
                        label: 'Down Payment',
                        suffix: '%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _interestRateController,
                        label: 'Interest Rate',
                        suffix: '%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InputField(
                        controller: _termController,
                        label: 'Term',
                        suffix: 'yrs',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _SectionLabel('Buying Costs'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _propertyTaxController,
                        label: 'Property Tax Rate',
                        suffix: '%/yr',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InputField(
                        controller: _homeInsuranceController,
                        label: 'Home Insurance',
                        prefix: '\$',
                        suffix: '/yr',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _hoaController,
                        label: 'HOA',
                        prefix: '\$',
                        suffix: '/mo',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InputField(
                        controller: _maintenanceController,
                        label: 'Maintenance',
                        suffix: '%/yr',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _closingCostsController,
                        label: 'Closing Costs',
                        suffix: '%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InputField(
                        controller: _pmiRateController,
                        label: 'PMI Rate',
                        suffix: '%/yr',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _SectionLabel('Renting Costs'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _monthlyRentController,
                        label: 'Monthly Rent',
                        prefix: '\$',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InputField(
                        controller: _rentIncreaseController,
                        label: 'Annual Increase',
                        suffix: '%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _rentersInsuranceController,
                  label: 'Renters Insurance',
                  prefix: '\$',
                  suffix: '/mo',
                ),

                const SizedBox(height: 16),
                _SectionLabel('Economic Assumptions'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _appreciationController,
                        label: 'Home Appreciation',
                        suffix: '%/yr',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InputField(
                        controller: _investmentReturnController,
                        label: 'Investment Return',
                        suffix: '%/yr',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _taxRateController,
                        label: 'Tax Bracket',
                        suffix: '%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        // ignore: deprecated_member_use
                        value: _analysisYears,
                        decoration: const InputDecoration(
                          labelText: 'Analysis Period',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [5, 7, 10, 15, 20, 30]
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text('$y years'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _analysisYears = v ?? 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary(RentVsBuyCalculation result) {
    final theme = Theme.of(context);
    final isBuyingBetter = result.buyingIsBetter;

    return Card(
      color: isBuyingBetter
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.tertiary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              isBuyingBetter ? Icons.home : Icons.apartment,
              size: 48,
              color: isBuyingBetter
                  ? theme.colorScheme.primary
                  : theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 8),
            Text(
              isBuyingBetter ? 'Buying is Better' : 'Renting May Be Better',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isBuyingBetter
                    ? theme.colorScheme.primary
                    : theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBuyingBetter
                  ? 'You save ${_currency.format(result.monthlySavings.abs())}/month by buying'
                  : 'You save ${_currency.format(result.monthlySavings.abs())}/month by renting',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Break-even: ${_formatBreakEven(result.breakEvenMonths)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatBreakEven(int months) {
    if (months <= 0) return 'Immediately';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (years == 0) return '$remainingMonths months';
    if (remainingMonths == 0) return '$years years';
    return '$years years, $remainingMonths months';
  }

  Widget _buildCostComparison(RentVsBuyCalculation result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Cost Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buying Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUYING',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CostRow('P&I', result.buyingCosts.principalAndInterest),
                      _CostRow('Property Tax', result.buyingCosts.propertyTax),
                      _CostRow('Insurance', result.buyingCosts.homeInsurance),
                      if (result.buyingCosts.pmi > 0)
                        _CostRow('PMI', result.buyingCosts.pmi),
                      if (result.buyingCosts.hoa > 0)
                        _CostRow('HOA', result.buyingCosts.hoa),
                      _CostRow('Maintenance', result.buyingCosts.maintenance),
                      _CostRow(
                        'Tax Benefit',
                        -result.buyingCosts.taxBenefit,
                        isCredit: true,
                      ),
                      const Divider(),
                      _CostRow('Total', result.buyingCosts.total, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Renting Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RENTING',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CostRow('Rent', result.rentingCosts.rent),
                      _CostRow(
                        'Insurance',
                        result.rentingCosts.rentersInsurance,
                      ),
                      const Divider(),
                      _CostRow(
                        'Total',
                        result.rentingCosts.total,
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '* Opportunity cost of ${_currency.format(result.rentingCosts.opportunityCost)}/mo '
                        'not included in total',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionsChart(RentVsBuyCalculation result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Worth Projection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Compares wealth accumulation over time',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.formatCompactCurrency(
                              value,
                              maxDigits: 7,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('Yr ${value.toInt()}');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Buying Line
                    LineChartBarData(
                      spots: _buyingSpots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    // Renting Line
                    LineChartBarData(
                      spots: _rentingSpots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.tertiary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Buying',
                ),
                const SizedBox(width: 24),
                _LegendItem(
                  color: Theme.of(context).colorScheme.tertiary,
                  label: 'Renting',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodologySection(RentVsBuyCalculation result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science_outlined),
                const SizedBox(width: 8),
                Text(
                  'Calculation Methodology',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Full transparency into how each value was calculated',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            ...result.breakdown.steps.map(
              (step) => _MethodologyStep(step: step),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? prefix;
  final String? suffix;

  const _InputField({
    required this.controller,
    required this.label,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final bool isCredit;

  const _CostRow(
    this.label,
    this.value, {
    this.isBold = false,
    this.isCredit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            isCredit
                ? '-${_currency.format(value.abs())}'
                : _currency.format(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              color: isCredit ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _MethodologyStep extends StatelessWidget {
  final CalculationStep step;

  const _MethodologyStep({required this.step});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(child: Text(step.name)),
          Text(
            _currency.format(step.result),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Formula
              Row(
                children: [
                  const Icon(Icons.functions, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.formula,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Inputs
              ...step.inputs.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Row(
                    children: [
                      Text('${e.key}: '),
                      Text(
                        e.value is double
                            ? (e.value as double).toStringAsFixed(4)
                            : e.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Explanation
              Text(
                step.explanation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiRentVsBuyMemoCard extends StatefulWidget {
  const _AiRentVsBuyMemoCard({
    required this.homePrice,
    required this.monthlyRent,
    required this.breakEvenYear,
    required this.netWealthDifference,
    required this.analysisYears,
  });

  final double homePrice;
  final double monthlyRent;
  final int breakEvenYear;
  final double netWealthDifference;
  final int analysisYears;

  @override
  State<_AiRentVsBuyMemoCard> createState() => _AiRentVsBuyMemoCardState();
}

class _AiRentVsBuyMemoCardState extends State<_AiRentVsBuyMemoCard> {
  bool _loading = false;
  String? _memo;
  bool _expanded = false;

  Future<void> _fetchMemo() async {
    setState(() {
      _loading = true;
      _expanded = true;
    });
    try {
      final nlpService = Provider.of<NlpSettingsProvider?>(context, listen: false)?.calculatorService ??
          NLPCalculatorService();
      final result = await nlpService.generateRentVsBuyMemo(
        homePrice: widget.homePrice,
        monthlyRent: widget.monthlyRent,
        breakEvenYear: widget.breakEvenYear,
        netWealthDifference: widget.netWealthDifference,
        analysisYears: widget.analysisYears,
      );
      if (!mounted) return;
      setState(() => _memo = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _memo = 'Could not load memo at this time.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<NlpSettingsProvider?>(context);
    final hasGemini = settings?.hasKey ?? false;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  hasGemini ? Icons.auto_awesome : Icons.article_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasGemini
                        ? 'Client Decision Memo (Gemini AI)'
                        : 'Client Decision Memo',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (!_expanded)
                  TextButton.icon(
                    onPressed: _loading ? null : _fetchMemo,
                    icon: _loading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.summarize_outlined, size: 16),
                    label: const Text('Generate Memo'),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_memo != null)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          tooltip: 'Copy Memo',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _memo!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Memo copied to clipboard')),
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16),
                        tooltip: 'Refresh Memo',
                        onPressed: _loading ? null : _fetchMemo,
                      ),
                    ],
                  ),
              ],
            ),
            if (_expanded) ...[
              const Divider(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_memo != null)
                Text(
                  _memo!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
