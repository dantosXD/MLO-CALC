import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/options/domain/models/loan_option.dart';
import 'package:loan_ranger/src/features/options/domain/models/member_profile.dart';
import 'package:loan_ranger/src/features/options/domain/services/options_builder.dart';

const _rates = RateSheet({
  'conventional_30': 6.75,
  'conventional_15': 6.0,
  'fha_30': 6.25,
  'va_30': 6.0,
  'usda_30': 6.25,
});

List<LoanOption> _build(MemberProfile m, [RateSheet r = _rates]) =>
    const OptionsBuilder().build(m, r);

LoanOption _id(List<LoanOption> o, String id) =>
    o.firstWhere((e) => e.id == id);

void main() {
  test("all option titles are ASCII", () {
    final opts = const OptionsBuilder().build(
      const MemberProfile(
        price: 400000,
        cashAvailable: 200000,
        annualIncome: 150000,
        isVeteran: true,
        ruralEligible: true,
      ),
      const RateSheet({
        "conventional_30": 6.5,
        "conventional_15": 5.75,
        "fha_30": 6.25,
        "va_30": 6.0,
        "usda_30": 6.1,
      }),
    );
    expect(opts.length, greaterThanOrEqualTo(5));
    for (final o in opts) {
      expect(o.title.codeUnits.every((c) => c < 128), isTrue, reason: o.title);
    }
  });

  const base = MemberProfile(price: 400000, cashAvailable: 100000);

  test('va/usda only when eligible', () {
    final o = _build(base);
    expect(o.any((e) => e.programId == 'va_30'), isFalse);
    expect(o.any((e) => e.programId == 'usda_30'), isFalse);
    final v = _build(
      const MemberProfile(
        price: 400000,
        cashAvailable: 100000,
        isVeteran: true,
      ),
    );
    expect(v.any((e) => e.programId == 'va_30'), isTrue);
  });

  test('program missing from rate sheet is omitted', () {
    final o = _build(base, const RateSheet({'conventional_30': 6.75}));
    expect(o.any((e) => e.programId == 'fha_30'), isFalse);
    expect(o.any((e) => e.programId == 'conventional_30'), isTrue);
    expect(_build(base, const RateSheet({})), isEmpty);
  });

  test('low cash: no 20% option, fha short on cash or within cash', () {
    final o = _build(const MemberProfile(price: 400000, cashAvailable: 20000));
    expect(o.any((e) => e.id == 'conventional_30_20'), isFalse);
    final fha = _id(o, 'fha_30');
    expect(
      fha.cashToClose <= 20000 || fha.flags.contains('Short on cash'),
      isTrue,
    );
  });

  test('cash 100000 yields both conv30 options; 20% down has no MI', () {
    final o = _build(base);
    expect(_id(o, 'conventional_30_min').monthlyMi, greaterThan(0));
    expect(_id(o, 'conventional_30_20').monthlyMi, 0);
    expect(_id(o, 'conventional_30_20').downPayment, 80000);
  });

  test('dti matches piti + debt over monthly income', () {
    final o = _build(
      const MemberProfile(
        price: 400000,
        cashAvailable: 100000,
        annualIncome: 60000,
        monthlyDebt: 1500,
      ),
    );
    final f = _id(o, 'fha_30');
    expect(f.backEndDti, closeTo((f.piti + 1500) / 5000 * 100, 0.01));
    expect(f.flags, contains('DTI over program max'));
  });

  test('buydown uses note-rate payment and extras; piggyback present', () {
    final o = _build(base);
    final b = _id(o, 'conventional_30_buydown');
    final c = _id(o, 'conventional_30_min');
    expect(b.buydown, isNotNull);
    expect(b.piti, closeTo(c.piti, 0.001));
    expect(b.cashToClose, c.cashToClose);
    final p = _id(o, 'piggyback_80_10_10');
    expect(p.loanAmount, 360000);
    expect(p.downPayment, 40000);
    expect(p.monthlyMi, 0);
  });

  test('sorted by piti, ids unique', () {
    final o = _build(base);
    for (var i = 1; i < o.length; i++) {
      expect(o[i].piti, greaterThanOrEqualTo(o[i - 1].piti));
    }
    expect(o.map((e) => e.id).toSet().length, o.length);
  });

  test('piggyback first lien over conforming limit is flagged', () {
    final o = _build(
      const MemberProfile(price: 1200000, cashAvailable: 500000),
    );
    expect(_id(o, 'piggyback_80_10_10').flags, contains('Exceeds baseline limit (check county)'));
  });

  test('piggyback uses explicit second-lien rate else conv30 + 2', () {
    const conv = {'conventional_30': 6.5};
    final dflt = _id(_build(base, const RateSheet(conv)), 'piggyback_80_10_10');
    final same = _id(
      _build(base, const RateSheet({...conv, 'piggyback_second': 8.5})),
      'piggyback_80_10_10',
    );
    final higher = _id(
      _build(base, const RateSheet({...conv, 'piggyback_second': 10})),
      'piggyback_80_10_10',
    );
    expect(same.principalAndInterest, closeTo(dflt.principalAndInterest, 0.001));
    expect(higher.principalAndInterest, greaterThan(dflt.principalAndInterest));
    expect(const OptionsBuilder().secondLienRate(const RateSheet(conv)), 8.5);
    expect(
      const OptionsBuilder().secondLienRate(
        const RateSheet({...conv, 'piggyback_second': 10}),
      ),
      10,
    );
  });

  test('non-positive rates are skipped', () {
    var o = _build(
      base,
      const RateSheet({'fha_30': 0, 'conventional_30': 6.5}),
    );
    expect(o.any((e) => e.programId == 'fha_30'), isFalse);
    o = _build(base, const RateSheet({'conventional_30': 0}));
    expect(o, isEmpty);
  });

  test('pinned dollar amounts: FHA', () {
    final f = _id(_build(base), 'fha_30');
    expect(f.loanAmount, closeTo(392755, 0.01));
    expect(f.principalAndInterest, closeTo(2418.2601, 0.01));
    expect(f.cashToClose, closeTo(26000, 0.01));
  });

  test('pinned dollar amounts: VA', () {
    final v = _id(
      _build(
        const MemberProfile(
          price: 400000,
          cashAvailable: 100000,
          isVeteran: true,
        ),
      ),
      'va_30',
    );
    expect(v.loanAmount, closeTo(408600, 0.01));
    expect(v.principalAndInterest, closeTo(2449.7634, 0.01));
    expect(v.monthlyMi, 0);
    expect(v.cashToClose, closeTo(12000, 0.01));
  });
}
