import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/validators/enhanced_validators.dart';

void main() {
  test('min-income result sits on the limit and must not warn (float noise)', () {
    var spurious = 0;
    for (var cents = 100000; cents < 600000; cents += 7) {
      final piti = cents / 100 + 0.0037; // payments are not whole cents
      final income = piti / 0.28 * 12; // what calculateMinimumIncome returns
      final front = DtiValidator.calculateHousingDti(
        monthlyHousingPayment: piti,
        monthlyGrossIncome: income / 12,
      );
      final w = DtiValidator.getDtiWarnings(
        frontEndDti: front,
        backEndDti: 0,
        frontEndLimit: 28,
        backEndLimit: 36,
      );
      if (w.any((x) => x.message.contains('Housing DTI'))) spurious++;
    }
    expect(spurious, 0);
  });

  test('DTI genuinely above the limit still warns', () {
    final w = DtiValidator.getDtiWarnings(
      frontEndDti: 28.5,
      backEndDti: 20,
      frontEndLimit: 28,
      backEndLimit: 36,
    );
    expect(w.where((x) => x.message.contains('Housing DTI')), hasLength(1));
  });
}
