import 'dart:convert';

class ArmScenario {
  final double loanAmount;
  final double termYears;
  final double initialRate;
  final double initialFixedYears;
  final double adjustmentFrequencyYears;
  final double rateChangePerAdjustment;
  final double periodicCap;
  final double lifetimeCap;
  final double lifetimeFloor;

  const ArmScenario({
    required this.loanAmount,
    required this.termYears,
    required this.initialRate,
    required this.initialFixedYears,
    required this.adjustmentFrequencyYears,
    required this.rateChangePerAdjustment,
    required this.periodicCap,
    required this.lifetimeCap,
    required this.lifetimeFloor,
  });

  ArmScenario copyWith({
    double? loanAmount,
    double? termYears,
    double? initialRate,
    double? initialFixedYears,
    double? adjustmentFrequencyYears,
    double? rateChangePerAdjustment,
    double? periodicCap,
    double? lifetimeCap,
    double? lifetimeFloor,
  }) {
    return ArmScenario(
      loanAmount: loanAmount ?? this.loanAmount,
      termYears: termYears ?? this.termYears,
      initialRate: initialRate ?? this.initialRate,
      initialFixedYears: initialFixedYears ?? this.initialFixedYears,
      adjustmentFrequencyYears:
          adjustmentFrequencyYears ?? this.adjustmentFrequencyYears,
      rateChangePerAdjustment:
          rateChangePerAdjustment ?? this.rateChangePerAdjustment,
      periodicCap: periodicCap ?? this.periodicCap,
      lifetimeCap: lifetimeCap ?? this.lifetimeCap,
      lifetimeFloor: lifetimeFloor ?? this.lifetimeFloor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loanAmount': loanAmount,
      'termYears': termYears,
      'initialRate': initialRate,
      'initialFixedYears': initialFixedYears,
      'adjustmentFrequencyYears': adjustmentFrequencyYears,
      'rateChangePerAdjustment': rateChangePerAdjustment,
      'periodicCap': periodicCap,
      'lifetimeCap': lifetimeCap,
      'lifetimeFloor': lifetimeFloor,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory ArmScenario.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ArmScenario(
      loanAmount: toDouble(json['loanAmount']),
      termYears: toDouble(json['termYears']),
      initialRate: toDouble(json['initialRate']),
      initialFixedYears: toDouble(json['initialFixedYears']),
      adjustmentFrequencyYears: toDouble(json['adjustmentFrequencyYears']),
      rateChangePerAdjustment: toDouble(json['rateChangePerAdjustment']),
      periodicCap: toDouble(json['periodicCap']),
      lifetimeCap: toDouble(json['lifetimeCap']),
      lifetimeFloor: toDouble(json['lifetimeFloor']),
    );
  }

  static ArmScenario fromJsonString(String jsonString) {
    final Map<String, dynamic> data =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return ArmScenario.fromJson(data);
  }
}

class ArmPeriodSummary {
  final int startMonth;
  final int endMonth;
  final double rate;
  final double monthlyPayment;
  final double principalPaid;
  final double interestPaid;
  final double endingBalance;

  const ArmPeriodSummary({
    required this.startMonth,
    required this.endMonth,
    required this.rate,
    required this.monthlyPayment,
    required this.principalPaid,
    required this.interestPaid,
    required this.endingBalance,
  });
}

class ArmScheduleResult {
  final List<ArmPeriodSummary> periods;
  final double totalInterest;
  final double totalPaid;

  const ArmScheduleResult({
    required this.periods,
    required this.totalInterest,
    required this.totalPaid,
  });

  bool get hasAdjustments => periods.length > 1;
}
