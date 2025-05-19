import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/monitoring_view_model.dart';

class BpmRealtimeChartWidget extends StatelessWidget {
  final List<BpmPoint> bpmData;
  const BpmRealtimeChartWidget({Key? key, required this.bpmData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bpmData.isEmpty) {
      return const Center(child: Text('Belum ada data BPM'));
    }
    // Show all data for historical trend
    final data = bpmData;
    final List<FlSpot> spots =
        data
            .map((e) => FlSpot(e.time.inSeconds.toDouble(), e.bpm.toDouble()))
            .toList();
    final minY =
        (spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 10)
            .clamp(40, 180)
            .toDouble();
    final maxY =
        (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 10)
            .clamp(120, 220)
            .toDouble();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Detak Jantung Janin (BPM)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
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
                            (v) => FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            ),
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
                          isCurved: false, // sharp lines
                          color: Colors.red,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: ${spots.map((e) => e.y.toInt()).reduce((a, b) => a < b ? a : b)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Max: ${spots.map((e) => e.y.toInt()).reduce((a, b) => a > b ? a : b)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Terbaru: ${spots.last.y.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
