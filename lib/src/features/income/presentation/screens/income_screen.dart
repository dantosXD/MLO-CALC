import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:provider/provider.dart';

import '../../domain/models/income.dart';
import '../../domain/services/income_calculator.dart';

final NumberFormat _currency = NumberFormat.simpleCurrency();

String _money(double? v) =>
    (v == null || !v.isFinite) ? '—' : _currency.format(v);

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  static const _calc = IncomeCalculator();
  static const _seFields = [
    ('net', 'Net profit'),
    ('dep', 'Depreciation'),
    ('depl', 'Depletion'),
    ('home', 'Business use of home'),
    ('amort', 'Amortization/casualty'),
    ('nonrec', 'Nonrecurring income'),
  ];
  static final _keys = [
    'base',
    for (final y in ['p', 'r']) ...[
      for (final f in _seFields) 'se_${y}_${f.$1}',
    ],
    'var_prior',
    'var_recent',
    'var_ytd',
    'var_months',
    'rent',
    'pitia',
    'sl_balance',
    'sl_payment',
    'other_debt',
  ];
  final _c = {for (final k in _keys) k: TextEditingController()};
  StudentLoanAgency _agency = StudentLoanAgency.fannie;

  @override
  void initState() {
    super.initState();
    final d = Provider.of<CalculatorProvider?>(
      context,
      listen: false,
    )?.monthlyDebt;
    if (d != null && d.isFinite && d > 0) _c['other_debt']!.text = d.toString();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(String k) {
    final x = double.tryParse(_c[k]!.text);
    return (x != null && x.isFinite) ? x : 0;
  }

  Widget _field(String k, String label) => SizedBox(
    width: 160,
    child: TextField(
      key: Key('inc_$k'),
      controller: _c[k],
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    ),
  );

  Widget _seField(String y, (String, String) f, String yr) => TextField(
    key: Key('inc_se_${y}_${f.$1}'),
    controller: _c['se_${y}_${f.$1}'],
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    decoration: InputDecoration(
      labelText: '$yr: ${f.$2}',
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    onChanged: (_) => setState(() {}),
  );

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: children),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    ScheduleCYear year(String y) => ScheduleCYear(
      netProfit: _v('se_${y}_net'),
      depreciation: _v('se_${y}_dep'),
      depletion: _v('se_${y}_depl'),
      businessUseOfHome: _v('se_${y}_home'),
      amortization: _v('se_${y}_amort'),
      nonrecurring: _v('se_${y}_nonrec'),
    );
    final se = _calc.selfEmployedMonthly(
      priorYear: year('p'),
      recentYear: year('r'),
    );
    final variable = _calc.variableMonthly(
      priorYear: _v('var_prior'),
      recentYear: _v('var_recent'),
      ytd: _v('var_ytd'),
      ytdMonths: _v('var_months').round(),
    );
    final rental = _calc.rentalMonthly(
      grossMonthlyRent: _v('rent'),
      monthlyPitia: _v('pitia'),
    );
    final student = _calc.studentLoanMonthly(
      agency: _agency,
      balance: _v('sl_balance'),
      reportedPayment: _v('sl_payment'),
    );
    final income = _v('base') + se + variable + (rental > 0 ? rental : 0);
    final debts = student + (rental < 0 ? -rental : 0) + _v('other_debt');
    final provider = Provider.of<CalculatorProvider?>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Base income', [
            _field('base', 'Other / base monthly income'),
          ]),
          const SizedBox(height: 8),
          Text(
            'Self-employed (Schedule C, annual)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final f in _seFields)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: _seField('p', f, 'Prior')),
                  const SizedBox(width: 12),
                  Expanded(child: _seField('r', f, 'Recent')),
                ],
              ),
            ),
          Text('Self-employed monthly: ${_money(se)}'),
          const SizedBox(height: 16),
          _section('Variable (bonus / commission / overtime)', [
            _field('var_prior', 'Prior Yr Total'),
            _field('var_recent', 'Recent Yr Total'),
            _field('var_ytd', 'YTD Total'),
            _field('var_months', 'YTD Months'),
          ]),
          Text('Variable monthly: ${_money(variable)}'),
          const SizedBox(height: 16),
          _section('Rental', [
            _field('rent', 'Gross Monthly Rent'),
            _field('pitia', 'Monthly PITIA'),
          ]),
          Text('Net rental: ${_money(rental)}'),
          const SizedBox(height: 16),
          _section('Student loans', [
            DropdownButton<StudentLoanAgency>(
              key: const Key('inc_agency'),
              value: _agency,
              items: [
                for (final a in StudentLoanAgency.values)
                  DropdownMenuItem(value: a, child: Text(a.label)),
              ],
              onChanged: (a) => setState(() => _agency = a ?? _agency),
            ),
            _field('sl_balance', 'Balance'),
            _field('sl_payment', 'Reported Payment'),
          ]),
          Text('Student loan monthly: ${_money(student)}'),
          const SizedBox(height: 16),
          _section('Other', [_field('other_debt', 'Other Monthly Debts')]),
          const Divider(),
          Text('Total monthly income: ${_money(income)}'),
          Text('Total monthly debts: ${_money(debts)}'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: provider == null
                ? null
                : () {
                    provider.setAnnualIncome(value: income * 12);
                    provider.setMonthlyDebt(value: debts);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sent to Qualification')),
                    );
                  },
            child: const Text('Send to Qualification'),
          ),
        ],
      ),
    );
  }
}
