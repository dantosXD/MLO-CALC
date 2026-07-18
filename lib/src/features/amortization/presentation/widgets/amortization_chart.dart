import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/models/amortization_entry.dart';

import 'package:loan_ranger/src/core/utils/formatters.dart';

class AmortizationChart extends StatefulWidget {
  final List<AmortizationEntry> data;

  const AmortizationChart({super.key, required this.data});

  @override
  State<AmortizationChart> createState() => _AmortizationChartState();
}

class _AmortizationChartState extends State<AmortizationChart> {
  late List<FlSpot> _principalSpots;
  late List<FlSpot> _interestSpots;
  late double _maxY;

  @override
  void initState() {
    super.initState();
    _buildCache(widget.data);
  }

  @override
  void didUpdateWidget(AmortizationChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _buildCache(widget.data);
    }
  }

  void _buildCache(List<AmortizationEntry> data) {
    _principalSpots = List.unmodifiable(
      data.asMap().entries.map(
        (e) => FlSpot(e.key.toDouble(), e.value.principal),
      ),
    );
    _interestSpots = List.unmodifiable(
      data.asMap().entries.map(
        (e) => FlSpot(e.key.toDouble(), e.value.interest),
      ),
    );

    double maxPrincipal = 0;
    double maxInterest = 0;
    for (final entry in data) {
      if (entry.principal > maxPrincipal) maxPrincipal = entry.principal;
      if (entry.interest > maxInterest) maxInterest = entry.interest;
    }
    final maxValue = maxPrincipal > maxInterest ? maxPrincipal : maxInterest;
    _maxY = (maxValue * 1.2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Principal vs Interest Over Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _maxY > 0
                        ? (_maxY / 5).clamp(10000.0, 200000.0)
                        : 50000.0,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colorScheme.outline.withValues(alpha: 0.20),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (data.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= data.length) {
                            return const Text('');
                          }
                          final year = (value.toInt() / 12).ceil();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Yr $year',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.70,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${(value / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.70,
                              ),
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outline, width: 1),
                      left: BorderSide(color: colorScheme.outline, width: 1),
                    ),
                  ),
                  minX: 0,
                  maxX: data.length.toDouble() - 1,
                  minY: 0,
                  maxY: _maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _principalSpots,
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withValues(alpha: 0.20),
                      ),
                    ),
                    LineChartBarData(
                      spots: _interestSpots,
                      isCurved: true,
                      color: colorScheme.secondary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.secondary.withValues(alpha: 0.20),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          colorScheme.surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final month = spot.x.toInt() + 1;
                          final isInterest = spot.barIndex == 1;
                          return LineTooltipItem(
                            '${isInterest ? 'Interest' : 'Principal'}\nMonth $month: ${CurrencyFormatter.formatCurrency(spot.y)}',
                            TextStyle(
                              color: spot.bar.color,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: colorScheme.primary, label: 'Principal'),
                const SizedBox(width: 24),
                _LegendItem(color: colorScheme.secondary, label: 'Interest'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
