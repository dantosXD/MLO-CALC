import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Google font needs network; fall back to the built-in font offline/tests.
Future<pw.ThemeData?> loadReportTheme() async {
  try {
    final font = await PdfGoogleFonts.nunitoExtraLight().timeout(
      const Duration(seconds: 3),
    );
    return pw.ThemeData.withFont(base: font);
  } catch (_) {
    return null;
  }
}
