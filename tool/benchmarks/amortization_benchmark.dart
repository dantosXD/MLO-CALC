// ignore_for_file: avoid_print

import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/features/arm/domain/models/arm_scenario.dart';
import 'package:loan_ranger/src/features/arm/domain/services/arm_calculator_service.dart';

void main() {
  final mathEngine = const LoanMath();
  final amortizationDuration = _benchmark(() => _buildSchedule(mathEngine));
  print('Amortization schedule: $amortizationDuration ms');

  final armDuration = _benchmark(() {
    final armService = ArmCalculatorService(mathEngine);
    armService.calculateSchedule(
      const ArmScenario(
        loanAmount: 450000,
        termYears: 30,
        initialRate: 4.75,
        initialFixedYears: 5,
        adjustmentFrequencyYears: 1,
        rateChangePerAdjustment: 1,
        periodicCap: 2,
        lifetimeCap: 9,
        lifetimeFloor: 3,
      ),
    );
  });
  print('ARM schedule: $armDuration ms');
}

int _benchmark(void Function() action) {
  final sw = Stopwatch()..start();
  action();
  sw.stop();
  return sw.elapsedMilliseconds;
}

void _buildSchedule(LoanMath mathEngine) {
  const loanAmount = 500000.0;
  const interestRate = 6.125;
  const termYears = 30.0;
  final monthlyPayment = mathEngine.calculatePayment(
    loanAmount: loanAmount,
    interestRate: interestRate,
    termYears: termYears,
  );

  double balance = loanAmount;
  final monthlyRate = interestRate / 100 / 12;
  final totalMonths = (termYears * 12).round();

  for (var month = 0; month < totalMonths; month++) {
    final interestPaid = balance * monthlyRate;
    var principalPaid = monthlyPayment - interestPaid;
    if (month == totalMonths - 1) {
      principalPaid = balance;
    }
    balance -= principalPaid;
  }
}
