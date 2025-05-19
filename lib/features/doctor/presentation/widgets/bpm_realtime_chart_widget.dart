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
    // Tampilkan hanya 60 data terakhir
    final data =
        bpmData.length > 60 ? bpmData.sublist(bpmData.length - 60) : bpmData;
    final List<FlSpot> spots =
        data
            .map((e) => FlSpot(e.time.inSeconds.toDouble(), e.bpm.toDouble()))
            .toList();
    final minY =
        (data.map((e) => e.bpm).reduce((a, b) => a < b ? a : b) - 10)
            .clamp(60, 180)
            .toDouble();
    final maxY =
        (data.map((e) => e.bpm).reduce((a, b) => a > b ? a : b) + 10)
            .clamp(120, 220)
            .toDouble();
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
                  width: (spots.length * 16).clamp(320, 800).toDouble(),
                  child: LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
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
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.withOpacity(0.08),
                          ),
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
                  'Min: ${data.map((e) => e.bpm).reduce((a, b) => a < b ? a : b)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Max: ${data.map((e) => e.bpm).reduce((a, b) => a > b ? a : b)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Terbaru: ${data.last.bpm}',
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
