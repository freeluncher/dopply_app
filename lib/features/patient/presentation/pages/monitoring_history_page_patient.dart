import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/services/api/monitoring_api_service.dart';
import 'package:dopply_app/app/theme.dart';
import 'dart:convert';

/// Provider untuk MonitoringApiService
final monitoringApiServiceProvider = Provider((ref) => MonitoringApiService());

/// Provider untuk doctor list
final doctorListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final apiService = ref.read(monitoringApiServiceProvider);
  return await apiService.getDoctorList();
});

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
          return _buildHistoryCard(context, ref, item);
        },
      ),
    );
  }

  /// Build individual history card
  Widget _buildHistoryCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    final classification = item['classification'] ?? 'unknown';
    final Color statusColor = _getStatusColor(classification);
    final IconData statusIcon = _getStatusIcon(classification);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailDialog(context, ref, item),
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
                  // Share button or assigned doctor info
                  _buildShareSection(context, ref, item),
                  const SizedBox(width: 12),
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
  void _showDetailDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
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
                  // Show assigned doctor info if available
                  if (_isAssignedToDoctor(item))
                    _buildAssignedDoctorDetailRow(ref, item),
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

  /// Build assigned doctor detail row for detail dialog
  Widget _buildAssignedDoctorDetailRow(
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    // Check if doctor information is available directly from doctor_assignment
    if (item['doctor_assignment'] != null && item['doctor_assignment'] is Map) {
      final doctorAssignment =
          item['doctor_assignment'] as Map<String, dynamic>;
      final doctorName = doctorAssignment['doctor_name'] ?? 'Dokter';
      return _buildDetailRow('Dokter', doctorName);
    }

    // Fallback: get doctor info from doctor list using doctor ID
    final doctorId = _getAssignedDoctorId(item);

    return Consumer(
      builder: (context, ref, child) {
        final doctorListAsync = ref.watch(doctorListProvider);

        return doctorListAsync.when(
          loading: () => _buildDetailRow('Dokter', 'Loading...'),
          error: (error, stack) => _buildDetailRow('Dokter', 'Dokter'),
          data: (doctors) {
            // Find the assigned doctor from the list
            final assignedDoctor = doctors.firstWhere(
              (doctor) => doctor['id'] == doctorId,
              orElse: () => <String, dynamic>{},
            );

            final doctorName = assignedDoctor['name'] ?? 'Dokter';
            final specialization = assignedDoctor['specialization'] ?? '';
            final displayText =
                specialization.isNotEmpty
                    ? '$doctorName ($specialization)'
                    : doctorName;

            return _buildDetailRow('Dokter', displayText);
          },
        );
      },
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

  /// Show share to doctor dialog
  void _showShareDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
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
                  Icons.share,
                  color: AppColors.medicalGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Share ke Dokter',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Consumer(
                builder: (context, ref, child) {
                  final doctorListAsync = ref.watch(doctorListProvider);

                  return doctorListAsync.when(
                    loading:
                        () => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue,
                            ),
                          ),
                        ),
                    error:
                        (error, stack) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.medicalRed,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gagal memuat daftar dokter',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                ref.invalidate(doctorListProvider);
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                    data: (doctors) {
                      if (doctors.isEmpty) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.medicalOrange,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada dokter tersedia',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pilih dokter untuk berbagi hasil monitoring:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: doctors.length,
                              itemBuilder: (context, index) {
                                final doctor = doctors[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryBlue,
                                      child: const Icon(
                                        Icons.local_hospital,
                                        color: AppColors.medicalWhite,
                                      ),
                                    ),
                                    title: Text(
                                      doctor['name'] ?? 'Dokter',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      doctor['specialization'] ??
                                          doctor['email'] ??
                                          '',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.primaryBlue,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _shareToDoctor(
                                        context,
                                        ref,
                                        item,
                                        doctor,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Batal',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// Share monitoring result to selected doctor
  Future<void> _shareToDoctor(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
    Map<String, dynamic> doctor,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text('Mengirim ke dokter...', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
    );

    try {
      final apiService = ref.read(monitoringApiServiceProvider);
      final response = await apiService.shareMonitoringToDoctor(
        monitoringId: item['id'] ?? 0,
        doctorId: doctor['id'] ?? 0,
      );

      print('[SHARE_TO_DOCTOR] API Response: $response');

      // Close loading dialog first
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success dialog WITHOUT calling ref.invalidate immediately
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.medicalGreen,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Berhasil!',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hasil monitoring berhasil dibagikan ke ${doctor['name'] ?? 'dokter'}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Refresh data ONLY after dialog is fully closed
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted) {
                          try {
                            ref.invalidate(monitoringHistoryProvider);
                            print(
                              '[SHARE_TO_DOCTOR] Provider invalidated successfully',
                            );
                          } catch (e) {
                            print(
                              '[SHARE_TO_DOCTOR] Provider invalidation error: $e',
                            );
                          }
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.medicalGreen,
                      foregroundColor: AppColors.medicalWhite,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print('[SHARE_TO_DOCTOR] Error: $e');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.medicalRed,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Mengirim',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Terjadi kesalahan saat membagikan hasil monitoring: ${e.toString()}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.medicalRed,
                      foregroundColor: AppColors.medicalWhite,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  /// Check if monitoring result is already assigned to a doctor
  bool _isAssignedToDoctor(Map<String, dynamic> item) {
    // Check if doctor_assignment field exists and is not null (new backend format)
    if (item['doctor_assignment'] != null) {
      return true;
    }

    // Fallback: check older field names for backwards compatibility
    return item['doctor_id'] != null ||
        item['shared_with'] != null ||
        item['assigned_doctor_id'] != null ||
        item['doctor'] != null;
  }

  /// Get assigned doctor ID
  int? _getAssignedDoctorId(Map<String, dynamic> item) {
    // Check new backend format first
    if (item['doctor_assignment'] != null && item['doctor_assignment'] is Map) {
      final doctorAssignment =
          item['doctor_assignment'] as Map<String, dynamic>;
      if (doctorAssignment['doctor_id'] != null) {
        return doctorAssignment['doctor_id'] is int
            ? doctorAssignment['doctor_id']
            : int.tryParse(doctorAssignment['doctor_id'].toString());
      }
    }

    // Fallback: check older field names for backwards compatibility
    if (item['doctor_id'] != null) {
      return item['doctor_id'] is int
          ? item['doctor_id']
          : int.tryParse(item['doctor_id'].toString());
    }
    if (item['shared_with'] != null) {
      return item['shared_with'] is int
          ? item['shared_with']
          : int.tryParse(item['shared_with'].toString());
    }
    if (item['assigned_doctor_id'] != null) {
      return item['assigned_doctor_id'] is int
          ? item['assigned_doctor_id']
          : int.tryParse(item['assigned_doctor_id'].toString());
    }
    if (item['doctor'] != null) {
      // Handle case where doctor is a nested object with id
      if (item['doctor'] is Map && item['doctor']['id'] != null) {
        return item['doctor']['id'] is int
            ? item['doctor']['id']
            : int.tryParse(item['doctor']['id'].toString());
      }
      // Handle case where doctor is just an ID
      return item['doctor'] is int
          ? item['doctor']
          : int.tryParse(item['doctor'].toString());
    }

    return null;
  }

  /// Build share section - either share button or assigned doctor info
  Widget _buildShareSection(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    final isAssigned = _isAssignedToDoctor(item);

    if (isAssigned) {
      return _buildAssignedDoctorInfo(context, ref, item);
    } else {
      return _buildShareButton(context, ref, item);
    }
  }

  /// Build share button for unassigned monitoring results
  Widget _buildShareButton(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    return InkWell(
      onTap: () => _showShareDialog(context, ref, item),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share, size: 14, color: AppColors.medicalGreen),
            const SizedBox(width: 4),
            Text(
              'Share',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.medicalGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build assigned doctor info for already assigned monitoring results
  Widget _buildAssignedDoctorInfo(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    // Check if doctor information is available directly from doctor_assignment
    if (item['doctor_assignment'] != null && item['doctor_assignment'] is Map) {
      final doctorAssignment =
          item['doctor_assignment'] as Map<String, dynamic>;
      final doctorName = doctorAssignment['doctor_name'] ?? 'Dokter';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_hospital,
              size: 14,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(width: 4),
            Text(
              doctorName,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Fallback: get doctor info from doctor list using doctor ID
    final doctorId = _getAssignedDoctorId(item);

    return Consumer(
      builder: (context, ref, child) {
        final doctorListAsync = ref.watch(doctorListProvider);

        return doctorListAsync.when(
          loading:
              () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Loading...',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
          error:
              (error, stack) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_hospital,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dokter',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
          data: (doctors) {
            // Find the assigned doctor from the list
            final assignedDoctor = doctors.firstWhere(
              (doctor) => doctor['id'] == doctorId,
              orElse: () => <String, dynamic>{},
            );

            final doctorName = assignedDoctor['name'] ?? 'Dokter';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_hospital,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    doctorName,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
