
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:loan_ranger/src/core/models/amortization_entry.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportService {
  static final _currency = NumberFormat.simpleCurrency();

  static Future<Uint8List> generateLoanReport({
    required CalculatorProvider provider,
    String? clientName,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => [
          _buildHeader(clientName),
          pw.SizedBox(height: 20),
          _buildLoanSummary(provider),
          pw.SizedBox(height: 20),
          _buildMonthlyBreakdown(provider),
          pw.SizedBox(height: 20),
          _buildClosingCosts(provider),
          pw.SizedBox(height: 20),
          if (provider.amortizationData.isNotEmpty)
            _buildAmortizationSummary(provider.amortizationData),
          pw.Divider(),
          _buildDisclaimer(),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader(String? clientName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Loan Estimate Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text(DateFormat.yMMMd().format(DateTime.now())),
          ],
        ),
        if (clientName != null) ...[
          pw.SizedBox(height: 5),
          pw.Text('Prepared for: $clientName', style: const pw.TextStyle(fontSize: 14)),
        ],
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildLoanSummary(CalculatorProvider provider) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Loan Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('Loan Amount', _currency.format(provider.loanAmount ?? 0)),
              _buildInfoColumn(
                'Interest Rate',
                CurrencyFormatter.formatPercent(provider.interestRate, decimals: 3),
              ),
              _buildInfoColumn('Term', '${provider.termYears?.toStringAsFixed(0)} Years'),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('Purchase Price', _currency.format(provider.price ?? 0)),
              _buildInfoColumn('Down Payment', _currency.format(provider.downPayment ?? 0)), // Simplified
              _buildInfoColumn('LTV', _calculateLTV(provider)),
            ],
          ),
        ],
      ),
    );
  }

  static String _calculateLTV(CalculatorProvider provider) {
    if (provider.price == null || provider.loanAmount == null || provider.price == 0) return '0%';
    return CurrencyFormatter.formatPercent(
      (provider.loanAmount! / provider.price!) * 100,
      decimals: 3,
    );
  }

  static pw.Widget _buildInfoColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildMonthlyBreakdown(CalculatorProvider provider) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Monthly Payment Breakdown', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('Principal & Interest', provider.payment ?? 0),
            if (provider.propertyTax != null) _buildTableRow('Property Tax', provider.propertyTax! / 12),
            if (provider.homeInsurance != null) _buildTableRow('Home Insurance', provider.homeInsurance! / 12),
            if (provider.mortgageInsurance != null) _buildTableRow('Mortgage Insurance (PMI)', provider.mortgageInsurance! / 12),
            if (provider.monthlyExpenses != null) _buildTableRow('HOA & Other', provider.monthlyExpenses!),
            _buildTableRow('Total Monthly Payment', provider.pitiPayment, isTotal: true),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _buildTableRow(String label, double value, {bool isTotal = false}) {
    return pw.TableRow(
      decoration: isTotal ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label, style: isTotal ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(_currency.format(value),
              textAlign: pw.TextAlign.right,
              style: isTotal ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
        ),
      ],
    );
  }

  static pw.Widget _buildClosingCosts(CalculatorProvider provider) {
    final costs = provider.closingCosts;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Closing Costs & Cash to Close', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('Loan Charges (Origination, Points, etc.)', costs.totalLoanCharges),
            _buildTableRow('Services (Appraisal, Credit, etc.)', costs.totalServices),
            _buildTableRow('Title & Escrow', costs.totalTitleEscrow),
            _buildTableRow('Prepaids (Interest, Taxes, Insurance)', costs.totalPrepaids),
            _buildTableRow('Total Closing Costs', costs.total, isTotal: true),
            _buildTableRow('Estimated Cash to Close', provider.cashToClose, isTotal: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAmortizationSummary(List<AmortizationEntry> amortization) {
    if (amortization.isEmpty) return pw.Container();
    
    final totalInterest = amortization.fold<double>(0, (sum, item) => sum + item.interest);
    final totalPrincipal = amortization.fold<double>(0, (sum, item) => sum + item.principal);
    final totalCost = totalInterest + totalPrincipal;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Amortization Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoColumn('Total Principal', _currency.format(totalPrincipal)),
            _buildInfoColumn('Total Interest', _currency.format(totalInterest)),
            _buildInfoColumn('Total Loan Cost', _currency.format(totalCost)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDisclaimer() {
    return pw.Text(
      'Disclaimer: This report is for informational purposes only and does not constitute a loan offer or commitment. '
      'Actual rates, fees, and payments may vary based on creditworthiness, collateral, and market conditions. '
      'Consult with a qualified Mortgage Loan Officer for official estimates.',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      textAlign: pw.TextAlign.center,
    );
  }
}
