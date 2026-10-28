import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:provider/provider.dart';

import '../../domain/models/buydown.dart';
import '../../domain/services/buydown_calculator.dart';

final NumberFormat _currency = NumberFormat.simpleCurrency();

String _money(double? v) =>
    (v == null || !v.isFinite) ? '—' : _currency.format(v);

class BuydownScreen extends StatefulWidget {
  const BuydownScreen({super.key});

  @override
  State<BuydownScreen> createState() => _BuydownScreenState();
}

class _BuydownScreenState extends State<BuydownScreen> {
  final _calculator = const BuydownCalculator();
  final _loan = TextEditingController();
  final _rate = TextEditingController();
  final _term = TextEditingController();
  BuydownType _type = BuydownType.twoOne;

  @override
  void initState() {
    super.initState();
    final p = Provider.of<CalculatorProvider?>(context, listen: false);
    String fmt(double? v) =>
        (v == null || !v.isFinite || v <= 0) ? '' : v.toString();
    _loan.text = fmt(p?.loanAmount);
    _rate.text = fmt(p?.interestRate);
    _term.text = fmt(p?.termYears);
  }

  @override
  void dispose() {
    _loan.dispose();
    _rate.dispose();
    _term.dispose();
    super.dispose();
  }

  Widget _field(String key, String label, TextEditingController c) => Expanded(
    child: TextField(
      key: Key(key),
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final loan = double.tryParse(_loan.text);
    final rate = double.tryParse(_rate.text);
    final term = double.tryParse(_term.text);
    final valid =
        loan != null &&
        rate != null &&
        term != null &&
        loan > 0 &&
        rate > 0 &&
        term > 0;

    BuydownResult? result;
    String? error;
    if (valid) {
      try {
        result = _calculator.calculate(
          loanAmount: loan,
          noteRate: rate,
          termYears: term,
          type: _type,
        );
      } on ArgumentError {
        error = 'Buydown exceeds note rate';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Temporary Buydown')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _field('buydown_loan', 'Loan Amount', _loan),
              const SizedBox(width: 12),
              _field('buydown_rate', 'Note Rate %', _rate),
              const SizedBox(width: 12),
              _field('buydown_term', 'Term (yrs)', _term),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<BuydownType>(
            segments: [
              for (final t in BuydownType.values)
                ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          if (error != null)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else ...[
            Text('Note payment: ${_money(result?.notePayment)}'),
            const SizedBox(height: 8),
            DataTable(
              columns: const [
                DataColumn(label: Text('Year')),
                DataColumn(label: Text('Rate')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Subsidy/mo')),
              ],
              rows: [
                if (result == null)
                  const DataRow(
                    cells: [
                      DataCell(Text('—')),
                      DataCell(Text('—')),
                      DataCell(Text('—')),
                      DataCell(Text('—')),
                    ],
                  )
                else
                  for (final y in result.years)
                    DataRow(
                      cells: [
                        DataCell(Text('${y.year}')),
                        DataCell(Text('${y.rate.toStringAsFixed(3)}%')),
                        DataCell(Text(_money(y.payment))),
                        DataCell(Text(_money(y.monthlySubsidy))),
                      ],
                    ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Total subsidy'),
                trailing: Text(
                  _money(result?.totalSubsidy),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seller/builder credit needed: ${_money(result?.totalSubsidy)}',
            ),
          ],
        ],
      ),
    );
  }
}
