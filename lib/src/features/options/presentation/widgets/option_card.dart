import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/options/domain/models/loan_option.dart';

class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onSelected,
    this.onOpenInCalculator,
  });

  final LoanOption option;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback? onOpenInCalculator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key('opt_card_${option.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  key: Key('opt_sel_${option.id}'),
                  value: selected,
                  onChanged: (v) => onSelected(v ?? false),
                ),
                Expanded(
                  child: Text(option.title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            Text(
              '${formatMoneyOrDash(option.piti)}/mo PITI',
              style: theme.textTheme.headlineSmall,
            ),
            Text(
              'Cash to close ${formatMoneyOrDash(option.cashToClose)}  |  Rate '
              '${formatPercentOrDash(option.rate, digits: 3)}  |  MI '
              '${formatMoneyOrDash(option.monthlyMi)}/mo  |  DTI '
              '${formatPercentOrDash(option.backEndDti, digits: 1)}',
            ),
            if (option.flags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: [for (final f in option.flags) Chip(label: Text(f))],
              ),
            if (onOpenInCalculator != null)
              TextButton.icon(
                key: Key('opt_open_${option.id}'),
                onPressed: onOpenInCalculator,
                icon: const Icon(Icons.calculate),
                label: const Text('Open in Calculator'),
              ),
          ],
        ),
      ),
    );
  }
}
