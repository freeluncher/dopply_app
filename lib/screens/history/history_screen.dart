// =============================================================================
// Monitoring History Screen - View Past Monitoring Sessions
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dopply_app/services/monitoring_service.dart';
import 'package:dopply_app/models/monitoring.dart';
import 'package:dopply_app/core/theme.dart';

class MonitoringHistoryScreen extends ConsumerWidget {
  const MonitoringHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(monitoringHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Monitoring'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: historyAsync.when(
        data: (history) => _buildHistoryList(context, history),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(context, error.toString()),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<MonitoringResult> history,
  ) {
    if (history.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh the history
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final result = history[index];
          return _buildHistoryCard(context, result);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat monitoring',
              style: AppTheme.heading2.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai monitoring untuk melihat riwayat di sini',
              style: AppTheme.bodyText.copyWith(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat riwayat',
              style: AppTheme.heading2.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTheme.bodyText.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, MonitoringResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showDetailDialog(context, result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and classification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(result.createdAt),
                    style: AppTheme.heading3,
                  ),
                  _buildClassificationChip(result.classification),
                ],
              ),
              const SizedBox(height: 12),

              // BPM Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Rata-rata',
                      '${result.calculatedAverageBpm.toStringAsFixed(0)} BPM',
                      Icons.timeline,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Maksimum',
                      '${result.calculatedMaxBpm} BPM',
                      Icons.keyboard_arrow_up,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Minimum',
                      '${result.calculatedMinBpm} BPM',
                      Icons.keyboard_arrow_down,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Mini chart
              if (result.bpmData.isNotEmpty) _buildMiniChart(result.bpmData),

              // Patient info if available
              if (result.patientName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(result.patientName!, style: AppTheme.caption),
                  ],
                ),
              ],

              // Doctor notes if available
              if (result.doctorNotes != null &&
                  result.doctorNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        result.doctorNotes!,
                        style: AppTheme.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassificationChip(String classification) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (classification.toLowerCase()) {
      case 'normal':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Normal';
        break;
      case 'bradikardia':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = 'Bradikardia';
        break;
      case 'takikardia':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Takikardia';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: AppTheme.caption),
      ],
    );
  }

  Widget _buildMiniChart(List<int> bpmData) {
    return SizedBox(
      height: 60,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:
                  bpmData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                  }).toList(),
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
            ),
          ],
          minY: bpmData.reduce((a, b) => a < b ? a : b).toDouble() - 10,
          maxY: bpmData.reduce((a, b) => a > b ? a : b).toDouble() + 10,
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, MonitoringResult result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detail Monitoring'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    'Tanggal',
                    DateFormat('dd MMMM yyyy').format(result.createdAt),
                  ),
                  _buildDetailRow(
                    'Waktu',
                    DateFormat('HH:mm:ss').format(result.createdAt),
                  ),
                  _buildDetailRow('Klasifikasi', result.classification),
                  _buildDetailRow(
                    'Rata-rata BPM',
                    '${result.calculatedAverageBpm.toStringAsFixed(1)}',
                  ),
                  _buildDetailRow('Maksimum BPM', '${result.calculatedMaxBpm}'),
                  _buildDetailRow('Minimum BPM', '${result.calculatedMinBpm}'),
                  _buildDetailRow(
                    'Total Data Points',
                    '${result.bpmData.length}',
                  ),

                  if (result.gestationalAge != null)
                    _buildDetailRow(
                      'Usia Kandungan',
                      '${result.gestationalAge} minggu',
                    ),

                  if (result.patientName != null)
                    _buildDetailRow('Nama Pasien', result.patientName!),

                  if (result.doctorName != null)
                    _buildDetailRow('Nama Dokter', result.doctorName!),

                  if (result.notes != null && result.notes!.isNotEmpty)
                    _buildDetailRow('Catatan', result.notes!),

                  if (result.doctorNotes != null &&
                      result.doctorNotes!.isNotEmpty)
                    _buildDetailRow('Catatan Dokter', result.doctorNotes!),

                  const SizedBox(height: 16),

                  // Full chart
                  if (result.bpmData.isNotEmpty) ...[
                    Text('Grafik BPM', style: AppTheme.heading3),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget:
                                    (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                              ),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots:
                                  result.bpmData.asMap().entries.map((entry) {
                                    return FlSpot(
                                      entry.key.toDouble(),
                                      entry.value.toDouble(),
                                    );
                                  }).toList(),
                              isCurved: true,
                              color: AppTheme.primaryColor,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTheme.caption.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: AppTheme.bodyText)),
        ],
      ),
    );
  }
}
