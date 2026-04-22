import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/closing_costs.dart';
import 'package:provider/provider.dart';

class ClosingCostsSheet extends StatefulWidget {
  const ClosingCostsSheet({super.key});

  @override
  State<ClosingCostsSheet> createState() => _ClosingCostsSheetState();
}

class _ClosingCostsSheetState extends State<ClosingCostsSheet> {
  // Controllers
  final _originationController = TextEditingController();
  final _pointsController = TextEditingController();
  final _processingController = TextEditingController();
  final _underwritingController = TextEditingController();
  final _appraisalController = TextEditingController();
  final _creditReportController = TextEditingController();
  final _floodCertController = TextEditingController();
  final _titleLenderController = TextEditingController();
  final _titleOwnerController = TextEditingController();
  final _settlementController = TextEditingController();
  final _recordingController = TextEditingController();
  final _transferTaxController = TextEditingController();
  final _prepaidInterestController = TextEditingController();
  final _prepaidInsuranceController = TextEditingController();
  final _prepaidTaxController = TextEditingController();
  final _otherFeesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() {
    final costs = context.read<CalculatorProvider>().closingCosts;
    _originationController.text = costs.originationFee.toStringAsFixed(2);
    _pointsController.text = costs.discountPoints.toStringAsFixed(2);
    _processingController.text = costs.processingFee.toStringAsFixed(2);
    _underwritingController.text = costs.underwritingFee.toStringAsFixed(2);
    _appraisalController.text = costs.appraisalFee.toStringAsFixed(2);
    _creditReportController.text = costs.creditReportFee.toStringAsFixed(2);
    _floodCertController.text = costs.floodCertificationFee.toStringAsFixed(2);
    _titleLenderController.text = costs.titleInsuranceLender.toStringAsFixed(2);
    _titleOwnerController.text = costs.titleInsuranceOwner.toStringAsFixed(2);
    _settlementController.text = costs.settlementFee.toStringAsFixed(2);
    _recordingController.text = costs.recordingFees.toStringAsFixed(2);
    _transferTaxController.text = costs.transferTaxes.toStringAsFixed(2);
    _prepaidInterestController.text = costs.prepaidInterest.toStringAsFixed(2);
    _prepaidInsuranceController.text = costs.prepaidHomeInsurance
        .toStringAsFixed(2);
    _prepaidTaxController.text = costs.prepaidPropertyTaxes.toStringAsFixed(2);
    _otherFeesController.text = costs.otherFees.toStringAsFixed(2);
  }

  void _updateCosts() {
    final provider = context.read<CalculatorProvider>();
    final newCosts = ClosingCosts(
      originationFee: double.tryParse(_originationController.text) ?? 0,
      discountPoints: double.tryParse(_pointsController.text) ?? 0,
      processingFee: double.tryParse(_processingController.text) ?? 0,
      underwritingFee: double.tryParse(_underwritingController.text) ?? 0,
      appraisalFee: double.tryParse(_appraisalController.text) ?? 0,
      creditReportFee: double.tryParse(_creditReportController.text) ?? 0,
      floodCertificationFee: double.tryParse(_floodCertController.text) ?? 0,
      titleInsuranceLender: double.tryParse(_titleLenderController.text) ?? 0,
      titleInsuranceOwner: double.tryParse(_titleOwnerController.text) ?? 0,
      settlementFee: double.tryParse(_settlementController.text) ?? 0,
      recordingFees: double.tryParse(_recordingController.text) ?? 0,
      transferTaxes: double.tryParse(_transferTaxController.text) ?? 0,
      prepaidInterest: double.tryParse(_prepaidInterestController.text) ?? 0,
      prepaidHomeInsurance:
          double.tryParse(_prepaidInsuranceController.text) ?? 0,
      prepaidPropertyTaxes: double.tryParse(_prepaidTaxController.text) ?? 0,
      otherFees: double.tryParse(_otherFeesController.text) ?? 0,
    );
    provider.updateClosingCosts(newCosts);
  }

  @override
  void dispose() {
    _originationController.dispose();
    _pointsController.dispose();
    _processingController.dispose();
    _underwritingController.dispose();
    _appraisalController.dispose();
    _creditReportController.dispose();
    _floodCertController.dispose();
    _titleLenderController.dispose();
    _titleOwnerController.dispose();
    _settlementController.dispose();
    _recordingController.dispose();
    _transferTaxController.dispose();
    _prepaidInterestController.dispose();
    _prepaidInsuranceController.dispose();
    _prepaidTaxController.dispose();
    _otherFeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final estimateButton = TextButton.icon(
                      onPressed: () {
                        context
                            .read<CalculatorProvider>()
                            .estimateClosingCosts();
                        _loadValues();
                      },
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Estimate'),
                    );

                    if (constraints.maxWidth < 420) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Closing Costs Breakdown',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: estimateButton,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Closing Costs Breakdown',
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        estimateButton,
                      ],
                    );
                  },
                ),
              ),

              const Divider(),

              // Form
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionTitle(context, 'Loan Charges'),
                    _buildInput('Origination Fee', _originationController),
                    _buildInput('Discount Points (\$)', _pointsController),
                    _buildInput('Processing Fee', _processingController),
                    _buildInput('Underwriting Fee', _underwritingController),

                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Services'),
                    _buildInput('Appraisal', _appraisalController),
                    _buildInput('Credit Report', _creditReportController),
                    _buildInput('Flood Certification', _floodCertController),

                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Title & Escrow'),
                    _buildInput(
                      'Lender Title Insurance',
                      _titleLenderController,
                    ),
                    _buildInput('Owner Title Insurance', _titleOwnerController),
                    _buildInput(
                      'Settlement/Closing Fee',
                      _settlementController,
                    ),
                    _buildInput('Recording Fees', _recordingController),
                    _buildInput('Transfer Taxes', _transferTaxController),

                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Prepaids & Reserves'),
                    _buildInput('Prepaid Interest', _prepaidInterestController),
                    _buildInput(
                      'Prepaid Home Insurance',
                      _prepaidInsuranceController,
                    ),
                    _buildInput(
                      'Prepaid Property Taxes',
                      _prepaidTaxController,
                    ),

                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Other'),
                    _buildInput('Other Fees', _otherFeesController),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Footer Summary
              Consumer<CalculatorProvider>(
                builder: (context, provider, child) {
                  final closingCosts = provider.closingCosts.total;
                  final cashToClose = provider.cashToClose;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          context,
                          'Total Closing Costs',
                          closingCosts,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          context,
                          'Estimated Cash to Close',
                          cashToClose,
                          isTotal: true,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixText: '\$ ',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        onChanged: (_) => _updateCosts(),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          CurrencyFormatter.formatCurrency(value),
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
