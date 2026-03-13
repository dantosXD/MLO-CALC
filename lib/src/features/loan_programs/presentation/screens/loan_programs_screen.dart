import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import '../../application/providers/loan_programs_provider.dart';
import '../../domain/models/loan_program.dart';
import '../widgets/loan_program_editor.dart';

class LoanProgramsScreen extends StatelessWidget {
  const LoanProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Programs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Custom Program',
            onPressed: () => _showProgramEditor(context, null),
          ),
        ],
      ),
      body: Consumer<LoanProgramsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Selected Program Card
              if (provider.selectedProgram != null) ...[
                _SelectedProgramCard(program: provider.selectedProgram!),
                const SizedBox(height: 24),
              ],

              // Built-in Programs
              Text(
                'Built-in Programs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...provider.builtInPrograms.map(
                (p) => _ProgramCard(
                  program: p,
                  isSelected: p.id == provider.selectedProgram?.id,
                  onSelect: () => _selectProgram(context, provider, p),
                  onDuplicate: () => _duplicateProgram(context, provider, p),
                  onEdit: null, // Can't edit built-in
                  onDelete: null, // Can't delete built-in
                ),
              ),

              // Custom Programs
              if (provider.customPrograms.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Custom Programs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...provider.customPrograms.map(
                  (p) => _ProgramCard(
                    program: p,
                    isSelected: p.id == provider.selectedProgram?.id,
                    onSelect: () => _selectProgram(context, provider, p),
                    onDuplicate: () => _duplicateProgram(context, provider, p),
                    onEdit: () => _showProgramEditor(context, p),
                    onDelete: () => _deleteProgram(context, provider, p),
                  ),
                ),
              ],

              const SizedBox(height: 80), // Space for FAB
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProgramEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New Program'),
      ),
    );
  }

  void _showProgramEditor(BuildContext context, LoanProgram? program) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoanProgramEditor(program: program),
      ),
    );
  }

  void _selectProgram(
    BuildContext context,
    LoanProgramsProvider provider,
    LoanProgram program,
  ) {
    // Select the program
    provider.selectProgram(program);
    
    // Sync the program's DTI ratios to the calculator
    final calculatorProvider = context.read<CalculatorProvider>();
    calculatorProvider.setQualRatio1(program.toQualifyingRatio());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selected "${program.name}" (${CurrencyFormatter.formatPercent(program.housingRatio, decimals: 2)}/${CurrencyFormatter.formatPercent(program.debtRatio, decimals: 2)})',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _duplicateProgram(
    BuildContext context,
    LoanProgramsProvider provider,
    LoanProgram program,
  ) async {
    final newProgram = await provider.duplicateProgram(program);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "${newProgram.name}"')),
      );
    }
  }

  Future<void> _deleteProgram(
    BuildContext context,
    LoanProgramsProvider provider,
    LoanProgram program,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Program?'),
        content: Text('Are you sure you want to delete "${program.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteProgram(program.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program deleted')),
        );
      }
    }
  }
}

class _SelectedProgramCard extends StatelessWidget {
  final LoanProgram program;

  const _SelectedProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Program',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              program.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              program.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: 'DTI',
                  value: '${CurrencyFormatter.formatPercent(program.housingRatio, decimals: 2)}/${CurrencyFormatter.formatPercent(program.debtRatio, decimals: 2)}',
                ),
                _InfoChip(
                  label: 'Min Down',
                  value: CurrencyFormatter.formatPercent(
                    program.minDownPaymentPercent,
                    decimals: 2,
                  ),
                ),
                if (program.maxLoanAmount != null)
                  _InfoChip(
                    label: 'Max Loan',
                    value: '\$${_formatNumber(program.maxLoanAmount!)}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final LoanProgram program;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback? onDuplicate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProgramCard({
    required this.program,
    required this.isSelected,
    required this.onSelect,
    this.onDuplicate,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Program Type Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(program.type).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getTypeAbbrev(program.type),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _getTypeColor(program.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Program Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            program.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DTI: ${CurrencyFormatter.formatPercent(program.housingRatio, decimals: 2)}/${CurrencyFormatter.formatPercent(program.debtRatio, decimals: 2)} • Min Down: ${CurrencyFormatter.formatPercent(program.minDownPaymentPercent, decimals: 2)}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'select':
                      onSelect();
                      break;
                    case 'duplicate':
                      onDuplicate?.call();
                      break;
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'select',
                    child: ListTile(
                      leading: Icon(Icons.check),
                      title: Text('Select'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(LoanProgramType type) {
    switch (type) {
      case LoanProgramType.conventional:
        return Colors.blue;
      case LoanProgramType.fha:
        return Colors.green;
      case LoanProgramType.va:
        return Colors.purple;
      case LoanProgramType.usda:
        return Colors.brown;
      case LoanProgramType.jumbo:
        return Colors.orange;
      case LoanProgramType.nonQm:
        return Colors.teal;
      case LoanProgramType.custom:
        return Colors.grey;
    }
  }

  String _getTypeAbbrev(LoanProgramType type) {
    switch (type) {
      case LoanProgramType.conventional:
        return 'CNV';
      case LoanProgramType.fha:
        return 'FHA';
      case LoanProgramType.va:
        return 'VA';
      case LoanProgramType.usda:
        return 'USD';
      case LoanProgramType.jumbo:
        return 'JMB';
      case LoanProgramType.nonQm:
        return 'NQM';
      case LoanProgramType.custom:
        return 'CUS';
    }
  }
}
