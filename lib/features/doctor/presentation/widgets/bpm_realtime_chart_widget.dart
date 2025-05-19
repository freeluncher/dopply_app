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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start, // Tambah ini agar header tidak overflow
              children: [
                Flexible(
                  child: const Text(
                    'Grafik Detak Jantung Janin (BPM)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (spots.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, color: Colors.red[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'BPM: ${spots.last.y.toInt()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              width: double.infinity, // Tambahkan ini agar chart tidak overflow
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBox(
                  label: 'Min',
                  value:
                      spots
                          .map((e) => e.y.toInt())
                          .reduce((a, b) => a < b ? a : b)
                          .toString(),
                  color: Colors.blue[700],
                ),
                _StatBox(
                  label: 'Max',
                  value:
                      spots
                          .map((e) => e.y.toInt())
                          .reduce((a, b) => a > b ? a : b)
                          .toString(),
                  color: Colors.orange[700],
                ),
                _StatBox(
                  label: 'Terbaru',
                  value: spots.last.y.toInt().toString(),
                  color: Colors.red[700],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tambahkan widget kecil untuk statistik
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatBox({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.08) ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color ?? Colors.grey, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color ?? Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
