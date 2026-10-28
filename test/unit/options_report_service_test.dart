import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/options/domain/models/member_profile.dart';
import 'package:loan_ranger/src/features/options/domain/services/options_builder.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/brand_header.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/options_report_service.dart';

void main() {
  pdfPlaceholderTests();
  const member = MemberProfile(
    price: 400000,
    cashAvailable: 60000,
    annualIncome: 120000,
  );
  final options = const OptionsBuilder().build(
    member,
    const RateSheet({'conventional_30': 6.5, 'fha_30': 6.25, 'va_30': 6.0}),
  );

  for (final brand in [
    const BrandInfo(
      name: 'Jane',
      nmls: '1',
      company: 'Co',
      phone: '1',
      email: 'a@b.c',
      applyUrl: 'https://x.y',
      disclaimer: 'd',
      accentColor: 0xFF1565C0,
    ),
    const BrandInfo(
      name: '',
      nmls: '',
      company: '',
      phone: '',
      email: '',
      applyUrl: '',
      disclaimer: '',
      accentColor: 0xFF1565C0,
    ),
  ]) {
    test('generates bytes for ${options.length} options', () async {
      expect(options.length, greaterThanOrEqualTo(3));
      final bytes = await OptionsReportService.generate(
        options: options.take(3).toList(),
        member: member,
        brand: brand,
        memberName: 'Sam',
      );
      expect(bytes, isNotEmpty);
    });
  }
}

void pdfPlaceholderTests() {
  test('assumptions lines are ASCII and cover buydown and piggyback', () {
    final opts = const OptionsBuilder().build(
      const MemberProfile(price: 400000, cashAvailable: 100000),
      const RateSheet({'conventional_30': 6.5}),
    );
    final lines = optionsAssumptions(opts, 3, 8.5);
    expect(lines.first, contains('closing costs of 3% of price'));
    expect(lines.any((l) => l.contains('requires \$')), isTrue);
    expect(lines.any((l) => l.contains('Piggyback second lien at 8.5% / 15 yr')), isTrue);
    for (final l in lines) {
      expect(l.codeUnits.every((c) => c < 128), isTrue, reason: l);
    }
    expect(optionsAssumptions([], 3, null).length, 1);
  });

  test('pdf placeholders are ASCII n/a', () {
    for (final v in [null, double.nan, double.infinity]) {
      expect(OptionsReportService.pdfMoney(v), 'n/a');
      expect(OptionsReportService.pdfPercent(v, 1), 'n/a');
    }
    expect(OptionsReportService.pdfPercent(12.34, 1), '12.3%');
  });
}
