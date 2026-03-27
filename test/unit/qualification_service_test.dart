import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/calculation_result.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/qualification_result.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';

void main() {
  const service = QualificationService(LoanMath());
  const ratio = QualifyingRatio(
    id: 'conventional',
    name: 'Conventional',
    housingRatio: 28,
    debtRatio: 36,
  );

  group('QualificationService', () {
    test('calculateMaxLoan uses the housing-ratio bound when it is tighter', () {
      final result = service.calculateMaxLoan(
        ratio: ratio,
        annualIncome: 120000,
        interestRate: 6.0,
        termYears: 30,
      );

      expect(result, isA<CalcSuccess<QualificationResult>>());
      expect(result.isSuccess, isTrue);
      expect(result.value, isNotNull);
      expect(result.value!.monthlyPiPayment, closeTo(2800, 0.01));
    });

    test('calculateMaxLoan uses the debt-ratio bound when it is tighter', () {
      final result = service.calculateMaxLoan(
        ratio: ratio,
        annualIncome: 120000,
        interestRate: 6.0,
        termYears: 30,
        monthlyDebt: 2000,
      );

      expect(result, isA<CalcSuccess<QualificationResult>>());
      expect(result.value, isNotNull);
      expect(result.value!.monthlyPiPayment, closeTo(1600, 0.01));
    });

    test('calculateMaxLoan fails when maxPi is not positive', () {
      final result = service.calculateMaxLoan(
        ratio: ratio,
        annualIncome: 60000,
        interestRate: 6.0,
        termYears: 30,
        monthlyDebt: 3000,
      );

      expect(result, isA<CalcFailure<QualificationResult>>());
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Insufficient income'));
    });
  });
}
