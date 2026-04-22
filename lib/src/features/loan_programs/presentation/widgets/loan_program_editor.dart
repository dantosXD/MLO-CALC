import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/loan_programs_provider.dart';
import '../../domain/models/loan_program.dart';

class LoanProgramEditor extends StatefulWidget {
  final LoanProgram? program;

  const LoanProgramEditor({super.key, this.program});

  @override
  State<LoanProgramEditor> createState() => _LoanProgramEditorState();
}

class _LoanProgramEditorState extends State<LoanProgramEditor> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _housingRatioController;
  late TextEditingController _debtRatioController;
  late TextEditingController _minDownPaymentController;
  late TextEditingController _maxLoanAmountController;
  late TextEditingController _upfrontMiController;
  late TextEditingController _annualMiController;
  late TextEditingController _fundingFeeController;
  late TextEditingController _miCancelLtvController;

  LoanProgramType _selectedType = LoanProgramType.custom;
  bool _hasMiConfig = false;
  bool _autoCalculateMi = true;
  bool _isSaving = false;

  bool get isEditing => widget.program != null;

  @override
  void initState() {
    super.initState();
    final p = widget.program;

    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _housingRatioController = TextEditingController(
      text: p?.housingRatio.toString() ?? '28',
    );
    _debtRatioController = TextEditingController(
      text: p?.debtRatio.toString() ?? '36',
    );
    _minDownPaymentController = TextEditingController(
      text: p?.minDownPaymentPercent.toString() ?? '3',
    );
    _maxLoanAmountController = TextEditingController(
      text: p?.maxLoanAmount?.toString() ?? '',
    );

    // MI Config
    _upfrontMiController = TextEditingController(
      text: p?.miConfig?.upfrontPercent?.toString() ?? '',
    );
    _annualMiController = TextEditingController(
      text: p?.miConfig?.annualPercent?.toString() ?? '',
    );
    _fundingFeeController = TextEditingController(
      text: p?.miConfig?.fundingFeePercent?.toString() ?? '',
    );
    _miCancelLtvController = TextEditingController(
      text: p?.miConfig?.cancelationLtvThreshold?.toString() ?? '80',
    );

    _selectedType = p?.type ?? LoanProgramType.custom;
    _hasMiConfig = p?.miConfig != null;
    _autoCalculateMi = p?.miConfig?.autoCalculate ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _housingRatioController.dispose();
    _debtRatioController.dispose();
    _minDownPaymentController.dispose();
    _maxLoanAmountController.dispose();
    _upfrontMiController.dispose();
    _annualMiController.dispose();
    _fundingFeeController.dispose();
    _miCancelLtvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 420;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Program' : 'New Program'),
        actions: [
          if (isNarrow)
            IconButton(
              onPressed: _isSaving ? null : _save,
              tooltip: 'Save',
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
            )
          else
            TextButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            _SectionHeader(title: 'Basic Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Program Name *',
                hintText: 'e.g., My Custom FHA',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of the program',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LoanProgramType>(
              // ignore: deprecated_member_use
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Program Type',
                border: OutlineInputBorder(),
              ),
              items: LoanProgramType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                  _applyTypeDefaults(value);
                }
              },
            ),

            const SizedBox(height: 24),

            // DTI Ratios Section
            _SectionHeader(title: 'Qualifying Ratios'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _housingRatioController,
                    decoration: const InputDecoration(
                      labelText: 'Housing Ratio (%) *',
                      hintText: '28',
                      border: OutlineInputBorder(),
                      helperText: 'Front-end DTI',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val < 0 || val > 100) {
                        return 'Enter 0-100';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _debtRatioController,
                    decoration: const InputDecoration(
                      labelText: 'Debt Ratio (%) *',
                      hintText: '36',
                      border: OutlineInputBorder(),
                      helperText: 'Back-end DTI',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val < 0 || val > 100) {
                        return 'Enter 0-100';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Loan Limits Section
            _SectionHeader(title: 'Loan Limits'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minDownPaymentController,
                    decoration: const InputDecoration(
                      labelText: 'Min Down Payment (%) *',
                      hintText: '3',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val < 0 || val > 100) {
                        return 'Enter 0-100';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxLoanAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Max Loan Amount',
                      hintText: 'e.g., 766550',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Mortgage Insurance Section
            _SectionHeader(title: 'Mortgage Insurance'),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Has Mortgage Insurance'),
              subtitle: const Text('Configure MI/MIP/Funding Fee'),
              value: _hasMiConfig,
              onChanged: (value) => setState(() => _hasMiConfig = value),
            ),

            if (_hasMiConfig) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Auto-calculate MI'),
                subtitle: const Text('Calculate based on LTV and credit'),
                value: _autoCalculateMi,
                onChanged: (value) => setState(() => _autoCalculateMi = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _upfrontMiController,
                      decoration: const InputDecoration(
                        labelText: 'Upfront MI (%)',
                        hintText: '1.75',
                        border: OutlineInputBorder(),
                        helperText: 'UFMIP/Guarantee',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _annualMiController,
                      decoration: const InputDecoration(
                        labelText: 'Annual MI (%)',
                        hintText: '0.85',
                        border: OutlineInputBorder(),
                        helperText: 'Annual MIP',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fundingFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Funding Fee (%)',
                        hintText: '2.15',
                        border: OutlineInputBorder(),
                        helperText: 'VA Funding Fee',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _miCancelLtvController,
                      decoration: const InputDecoration(
                        labelText: 'Cancel at LTV (%)',
                        hintText: '80',
                        border: OutlineInputBorder(),
                        helperText: 'MI removal threshold',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _applyTypeDefaults(LoanProgramType type) {
    switch (type) {
      case LoanProgramType.conventional:
        _housingRatioController.text = '28';
        _debtRatioController.text = '36';
        _minDownPaymentController.text = '3';
        _maxLoanAmountController.text = '766550';
        _hasMiConfig = true;
        _annualMiController.text = '0.5';
        _miCancelLtvController.text = '80';
        break;
      case LoanProgramType.fha:
        _housingRatioController.text = '31';
        _debtRatioController.text = '43';
        _minDownPaymentController.text = '3.5';
        _maxLoanAmountController.text = '472030';
        _hasMiConfig = true;
        _upfrontMiController.text = '1.75';
        _annualMiController.text = '0.85';
        break;
      case LoanProgramType.va:
        _housingRatioController.text = '41';
        _debtRatioController.text = '41';
        _minDownPaymentController.text = '0';
        _maxLoanAmountController.text = '';
        _hasMiConfig = true;
        _fundingFeeController.text = '2.15';
        break;
      case LoanProgramType.usda:
        _housingRatioController.text = '29';
        _debtRatioController.text = '41';
        _minDownPaymentController.text = '0';
        _maxLoanAmountController.text = '';
        _hasMiConfig = true;
        _upfrontMiController.text = '1.0';
        _annualMiController.text = '0.35';
        break;
      case LoanProgramType.jumbo:
        _housingRatioController.text = '28';
        _debtRatioController.text = '43';
        _minDownPaymentController.text = '10';
        _maxLoanAmountController.text = '';
        _hasMiConfig = false;
        break;
      case LoanProgramType.nonQm:
        _housingRatioController.text = '43';
        _debtRatioController.text = '50';
        _minDownPaymentController.text = '10';
        _maxLoanAmountController.text = '';
        _hasMiConfig = false;
        break;
      case LoanProgramType.custom:
        // Keep current values
        break;
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<LoanProgramsProvider>();

      MortgageInsuranceConfig? miConfig;
      if (_hasMiConfig) {
        miConfig = MortgageInsuranceConfig(
          upfrontPercent: double.tryParse(_upfrontMiController.text),
          annualPercent: double.tryParse(_annualMiController.text),
          fundingFeePercent: double.tryParse(_fundingFeeController.text),
          autoCalculate: _autoCalculateMi,
          cancelationLtvThreshold: double.tryParse(_miCancelLtvController.text),
        );
      }

      if (isEditing) {
        // Update existing
        final updated = widget.program!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text,
          type: _selectedType,
          housingRatio: double.parse(_housingRatioController.text),
          debtRatio: double.parse(_debtRatioController.text),
          minDownPaymentPercent: double.parse(_minDownPaymentController.text),
          maxLoanAmount: double.tryParse(_maxLoanAmountController.text),
          miConfig: miConfig,
        );
        await provider.updateProgram(updated);
      } else {
        // Create new
        await provider.addProgram(
          name: _nameController.text,
          description: _descriptionController.text,
          type: _selectedType,
          housingRatio: double.parse(_housingRatioController.text),
          debtRatio: double.parse(_debtRatioController.text),
          minDownPaymentPercent: double.parse(_minDownPaymentController.text),
          maxLoanAmount: double.tryParse(_maxLoanAmountController.text),
          miConfig: miConfig,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Program updated' : 'Program created'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
      ],
    );
  }
}
