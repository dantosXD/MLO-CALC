import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/math/government_fees.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/loan_programs/domain/services/program_cost_service.dart';
import 'package:loan_ranger/src/features/options/application/rate_sheet_store.dart';
import 'package:loan_ranger/src/features/options/domain/models/loan_option.dart';
import 'package:loan_ranger/src/features/options/domain/models/member_profile.dart';
import 'package:loan_ranger/src/features/options/domain/services/options_builder.dart';
import 'package:loan_ranger/src/features/options/presentation/widgets/option_card.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/brand_header.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/options_report_service.dart';
import 'package:loan_ranger/src/features/settings/domain/providers/mlo_profile_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

const _rateIds = {
  'conventional_30': 'Conventional 30',
  'conventional_15': 'Conventional 15',
  'fha_30': 'FHA 30',
  'va_30': 'VA 30',
  'usda_30': 'USDA 30',
};

const _memberKeys = [
  'name',
  'price',
  'cash',
  'income',
  'debt',
  'tax',
  'ins',
  'hoa',
];

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key, this.rateStore});

  final RateSheetStore? rateStore;

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  late final Map<String, TextEditingController> _c = {
    for (final k in [..._memberKeys, ..._rateIds.keys])
      k: TextEditingController(),
  };
  late final RateSheetStore? _store =
      widget.rateStore ??
      (serviceLocator.isRegistered<PreferenceStore>()
          ? RateSheetStore(serviceLocator<PreferenceStore>())
          : null);
  bool _veteran = false, _vaSubsequent = false, _vaExempt = false;
  bool _rural = false;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    final saved = _store?.load().ratesByProgramId ?? const {};
    for (final id in _rateIds.keys) {
      if (saved[id] != null) _c[id]!.text = saved[id].toString();
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(String k) => double.tryParse(_c[k]!.text) ?? 0;

  RateSheet get _rates => RateSheet({
    for (final id in _rateIds.keys)
      if ((double.tryParse(_c[id]!.text) ?? 0) > 0)
        id: double.parse(_c[id]!.text),
  });

  MemberProfile get _member => MemberProfile(
    price: _v('price'),
    cashAvailable: _v('cash'),
    annualIncome: _v('income'),
    monthlyDebt: _v('debt'),
    annualTax: _v('tax'),
    annualInsurance: _v('ins'),
    hoaMonthly: _v('hoa'),
    isVeteran: _veteran,
    ruralEligible: _rural,
    eligibility: BorrowerEligibility(
      vaUse: _vaSubsequent ? VaUse.subsequent : VaUse.first,
      vaExempt: _vaExempt,
    ),
  );

  Widget _field(String k, String label, {bool rate = false}) => SizedBox(
    width: 170,
    child: TextField(
      key: Key(rate ? 'opt_rate_$k' : 'opt_$k'),
      controller: _c[k],
      keyboardType: k == 'name'
          ? TextInputType.name
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) {
        if (rate) _store?.save(_rates);
        setState(() {});
      },
    ),
  );

  Widget _flag(String label, bool v, ValueChanged<bool> f) => FilterChip(
    label: Text(label),
    selected: v,
    onSelected: (b) => setState(() => f(b)),
  );

  Future<void> _pdf(List<LoanOption> chosen) async {
    final brand =
        context.read<MloProfileProvider?>()?.toBrandInfo() ??
        const BrandInfo(
          name: '',
          nmls: '',
          company: '',
          phone: '',
          email: '',
          applyUrl: '',
          disclaimer: '',
          accentColor: 0xFF1565C0,
        );
    final bytes = await OptionsReportService.generate(
      options: chosen,
      member: _member,
      brand: brand,
      memberName: _c['name']!.text,
    );
    if (!mounted) return;
    await Printing.sharePdf(bytes: bytes, filename: 'loan-options.pdf');
  }

  double _term(LoanOption o) => o.programId == 'conventional_15' ? 15 : 30;

  void _save(CalculatorProvider p, List<LoanOption> chosen) {
    final m = _member;
    for (final o in chosen) {
      p.historyController.addQuoteEntry(
        type: CalculationEntryType.payment,
        loanAmount: o.loanAmount,
        interestRate: o.rate,
        termYears: _term(o),
        payment: o.principalAndInterest,
        propertyTax: m.annualTax,
        homeInsurance: m.annualInsurance,
        mortgageInsurance: o.monthlyMi * 12,
        monthlyExpenses: m.hoaMonthly,
        price: m.price,
        downPayment: o.downPayment,
        notes: o.title,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${chosen.length} to history')),
    );
  }

  void _open(CalculatorProvider p, LoanOption o) {
    final m = _member;
    p.setInterestRate(value: o.rate);
    p.setTermYears(value: _term(o));
    p.setPrice(value: m.price);
    p.setDownPayment(value: o.downPayment);
    p.setLoanAmount(value: o.loanAmount);
    p.setPropertyTax(value: m.annualTax);
    p.setHomeInsurance(value: m.annualInsurance);
    p.setMortgageInsurance(value: o.monthlyMi * 12);
    p.setMonthlyExpenses(value: m.hoaMonthly);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final calc = Provider.of<CalculatorProvider?>(context, listen: false);
    final member = _member;
    final options = member.price > 0
        ? const OptionsBuilder().build(member, _rates)
        : const <LoanOption>[];
    _selected.retainAll(options.map((o) => o.id));
    final chosen = options.where((o) => _selected.contains(o.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Options Builder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _field('name', 'Member name (optional)'),
              _field('price', 'Price'),
              _field('cash', 'Cash available'),
              _field('income', 'Annual income'),
              _field('debt', 'Monthly debts'),
              _field('tax', 'Annual tax'),
              _field('ins', 'Annual insurance'),
              _field('hoa', 'HOA / month'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _flag('Veteran', _veteran, (b) => _veteran = b),
              if (_veteran) ...[
                _flag(
                  'VA subsequent use',
                  _vaSubsequent,
                  (b) => _vaSubsequent = b,
                ),
                _flag('VA exempt', _vaExempt, (b) => _vaExempt = b),
              ],
              _flag('Rural eligible', _rural, (b) => _rural = b),
            ],
          ),
          const Divider(height: 32),
          Text(
            "Today's rates (%)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final e in _rateIds.entries)
                _field(e.key, e.value, rate: true),
            ],
          ),
          const Divider(height: 32),
          if (options.isEmpty)
            const Text('—')
          else
            for (final o in options)
              OptionCard(
                option: o,
                selected: _selected.contains(o.id),
                onSelected: (b) => setState(
                  () => b ? _selected.add(o.id) : _selected.remove(o.id),
                ),
                onOpenInCalculator: calc == null ? null : () => _open(calc, o),
              ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              FilledButton(
                key: const Key('opt_pdf'),
                onPressed: chosen.length >= 2 && chosen.length <= 4
                    ? () => _pdf(chosen)
                    : null,
                child: const Text('Options sheet PDF'),
              ),
              FilledButton(
                key: const Key('opt_save'),
                onPressed: chosen.isNotEmpty && calc != null
                    ? () => _save(calc, chosen)
                    : null,
                child: const Text('Save to History'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
