import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/bpm_point.dart';
import 'bpm_line_chart.dart';
import 'bpm_stat_row.dart';

/// Widget displaying a real-time BPM chart and stats for fetal monitoring.
class BpmRealtimeChartWidget extends StatelessWidget {
  final List<BpmPoint> bpmData;
  const BpmRealtimeChartWidget({super.key, required this.bpmData});

  @override
  Widget build(BuildContext context) {
    if (bpmData.isEmpty) {
      return const Center(child: Text('Belum ada data BPM'));
    }
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
    final isWide = MediaQuery.of(context).size.width > 600;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChartHeader(spots: spots),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive chart width: more width for wide screens
                final chartWidth =
                    isWide
                        ? (constraints.maxWidth * 0.9).clamp(400, 1200)
                        : (constraints.maxWidth * 1.2).clamp(320, 800);
                return SizedBox(
                  width: chartWidth.toDouble(),
                  child: BpmLineChart(
                    spots: spots,
                    minY: minY,
                    maxY: maxY,
                    minX: minX,
                    maxX: maxX,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            isWide
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: BpmStatRow(
                        minBpm: spots
                            .map((e) => e.y.toInt())
                            .reduce((a, b) => a < b ? a : b),
                        maxBpm: spots
                            .map((e) => e.y.toInt())
                            .reduce((a, b) => a > b ? a : b),
                        latestBpm: spots.last.y.toInt(),
                      ),
                    ),
                  ],
                )
                : BpmStatRow(
                  minBpm: spots
                      .map((e) => e.y.toInt())
                      .reduce((a, b) => a < b ? a : b),
                  maxBpm: spots
                      .map((e) => e.y.toInt())
                      .reduce((a, b) => a > b ? a : b),
                  latestBpm: spots.last.y.toInt(),
                ),
          ],
        ),
      ),
    );
  }
}

class _ChartHeader extends StatelessWidget {
  final List<FlSpot> spots;
  const _ChartHeader({required this.spots});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Flexible(
          child: Text(
            'Grafik Detak Jantung Janin (BPM)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (spots.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }
}
