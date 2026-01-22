import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/comparison/application/providers/comparison_provider.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/features/comparison/presentation/screens/comparison_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _type = 'all'; // all | payment | loan_amount | term | interest_rate | qualification
  bool _selectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        // Clear selections when exiting selection mode
        context.read<ComparisonProvider>().clearSelections();
      }
    });
  }

  void _startComparison(BuildContext context) {
    final comparisonProvider = context.read<ComparisonProvider>();
    final calculatorProvider = context.read<CalculatorProvider>();

    if (!comparisonProvider.canCompare) return;

    final comparisonData = comparisonProvider.buildComparison(
      calculatorProvider.history.entries,
    );

    if (comparisonData != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ComparisonScreen(data: comparisonData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalculatorProvider>(context);
    final entries = _filtered(provider.history.entries);

    return Column(
      children: [
        _buildToolbar(context, provider),
        _buildChips(),
        const SizedBox(height: 8),
        Expanded(
          child: entries.isEmpty
              ? _empty()
              : ListView.builder(
                  itemCount: entries.length,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemBuilder: (context, i) => Consumer<ComparisonProvider>(
                    builder: (context, comparisonProvider, _) => _HistoryCard(
                      entry: entries[i],
                      onApply: () => provider.applyHistoryEntry(entries[i]),
                      onDelete: () => provider.removeHistoryEntry(entries[i].id),
                      selected: comparisonProvider.isSelected(entries[i].id),
                      selectionMode: _selectionMode,
                      onSelect: () => comparisonProvider.toggleSelection(entries[i].id),
                      onLongPress: () {
                        if (!_selectionMode) {
                          _toggleSelectionMode();
                          comparisonProvider.toggleSelection(entries[i].id);
                        }
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, CalculatorProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search history (loan, rate, term, notes)...',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _query = '';
                          _searchController.clear();
                        }),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<ComparisonProvider>(
            builder: (context, comparisonProvider, _) {
              if (_selectionMode) {
                return Tooltip(
                  message: 'Compare selected',
                  child: IconButton(
                    icon: Badge(
                      label: Text('${comparisonProvider.selectionCount}'),
                      child: const Icon(Icons.compare_arrows),
                    ),
                    onPressed: comparisonProvider.canCompare
                        ? () => _startComparison(context)
                        : null,
                  ),
                );
              }
              return Tooltip(
                message: 'Compare calculations',
                child: IconButton(
                  icon: const Icon(Icons.compare_arrows),
                  onPressed: provider.history.entries.length >= 2
                      ? _toggleSelectionMode
                      : null,
                ),
              );
            },
          ),
          Tooltip(
            message: 'Clear all history',
            child: IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: provider.history.entries.isEmpty
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Clear all history?'),
                          content: const Text('This will permanently remove all saved calculations.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Clear')),
                          ],
                        ),
                      );
                      if (ok == true) provider.clearHistory();
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    final types = <String, (String, IconData)>{
      'all': ('All', Icons.filter_alt_outlined),
      'payment': ('Payment', Icons.payments_outlined),
      'loan_amount': ('Loan Amount', Icons.account_balance_outlined),
      'term': ('Term', Icons.schedule_outlined),
      'interest_rate': ('Rate', Icons.percent_outlined),
      'qualification': ('Qualification', Icons.verified_user_outlined),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: types.entries.map((e) {
          final selected = _type == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Row(children: [Icon(e.value.$2, size: 16), const SizedBox(width: 6), Text(e.value.$1)]),
              selected: selected,
              onSelected: (_) => setState(() => _type = e.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<CalculationEntry> _filtered(List<CalculationEntry> source) {
    Iterable<CalculationEntry> items = source;
    if (_type != 'all') items = items.where((e) => e.type == _type);
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      items = items.where((e) => e.summary.toLowerCase().contains(q) || (e.notes ?? '').toLowerCase().contains(q));
    }
    return items.toList();
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No history yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Perform a calculation to see it here.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CalculationEntry entry;
  final VoidCallback onApply;
  final VoidCallback onDelete;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onSelect;
  final VoidCallback onLongPress;

  const _HistoryCard({
    required this.entry,
    required this.onApply,
    required this.onDelete,
    required this.selected,
    required this.selectionMode,
    required this.onSelect,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: InkWell(
        onLongPress: onLongPress,
        onTap: selectionMode ? onSelect : null,
        child: ListTile(
          leading: selectionMode
              ? Checkbox(
                  value: selected,
                  onChanged: (_) => onSelect(),
                )
              : CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(_iconFor(entry.type), color: theme.colorScheme.onPrimaryContainer),
                ),
          title: Text(entry.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fmt(entry.timestamp)),
              const SizedBox(height: 2),
              Text(entry.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          isThreeLine: true,
          trailing: selectionMode
              ? null
              : Wrap(spacing: 4, children: [
                  IconButton(
                    tooltip: 'Apply to calculator',
                    icon: const Icon(Icons.playlist_add_check_outlined),
                    onPressed: onApply,
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete entry?'),
                          content: Text(entry.summary),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) onDelete();
                    },
                  ),
                ]),
        ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'payment':
        return Icons.payments_outlined;
      case 'loan_amount':
        return Icons.account_balance_outlined;
      case 'term':
        return Icons.schedule_outlined;
      case 'interest_rate':
        return Icons.percent_outlined;
      case 'qualification':
        return Icons.verified_user_outlined;
      default:
        return Icons.calculate_outlined;
    }
  }

  static String _fmt(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
