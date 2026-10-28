import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:loan_ranger/src/features/options/domain/models/loan_option.dart';
import 'package:loan_ranger/src/features/options/domain/models/member_profile.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/brand_header.dart';
import 'package:loan_ranger/src/features/reporting/domain/services/report_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class OptionsReportService {
  static final _currency = NumberFormat.simpleCurrency();

  static String _money(double? v) =>
      (v == null || !v.isFinite) ? '—' : _currency.format(v);

  static Future<Uint8List> generate({
    required List<LoanOption> options,
    required MemberProfile member,
    required BrandInfo brand,
    String? memberName,
  }) async {
    final name = memberName?.trim() ?? '';
    final rows = <String, String Function(LoanOption)>{
      'Loan amount': (o) => _money(o.loanAmount),
      'Down payment': (o) => _money(o.downPayment),
      'Rate': (o) => o.rate.isFinite ? '${o.rate.toStringAsFixed(3)}%' : '—',
      'P&I': (o) => _money(o.principalAndInterest),
      'MI': (o) => _money(o.monthlyMi),
      'PITI': (o) => _money(o.piti),
      'Cash to close': (o) => _money(o.cashToClose),
      'DTI': (o) {
        final d = o.backEndDti;
        return (d == null || !d.isFinite) ? '—' : '${d.toStringAsFixed(1)}%';
      },
      'Notes': (o) => o.flags.isEmpty ? '' : o.flags.join(', '),
    };
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: await loadReportTheme(),
        footer: (_) => buildBrandFooter(brand),
        build: (_) => [
          buildBrandHeader(
            brand,
            title: name.isEmpty ? 'Loan Options' : 'Loan Options for $name',
          ),
          pw.Text(
            'Price ${_money(member.price)}  |  Cash available '
            '${_money(member.cashAvailable)}  |  Income '
            '${_money(member.annualIncome)}/yr  |  '
            '${DateFormat.yMMMd().format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['', for (final o in options) o.title],
            data: [
              for (final e in rows.entries)
                [e.key, for (final o in options) e.value(o)],
            ],
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          for (final o in options.where((o) => o.buydown != null)) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              '${o.title} buydown: ${[for (final y in o.buydown!.years) 'Yr ${y.year} ${y.rate.toStringAsFixed(3)}% ${_money(y.payment)}'].join('; ')}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }
}
