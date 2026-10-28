import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/services/second_lien_calculator.dart';

final NumberFormat _currency = NumberFormat.simpleCurrency();

String _money(double? v) =>
    (v == null || !v.isFinite) ? '—' : _currency.format(v);

String _pct(double? v) =>
    (v == null || !v.isFinite) ? '—' : '${v.toStringAsFixed(1)}%';

class SecondLienScreen extends StatelessWidget {
  const SecondLienScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Second Lien'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Piggyback'),
            Tab(text: 'HELOC'),
          ],
        ),
      ),
      body: const TabBarView(children: [_PiggybackTab(), _HelocTab()]),
    ),
  );
}

mixin _Fields<T extends StatefulWidget> on State<T> {
  final Map<String, TextEditingController> c = {};

  void init(List<String> keys, {Map<String, String> defaults = const {}}) {
    for (final k in keys) {
      c[k] = TextEditingController(text: defaults[k] ?? '');
    }
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  double? v(String k) => double.tryParse(c[k]!.text);

  Widget field(String k, String label) => SizedBox(
    width: 160,
    child: TextField(
      key: Key(k),
      controller: c[k],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    ),
  );
}

class _PiggybackTab extends StatefulWidget {
  const _PiggybackTab();

  @override
  State<_PiggybackTab> createState() => _PiggybackTabState();
}

class _PiggybackTabState extends State<_PiggybackTab>
    with _Fields, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    init(
      [
        'sl_price',
        'sl_first_ltv',
        'sl_second_ltv',
        'sl_first_rate',
        'sl_second_rate',
        'sl_term',
        'sl_second_term',
        'sl_mi',
      ],
      defaults: {'sl_first_ltv': '80', 'sl_second_ltv': '10', 'sl_term': '30'},
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final price = v('sl_price');
    final f = v('sl_first_ltv');
    final s = v('sl_second_ltv');
    final fr = v('sl_first_rate');
    final sr = v('sl_second_rate');
    final t = v('sl_term');
    final st = v('sl_second_term');
    final mi = v('sl_mi') ?? 0;
    final ok =
        [price, f, s, fr, sr, t, st].every((x) => x != null && x > 0) &&
        mi >= 0;
    final r = ok
        ? const SecondLienCalculator().piggyback(
            price: price!,
            firstLtv: f!,
            secondLtv: s!,
            firstRate: fr!,
            secondRate: sr!,
            termYears: t!,
            secondTermYears: st!,
            singleLoanMiAnnualPercent: mi,
          )
        : null;
    final diff = r?.monthlyDifference;
    final note = diff == null || !diff.isFinite
        ? ''
        : diff >= 0
        ? ' (piggyback cheaper)'
        : ' (single loan cheaper)';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            field('sl_price', 'Price'),
            field('sl_first_ltv', 'First LTV %'),
            field('sl_second_ltv', 'Second LTV %'),
            field('sl_first_rate', 'First Rate %'),
            field('sl_second_rate', 'Second Rate %'),
            field('sl_term', 'Term (yrs)'),
            field('sl_second_term', 'Second Term (yrs)'),
            field('sl_mi', 'Single-loan MI %/yr'),
          ],
        ),
        const SizedBox(height: 16),
        Text('First loan: ${_money(r?.firstLoan)}'),
        Text('Second loan: ${_money(r?.secondLoan)}'),
        Text('First payment: ${_money(r?.firstPayment)}'),
        Text('Second payment: ${_money(r?.secondPayment)}'),
        Text('Combined payment: ${_money(r?.combinedPayment)}'),
        Text('Single loan + MI payment: ${_money(r?.singleLoanPaymentWithMi)}'),
        Text('Monthly difference: ${_money(diff)}$note'),
      ],
    );
  }
}

class _HelocTab extends StatefulWidget {
  const _HelocTab();

  @override
  State<_HelocTab> createState() => _HelocTabState();
}

class _HelocTabState extends State<_HelocTab>
    with _Fields, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    init(
      ['hl_value', 'hl_first', 'hl_cltv', 'hl_draw', 'hl_rate', 'hl_repay'],
      defaults: {'hl_cltv': '85'},
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final value = v('hl_value');
    final first = v('hl_first');
    final cltv = v('hl_cltv');
    final draw = v('hl_draw');
    final rate = v('hl_rate');
    final repay = v('hl_repay');
    final ok =
        value != null &&
        first != null &&
        cltv != null &&
        draw != null &&
        rate != null &&
        repay != null &&
        value > 0 &&
        first >= 0 &&
        cltv > 0 &&
        draw >= 0 &&
        rate > 0 &&
        repay > 0;
    final r = ok
        ? const SecondLienCalculator().heloc(
            homeValue: value,
            firstBalance: first,
            maxCltv: cltv,
            drawAmount: draw,
            rate: rate,
            repayYears: repay,
          )
        : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            field('hl_value', 'Home Value'),
            field('hl_first', 'First Balance'),
            field('hl_cltv', 'Max CLTV %'),
            field('hl_draw', 'Draw Amount'),
            field('hl_rate', 'Rate %'),
            field('hl_repay', 'Repay (yrs)'),
          ],
        ),
        const SizedBox(height: 16),
        Text('Max line: ${_money(r?.maxLine)}'),
        Text('CLTV: ${_pct(r?.cltv)}'),
        Text('Interest-only payment: ${_money(r?.interestOnlyPayment)}'),
        Text('Fully amortizing payment: ${_money(r?.fullyAmortizingPayment)}'),
        if (r != null && draw! > r.maxLine)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Draw exceeds available line',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
