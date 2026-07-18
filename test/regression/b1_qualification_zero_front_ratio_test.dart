// Regression: BUGLOG B1 — VA / zero-front-ratio qualification.
//
// A QualifyingRatio.housingRatio of 0 encodes "no front-end constraint"
// (e.g. VA). It must NOT be treated as a literal 0% cap, which previously
// (a) made calculateMaxLoan always fail 'Insufficient income for housing'
// and (b) made calculateMinimumIncome divide by zero and return Infinity.
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/calculation_result.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/qualification_result.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';

void main() {
  const service = QualificationService(LoanMath());
  const va = QualifyingRatio(
    id: 'va',
    name: 'VA',
    housingRatio: 0, // no front-end ratio
    debtRatio: 41,
  );

  group('B1: zero front-end (VA) ratio', () {
    test('calculateMaxLoan succeeds using the back-end ratio alone', () {
      final result = service.calculateMaxLoan(
        ratio: va,
        annualIncome: 120000,
        interestRate: 6.0,
        termYears: 30,
      );

      expect(result, isA<CalcSuccess<QualificationResult>>());
      expect(result.value, isNotNull);
      // Back-end only: monthly income 10000 * 41% = 4100 max PITI.
      expect(result.value!.monthlyPiPayment, closeTo(4100, 0.01));
      expect(result.value!.loanAmount, greaterThan(0));
      expect(result.value!.loanAmount.isFinite, isTrue);
    });

    test(
      'calculateMinimumIncome returns a finite value (no divide-by-zero)',
      () {
        final result = service.calculateMinimumIncome(
          ratio: va,
          pitiPayment: 2000,
        );

        expect(result, isA<CalcSuccess<double>>());
        expect(result.value, isNotNull);
        expect(result.value!.isFinite, isTrue);
        // Back-end only: (2000 / 0.41) * 12.
        expect(result.value!, closeTo(58536.59, 1.0));
      },
    );
  });
}
