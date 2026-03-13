import 'package:loan_ranger/src/core/scenarios/scenario_definition.dart';
import 'package:loan_ranger/src/core/scenarios/scenario_field.dart';
import 'package:loan_ranger/src/core/scenarios/scenario_result.dart';

class ScenarioCatalog {
  static const String purchaseQuoteId = 'purchase_quote';
  static const String qualificationMaxLoanId = 'qualification_max_loan';

  static final List<ScenarioDefinition> defaults = <ScenarioDefinition>[
    ScenarioDefinition(
      id: purchaseQuoteId,
      title: 'Purchase Quote',
      category: 'Quote',
      inputSchema: const <ScenarioField>[
        ScenarioField(key: 'price', type: ScenarioFieldType.currency, label: 'Price'),
        ScenarioField(key: 'downPayment', type: ScenarioFieldType.currency, label: 'Down Payment'),
        ScenarioField(key: 'loanAmount', type: ScenarioFieldType.currency, label: 'Loan Amount'),
        ScenarioField(key: 'interestRate', type: ScenarioFieldType.percent, label: 'Interest Rate'),
        ScenarioField(key: 'termYears', type: ScenarioFieldType.years, label: 'Term'),
        ScenarioField(key: 'propertyTax', type: ScenarioFieldType.annualCurrency, label: 'Property Tax'),
        ScenarioField(key: 'homeInsurance', type: ScenarioFieldType.annualCurrency, label: 'Home Insurance'),
        ScenarioField(key: 'mortgageInsurance', type: ScenarioFieldType.annualCurrency, label: 'Mortgage Insurance'),
        ScenarioField(key: 'monthlyExpenses', type: ScenarioFieldType.monthlyCurrency, label: 'Monthly Expenses'),
      ],
      resultSchema: const <ScenarioResult>[
        ScenarioResult(key: 'payment', type: ScenarioFieldType.monthlyCurrency, label: 'Payment'),
        ScenarioResult(key: 'pitiPayment', type: ScenarioFieldType.monthlyCurrency, label: 'PITI Payment'),
        ScenarioResult(key: 'cashToClose', type: ScenarioFieldType.currency, label: 'Cash To Close'),
      ],
      actions: <String>['calculate_payment', 'calculate_loan_amount', 'calculate_term', 'calculate_interest_rate'],
      shareTemplateIds: <String>['mortgage-quote-email', 'mortgage-quote-sms'],
      supportedNlpIntents: <String>['update_inputs_and_run', 'share_quote'],
    ),
    ScenarioDefinition(
      id: qualificationMaxLoanId,
      title: 'Qualification Max Loan',
      category: 'Qualification',
      inputSchema: const <ScenarioField>[
        ScenarioField(key: 'annualIncome', type: ScenarioFieldType.annualCurrency, label: 'Annual Income'),
        ScenarioField(key: 'monthlyDebt', type: ScenarioFieldType.monthlyCurrency, label: 'Monthly Debt'),
        ScenarioField(key: 'interestRate', type: ScenarioFieldType.percent, label: 'Interest Rate'),
        ScenarioField(key: 'termYears', type: ScenarioFieldType.years, label: 'Term'),
      ],
      resultSchema: const <ScenarioResult>[
        ScenarioResult(key: 'maxLoanAmount', type: ScenarioFieldType.currency, label: 'Max Loan Amount'),
      ],
      actions: <String>['calculate_max_qualifying_loan', 'calculate_min_income'],
      supportedNlpIntents: <String>['qualify_borrower'],
    ),
  ];

  const ScenarioCatalog();

  ScenarioDefinition? byId(String id) {
    for (final definition in defaults) {
      if (definition.id == id) {
        return definition;
      }
    }
    return null;
  }
}
