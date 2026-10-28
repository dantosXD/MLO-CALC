import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class BrandInfo {
  const BrandInfo({
    required this.name,
    required this.nmls,
    required this.company,
    required this.phone,
    required this.email,
    required this.applyUrl,
    required this.disclaimer,
    required this.accentColor,
    this.logo,
  });

  final String name, nmls, company, phone, email, applyUrl, disclaimer;
  final Uint8List? logo;
  final int accentColor;
}

pw.Widget buildBrandHeader(BrandInfo brand, {String? title}) {
  pw.Widget? logo;
  if (brand.logo != null) {
    try {
      logo = pw.Image(pw.MemoryImage(brand.logo!), height: 48);
    } catch (_) {
      logo = null; // bad bytes: omit the logo rather than fail the report
    }
  }
  final accent = PdfColor.fromInt(brand.accentColor);
  final contact = [
    if (brand.company.isNotEmpty) brand.company,
    if (brand.phone.isNotEmpty) brand.phone,
    if (brand.email.isNotEmpty) brand.email,
  ];
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) ...[logo, pw.SizedBox(width: 12)],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (brand.name.isNotEmpty)
                  pw.Text(
                    brand.name,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: accent,
                    ),
                  ),
                if (brand.nmls.isNotEmpty)
                  pw.Text(
                    'NMLS #${brand.nmls}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                for (final c in contact)
                  pw.Text(c, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
      if (title != null) ...[
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
      ],
      pw.Divider(color: accent),
    ],
  );
}

pw.Widget buildBrandFooter(BrandInfo brand) {
  return pw.Column(
    children: [
      pw.Divider(),
      if (brand.disclaimer.isNotEmpty)
        pw.Text(
          brand.disclaimer,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      if (brand.applyUrl.isNotEmpty)
        pw.Text(
          'Apply: ${brand.applyUrl}',
          style: const pw.TextStyle(fontSize: 8),
        ),
    ],
  );
}
