import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/network_metrics.dart';

class JitterGraphWidget extends StatelessWidget {
  final List<PingDataPoint> history;
  const JitterGraphWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('Collecting data…', style: TextStyle(color: Colors.white54))),
      );
    }

    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.latencyMs.toDouble()))
        .toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.cyanAccent,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.cyanAccent.withOpacity(0.15)),
            ),
          ],
        ),
      ),
    );
  }
}
