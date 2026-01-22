
class ClosingCosts {
  // Loan Charges
  final double originationFee;
  final double discountPoints; // Amount, not percentage
  final double processingFee;
  final double underwritingFee;

  // Services
  final double appraisalFee;
  final double creditReportFee;
  final double floodCertificationFee;

  // Title & Escrow
  final double titleInsuranceLender;
  final double titleInsuranceOwner;
  final double settlementFee;
  final double recordingFees;
  final double transferTaxes;

  // Prepaids & Reserves
  final double prepaidInterest; // Usually calculated based on close date
  final double prepaidHomeInsurance; // 12 months usually
  final double prepaidPropertyTaxes;
  
  // Other
  final double otherFees;

  const ClosingCosts({
    this.originationFee = 0,
    this.discountPoints = 0,
    this.processingFee = 0,
    this.underwritingFee = 0,
    this.appraisalFee = 0,
    this.creditReportFee = 0,
    this.floodCertificationFee = 0,
    this.titleInsuranceLender = 0,
    this.titleInsuranceOwner = 0,
    this.settlementFee = 0,
    this.recordingFees = 0,
    this.transferTaxes = 0,
    this.prepaidInterest = 0,
    this.prepaidHomeInsurance = 0,
    this.prepaidPropertyTaxes = 0,
    this.otherFees = 0,
  });

  double get totalLoanCharges => 
      originationFee + discountPoints + processingFee + underwritingFee;

  double get totalServices => 
      appraisalFee + creditReportFee + floodCertificationFee;

  double get totalTitleEscrow => 
      titleInsuranceLender + titleInsuranceOwner + settlementFee + recordingFees + transferTaxes;

  double get totalPrepaids => 
      prepaidInterest + prepaidHomeInsurance + prepaidPropertyTaxes;

  double get total => 
      totalLoanCharges + totalServices + totalTitleEscrow + totalPrepaids + otherFees;

  ClosingCosts copyWith({
    double? originationFee,
    double? discountPoints,
    double? processingFee,
    double? underwritingFee,
    double? appraisalFee,
    double? creditReportFee,
    double? floodCertificationFee,
    double? titleInsuranceLender,
    double? titleInsuranceOwner,
    double? settlementFee,
    double? recordingFees,
    double? transferTaxes,
    double? prepaidInterest,
    double? prepaidHomeInsurance,
    double? prepaidPropertyTaxes,
    double? otherFees,
  }) {
    return ClosingCosts(
      originationFee: originationFee ?? this.originationFee,
      discountPoints: discountPoints ?? this.discountPoints,
      processingFee: processingFee ?? this.processingFee,
      underwritingFee: underwritingFee ?? this.underwritingFee,
      appraisalFee: appraisalFee ?? this.appraisalFee,
      creditReportFee: creditReportFee ?? this.creditReportFee,
      floodCertificationFee: floodCertificationFee ?? this.floodCertificationFee,
      titleInsuranceLender: titleInsuranceLender ?? this.titleInsuranceLender,
      titleInsuranceOwner: titleInsuranceOwner ?? this.titleInsuranceOwner,
      settlementFee: settlementFee ?? this.settlementFee,
      recordingFees: recordingFees ?? this.recordingFees,
      transferTaxes: transferTaxes ?? this.transferTaxes,
      prepaidInterest: prepaidInterest ?? this.prepaidInterest,
      prepaidHomeInsurance: prepaidHomeInsurance ?? this.prepaidHomeInsurance,
      prepaidPropertyTaxes: prepaidPropertyTaxes ?? this.prepaidPropertyTaxes,
      otherFees: otherFees ?? this.otherFees,
    );
  }

  // Factory for default/estimated costs based on loan amount and price
  factory ClosingCosts.estimate({
    required double loanAmount, 
    required double price,
  }) {
    // Rough industry estimates
    return ClosingCosts(
      originationFee: 0, // Often 0 or 1%
      processingFee: 500,
      underwritingFee: 500,
      appraisalFee: 500,
      creditReportFee: 50,
      floodCertificationFee: 20,
      titleInsuranceLender: loanAmount * 0.005, // approx 0.5%
      titleInsuranceOwner: price * 0.003, // approx 0.3%
      settlementFee: 1000,
      recordingFees: 150,
      transferTaxes: 0, // Highly variable by location
      // Prepaids calculated separately usually, but we can zero them for base structure
    );
  }
}
