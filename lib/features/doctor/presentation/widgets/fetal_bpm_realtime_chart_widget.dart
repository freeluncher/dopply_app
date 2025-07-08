// =============================================================================
// Fetal BPM Real-time Chart Widget
//
// Modern chart widget for displaying fetal heart rate data
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dopply_app/app/theme.dart';
import 'package:dopply_app/shared/services/fetal_doppler_ble_service.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/fetal_monitoring_notifier.dart';

class FetalBpmRealtimeChartWidget extends ConsumerWidget {
  final double height;
  final bool showLegend;

  const FetalBpmRealtimeChartWidget({
    super.key,
    this.height = 300,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartData = ref.watch(fetalBpmChartDataProvider);

    if (chartData.isEmpty) {
      return _buildEmptyChart();
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.medicalWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Grafik Detak Jantung Janin',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (showLegend) _buildLegend(),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          Expanded(child: _buildChart(chartData)),

          // Chart Footer with current BPM
          const SizedBox(height: 8),
          _buildChartFooter(chartData),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.medicalWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 16),
            Text(
              'Menunggu Data BPM',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hubungkan perangkat dan mulai monitoring untuk melihat grafik',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<FetalBpmPoint> data) {
    // Prepare chart data points
    final spots =
        data.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.bpm.toDouble());
        }).toList();

    // Calculate Y-axis range based on fetal heart rate normal ranges
    const double minY = 80;
    const double maxY = 200;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 20,
          verticalInterval:
              data.length > 10 ? (data.length / 10).ceil().toDouble() : 1,
          getDrawingHorizontalLine:
              (value) => FlLine(
                color: AppColors.border.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
          getDrawingVerticalLine:
              (value) => FlLine(
                color: AppColors.border.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
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
              interval:
                  data.length > 10 ? (data.length / 5).ceil().toDouble() : 2,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final seconds = data[index].time.inSeconds;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${seconds}s',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${value.toInt()}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        minX: 0,
        maxX: data.length > 1 ? (data.length - 1).toDouble() : 1,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: AppColors.primaryGradient,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length <= 20, // Show dots only for small datasets
              getDotPainter: (spot, percent, barData, index) {
                final point = data[index];
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getClassificationColor(point.classification),
                  strokeWidth: 2,
                  strokeColor: AppColors.medicalWhite,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.1),
                  AppColors.primaryBlue.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.medicalWhite,
            tooltipBorder: BorderSide(color: AppColors.border),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < data.length) {
                  final point = data[index];
                  return LineTooltipItem(
                    '${point.bpm} BPM\n${point.time.inSeconds}s\n${_getClassificationLabel(point.classification)}',
                    AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('Normal', AppColors.medicalGreen),
        const SizedBox(width: 8),
        _buildLegendItem('Abnormal', AppColors.medicalRed),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChartFooter(List<FetalBpmPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final latestPoint = data.last;
    final avgBpm = data.map((p) => p.bpm).reduce((a, b) => a + b) / data.length;

    return Row(
      children: [
        Text(
          'Terbaru: ${latestPoint.bpm} BPM',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Rata-rata: ${avgBpm.round()} BPM',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          'Durasi: ${latestPoint.time.inMinutes}:${(latestPoint.time.inSeconds % 60).toString().padLeft(2, '0')}',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getClassificationColor(FetalBPMClassification classification) {
    switch (classification) {
      case FetalBPMClassification.normal:
        return AppColors.medicalGreen;
      case FetalBPMClassification.bradycardia:
        return AppColors.medicalOrange;
      case FetalBPMClassification.tachycardia:
        return AppColors.medicalRed;
      case FetalBPMClassification.irregular:
        return AppColors.medicalPurple;
    }
  }

  String _getClassificationLabel(FetalBPMClassification classification) {
    switch (classification) {
      case FetalBPMClassification.normal:
        return 'Normal';
      case FetalBPMClassification.bradycardia:
        return 'Bradikardia';
      case FetalBPMClassification.tachycardia:
        return 'Tachikardia';
      case FetalBPMClassification.irregular:
        return 'Irregular';
    }
  }
}
