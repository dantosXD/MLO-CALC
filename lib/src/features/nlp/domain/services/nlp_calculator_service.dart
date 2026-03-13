import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class NLPCalculatorService {
  GenerativeModel? _model;
  bool _isInitialized = false;
  String? _activeApiKey;

  /// Initialize the service with Gemini API key
  /// Users should set their API key via environment variable or settings
  Future<void> initialize(String apiKey) async {
    final normalizedKey = apiKey.trim();
    if (normalizedKey.isEmpty) {
      _isInitialized = false;
      _model = null;
      _activeApiKey = null;
      throw Exception('API key is empty');
    }

    if (_isInitialized && _activeApiKey == normalizedKey) {
      return;
    }

    try {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: normalizedKey);
      _isInitialized = true;
      _activeApiKey = normalizedKey;
    } catch (e) {
      developer.log(
        'Error initializing NLP service',
        name: 'NLPCalculatorService',
        error: e,
      );
      _isInitialized = false;
      _activeApiKey = null;
    }
  }

  bool get isInitialized => _isInitialized;

  /// Process natural language query and extract loan parameters
  Future<CalculationRequest> processQuery(String query) async {
    if (!_isInitialized || _model == null) {
      throw Exception(
        'NLP service not initialized. Please set your Gemini API key.',
      );
    }

    // Input Sanitization
    String sanitizedQuery = query.trim();
    
    // Remove control characters (keeping newlines/tabs is usually fine for natural language, 
    // but let's remove non-printable characters just in case)
    sanitizedQuery = sanitizedQuery.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    if (sanitizedQuery.isEmpty) {
      throw Exception('Query is empty.');
    }

    // Limit query length to prevent excessive token usage
    if (sanitizedQuery.length > 500) {
       sanitizedQuery = sanitizedQuery.substring(0, 500);
    }

    final prompt =
        '''
You are a mortgage calculator assistant. Your task is to parse natural language queries related to mortgage calculations and extract specific loan parameters into a structured JSON format.

Query: "$sanitizedQuery"

Instructions:
1. Analyze the user's intent.
2. Extract numerical values for loan parameters.
   - Handle common abbreviations: "k" or "grand" = 1,000, "m" or "mil" = 1,000,000.
   - Handle "percent" or "%" for interest rates.
   - Distinguish between monthly values (payment, expenses, debt) and annual values (income, tax, insurance) based on context if specified, otherwise assume standard conventions (Income is usually annual, HOA is monthly).
3. Determine the "action" based on what the user is asking to find.

Return ONLY a valid JSON object with the following schema (use null if a value is not present or cannot be inferred):

{
  "action": "calculate_payment" | "calculate_loan_amount" | "calculate_term" | "calculate_interest_rate" | "calculate_max_qualifying_loan" | "calculate_min_income" | "generate_amortization" | "calculate_biweekly",
  "loanAmount": number | null,
  "interestRate": number | null (e.g., 5.5 for 5.5%),
  "termYears": number | null,
  "payment": number | null,
  "price": number | null,
  "downPayment": number | null,
  "propertyTax": number | null (annual amount),
  "homeInsurance": number | null (annual amount),
  "mortgageInsurance": number | null (annual amount),
  "monthlyExpenses": number | null (HOA/Strata fees),
  "annualIncome": number | null,
  "monthlyDebt": number | null,
  "explanation": "A brief, friendly sentence explaining what you are calculating."
}

Examples:
- "Payment for 350k at 5.5 percent for 30 years" 
  -> {"action": "calculate_payment", "loanAmount": 350000, "interestRate": 5.5, "termYears": 30, "explanation": "Calculating monthly payment for a \$350,000 loan."}
  
- "Max loan with 100k income and 500 monthly debt" 
  -> {"action": "calculate_max_qualifying_loan", "annualIncome": 100000, "monthlyDebt": 500, "explanation": "Calculating maximum loan amount based on your income and debts."}
  
- "How much house for 2500 a month at 6.5?" 
  -> {"action": "calculate_loan_amount", "payment": 2500, "interestRate": 6.5, "explanation": "Calculating affordable loan amount for a \$2,500 monthly payment."}

- "Amortization for 400000 loan"
  -> {"action": "generate_amortization", "loanAmount": 400000, "explanation": "Generating amortization schedule for \$400,000."}

Notes:
- Do not include markdown formatting (like ```json).
- Return ONLY the JSON object.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      // Clean up the response (remove markdown code blocks if present)
      final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
      final Match? match = jsonRegex.firstMatch(responseText);
      
      if (match == null) {
        throw Exception('No JSON found in response');
      }
      
      final String cleanedResponse = match.group(0)!;

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
  final double? mortgageInsurance;
  final double? monthlyExpenses;
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
    this.mortgageInsurance,
    this.monthlyExpenses,
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
      mortgageInsurance: _toDouble(json['mortgageInsurance']),
      monthlyExpenses: _toDouble(json['monthlyExpenses']),
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
      'mortgageInsurance': mortgageInsurance,
      'monthlyExpenses': monthlyExpenses,
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
