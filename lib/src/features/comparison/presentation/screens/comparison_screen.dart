import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/comparison/domain/models/comparison_data.dart';
import 'package:loan_ranger/src/features/share/domain/models/quote_share_data.dart';
import 'package:loan_ranger/src/features/share/presentation/dialogs/share_quote_dialog.dart';

import '../../application/providers/comparison_provider.dart';
import '../../domain/export/comparison_exporter.dart';

final NumberFormat _currency = NumberFormat.simpleCurrency();

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key, required this.data});

  final ComparisonData data;

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  static const LoanMath _loanMath = LoanMath();

  double _rateDelta = 0;
  double _termDelta = 0;
  double _downPaymentDelta = 0;
  final Map<String, _AdjustedProjection> _projectionCache =
      <String, _AdjustedProjection>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share scenario',
            onPressed: () async {
              final selected = await showModalBottomSheet<ComparisonEntryView>(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Share which scenario?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ...widget.data.views.map(
                        (view) => ListTile(
                          title: Text(view.entry.title),
                          subtitle: Text(view.entry.summary),
                          trailing: view.isBaseline
                              ? const Icon(Icons.star, size: 18)
                              : null,
                          onTap: () => Navigator.of(context).pop(view),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );

              if (!context.mounted || selected == null) return;
              await ShareQuoteDialog.show(
                context,
                data: QuoteShareData.fromCalculationEntry(selected.entry),
                scenarioName: selected.entry.title,
                title: 'Share Scenario',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: () {
              final csv = ComparisonExporter.buildCsv(widget.data);
              _showExportDialog(context, csv);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.data.views
                  .map(
                    (view) => _ComparisonCard(
                      view: view,
                      baselinePayment: widget.data.baseline.monthlyPayment,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            _ComparisonSummaryView(summary: widget.data.summary),
            const SizedBox(height: 24),
            _buildSensitivitySection(_currency),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitivitySection(NumberFormat currency) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensitivity Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _SliderTile(
              title:
                  'Interest Rate Δ (${CurrencyFormatter.formatPercent(_rateDelta, decimals: 2)})',
              min: -2,
              max: 2,
              value: _rateDelta,
              onChanged: (value) => setState(() {
                _rateDelta = value;
              }),
            ),
            _SliderTile(
              title: 'Term Δ (${CurrencyFormatter.formatYears(_termDelta)})',
              min: -5,
              max: 5,
              value: _termDelta,
              onChanged: (value) => setState(() {
                _termDelta = value;
              }),
            ),
            _SliderTile(
              title:
                  'Down Payment Δ (${CurrencyFormatter.formatNumber(_downPaymentDelta, decimals: 1)} pts)',
              min: -10,
              max: 10,
              value: _downPaymentDelta,
              onChanged: (value) => setState(() {
                _downPaymentDelta = value;
              }),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Scenario')),
                  DataColumn(label: Text('Adj Payment')),
                  DataColumn(label: Text('Adj Rate')),
                  DataColumn(label: Text('Adj Term')),
                  DataColumn(label: Text('Adj Loan')),
                ],
                rows: widget.data.views
                    .map((view) => _buildSensitivityRow(view, _currency))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildSensitivityRow(
    ComparisonEntryView view,
    NumberFormat currency,
  ) {
    final projection = _project(view);
    return DataRow(
      cells: [
        DataCell(Text(view.entry.title)),
        DataCell(
          Text(
            projection.adjustedPayment != null
                ? currency.format(projection.adjustedPayment)
                : '—',
          ),
        ),
        DataCell(
          Text(
            projection.adjustedRate == null
                ? '—'
                : CurrencyFormatter.formatPercent(
                    projection.adjustedRate,
                    decimals: 3,
                  ),
          ),
        ),
        DataCell(
          Text(
            projection.adjustedTerm == null
                ? '—'
                : CurrencyFormatter.formatYears(projection.adjustedTerm),
          ),
        ),
        DataCell(
          Text(
            projection.adjustedLoan != null
                ? currency.format(projection.adjustedLoan)
                : '—',
          ),
        ),
      ],
    );
  }

  _AdjustedProjection _project(ComparisonEntryView view) {
    final cacheKey = [
      view.entry.id,
      _rateDelta.toStringAsFixed(3),
      _termDelta.toStringAsFixed(3),
      _downPaymentDelta.toStringAsFixed(3),
    ].join('|');
    final cached = _projectionCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    if (_projectionCache.length >= 200) {
      _projectionCache.remove(_projectionCache.keys.first);
    }

    final double? baseRate = view.entry.interestRate;
    final double? baseTerm = view.termYears;
    final double? baseLoan = view.entry.loanAmount;
    final double? price = view.entry.price;
    final double? downPaymentPercent = (price != null && baseLoan != null)
        ? ((price - baseLoan) / price) * 100
        : null;

    final double adjustedRate = ((baseRate ?? 0) + _rateDelta).clamp(0.01, 20);
    final double adjustedTerm = ((baseTerm ?? 0) + _termDelta).clamp(5, 40);

    double? adjustedLoan;
    if (price != null && downPaymentPercent != null) {
      final double percent = (downPaymentPercent + _downPaymentDelta).clamp(
        0,
        90,
      );
      adjustedLoan = price * (1 - percent / 100);
    } else if (baseLoan != null) {
      adjustedLoan = baseLoan;
    }

    double? adjustedPayment;
    if (adjustedLoan != null) {
      adjustedPayment = _calculatePayment(
        adjustedLoan,
        adjustedRate,
        adjustedTerm,
      );
    }

    return _AdjustedProjection(
      adjustedPayment: adjustedPayment,
      adjustedRate: adjustedRate,
      adjustedTerm: adjustedTerm,
      adjustedLoan: adjustedLoan,
    ).._cacheTo(_projectionCache, cacheKey);
  }

  double _calculatePayment(double principal, double rate, double termYears) {
    if (rate <= 0) {
      return principal / (termYears * 12);
    }
    return _loanMath.calculatePayment(
      loanAmount: principal,
      interestRate: rate,
      termYears: termYears,
    );
  }

  void _showExportDialog(BuildContext context, String csv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              height: 200,
              child: SingleChildScrollView(
                child: SelectableText(
                  csv,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Copy the CSV text above to share with borrowers or import into spreadsheets.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.view, required this.baselinePayment});

  final ComparisonEntryView view;
  final double? baselinePayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double? delta =
        (view.monthlyPayment != null &&
            baselinePayment != null &&
            !view.isBaseline)
        ? view.monthlyPayment! - baselinePayment!
        : null;

    final screenWidth = MediaQuery.sizeOf(context).width;
    // On mobile, use full width; on larger screens, use fixed width
    final cardWidth = screenWidth < 600 ? double.infinity : 340.0;

    return SizedBox(
      width: cardWidth,
      child: Card(
        color: view.isBaseline ? theme.colorScheme.primaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                view.entry.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: view.isBaseline
                      ? theme.colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                view.entry.summary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: view.isBaseline
                      ? theme.colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Monthly Payment',
                value: view.monthlyPayment != null
                    ? _currency.format(view.monthlyPayment)
                    : '—',
                highlight: delta,
              ),
              _MetricRow(
                label: 'Total Cost',
                value: view.totalCost != null
                    ? _currency.format(view.totalCost)
                    : '—',
              ),
              _MetricRow(
                label: 'Total Interest',
                value: view.totalInterest != null
                    ? _currency.format(view.totalInterest)
                    : '—',
              ),
              _MetricRow(
                label: 'MI Drop (mo)',
                value: view.miDropMonth?.toString() ?? '—',
              ),
              _MetricRow(
                label: 'Break-even (mo)',
                value: view.breakEvenMonths == null
                    ? '—'
                    : CurrencyFormatter.formatNumber(
                        view.breakEvenMonths,
                        decimals: 1,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, this.highlight});

  final String label;
  final String value;
  final double? highlight;

  @override
  Widget build(BuildContext context) {
    Color? color;
    String? deltaLabel;
    if (highlight != null) {
      color = highlight! < 0 ? Colors.green : Colors.red;
      deltaLabel =
          '${highlight! > 0 ? '+' : '-'}${CurrencyFormatter.formatCurrency(highlight!.abs())} /mo';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              if (deltaLabel != null)
                Text(
                  deltaLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonSummaryView extends StatelessWidget {
  const _ComparisonSummaryView({required this.summary});

  final ComparisonSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryChip(
          label: 'Selections',
          value: '${summary.comparableCount}/${summary.count}',
        ),
        _SummaryChip(
          label: 'Payment Range',
          value: _formatCurrency(summary.paymentRange),
        ),
        _SummaryChip(
          label: 'Interest Range',
          value: _formatCurrency(summary.interestRange),
        ),
      ],
    );
  }

  String _formatCurrency(double? value) {
    if (value == null) return '—';
    return _currency.format(value);
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Slider(
          min: min,
          max: max,
          divisions: 40,
          value: value,
          label: CurrencyFormatter.formatNumber(value, decimals: 2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AdjustedProjection {
  const _AdjustedProjection({
    required this.adjustedPayment,
    required this.adjustedRate,
    required this.adjustedTerm,
    required this.adjustedLoan,
  });

  final double? adjustedPayment;
  final double? adjustedRate;
  final double? adjustedTerm;
  final double? adjustedLoan;

  void _cacheTo(Map<String, _AdjustedProjection> cache, String key) {
    cache[key] = this;
  }
}
