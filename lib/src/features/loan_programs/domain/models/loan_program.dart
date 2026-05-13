import 'dart:convert';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';

/// Represents a loan program with specific qualification parameters
class LoanProgram {
  final String id;
  final String name;
  final String description;
  final LoanProgramType type;
  final double housingRatio; // Front-end DTI
  final double debtRatio; // Back-end DTI
  final double minDownPaymentPercent;
  final double? maxLoanAmount; // Conforming limit
  final MortgageInsuranceConfig? miConfig;
  final bool isBuiltIn; // Can't delete built-in programs
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoanProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.housingRatio,
    required this.debtRatio,
    required this.minDownPaymentPercent,
    this.maxLoanAmount,
    this.miConfig,
    this.isBuiltIn = false,
    required this.createdAt,
    required this.updatedAt,
  });

  LoanProgram copyWith({
    String? id,
    String? name,
    String? description,
    LoanProgramType? type,
    double? housingRatio,
    double? debtRatio,
    double? minDownPaymentPercent,
    double? maxLoanAmount,
    MortgageInsuranceConfig? miConfig,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      housingRatio: housingRatio ?? this.housingRatio,
      debtRatio: debtRatio ?? this.debtRatio,
      minDownPaymentPercent:
          minDownPaymentPercent ?? this.minDownPaymentPercent,
      maxLoanAmount: maxLoanAmount ?? this.maxLoanAmount,
      miConfig: miConfig ?? this.miConfig,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'housingRatio': housingRatio,
      'debtRatio': debtRatio,
      'minDownPaymentPercent': minDownPaymentPercent,
      'maxLoanAmount': maxLoanAmount,
      'miConfig': miConfig?.toJson(),
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LoanProgram.fromJson(Map<String, dynamic> json) {
    return LoanProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: LoanProgramType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LoanProgramType.conventional,
      ),
      housingRatio: (json['housingRatio'] as num).toDouble(),
      debtRatio: (json['debtRatio'] as num).toDouble(),
      minDownPaymentPercent: (json['minDownPaymentPercent'] as num).toDouble(),
      maxLoanAmount: json['maxLoanAmount'] != null
          ? (json['maxLoanAmount'] as num).toDouble()
          : null,
      miConfig: json['miConfig'] != null
          ? MortgageInsuranceConfig.fromJson(json['miConfig'])
          : null,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory LoanProgram.fromJsonString(String jsonString) {
    return LoanProgram.fromJson(jsonDecode(jsonString));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanProgram &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Convert this loan program's DTI ratios to a QualifyingRatio
  QualifyingRatio toQualifyingRatio() {
    return QualifyingRatio(
      id: 'program_$id',
      name: name,
      description: description,
      housingRatio: housingRatio,
      debtRatio: debtRatio,
      isBuiltIn: isBuiltIn,
    );
  }
}

enum LoanProgramType { conventional, fha, va, usda, jumbo, nonQm, custom }

extension LoanProgramTypeExtension on LoanProgramType {
  String get displayName {
    switch (this) {
      case LoanProgramType.conventional:
        return 'Conventional';
      case LoanProgramType.fha:
        return 'FHA';
      case LoanProgramType.va:
        return 'VA';
      case LoanProgramType.usda:
        return 'USDA';
      case LoanProgramType.jumbo:
        return 'Jumbo';
      case LoanProgramType.nonQm:
        return 'Non-QM';
      case LoanProgramType.custom:
        return 'Custom';
    }
  }
}

/// Configuration for mortgage insurance
class MortgageInsuranceConfig {
  final double? upfrontPercent; // e.g., FHA UFMIP 1.75%
  final double? annualPercent; // e.g., FHA annual MIP 0.85%
  final double? fundingFeePercent; // VA funding fee
  final bool autoCalculate;
  final double? cancelationLtvThreshold; // When MI can be removed (e.g., 80%)

  const MortgageInsuranceConfig({
    this.upfrontPercent,
    this.annualPercent,
    this.fundingFeePercent,
    this.autoCalculate = true,
    this.cancelationLtvThreshold,
  });

  Map<String, dynamic> toJson() {
    return {
      'upfrontPercent': upfrontPercent,
      'annualPercent': annualPercent,
      'fundingFeePercent': fundingFeePercent,
      'autoCalculate': autoCalculate,
      'cancelationLtvThreshold': cancelationLtvThreshold,
    };
  }

  factory MortgageInsuranceConfig.fromJson(Map<String, dynamic> json) {
    return MortgageInsuranceConfig(
      upfrontPercent: json['upfrontPercent'] != null
          ? (json['upfrontPercent'] as num).toDouble()
          : null,
      annualPercent: json['annualPercent'] != null
          ? (json['annualPercent'] as num).toDouble()
          : null,
      fundingFeePercent: json['fundingFeePercent'] != null
          ? (json['fundingFeePercent'] as num).toDouble()
          : null,
      autoCalculate: json['autoCalculate'] as bool? ?? true,
      cancelationLtvThreshold: json['cancelationLtvThreshold'] != null
          ? (json['cancelationLtvThreshold'] as num).toDouble()
          : null,
    );
  }

  MortgageInsuranceConfig copyWith({
    double? upfrontPercent,
    double? annualPercent,
    double? fundingFeePercent,
    bool? autoCalculate,
    double? cancelationLtvThreshold,
  }) {
    return MortgageInsuranceConfig(
      upfrontPercent: upfrontPercent ?? this.upfrontPercent,
      annualPercent: annualPercent ?? this.annualPercent,
      fundingFeePercent: fundingFeePercent ?? this.fundingFeePercent,
      autoCalculate: autoCalculate ?? this.autoCalculate,
      cancelationLtvThreshold:
          cancelationLtvThreshold ?? this.cancelationLtvThreshold,
    );
  }
}

/// Default built-in loan programs
class DefaultLoanPrograms {
  static final List<LoanProgram> programs = [
    LoanProgram(
      id: 'conventional_30',
      name: 'Conventional 30-Year',
      description: 'Standard conforming loan with 28/36 DTI ratios',
      type: LoanProgramType.conventional,
      housingRatio: 28,
      debtRatio: 36,
      minDownPaymentPercent: 3,
      maxLoanAmount: 766550, // 2024 conforming limit
      miConfig: const MortgageInsuranceConfig(
        annualPercent: 0.5, // Varies by LTV/credit
        cancelationLtvThreshold: 80,
      ),
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LoanProgram(
      id: 'conventional_15',
      name: 'Conventional 15-Year',
      description: 'Shorter term with better rates, 28/36 DTI',
      type: LoanProgramType.conventional,
      housingRatio: 28,
      debtRatio: 36,
      minDownPaymentPercent: 3,
      maxLoanAmount: 766550,
      miConfig: const MortgageInsuranceConfig(
        annualPercent: 0.4,
        cancelationLtvThreshold: 80,
      ),
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LoanProgram(
      id: 'fha_30',
      name: 'FHA 30-Year',
      description: 'Government-backed with 31/43 DTI, 3.5% min down',
      type: LoanProgramType.fha,
      housingRatio: 31,
      debtRatio: 43,
      minDownPaymentPercent: 3.5,
      maxLoanAmount: 472030, // Standard FHA limit 2024
      miConfig: const MortgageInsuranceConfig(
        upfrontPercent: 1.75, // UFMIP
        annualPercent: 0.85, // Annual MIP
        autoCalculate: true,
      ),
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LoanProgram(
      id: 'va_30',
      name: 'VA 30-Year',
      description: 'Veterans loan, no DTI limit, 0% down',
      type: LoanProgramType.va,
      housingRatio: 41, // VA uses residual income, this is guideline
      debtRatio: 41,
      minDownPaymentPercent: 0,
      maxLoanAmount: null, // No VA loan limit with entitlement
      miConfig: const MortgageInsuranceConfig(
        fundingFeePercent: 2.15, // First use, 0% down
        autoCalculate: true,
      ),
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LoanProgram(
      id: 'usda_30',
      name: 'USDA 30-Year',
      description: 'Rural development, 29/41 DTI, 0% down',
      type: LoanProgramType.usda,
      housingRatio: 29,
      debtRatio: 41,
      minDownPaymentPercent: 0,
      maxLoanAmount: null, // Income limits apply
      miConfig: const MortgageInsuranceConfig(
        upfrontPercent: 1.0, // Guarantee fee
        annualPercent: 0.35, // Annual fee
        autoCalculate: true,
      ),
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LoanProgram(
      id: 'jumbo_30',
      name: 'Jumbo 30-Year',
      description: 'Non-conforming loan above limits, stricter DTI',
      type: LoanProgramType.jumbo,
      housingRatio: 28,
      debtRatio: 43,
      minDownPaymentPercent: 10,
      maxLoanAmount: null, // No upper limit
      miConfig: null, // Typically no MI for jumbo
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LoanProgram(
      id: 'bank_statement',
      name: 'Bank Statement (Non-QM)',
      description: 'Self-employed, 12-24mo bank statements',
      type: LoanProgramType.nonQm,
      housingRatio: 43,
      debtRatio: 50,
      minDownPaymentPercent: 10,
      maxLoanAmount: 3000000,
      miConfig: null,
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    LoanProgram(
      id: 'dscr',
      name: 'DSCR Investment',
      description: 'Debt Service Coverage Ratio loan for investors',
      type: LoanProgramType.nonQm,
      housingRatio: 0, // Not applicable
      debtRatio: 0, // Uses DSCR instead
      minDownPaymentPercent: 20,
      maxLoanAmount: 2000000,
      miConfig: null,
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  ];
}
