import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/services/api/monitoring_api_service.dart';
import 'package:dopply_app/app/theme.dart';
import 'dart:convert';

/// Provider untuk MonitoringApiService
final monitoringApiServiceProvider = Provider((ref) => MonitoringApiService());

/// Provider untuk monitoring history data
final monitoringHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final apiService = ref.read(monitoringApiServiceProvider);
  return await apiService.getPatientMonitoringHistory();
});

class MonitoringHistoryPagePatient extends ConsumerWidget {
  const MonitoringHistoryPagePatient({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(monitoringHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Riwayat Monitoring',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.medicalWhite,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.medicalWhite),
      ),
      body: historyAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            ),
        error:
            (error, stack) => _buildErrorState(context, ref, error.toString()),
        data:
            (history) =>
                history.isEmpty
                    ? _buildEmptyState(context, ref)
                    : _buildHistoryList(context, ref, history),
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    // Check if it's a backend model error
    final isBackendModelError =
        error.contains('AttributeError') ||
        error.contains('patient_id') ||
        error.contains('500') ||
        error.contains('configuration error');

    // Check if it's a server connectivity error
    final isServerDownError =
        error.contains('502') ||
        error.contains('Bad Gateway') ||
        error.contains('temporarily unavailable');

    // Check if it's a network error
    final isNetworkError =
        error.contains('network') ||
        error.contains('connection') ||
        error.contains('internet');

    String title;
    String message;
    IconData iconData;

    if (isServerDownError) {
      title = 'Server Tidak Tersedia';
      message =
          'Server sedang mengalami gangguan teknis. Silakan coba lagi dalam beberapa menit.';
      iconData = Icons.cloud_off;
    } else if (isBackendModelError) {
      title = 'Server Sedang Diperbaiki';
      message =
          'Server sedang dalam proses perbaikan. Silakan coba lagi dalam beberapa saat.';
      iconData = Icons.construction;
    } else if (isNetworkError) {
      title = 'Masalah Koneksi';
      message = 'Periksa koneksi internet Anda dan coba lagi.';
      iconData = Icons.wifi_off;
    } else {
      title = 'Terjadi Kesalahan';
      message = error;
      iconData = Icons.error_outline;
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monitoringHistoryProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.medicalRedLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(iconData, size: 48, color: AppColors.medicalRed),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (isBackendModelError || isServerDownError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.medicalOrangeLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.medicalOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isServerDownError
                              ? 'Tim teknis sedang menangani masalah server. Mohon bersabar.'
                              : 'Tim teknis sedang memperbaiki masalah pada sistem monitoring.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.medicalOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(monitoringHistoryProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.medicalWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monitoringHistoryProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.medicalGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.history,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Riwayat',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda belum memiliki riwayat monitoring.\nMulai monitoring untuk melihat riwayat di sini.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/patient/self-monitoring');
                },
                icon: const Icon(Icons.monitor_heart),
                label: const Text('Mulai Monitoring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicalGreen,
                  foregroundColor: AppColors.medicalWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build history list widget
  Widget _buildHistoryList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> history,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monitoringHistoryProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return _buildHistoryCard(context, item);
        },
      ),
    );
  }

  /// Build individual history card
  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item) {
    final classification = item['classification'] ?? 'unknown';
    final Color statusColor = _getStatusColor(classification);
    final IconData statusIcon = _getStatusIcon(classification);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailDialog(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(item['created_at']),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hasil: ${item['monitoring_result'] ?? '-'}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(classification),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.medicalWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(item['created_at']),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Lihat Detail',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show detail dialog
  void _showDetailDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.monitor_heart,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Detail Monitoring',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Tanggal', _formatDate(item['created_at'])),
                  _buildDetailRow('Waktu', _formatTime(item['created_at'])),
                  _buildDetailRow('Hasil', item['monitoring_result'] ?? '-'),
                  _buildDetailRow(
                    'Klasifikasi',
                    _getStatusText(item['classification'] ?? 'unknown'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data BPM:',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item['bpm_data'] != null)
                    ..._buildBpmDataList(item['bpm_data'])
                  else
                    Text(
                      'Data BPM tidak tersedia',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Tutup',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build BPM data list
  List<Widget> _buildBpmDataList(dynamic bmpData) {
    if (bmpData == null) return [];

    List<dynamic> dataList;
    if (bmpData is String) {
      // If it's a JSON string, try to decode it
      try {
        dataList = json.decode(bmpData);
      } catch (e) {
        return [
          Text(
            'Format data BPM tidak valid',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ];
      }
    } else if (bmpData is List) {
      dataList = bmpData;
    } else {
      return [
        Text(
          'Format data BPM tidak dikenal',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ];
    }

    return dataList.map<Widget>((bmpItem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          '• ${bmpItem['time'] ?? '-'}s: ${bmpItem['bpm'] ?? '-'} BPM',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }).toList();
  }

  /// Get status color based on classification
  Color _getStatusColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'normal':
        return AppColors.medicalGreen;
      case 'warning':
        return AppColors.medicalOrange;
      case 'abnormal':
      case 'critical':
        return AppColors.medicalRed;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get status icon based on classification
  IconData _getStatusIcon(String classification) {
    switch (classification.toLowerCase()) {
      case 'normal':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'abnormal':
      case 'critical':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  /// Get status text based on classification
  String _getStatusText(String classification) {
    switch (classification.toLowerCase()) {
      case 'normal':
        return 'Normal';
      case 'warning':
        return 'Perhatian';
      case 'abnormal':
        return 'Abnormal';
      case 'critical':
        return 'Kritis';
      default:
        return 'Tidak Diketahui';
    }
  }

  /// Format date from API response
  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return '-';

    try {
      DateTime parsedDate = DateTime.parse(dateTime.toString());
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  /// Format time from API response
  String _formatTime(dynamic dateTime) {
    if (dateTime == null) return '-';

    try {
      DateTime parsedDate = DateTime.parse(dateTime.toString());
      return '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }
}
