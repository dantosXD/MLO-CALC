import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';

void main() {
  group('NLPCalculatorService.parseLocally', () {
    test('parses loan amount, rate, and term for payment calculation', () {
      final req = NLPCalculatorService.parseLocally(
        'Payment for 350k at 5.5 percent for 30 years',
      );

      expect(req.action, 'calculate_payment');
      expect(req.loanAmount, 350000);
      expect(req.interestRate, 5.5);
      expect(req.termYears, 30);
    });

    test('parses comma-separated values and dollar signs', () {
      final req = NLPCalculatorService.parseLocally(
        'Calculate loan of \$450,000 at 6.25% for 15 years',
      );

      expect(req.action, 'calculate_payment');
      expect(req.loanAmount, 450000);
      expect(req.interestRate, 6.25);
      expect(req.termYears, 15);
    });

    test('parses max loan query with annual income and monthly debt', () {
      final req = NLPCalculatorService.parseLocally(
        "What's my max loan with \$120,000 income and \$600 debt?",
      );

      expect(req.action, 'calculate_max_qualifying_loan');
      expect(req.annualIncome, 120000);
      expect(req.monthlyDebt, 600);
    });

    test('parses target payment to calculate loan amount', () {
      final req = NLPCalculatorService.parseLocally(
        'How much house for \$2,500 a month at 6.5%?',
      );

      expect(req.action, 'calculate_loan_amount');
      expect(req.payment, 2500);
      expect(req.interestRate, 6.5);
    });

    test('parses amortization schedule intent', () {
      final req = NLPCalculatorService.parseLocally(
        'Amortization schedule for 500k',
      );

      expect(req.action, 'generate_amortization');
      expect(req.loanAmount, 500000);
    });

    test('parses biweekly comparison intent', () {
      final req = NLPCalculatorService.parseLocally(
        'Calculate bi-weekly payment comparison for 400k at 6%',
      );

      expect(req.action, 'calculate_biweekly');
      expect(req.loanAmount, 400000);
      expect(req.interestRate, 6.0);
    });

    test('parses down payment and price correctly', () {
      final req = NLPCalculatorService.parseLocally(
        'Price 600k with 100k down at 6.875% for 30 yrs',
      );

      expect(req.price, 600000);
      expect(req.downPayment, 100000);
      expect(req.interestRate, 6.875);
      expect(req.termYears, 30);
    });
  });

  group('NLPCalculatorService fallbacks', () {
    test('processQuery succeeds with local parser when service is uninitialized', () async {
      final service = NLPCalculatorService();
      expect(service.isInitialized, isFalse);

      final req = await service.processQuery('300k at 7% for 30 years');
      expect(req.loanAmount, 300000);
      expect(req.interestRate, 7.0);
      expect(req.termYears, 30);
    });

    test('generateClientPitch returns friendly local template when uninitialized', () async {
      final service = NLPCalculatorService();
      final pitch = await service.generateClientPitch(
        loanAmount: 400000,
        interestRate: 6.5,
        termYears: 30,
        monthlyPayment: 2528.27,
      );

      expect(pitch, contains('\$400000'));
      expect(pitch, contains('6.50%'));
      expect(pitch, contains('\$2528.27'));
    });

    test('generateDtiAdvice provides actionable underwriting guidance when uninitialized', () async {
      final service = NLPCalculatorService();
      final advice = await service.generateDtiAdvice(
        frontEndDti: 32.0,
        backEndDti: 45.0,
        annualIncome: 120000,
        monthlyDebt: 500,
        piti: 3200,
      );

      expect(advice, contains('DTI'));
      expect(advice, contains('Action tip'));
    });

    test('multi-turn follow-up preserves existing context in parseLocally', () {
      final initial = NLPCalculatorService.parseLocally('400k at 6.5% for 30 years');
      expect(initial.loanAmount, 400000);
      expect(initial.interestRate, 6.5);
      expect(initial.termYears, 30);

      // Follow-up query adjusting only the term
      final followUp = NLPCalculatorService.parseLocally(
        'change to 15 years',
        previousContext: initial,
      );
      expect(followUp.loanAmount, 400000); // Retained from initial
      expect(followUp.interestRate, 6.5); // Retained from initial
      expect(followUp.termYears, 15); // Updated
    });

    test('generatePointsBreakEvenAdvice generates clear guidance when uninitialized', () async {
      final service = NLPCalculatorService();
      final advice = await service.generatePointsBreakEvenAdvice(
        loanAmount: 400000,
        originalRate: 6.875,
        newRate: 6.375,
        pointsCost: 4000,
        monthlySavings: 130,
        breakEvenMonths: 31,
      );

      expect(advice, contains('31 months'));
      expect(advice, contains('6.875%'));
      expect(advice, contains('6.375%'));
    });

    test('generatePayoffMilestones generates structured payoff timeline when uninitialized', () async {
      final service = NLPCalculatorService();
      final milestones = await service.generatePayoffMilestones(
        loanAmount: 350000,
        interestRate: 6.5,
        termYears: 30,
        monthlyPayment: 2212.24,
        extraMonthlyPrincipal: 200,
        monthsSaved: 68,
        totalInterestSaved: 54200,
      );

      expect(milestones, contains('Time Saved'));
      expect(milestones, contains('\$200/mo'));
      expect(milestones, contains('\$54200'));
    });

    test('generateRentVsBuyMemo evaluates net wealth outcome when uninitialized', () async {
      final service = NLPCalculatorService();
      final memo = await service.generateRentVsBuyMemo(
        homePrice: 450000,
        monthlyRent: 2200,
        breakEvenYear: 4,
        netWealthDifference: 65000,
        analysisYears: 10,
      );

      expect(memo, contains('year 4'));
      expect(memo, contains('\$65000'));
    });
  });
}
