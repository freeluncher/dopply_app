import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Widget displaying the BPM line chart using fl_chart.
class BpmLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final double minY, maxY, minX, maxX;
  const BpmLineChart({
    required this.spots,
    required this.minY,
    required this.maxY,
    required this.minX,
    required this.maxX,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: ((maxX - minX + 1) * 12).clamp(320, 2000).toDouble(),
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              minX: minX,
              maxX: maxX,
              gridData: FlGridData(
                show: true,
                horizontalInterval: 10,
                getDrawingHorizontalLine:
                    (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      if (value % 20 == 0) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 10,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}s',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.red,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
