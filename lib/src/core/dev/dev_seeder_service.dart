import 'dart:convert';

import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates realistic calculation history entries for development / QA testing.
/// Only used in debug builds (see SettingsScreen._DevSection).
class DevSeederService {
  DevSeederService._();

  /// Returns 25 pre-built entries spread across 90 days of history.
  static List<CalculationEntry> generateEntries() {
    final now = DateTime.now();

    // Helpers
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    CalculationEntry payment({
      required int daysBack,
      required double loanAmount,
      required double rate,
      required double term,
      required double pmt,
      double? price,
      double? downPayment,
      double? tax,
      double? insurance,
      String? notes,
    }) => CalculationEntry(
      id: _uuid.v4(),
      timestamp: daysAgo(daysBack),
      type: CalculationEntryType.payment,
      inputs: CalculationEntryInputs(
        loanAmount: loanAmount,
        interestRate: rate,
        termYears: term,
        price: price,
        downPayment: downPayment,
        propertyTax: tax,
        homeInsurance: insurance,
      ),
      results: CalculationEntryResults(payment: pmt),
      notes: notes,
    );

    CalculationEntry loanAmt({
      required int daysBack,
      required double pmt,
      required double rate,
      required double term,
      required double loan,
    }) => CalculationEntry(
      id: _uuid.v4(),
      timestamp: daysAgo(daysBack),
      type: CalculationEntryType.loanAmount,
      inputs: CalculationEntryInputs(
        payment: pmt,
        interestRate: rate,
        termYears: term,
      ),
      results: CalculationEntryResults(loanAmount: loan),
    );

    CalculationEntry termCalc({
      required int daysBack,
      required double loan,
      required double rate,
      required double term,
    }) => CalculationEntry(
      id: _uuid.v4(),
      timestamp: daysAgo(daysBack),
      type: CalculationEntryType.term,
      inputs: CalculationEntryInputs(loanAmount: loan, interestRate: rate),
      results: CalculationEntryResults(termYears: term),
    );

    CalculationEntry rateCalc({
      required int daysBack,
      required double loan,
      required double pmt,
      required double term,
      required double rate,
    }) => CalculationEntry(
      id: _uuid.v4(),
      timestamp: daysAgo(daysBack),
      type: CalculationEntryType.interestRate,
      inputs: CalculationEntryInputs(
        loanAmount: loan,
        payment: pmt,
        termYears: term,
      ),
      results: CalculationEntryResults(interestRate: rate),
    );

    CalculationEntry qual({
      required int daysBack,
      required double income,
      required double debt,
      required double rate,
      required double term,
      required double maxLoan,
      double? piPayment,
      String? notes,
    }) => CalculationEntry(
      id: _uuid.v4(),
      timestamp: daysAgo(daysBack),
      type: CalculationEntryType.qualification,
      inputs: CalculationEntryInputs(
        annualIncome: income,
        monthlyDebt: debt,
        interestRate: rate,
        termYears: term,
      ),
      results: CalculationEntryResults(
        maxLoanAmount: maxLoan,
        monthlyPiPayment: piPayment,
      ),
      notes: notes,
    );

    return [
      // ── Payment calculations (10) ──────────────────────────────────────
      payment(
        daysBack: 2,
        loanAmount: 380000,
        rate: 6.875,
        term: 30,
        pmt: 2497.25,
        price: 400000,
        downPayment: 20000,
        tax: 400,
        insurance: 167,
        notes: 'Starter home — Riverside',
      ),
      payment(
        daysBack: 5,
        loanAmount: 560000,
        rate: 6.5,
        term: 30,
        pmt: 3540.86,
        price: 625000,
        downPayment: 65000,
        tax: 625,
        insurance: 260,
        notes: 'Move-up buyer',
      ),
      payment(
        daysBack: 9,
        loanAmount: 240000,
        rate: 7.125,
        term: 30,
        pmt: 1616.20,
        price: 300000,
        downPayment: 60000,
        tax: 310,
        insurance: 125,
      ),
      payment(
        daysBack: 14,
        loanAmount: 195000,
        rate: 7.0,
        term: 15,
        pmt: 1752.71,
        price: 220000,
        downPayment: 25000,
        tax: 229,
        insurance: 92,
        notes: '15-yr accelerated payoff',
      ),
      payment(
        daysBack: 19,
        loanAmount: 730000,
        rate: 6.25,
        term: 30,
        pmt: 4496.34,
        price: 810000,
        downPayment: 80000,
        tax: 844,
        insurance: 338,
        notes: 'Jumbo — downtown condo',
      ),
      payment(
        daysBack: 25,
        loanAmount: 148500,
        rate: 6.75,
        term: 30,
        pmt: 962.95,
        price: 165000,
        downPayment: 16500,
        tax: 172,
        insurance: 69,
      ),
      payment(
        daysBack: 33,
        loanAmount: 425000,
        rate: 7.375,
        term: 30,
        pmt: 2937.42,
        price: 475000,
        downPayment: 50000,
        tax: 490,
        insurance: 198,
        notes: 'VA-eligible, using conventional',
      ),
      payment(
        daysBack: 42,
        loanAmount: 310000,
        rate: 5.875,
        term: 20,
        pmt: 2194.48,
        price: 350000,
        downPayment: 40000,
        tax: 365,
        insurance: 146,
        notes: '20-yr — lower total interest',
      ),
      payment(
        daysBack: 55,
        loanAmount: 198000,
        rate: 6.625,
        term: 30,
        pmt: 1268.70,
        price: 220000,
        downPayment: 22000,
        tax: 229,
        insurance: 92,
      ),
      payment(
        daysBack: 70,
        loanAmount: 850000,
        rate: 6.0,
        term: 30,
        pmt: 5094.95,
        price: 950000,
        downPayment: 100000,
        tax: 988,
        insurance: 396,
        notes: 'High-value — second review',
      ),

      // ── Loan amount calculations (5) ───────────────────────────────────
      loanAmt(daysBack: 3, pmt: 2200, rate: 7.0, term: 30, loan: 330805),
      loanAmt(daysBack: 11, pmt: 3500, rate: 6.5, term: 30, loan: 554252),
      loanAmt(daysBack: 28, pmt: 1800, rate: 7.25, term: 30, loan: 267688),
      loanAmt(daysBack: 46, pmt: 2800, rate: 6.875, term: 30, loan: 423831),
      loanAmt(daysBack: 63, pmt: 1400, rate: 7.0, term: 30, loan: 210511),

      // ── Term calculations (3) ──────────────────────────────────────────
      termCalc(daysBack: 7, loan: 280000, rate: 6.75, term: 25.0),
      termCalc(daysBack: 36, loan: 175000, rate: 7.125, term: 20.0),
      termCalc(daysBack: 58, loan: 430000, rate: 6.5, term: 30.0),

      // ── Interest rate calculations (3) ─────────────────────────────────
      rateCalc(daysBack: 13, loan: 320000, pmt: 2100, term: 30, rate: 6.57),
      rateCalc(daysBack: 38, loan: 215000, pmt: 1650, term: 30, rate: 7.11),
      rateCalc(daysBack: 72, loan: 495000, pmt: 3200, term: 30, rate: 6.39),

      // ── Qualification analyses (4) ─────────────────────────────────────
      qual(
        daysBack: 4,
        income: 95000,
        debt: 450,
        rate: 6.875,
        term: 30,
        maxLoan: 375420,
        piPayment: 2466,
        notes: 'FHA 3.5% down — first-time buyer',
      ),
      qual(
        daysBack: 22,
        income: 135000,
        debt: 900,
        rate: 6.5,
        term: 30,
        maxLoan: 489200,
        piPayment: 3093,
        notes: 'Dual income, student loans',
      ),
      qual(
        daysBack: 48,
        income: 72000,
        debt: 200,
        rate: 7.25,
        term: 30,
        maxLoan: 258750,
        piPayment: 1765,
      ),
      qual(
        daysBack: 80,
        income: 210000,
        debt: 1500,
        rate: 6.25,
        term: 30,
        maxLoan: 780000,
        piPayment: 4804,
        notes: 'Jumbo pre-qual',
      ),
    ];
  }

  /// Serialises the seed entries to a JSON string accepted by
  /// HistoryController.replaceFromJson.
  static String generateJsonString() {
    final entries = generateEntries();
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }
}
