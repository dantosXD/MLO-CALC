import 'package:flutter/material.dart';
import '../models/calculation_history.dart';
import '../providers/comparison_provider.dart';

class ComparisonScreen extends StatelessWidget {
  final ComparisonData data;

  const ComparisonScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final normalized = data.entries.map(_normalize).whereType<_NormalizedData>().toList();
    final summary = data.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Calculations'),
      ),
      body: normalized.isEmpty
          ? const Center(child: Text('No comparable data found in selection.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summary.comparableCount >= 2) _buildSummaryCard(context, summary),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      columns: [
                        const DataColumn(label: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold))),
                        ...normalized.map((e) => DataColumn(
                              label: Container(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  e.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )),
                      ],
                      rows: [
                        _buildRow('Loan Amount', normalized, (d) => '\$${d.loanAmount.toStringAsFixed(2)}'),
                        _buildRow('Interest Rate', normalized, (d) => '${d.interestRate.toStringAsFixed(3)}%'),
                        _buildRow('Term (Years)', normalized, (d) => d.termYears.toStringAsFixed(1)),
                        _buildRow('Monthly Payment', normalized, (d) => '\$${d.monthlyPayment.toStringAsFixed(2)}'),
                        _buildRow('Total Cost', normalized, (d) => '\$${d.totalCost.toStringAsFixed(2)}'),
                        _buildRow('Total Interest', normalized, (d) => '\$${d.totalInterest.toStringAsFixed(2)}'),
                        // Add difference rows if exactly 2 items
                        if (normalized.length == 2) ...[
                          _buildDiffRow('Difference (Cost)', normalized[0], normalized[1], (d) => d.totalCost),
                          _buildDiffRow('Difference (Interest)', normalized[0], normalized[1], (d) => d.totalInterest),
                          _buildDiffRow('Difference (Payment)', normalized[0], normalized[1], (d) => d.monthlyPayment),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ComparisonSummary summary) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Cost Difference: \$${summary.totalCostRange?.toStringAsFixed(2) ?? 'N/A'}'),
            Text('Monthly Difference: \$${summary.paymentRange?.toStringAsFixed(2) ?? 'N/A'}'),
            Text('Interest Difference: \$${summary.interestRange?.toStringAsFixed(2) ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(String label, List<_NormalizedData> data, String Function(_NormalizedData) extractor) {
    return DataRow(
      cells: [
        DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        ...data.map((d) => DataCell(Text(extractor(d)))),
      ],
    );
  }

  DataRow _buildDiffRow(String label, _NormalizedData d1, _NormalizedData d2, double Function(_NormalizedData) getValue) {
    final v1 = getValue(d1);
    final v2 = getValue(d2);
    final diff = v1 - v2; // d1 - d2. If positive, d1 is more expensive.
    
    final diffStr = diff.abs().toStringAsFixed(2);
    final color = diff == 0 ? Colors.grey : (diff > 0 ? Colors.red : Colors.green);
    
    return DataRow(
      cells: [
        DataCell(Text(label, style: const TextStyle(fontStyle: FontStyle.italic))),
         DataCell(const Text('-')), // Base
         DataCell(
           Row(
             children: [
               Icon(diff > 0 ? Icons.add : Icons.remove, size: 12, color: color),
               Text('\$$diffStr', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
             ],
           )
         ),
      ]
    );
  }

  _NormalizedData? _normalize(CalculationEntry entry) {
    // Try to extract standard loan params
    final inputs = entry.inputs;
    final results = entry.results;
    
    // Merge inputs and results to find values
    final all = {...inputs, ...results};

    final loanAmount = _getDouble(all, 'loanAmount');
    final interestRate = _getDouble(all, 'interestRate');
    final termYears = _getDouble(all, 'termYears');
    final payment = _getDouble(all, 'payment');

    if (loanAmount != null && interestRate != null && termYears != null && payment != null) {
      final totalCost = payment * termYears * 12;
      final totalInterest = totalCost - loanAmount;
      
      // Use a shorter title if possible
      String title = entry.summary.split('→').first.trim();
      if (title.length > 20) title = '${title.substring(0, 17)}...';

      return _NormalizedData(
        id: entry.id,
        title: title,
        loanAmount: loanAmount,
        interestRate: interestRate,
        termYears: termYears,
        monthlyPayment: payment,
        totalCost: totalCost,
        totalInterest: totalInterest,
      );
    }
    return null;
  }

  double? _getDouble(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class _NormalizedData {
  final String id;
  final String title;
  final double loanAmount;
  final double interestRate;
  final double termYears;
  final double monthlyPayment;
  final double totalCost;
  final double totalInterest;

  _NormalizedData({
    required this.id,
    required this.title,
    required this.loanAmount,
    required this.interestRate,
    required this.termYears,
    required this.monthlyPayment,
    required this.totalCost,
    required this.totalInterest,
  });
}
