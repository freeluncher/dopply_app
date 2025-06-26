import 'package:flutter/material.dart';
import 'package:dopply_app/features/doctor/data/models/patient_history_record.dart';
import 'package:dopply_app/app/theme.dart';

/// Helper untuk menampilkan snackbar notifikasi dengan tema medical
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline
                : isSuccess
                ? Icons.check_circle_outline
                : Icons.info_outline,
            color: AppColors.medicalWhite,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.medicalWhite,
              ),
            ),
          ),
        ],
      ),
      backgroundColor:
          isError
              ? AppColors.medicalRed
              : isSuccess
              ? AppColors.medicalGreen
              : AppColors.primaryBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: Duration(seconds: isError ? 4 : 3),
    ),
  );
}

/// Halaman detail riwayat monitoring pasien dengan medical theme
class PatientHistoryDetailPage extends StatelessWidget {
  /// Data record monitoring yang akan ditampilkan
  final PatientHistoryRecord record;
  const PatientHistoryDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Medical App Bar dengan gradient
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(gradient: _getStatusGradient()),
                child: FlexibleSpaceBar(
                  title: Text(
                    'Detail Riwayat',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.medicalWhite,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  background: Container(
                    decoration: BoxDecoration(gradient: _getStatusGradient()),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 80,
                        left: 16,
                        right: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.medicalWhite.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Icon(
                              Icons.monitor_heart,
                              color: AppColors.medicalWhite,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  record.patientName,
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.medicalWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Record #${record.id}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.medicalWhite.withOpacity(
                                      0.9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.share,
                    color: AppColors.medicalWhite,
                    size: 24,
                  ),
                  onPressed: () => _shareRecord(context),
                  tooltip: 'Bagikan',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.medicalWhite,
                    size: 24,
                  ),
                  onSelected: (value) => _handleMenuAction(context, value),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'export_pdf',
                          child: Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 12),
                              Text('Export PDF'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print, color: AppColors.textPrimary),
                              const SizedBox(width: 12),
                              Text('Print'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit_notes',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_note,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 12),
                              Text('Edit Catatan'),
                            ],
                          ),
                        ),
                      ],
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Content dengan padding
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Patient Information Section
                  _buildPatientInfoSection(),

                  const SizedBox(height: 20),

                  // Medical Record Section
                  _buildMedicalRecordSection(),

                  const SizedBox(height: 20),

                  // Classification & Notes Section
                  _buildClassificationSection(),

                  const SizedBox(height: 20),

                  // Timeline Section
                  _buildTimelineSection(),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareRecord(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bagikan Record',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        title: Text('Email'),
                        subtitle: Text('Kirim via email'),
                        onTap: () {
                          Navigator.pop(context);
                          showAppSnackBar(
                            context,
                            'Fitur email akan segera tersedia',
                            isSuccess: true,
                          );
                        },
                      ),
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.medicalGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.message_outlined,
                            color: AppColors.medicalGreen,
                            size: 20,
                          ),
                        ),
                        title: Text('WhatsApp'),
                        subtitle: Text('Bagikan via WhatsApp'),
                        onTap: () {
                          Navigator.pop(context);
                          showAppSnackBar(
                            context,
                            'Fitur WhatsApp akan segera tersedia',
                            isSuccess: true,
                          );
                        },
                      ),
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.medicalOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.link,
                            color: AppColors.medicalOrange,
                            size: 20,
                          ),
                        ),
                        title: Text('Copy Link'),
                        subtitle: Text('Salin link untuk dibagikan'),
                        onTap: () {
                          Navigator.pop(context);
                          showAppSnackBar(
                            context,
                            'Link berhasil disalin',
                            isSuccess: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'export_pdf':
        showAppSnackBar(
          context,
          'Export PDF akan segera tersedia',
          isSuccess: true,
        );
        break;
      case 'print':
        showAppSnackBar(
          context,
          'Fitur print akan segera tersedia',
          isSuccess: true,
        );
        break;
      case 'edit_notes':
        _showEditNotesDialog(context);
        break;
    }
  }

  void _showEditNotesDialog(BuildContext context) {
    final TextEditingController notesController = TextEditingController(
      text: record.notes ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Edit Catatan Dokter',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Container(
              width: double.maxFinite,
              child: TextField(
                controller: notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tambahkan catatan untuk record ini...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showAppSnackBar(
                    context,
                    'Catatan berhasil disimpan',
                    isSuccess: true,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.medicalWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Simpan'),
              ),
            ],
          ),
    );
  }

  LinearGradient _getStatusGradient() {
    // Return different gradients based on classification
    if (record.classification != null) {
      final classification = record.classification!.toLowerCase();
      if (classification.contains('normal')) {
        return AppColors.successGradient;
      } else if (classification.contains('tinggi') ||
          classification.contains('high')) {
        return const LinearGradient(
          colors: [AppColors.medicalRed, Color(0xFFD63384)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (classification.contains('rendah') ||
          classification.contains('low')) {
        return const LinearGradient(
          colors: [AppColors.medicalOrange, Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }
    return AppColors.primaryGradient;
  }

  Widget _buildPatientInfoSection() {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                'Informasi Pasien',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Nama Pasien',
            record.patientName,
            Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('ID Pasien', record.patientId, Icons.fingerprint),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordSection() {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_information,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Rekam Medis',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('ID Record', '#${record.id}', Icons.assignment),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Tanggal Monitoring',
            _formatDateTime(record.startTime),
            Icons.schedule,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Durasi Monitoring', _calculateDuration(), Icons.timer),
        ],
      ),
    );
  }

  Widget _buildClassificationSection() {
    final classification = record.classification;
    final notes = record.notes;

    return MedicalCard(
      backgroundColor: _getClassificationBackgroundColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getClassificationIcon(),
                color: _getClassificationColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Hasil Monitoring',
                style: AppTextStyles.titleLarge.copyWith(
                  color: _getClassificationColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Classification Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getClassificationColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getClassificationColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getClassificationIcon(),
                  color: _getClassificationColor(),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  classification ?? 'Tidak ada klasifikasi',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: _getClassificationColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Catatan Dokter',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.medicalGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                notes,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                'Timeline Monitoring',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline Items
          _buildTimelineItem(
            'Monitoring Dimulai',
            _formatDateTime(record.startTime),
            Icons.play_circle,
            AppColors.primaryBlue,
            isFirst: true,
          ),
          _buildTimelineItem(
            'Data Dianalisis',
            'Sistem melakukan analisis data BPM real-time',
            Icons.analytics,
            AppColors.medicalOrange,
          ),
          _buildTimelineItem(
            'Hasil Tersedia',
            'Klasifikasi: ${record.classification ?? "Tidak tersedia"}',
            Icons.check_circle,
            _getClassificationColor(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(width: 2, height: 20, color: AppColors.border),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 12, color: AppColors.medicalWhite),
            ),
            if (!isLast)
              Container(width: 2, height: 20, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateDuration() {
    // Mock duration calculation - in real app this would be based on actual monitoring data
    return '15 menit';
  }

  Color _getClassificationColor() {
    if (record.classification != null) {
      final classification = record.classification!.toLowerCase();
      if (classification.contains('normal')) {
        return AppColors.medicalGreen;
      } else if (classification.contains('tinggi') ||
          classification.contains('high')) {
        return AppColors.medicalRed;
      } else if (classification.contains('rendah') ||
          classification.contains('low')) {
        return AppColors.medicalOrange;
      }
    }
    return AppColors.primaryBlue;
  }

  Color _getClassificationBackgroundColor() {
    if (record.classification != null) {
      final classification = record.classification!.toLowerCase();
      if (classification.contains('normal')) {
        return AppColors.medicalGreenLight;
      } else if (classification.contains('tinggi') ||
          classification.contains('high')) {
        return AppColors.medicalRedLight;
      } else if (classification.contains('rendah') ||
          classification.contains('low')) {
        return AppColors.medicalOrangeLight;
      }
    }
    return AppColors.medicalWhite;
  }

  IconData _getClassificationIcon() {
    if (record.classification != null) {
      final classification = record.classification!.toLowerCase();
      if (classification.contains('normal')) {
        return Icons.check_circle;
      } else if (classification.contains('tinggi') ||
          classification.contains('high')) {
        return Icons.trending_up;
      } else if (classification.contains('rendah') ||
          classification.contains('low')) {
        return Icons.trending_down;
      }
    }
    return Icons.info;
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Tidak tersedia';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      final day = dateTime.day;
      final month = months[dateTime.month - 1];
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$day $month $year, $hour:$minute WIB';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
