import 'package:flutter/material.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/qualification/domain/services/affordability_solver.dart';
import 'package:provider/provider.dart';

/// "Max price for a target payment" card (reverse affordability).
class MaxPriceCard extends StatefulWidget {
  const MaxPriceCard({super.key});

  @override
  State<MaxPriceCard> createState() => _MaxPriceCardState();
}

class _MaxPriceCardState extends State<MaxPriceCard> {
  final _c = <String, TextEditingController>{
    for (final k in [
      'Target',
      'Rate',
      'Term',
      'Down',
      'Tax',
      'Ins',
      'Hoa',
      'Mi',
    ])
      k: TextEditingController(),
  };
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final p = Provider.of<CalculatorProvider?>(context, listen: false);
    if (p?.interestRate != null) _c['Rate']!.text = '${p!.interestRate}';
    if (p?.defaultPropertyTaxRate != null) {
      _c['Tax']!.text = '${p!.defaultPropertyTaxRate}';
    }
    if (p?.defaultInsuranceRate != null) {
      _c['Ins']!.text = '${p!.defaultInsuranceRate}';
    }
    if (p?.termYears != null) {
      _c['Term']!.text = p!.termYears!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(String k) => double.tryParse(_c[k]!.text.trim()) ?? 0;

  AffordabilityResult? get _result {
    final r = const AffordabilitySolver().maxPrice(
      targetPiti: _v('Target'),
      rate: _v('Rate'),
      termYears: _v('Term'),
      downPaymentPercent: _v('Down'),
      taxRatePercent: _v('Tax'),
      insuranceRatePercent: _v('Ins'),
      hoaMonthly: _v('Hoa'),
      miAnnualPercent: _v('Mi'),
    );
    if (r == null || !r.price.isFinite || r.price <= 0) return null;
    return r;
  }

  static String _money(double? v) => v == null || !v.isFinite
      ? '—'
      : '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

  Widget _field(String k, String label) => SizedBox(
    width: 150,
    child: TextField(
      key: Key('maxPrice$k'),
      controller: _c[k],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (_) => setState(() {}),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalculatorProvider?>(context, listen: false);
    final r = _result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Max price for a target payment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _field('Target', 'Target payment (\$/mo)'),
                _field('Rate', 'Rate (%)'),
                _field('Term', 'Term (years)'),
                _field('Down', 'Down payment (%)'),
                _field('Tax', 'Property tax (%/yr)'),
                _field('Ins', 'Insurance (%/yr)'),
                _field('Hoa', 'HOA (\$/mo)'),
                _field('Mi', 'MI (%/yr)'),
              ],
            ),
            const SizedBox(height: 12),
            Text('Max price: ${_money(r?.price)}'),
            Text('Loan amount: ${_money(r?.loanAmount)}'),
            Text('Principal & interest: ${_money(r?.principalAndInterest)}'),
            Text('Tax / insurance / MI: ${_money(r?.monthlyTaxInsMi)}'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: r == null || provider == null
                  ? null
                  : () {
                      final tax = _v('Tax'), ins = _v('Ins');
                      provider.setInterestRate(value: _v('Rate'));
                      provider.setTermYears(value: _v('Term'));
                      provider.setPrice(value: r.price);
                      provider.setDownPayment(value: _v('Down'));
                      // Annual dollars, so calculator PITI matches the target.
                      provider.setPropertyTax(value: r.price * tax / 100);
                      provider.setHomeInsurance(value: r.price * ins / 100);
                      provider.setMortgageInsurance(
                        value: r.loanAmount * _v('Mi') / 100,
                      );
                      provider.setMonthlyExpenses(value: _v('Hoa'));
                    },
              child: const Text('Use this price'),
            ),
          ],
        ),
      ),
    );
  }
}
