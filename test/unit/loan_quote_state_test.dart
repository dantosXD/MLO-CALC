import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/navigation/feature_catalog.dart';
import 'package:loan_ranger/src/features/calculator/application/states/loan_quote_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/closing_costs.dart';

void main() {
  test('cashToClose includes initial escrow', () {
    const base = LoanQuoteState(price: 400000, downPayment: 20);
    const withEscrow = LoanQuoteState(
      price: 400000,
      downPayment: 20,
      closingCosts: ClosingCosts(initialEscrow: 2400),
    );
    expect(withEscrow.cashToClose - base.cashToClose, closeTo(2400, 0.001));
  });

  test('pinned features include options without duplicates', () {
    final ids = FeatureCatalog.pinnedFeatures.map((e) => e.id).toList();
    expect(ids, contains('options'));
    expect(ids.toSet().length, ids.length);
  });
}
