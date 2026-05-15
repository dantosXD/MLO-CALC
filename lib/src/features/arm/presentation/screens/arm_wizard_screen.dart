import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:provider/provider.dart';

import '../../application/providers/arm_wizard_provider.dart';
import '../../domain/models/arm_scenario.dart';
import '../../domain/services/arm_calculator_service.dart';
import '../../domain/services/arm_preset_service.dart';

final NumberFormat _currency = NumberFormat.simpleCurrency();

class ArmWizardScreen extends StatefulWidget {
  const ArmWizardScreen({
    super.key,
    required this.calculator,
    required this.presetStorage,
  });

  final ArmCalculatorService calculator;
  final ArmPresetStorage presetStorage;

  @override
  State<ArmWizardScreen> createState() => _ArmWizardScreenState();
}

class _ArmWizardScreenState extends State<ArmWizardScreen> {
  late final ArmWizardProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ArmWizardProvider(
      calculator: widget.calculator,
      presetStorage: widget.presetStorage,
    );
    unawaited(_provider.loadPreset());
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: const _ArmWizardView(),
    );
  }
}

class _ArmWizardView extends StatefulWidget {
  const _ArmWizardView();

  @override
  State<_ArmWizardView> createState() => _ArmWizardViewState();
}

class _ArmWizardViewState extends State<_ArmWizardView> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ARM Wizard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save preset',
            onPressed: () {
              context.read<ArmWizardProvider>().savePreset();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('ARM preset saved')));
            },
          ),
        ],
      ),
      body: Consumer<ArmWizardProvider>(
        builder: (context, provider, _) {
          final scenario = provider.scenario;
          final steps = _buildSteps(context, scenario);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              SizedBox(
                height: 560,
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < steps.length - 1) {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep--;
                      });
                    }
                  },
                  controlsBuilder: (_, details) {
                    return Row(
                      children: [
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(
                            _currentStep == steps.length - 1 ? 'Done' : 'Next',
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                      ],
                    );
                  },
                  steps: steps,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_graph),
                  label: const Text('Generate schedule'),
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          await provider.calculate();
                        },
                ),
              ),
              const SizedBox(height: 24),
              if (provider.result != null)
                _ArmResultCard(result: provider.result!, theme: theme),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  List<Step> _buildSteps(BuildContext context, ArmScenario scenario) {
    return [
      Step(
        title: const Text('Loan Basics'),
        content: Column(
          children: [
            _NumberField(
              label: 'Loan Amount',
              suffix: '\$',
              value: scenario.loanAmount,
              onChanged: (value) => _updateScenario(
                context,
                scenario.copyWith(loanAmount: value),
              ),
            ),
            _NumberField(
              label: 'Term (years)',
              value: scenario.termYears,
              onChanged: (value) =>
                  _updateScenario(context, scenario.copyWith(termYears: value)),
            ),
            _NumberField(
              label: 'Initial Rate (%)',
              value: scenario.initialRate,
              onChanged: (value) => _updateScenario(
                context,
                scenario.copyWith(initialRate: value),
              ),
            ),
          ],
        ),
        isActive: _currentStep == 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Adjustment Settings'),
        content: Column(
          children: [
            _NumberField(
              label: 'Initial Fixed Period (years)',
              value: scenario.initialFixedYears,
              onChanged: (value) => _updateScenario(
                context,
                scenario.copyWith(initialFixedYears: value),
              ),
            ),
            _NumberField(
              label: 'Adjustment Frequency (years)',
              value: scenario.adjustmentFrequencyYears,
              onChanged: (value) => _updateScenario(
                context,
                scenario.copyWith(adjustmentFrequencyYears: value),
              ),
            ),
            _NumberField(
              label: 'Rate Change Per Adjustment (%)',
              value: scenario.rateChangePerAdjustment,
              onChanged: (value) => _updateScenario(
                context,
                scenario.copyWith(rateChangePerAdjustment: value),
              ),
            ),
          ],
        ),
        isActive: _currentStep == 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Caps'),
        content: Column(
          children: [
            _NumberField(
              label: 'Periodic Cap (%)',
              value: scenario.periodicCap,
              onChanged: (value) => _updateScenario(
                context,
                scenario.copyWith(periodicCap: value),
              ),
            ),
            _NumberField(
              label: 'Lifetime Cap (%)',
              value: scenario.lifetimeCap,
              onChanged: (value) => _updateScenario(
                context,
                scenario.copyWith(lifetimeCap: value),
              ),
            ),
            _NumberField(
              label: 'Lifetime Floor (%)',
              value: scenario.lifetimeFloor,
              onChanged: (value) => _updateScenario(
                context,
                scenario.copyWith(lifetimeFloor: value),
              ),
            ),
          ],
        ),
        isActive: _currentStep == 2,
        state: StepState.indexed,
      ),
    ];
  }

  void _updateScenario(BuildContext context, ArmScenario scenario) {
    context.read<ArmWizardProvider>().updateScenario(scenario);
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? suffix;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Format with 2 decimals for display
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update text if the external value significantly differs from current input
    // This prevents overwriting user input (e.g. "5.") with formatted value ("5.00")
    final currentInput = double.tryParse(_controller.text) ?? 0.0;
    if ((widget.value - currentInput).abs() > 0.001) {
      // External update (e.g. preset loaded)
      final newValueFormatted = _format(widget.value);
      if (_controller.text != newValueFormatted) {
        _controller.text = newValueFormatted;
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) {
    // If integer, show as integer to look cleaner, else 2 decimals
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          suffixText: widget.suffix,
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) {
          if (text.isEmpty) return;
          final parsed = double.tryParse(text);
          if (parsed != null) {
            widget.onChanged(parsed);
          }
        },
      ),
    );
  }
}

class _ArmResultCard extends StatelessWidget {
  const _ArmResultCard({required this.result, required this.theme});

  final ArmScheduleResult result;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ARM Schedule', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ResultChip(
                  label: 'Total Paid',
                  value: _currency.format(result.totalPaid),
                ),
                _ResultChip(
                  label: 'Total Interest',
                  value: _currency.format(result.totalInterest),
                ),
                _ResultChip(
                  label: 'Adjustments',
                  value: result.periods.length.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...result.periods.map(
              (period) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Months ${period.startMonth}-${period.endMonth}',
                  style: theme.textTheme.bodyLarge,
                ),
                subtitle: Text(
                  'Rate ${CurrencyFormatter.formatPercent(period.rate, decimals: 3)} • Payment ${_currency.format(period.monthlyPayment)}',
                ),
                trailing: Text(
                  'Balance ${_currency.format(period.endingBalance)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
