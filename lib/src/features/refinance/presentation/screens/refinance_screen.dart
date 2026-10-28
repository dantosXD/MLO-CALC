import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:provider/provider.dart';

import '../../domain/models/refinance.dart';
import '../../domain/services/refinance_analyzer.dart';

final NumberFormat _currency = NumberFormat.simpleCurrency();

String _money(double? v) =>
    (v == null || !v.isFinite) ? '—' : _currency.format(v);

class RefinanceScreen extends StatefulWidget {
  const RefinanceScreen({super.key});

  @override
  State<RefinanceScreen> createState() => _RefinanceScreenState();
}

class _RefinanceScreenState extends State<RefinanceScreen> {
  final _analyzer = const RefinanceAnalyzer();
  final _c = {
    for (final k in [
      'balance',
      'rate',
      'years',
      'mi',
      'new_rate',
      'new_term',
      'costs',
      'cash_out',
    ])
      k: TextEditingController(),
  };
  RefiProgram _program = RefiProgram.conventional;

  @override
  void initState() {
    super.initState();
    final p = Provider.of<CalculatorProvider?>(context, listen: false);
    String fmt(double? v) =>
        (v == null || !v.isFinite || v <= 0) ? '' : v.toString();
    _c['balance']!.text = fmt(p?.loanAmount);
    _c['rate']!.text = fmt(p?.interestRate);
    _c['years']!.text = fmt(p?.termYears);
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(String k) => double.tryParse(_c[k]!.text);

  Widget _field(String k, String label) => SizedBox(
    width: 160,
    child: TextField(
      key: Key('refi_$k'),
      controller: _c[k],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    ),
  );

  void _save(
    CalculatorProvider provider,
    RefinanceInputs i,
    RefinanceResult r,
  ) {
    final be = r.breakEvenMonths;
    provider.historyController.addQuoteEntry(
      type: CalculationEntryType.payment,
      loanAmount: i.currentBalance + i.cashOut,
      interestRate: i.newRate,
      termYears: i.newTermYears,
      payment: r.newPayment,
      notes:
          'Refi: ${i.program.label}, saves ${_money(r.monthlySavings)}/mo, '
          'break-even ${be == null ? 'never' : '${be.toStringAsFixed(1)} mo'}',
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved to history')));
  }

  @override
  Widget build(BuildContext context) {
    final balance = _v('balance');
    final rate = _v('rate');
    final years = _v('years');
    final newRate = _v('new_rate');
    final newTerm = _v('new_term');
    final valid =
        balance != null &&
        rate != null &&
        years != null &&
        newRate != null &&
        newTerm != null &&
        balance > 0 &&
        rate > 0 &&
        years > 0 &&
        newRate > 0 &&
        newTerm > 0 &&
        (_v('costs') ?? 0) >= 0 &&
        (_v('cash_out') ?? 0) >= 0;

    RefinanceInputs? inputs;
    RefinanceResult? r;
    if (valid) {
      inputs = RefinanceInputs(
        currentBalance: balance,
        currentRate: rate,
        currentRemainingYears: years,
        currentAnnualMiRate: _v('mi') ?? 0,
        newRate: newRate,
        newTermYears: newTerm,
        closingCosts: _v('costs') ?? 0,
        cashOut: _v('cash_out') ?? 0,
        program: _program,
      );
      r = _analyzer.analyze(inputs);
    }
    final be = r?.breakEvenMonths;
    final ntbMet = r?.ntbMet;
    final provider = Provider.of<CalculatorProvider?>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Refinance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _field('balance', 'Current Balance'),
              _field('rate', 'Current Rate %'),
              _field('years', 'Remaining (yrs)'),
              _field('mi', 'Annual MI %'),
              _field('new_rate', 'New Rate %'),
              _field('new_term', 'New Term (yrs)'),
              _field('costs', 'Closing Costs'),
              _field('cash_out', 'Cash Out'),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<RefiProgram>(
            segments: [
              for (final p in RefiProgram.values)
                ButtonSegment(value: p, label: Text(p.label)),
            ],
            selected: {_program},
            onSelectionChanged: (s) => setState(() => _program = s.first),
          ),
          const SizedBox(height: 16),
          Text('Current payment: ${_money(r?.currentPayment)}'),
          Text('New payment: ${_money(r?.newPayment)}'),
          Text('Monthly savings: ${_money(r?.monthlySavings)}'),
          Text(
            'Break-even: ${r == null
                ? '—'
                : be == null
                ? 'Never'
                : '${be.toStringAsFixed(1)} months'}',
          ),
          Text(
            'Lifetime interest change: ${_money(r?.lifetimeInterestChange)}',
          ),
          if (ntbMet != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Net tangible benefit: ${ntbMet ? 'Met' : 'Not met'} — ${r!.ntbReason}',
                style: ntbMet
                    ? null
                    : TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (inputs == null || provider == null)
                ? null
                : () => _save(provider, inputs!, r!),
            child: const Text('Save to History'),
          ),
        ],
      ),
    );
  }
}
