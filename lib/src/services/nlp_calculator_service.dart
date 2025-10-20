import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class NLPCalculatorService {
  GenerativeModel? _model;
  bool _isInitialized = false;

  /// Initialize the service with Gemini API key
  /// Users should set their API key via environment variable or settings
  Future<void> initialize(String apiKey) async {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      _isInitialized = true;
    } catch (e) {
      developer.log(
        'Error initializing NLP service',
        name: 'NLPCalculatorService',
        error: e,
      );
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;

  /// Process natural language query and extract loan parameters
  Future<CalculationRequest> processQuery(String query) async {
    if (!_isInitialized || _model == null) {
      throw Exception('NLP service not initialized. Please set your Gemini API key.');
    }

    final prompt = '''
You are a mortgage calculator assistant. Parse the following natural language query and extract loan parameters.

Query: "$query"

Extract and return ONLY a JSON object with these fields (use null for missing values):
{
  "action": "calculate_payment" | "calculate_loan_amount" | "calculate_term" | "calculate_interest_rate" | "calculate_max_qualifying_loan" | "calculate_min_income" | "generate_amortization" | "calculate_biweekly",
  "loanAmount": number or null,
  "interestRate": number or null (as percentage, e.g., 5.5 for 5.5%),
  "termYears": number or null,
  "payment": number or null,
  "price": number or null,
  "downPayment": number or null,
  "propertyTax": number or null (annual),
  "homeInsurance": number or null (annual),
  "annualIncome": number or null,
  "monthlyDebt": number or null,
  "explanation": "Brief explanation of what will be calculated"
}

Examples:
- "Calculate payment for a 350000 dollar loan at 5.5% for 30 years" → {"action": "calculate_payment", "loanAmount": 350000, "interestRate": 5.5, "termYears": 30, ...}
- "What's my max loan with 100k income and 6% rate for 30 years?" → {"action": "calculate_max_qualifying_loan", "annualIncome": 100000, "interestRate": 6, "termYears": 30, ...}
- "How much house can I afford with a 2500 monthly payment at 5% for 15 years?" → {"action": "calculate_loan_amount", "payment": 2500, "interestRate": 5, "termYears": 15, ...}

Return ONLY the JSON, no additional text.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      // Clean up the response (remove markdown code blocks if present)
      String cleanedResponse = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Parse JSON
      final jsonData = json.decode(cleanedResponse);
      return CalculationRequest.fromJson(jsonData);
    } catch (e) {
      throw Exception('Error processing query: $e');
    }
  }

  /// Get suggestions for common queries
  List<String> getSuggestions() {
    return [
      'Calculate payment for a \$350,000 loan at 5.5% for 30 years',
      'What\'s my max loan with \$100,000 income?',
      'Show me the amortization schedule',
      'Compare biweekly vs monthly payments',
      'Calculate minimum income needed for a \$400,000 loan at 6%',
      'What interest rate do I need for a \$2,000 monthly payment on \$300,000?',
      'How much house can I afford earning \$120,000 per year?',
    ];
  }
}

class CalculationRequest {
  final String action;
  final double? loanAmount;
  final double? interestRate;
  final double? termYears;
  final double? payment;
  final double? price;
  final double? downPayment;
  final double? propertyTax;
  final double? homeInsurance;
  final double? annualIncome;
  final double? monthlyDebt;
  final String explanation;

  CalculationRequest({
    required this.action,
    this.loanAmount,
    this.interestRate,
    this.termYears,
    this.payment,
    this.price,
    this.downPayment,
    this.propertyTax,
    this.homeInsurance,
    this.annualIncome,
    this.monthlyDebt,
    required this.explanation,
  });

  factory CalculationRequest.fromJson(Map<String, dynamic> json) {
    return CalculationRequest(
      action: json['action'] ?? 'unknown',
      loanAmount: _toDouble(json['loanAmount']),
      interestRate: _toDouble(json['interestRate']),
      termYears: _toDouble(json['termYears']),
      payment: _toDouble(json['payment']),
      price: _toDouble(json['price']),
      downPayment: _toDouble(json['downPayment']),
      propertyTax: _toDouble(json['propertyTax']),
      homeInsurance: _toDouble(json['homeInsurance']),
      annualIncome: _toDouble(json['annualIncome']),
      monthlyDebt: _toDouble(json['monthlyDebt']),
      explanation: json['explanation'] ?? 'Calculation requested',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'loanAmount': loanAmount,
      'interestRate': interestRate,
      'termYears': termYears,
      'payment': payment,
      'price': price,
      'downPayment': downPayment,
      'propertyTax': propertyTax,
      'homeInsurance': homeInsurance,
      'annualIncome': annualIncome,
      'monthlyDebt': monthlyDebt,
      'explanation': explanation,
    };
  }

  @override
  String toString() {
    return 'CalculationRequest(action: $action, explanation: $explanation)';
  }
}
