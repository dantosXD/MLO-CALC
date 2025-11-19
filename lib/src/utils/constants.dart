/// Application constants used across the app
library;

import 'package:flutter/material.dart';

class AppConstants {
  // Private constructor
  AppConstants._();

  // -- UI Colors --

  // Base theme color
  static const Color baseColor = Color(0xFF2C3E50);

  // Mic button states
  static const Color micIdleColor = Color(0xFF3498DB); // Brighter blue
  static const Color micListeningColor = Color(0xFF2ECC71); // Modern green
  static const Color micProcessingColor = Color(0xFFF39C12); // Warm amber
  static const Color micErrorColor = Color(0xFFE74C3C); // Clear red

  // Backspace button colors
  static const Color backspaceNormalColor = Color(0xFFD35400); // Pumpkin orange
  static const Color backspaceActiveColor = Color(0xFFE67E22); // Lighter orange
  static const Color backspaceClearColor = Color(0xFFC0392B); // Dark red

  // Other button colors
  static const Color functionButtonColor = Color(0xFF3A5062);
  static const Color operatorButtonColor = Color(0xFF4A6278);
  static const Color numberButtonColor = Color(0xFF34495E);
  static const Color clearButtonColor = Color(0xFF8B3A3A);
  static const Color equalsButtonColor = Color(0xFFE67E22);
  static const Color infoButtonColor = Color(0xFF4A6278);

  // -- Limits --

  // Interest Rate
  static const double minInterestRate = 0.1; // 0.1%
  static const double maxInterestRate = 30.0; // 30%

  // Loan Amount
  static const double minLoanAmount = 1000.0;
  static const double maxLoanAmount = 100000000.0; // $100M

  // Term
  static const double minTermYears = 1.0;
  static const double maxTermYears = 40.0;

  // Payment
  static const double maxPayment = 1000000.0; // $1M/month

  // Property Price
  static const double minPrice = 10000.0;
  static const double maxPrice = 200000000.0; // $200M

  // Taxes & Insurance
  static const double maxPropertyTax = 1000000.0; // $1M/year
  static const double maxInsurance = 100000.0; // $100K/year
  static const double maxMonthlyExpenses = 50000.0; // $50K/month

  // Income & Debt
  static const double minAnnualIncome = 1000.0;
  static const double maxAnnualIncome = 100000000.0; // $100M
  static const double maxMonthlyDebt = 500000.0; // $500K/month

  // Input Limits
  static const int maxInputLength = 15;
}
