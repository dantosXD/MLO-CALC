import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/core/validators/enhanced_validators.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/qualification/application/providers/qualifying_ratios_provider.dart';
import 'package:provider/provider.dart';

class QualificationScreen extends StatefulWidget {
  const QualificationScreen({super.key});

  @override
  State<QualificationScreen> createState() => _QualificationScreenState();
}

class _QualificationScreenState extends State<QualificationScreen> {
  final _incomeController = TextEditingController();
  final _debtController = TextEditingController();
  final _incomeFocusNode = FocusNode();
  final _debtFocusNode = FocusNode();
  CalculatorProvider? _calculatorProvider;
  Listenable? _calcListenable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<CalculatorProvider>();
    if (!identical(_calculatorProvider, nextProvider)) {
      _calculatorProvider?.removeListener(_syncFormFieldsFromProvider);
      _calculatorProvider = nextProvider;
      _calculatorProvider?.addListener(_syncFormFieldsFromProvider);
      _calcListenable = Listenable.merge([
        nextProvider.loanQuoteController,
        nextProvider.qualificationController,
      ]);
    }
    _syncFormFieldsFromProvider();
  }

  @override
  void dispose() {
    _calculatorProvider?.removeListener(_syncFormFieldsFromProvider);
    _incomeController.dispose();
    _debtController.dispose();
    _incomeFocusNode.dispose();
    _debtFocusNode.dispose();
    super.dispose();
  }

  void _syncFormFieldsFromProvider() {
    final provider = _calculatorProvider;
    if (provider == null) return;

    if (!_incomeFocusNode.hasFocus) {
      _syncTextController(
        _incomeController,
        provider.annualIncome != null
            ? provider.annualIncome!.toStringAsFixed(0)
            : '',
      );
    }

    if (!_debtFocusNode.hasFocus) {
      _syncTextController(
        _debtController,
        provider.monthlyDebt != null
            ? provider.monthlyDebt!.toStringAsFixed(2)
            : '',
      );
    }
  }

  void _syncTextController(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final calculatorProvider = context.read<CalculatorProvider>();
    final ratiosProvider = context.watch<QualifyingRatiosProvider>();

    if (ratiosProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedRatio =
        ratiosProvider.selectedRatio ?? DefaultQualifyingRatios.ratios.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Qualifying Ratios Card — no calculator dependency, only rebuilds with ratiosProvider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Qualifying Ratios',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: 'Add Custom Ratio',
                            onPressed: () => _showRatioEditor(context, null),
                          ),
                          IconButton(
                            icon: const Icon(Icons.list),
                            tooltip: 'Manage Ratios',
                            onPressed: () => _showRatiosList(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ratio dropdown
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Select Ratio',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRatio.id,
                        isExpanded: true,
                        isDense: true,
                        items: ratiosProvider.allRatios.map((ratio) {
                          return DropdownMenuItem<String>(
                            value: ratio.id,
                            child: Text(ratio.displayName),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            final ratio = ratiosProvider.getRatioById(id);
                            if (ratio != null) {
                              ratiosProvider.selectRatio(ratio);
                              calculatorProvider.setQualRatio1(ratio);
                            }
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Selected ratio details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Front-end DTI (Housing):',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              CurrencyFormatter.formatPercent(
                                selectedRatio.housingRatio,
                                decimals: 2,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Back-end DTI (Total Debt):',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              CurrencyFormatter.formatPercent(
                                selectedRatio.debtRatio,
                                decimals: 2,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (selectedRatio.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            selectedRatio.description!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (!selectedRatio.isBuiltIn) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          onPressed: () =>
                              _showRatioEditor(context, selectedRatio),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Borrower Information Card — form synced via listeners, no rebuild needed
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Borrower Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _incomeController,
                    focusNode: _incomeFocusNode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Annual Income',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      helperText: 'Gross annual income',
                    ),
                    onChanged: (value) {
                      final income = double.tryParse(value);
                      calculatorProvider.setAnnualIncome(value: income);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _debtController,
                    focusNode: _debtFocusNode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Debt Payments',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      helperText: 'Total monthly debt obligations',
                    ),
                    onChanged: (value) {
                      final debt = double.tryParse(value);
                      calculatorProvider.setMonthlyDebt(value: debt);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic sections — only rebuild when calculator controllers fire
          ListenableBuilder(
            listenable: _calcListenable!,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Loan Parameters Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loan Parameters',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Interest Rate',
                          value: calculatorProvider.interestRate != null
                              ? CurrencyFormatter.formatPercent(
                                  calculatorProvider.interestRate,
                                  decimals: 3,
                                )
                              : 'Not set',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Term',
                          value: calculatorProvider.termYears != null
                              ? '${calculatorProvider.termYears!.toStringAsFixed(0)} years'
                              : 'Not set',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Loan Amount',
                          value: calculatorProvider.loanAmount != null
                              ? CurrencyFormatter.formatCurrency(
                                  calculatorProvider.loanAmount,
                                )
                              : 'Not set',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Set these values in the Calculator tab',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Calculation Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            calculatorProvider.annualIncome != null &&
                                calculatorProvider.interestRate != null &&
                                calculatorProvider.termYears != null
                            ? () {
                                calculatorProvider.calculateMaxQualifyingLoan(
                                  useRatio1: true,
                                );
                                _showResultDialog(
                                  context,
                                  'Maximum Qualifying Loan',
                                  'Based on your income and debt ratios, you qualify for a maximum loan amount of:',
                                  calculatorProvider.loanAmount,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.trending_up),
                        label: const Text('Max Loan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            calculatorProvider.loanAmount != null &&
                                calculatorProvider.interestRate != null &&
                                calculatorProvider.termYears != null
                            ? () {
                                calculatorProvider.calculateMinimumIncome(
                                  useRatio1: true,
                                );
                                _showResultDialog(
                                  context,
                                  'Minimum Required Income',
                                  'To qualify for this loan, you need a minimum annual income of:',
                                  calculatorProvider.annualIncome,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.attach_money),
                        label: const Text('Min Income'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // DTI & LTV Warnings
                if (calculatorProvider.annualIncome != null &&
                    calculatorProvider.payment != null) ...[
                  Builder(
                    builder: (context) {
                      final monthlyIncome =
                          calculatorProvider.annualIncome! / 12;
                      final housingPayment = calculatorProvider.pitiPayment > 0
                          ? calculatorProvider.pitiPayment
                          : calculatorProvider.payment!;
                      final totalDebt =
                          housingPayment +
                          (calculatorProvider.monthlyDebt ?? 0);

                      final frontEndDti = DtiValidator.calculateHousingDti(
                        monthlyHousingPayment: housingPayment,
                        monthlyGrossIncome: monthlyIncome,
                      );
                      final backEndDti = DtiValidator.calculateDti(
                        monthlyDebtPayments: totalDebt,
                        monthlyGrossIncome: monthlyIncome,
                      );

                      final currentRatio = calculatorProvider.qualRatio1;

                      final warnings = DtiValidator.getDtiWarnings(
                        frontEndDti: frontEndDti,
                        backEndDti: backEndDti,
                        frontEndLimit: currentRatio.housingRatio,
                        backEndLimit: currentRatio.debtRatio,
                      );

                      if (warnings.isEmpty) return const SizedBox.shrink();

                      return Column(
                        children: [
                          ValidationWarningsDisplay(warnings: warnings),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ],

                // Results Card
                if (calculatorProvider.payment != null)
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Loan Summary',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Monthly P&I Payment',
                            value: CurrencyFormatter.formatCurrency(
                              calculatorProvider.payment,
                            ),
                            valueColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                          if (calculatorProvider.pitiPayment >
                              calculatorProvider.payment!)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _InfoRow(
                                label: 'Monthly PITI Payment',
                                value: CurrencyFormatter.formatCurrency(
                                  calculatorProvider.pitiPayment,
                                ),
                                valueColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(
    BuildContext context,
    String title,
    String message,
    double? value,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              value != null ? CurrencyFormatter.formatCurrency(value) : 'N/A',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRatioEditor(BuildContext context, QualifyingRatio? ratio) {
    final isEditing = ratio != null;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nameController = TextEditingController(text: ratio?.name ?? '');
    final descController = TextEditingController(
      text: ratio?.description ?? '',
    );
    final housingController = TextEditingController(
      text: ratio?.housingRatio.toString() ?? '28',
    );
    final debtController = TextEditingController(
      text: ratio?.debtRatio.toString() ?? '36',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Ratio' : 'Add Custom Ratio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., My Custom Ratio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: housingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Housing DTI %',
                        hintText: '28',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: debtController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total DTI %',
                        hintText: '36',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();

              // Get text from controllers and trim whitespace
              final housingText = housingController.text.trim();
              final debtText = debtController.text.trim();

              // Parse with validation - only use defaults if text is empty
              final housing = housingText.isEmpty
                  ? (ratio?.housingRatio ?? 28.0)
                  : (double.tryParse(housingText) ??
                        (ratio?.housingRatio ?? 28.0));
              final debt = debtText.isEmpty
                  ? (ratio?.debtRatio ?? 36.0)
                  : (double.tryParse(debtText) ?? (ratio?.debtRatio ?? 36.0));

              if (name.isEmpty) {
                messenger?.showSnackBar(
                  const SnackBar(content: Text('Please enter a name')),
                );
                return;
              }

              final provider = context.read<QualifyingRatiosProvider>();

              if (isEditing) {
                await provider.updateRatio(
                  ratio.copyWith(
                    name: name,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    housingRatio: housing,
                    debtRatio: debt,
                  ),
                );
              } else {
                await provider.addRatio(
                  name: name,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  housingRatio: housing,
                  debtRatio: debt,
                );
              }

              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showRatiosList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Consumer<QualifyingRatiosProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Qualifying Ratios',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRatioEditor(context, null);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Built-in ratios
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'BUILT-IN RATIOS',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      ...provider.builtInRatios.map(
                        (ratio) => _RatioListTile(
                          ratio: ratio,
                          isSelected: provider.selectedRatio?.id == ratio.id,
                          onTap: () {
                            provider.selectRatio(ratio);
                            context.read<CalculatorProvider>().setQualRatio1(
                              ratio,
                            );
                            Navigator.pop(ctx);
                          },
                          onDuplicate: () async {
                            await provider.duplicateRatio(ratio);
                          },
                        ),
                      ),

                      // Custom ratios
                      if (provider.customRatios.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'CUSTOM RATIOS',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                          ),
                        ),
                        ...provider.customRatios.map(
                          (ratio) => _RatioListTile(
                            ratio: ratio,
                            isSelected: provider.selectedRatio?.id == ratio.id,
                            onTap: () {
                              provider.selectRatio(ratio);
                              context.read<CalculatorProvider>().setQualRatio1(
                                ratio,
                              );
                              Navigator.pop(ctx);
                            },
                            onEdit: () {
                              Navigator.pop(ctx);
                              _showRatioEditor(context, ratio);
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Ratio?'),
                                  content: Text('Delete "${ratio.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await provider.deleteRatio(ratio.id);
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _RatioListTile extends StatelessWidget {
  final QualifyingRatio ratio;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  const _RatioListTile({
    required this.ratio,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          CurrencyFormatter.formatPercent(
            ratio.housingRatio,
            decimals: 2,
          ).replaceAll('%', ''),
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(ratio.name),
      subtitle: Text(
        '${CurrencyFormatter.formatPercent(ratio.housingRatio, decimals: 2)} / ${CurrencyFormatter.formatPercent(ratio.debtRatio, decimals: 2)}${ratio.description != null ? ' • ${ratio.description}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) const Icon(Icons.check, color: Colors.green),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit?.call();
                  break;
                case 'delete':
                  onDelete?.call();
                  break;
                case 'duplicate':
                  onDuplicate?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (onDuplicate != null)
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: 8),
                      Text('Duplicate'),
                    ],
                  ),
                ),
              if (onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
              if (onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
