// =============================================================================
// Modern Fetal Monitoring Page for Patients
//
// Self-monitoring page for patients using new architecture
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/app/theme.dart';
import 'package:dopply_app/shared/services/fetal_doppler_ble_service.dart';
import 'package:dopply_app/shared/models/fetal_monitoring.dart';
import 'package:dopply_app/features/auth/presentation/providers/user_provider.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/fetal_monitoring_notifier.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/fetal_ble_monitoring_widget.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/fetal_bpm_realtime_chart_widget.dart';

class ModernFetalMonitoringPagePatient extends ConsumerStatefulWidget {
  const ModernFetalMonitoringPagePatient({super.key});

  @override
  ConsumerState<ModernFetalMonitoringPagePatient> createState() =>
      _ModernFetalMonitoringPagePatientState();
}

class _ModernFetalMonitoringPagePatientState
    extends ConsumerState<ModernFetalMonitoringPagePatient> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPatientInfo();
    });
  }

  void _setupPatientInfo() {
    final user = ref.read(userProvider);
    final monitoringNotifier = ref.read(fetalMonitoringProvider.notifier);

    if (user != null) {
      // For patient self-monitoring, use patient's own info
      monitoringNotifier.selectPatient(
        patientId: user.id.toString(),
        patientName: user.email, // Use email as name for now, can be improved
        gestationalAge: 20, // Default, should be set by patient
      );
    }
  }

  @override
  void dispose() {
    _resetMonitoring();
    super.dispose();
  }

  void _resetMonitoring() {
    final monitoringNotifier = ref.read(fetalMonitoringProvider.notifier);
    final bleNotifier = ref.read(fetalDopplerBLEProvider.notifier);

    // Stop monitoring and disconnect
    monitoringNotifier.resetState();
    bleNotifier.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        _resetMonitoring();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Monitoring Mandiri',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.medicalWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.medicalWhite,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                const PatientHeaderSection(),
                const SizedBox(height: 20),

                // Patient Info Section
                const PatientInfoSection(),
                const SizedBox(height: 20),

                // BLE Connection Section
                const PatientBLEConnectionSection(),
                const SizedBox(height: 20),

                // Monitoring Control Section
                const PatientMonitoringControlSection(),
                const SizedBox(height: 20),

                // Current BPM Display
                const PatientCurrentBPMSection(),
                const SizedBox(height: 20),

                // Chart Section
                const PatientChartSection(),
                const SizedBox(height: 20),

                // Results Section
                const PatientResultsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Patient Header Section
class PatientHeaderSection extends StatelessWidget {
  const PatientHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.medicalGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: AppColors.medicalWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monitoring Mandiri',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau detak jantung janin Anda dari rumah dengan mudah dan aman',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Patient Info Section
class PatientInfoSection extends ConsumerWidget {
  const PatientInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final monitoringState = ref.watch(fetalMonitoringProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.medicalWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.medicalWhite,
                  size: 20,
                ),
              ),
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

          // Patient Info Display
          _buildInfoRow('Email', user?.email ?? '-'),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Usia Kehamilan',
            '${monitoringState.gestationalAge} minggu',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Status',
            user?.isValid == true ? 'Terverifikasi' : 'Belum Verifikasi',
          ),

          const SizedBox(height: 16),

          // Notice for patients
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBlue, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Monitoring mandiri tidak menggantikan pemeriksaan dokter. Konsultasikan hasil dengan dokter Anda.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// Patient BLE Connection Section
class PatientBLEConnectionSection extends ConsumerWidget {
  const PatientBLEConnectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.medicalWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bluetooth,
                  color: AppColors.medicalWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Koneksi Fetal Doppler',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.medicalGreenLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.medicalGreen, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Petunjuk Penggunaan:',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.medicalGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInstructionItem(
                  '1. Pastikan fetal doppler dalam keadaan hidup',
                ),
                _buildInstructionItem('2. Tekan tombol hubungkan di bawah'),
                _buildInstructionItem(
                  '3. Letakkan probe pada perut sesuai petunjuk',
                ),
                _buildInstructionItem('4. Mulai monitoring setelah terhubung'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // BLE Connection Widget
          FetalBLEConnectionWidget(
            onConnected: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fetal Doppler berhasil terhubung!'),
                  backgroundColor: AppColors.medicalGreen,
                ),
              );
            },
            onDisconnected: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fetal Doppler terputus'),
                  backgroundColor: AppColors.medicalOrange,
                ),
              );
            },
            onError: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terjadi kesalahan koneksi'),
                  backgroundColor: AppColors.medicalRed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.medicalGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.medicalGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Patient Monitoring Control Section
class PatientMonitoringControlSection extends ConsumerWidget {
  const PatientMonitoringControlSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringState = ref.watch(fetalMonitoringProvider);
    final monitoringNotifier = ref.read(fetalMonitoringProvider.notifier);
    final bleState = ref.watch(fetalDopplerBLEProvider);

    final isConnected =
        bleState == BLEConnectionState.connected ||
        bleState == BLEConnectionState.monitoring;
    final canStartMonitoring = isConnected && !monitoringState.isMonitoring;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.medicalWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  monitoringState.isMonitoring ? Icons.stop : Icons.play_arrow,
                  color: AppColors.medicalWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Kontrol Monitoring',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Monitoring Control Widget
          FetalMonitoringControlWidget(
            isMonitoring: monitoringState.isMonitoring,
            onStartMonitoring:
                canStartMonitoring
                    ? () async {
                      await monitoringNotifier.startMonitoring(
                        type: MonitoringType.home,
                      );
                    }
                    : null,
            onStopMonitoring:
                monitoringState.isMonitoring
                    ? () async {
                      await monitoringNotifier.stopMonitoring();
                    }
                    : null,
          ),

          // Status and restrictions
          if (!isConnected)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.medicalOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hubungkan fetal doppler terlebih dahulu',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.medicalOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Patient Current BPM Section
class PatientCurrentBPMSection extends ConsumerWidget {
  const PatientCurrentBPMSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringState = ref.watch(fetalMonitoringProvider);

    if (!monitoringState.isMonitoring ||
        monitoringState.latestReading == null) {
      return const SizedBox.shrink();
    }

    return CurrentFetalBPMDisplay(latestReading: monitoringState.latestReading);
  }
}

// Patient Chart Section
class PatientChartSection extends ConsumerWidget {
  const PatientChartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringState = ref.watch(fetalMonitoringProvider);

    if (!monitoringState.isMonitoring && monitoringState.readings.isEmpty) {
      return const SizedBox.shrink();
    }

    return const FetalBpmRealtimeChartWidget();
  }
}

// Patient Results Section
class PatientResultsSection extends ConsumerStatefulWidget {
  const PatientResultsSection({super.key});

  @override
  ConsumerState<PatientResultsSection> createState() =>
      _PatientResultsSectionState();
}

class _PatientResultsSectionState extends ConsumerState<PatientResultsSection> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitoringState = ref.watch(fetalMonitoringProvider);
    final monitoringNotifier = ref.read(fetalMonitoringProvider.notifier);

    if (monitoringState.result == null) {
      return const SizedBox.shrink();
    }

    final result = monitoringState.result!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.medicalWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_turned_in,
                  color: AppColors.medicalWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Hasil Monitoring',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Result Summary
          _buildResultSummary(result),
          const SizedBox(height: 16),

          // Patient Notes Input
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Catatan Pribadi',
              hintText:
                  'Tambahkan catatan tentang kondisi Anda saat monitoring...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save and Share Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.medicalGreen,
                    foregroundColor: AppColors.medicalWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final success = await monitoringNotifier.saveSession(
                      doctorNotes: _notesController.text.trim(),
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hasil monitoring berhasil disimpan!'),
                          backgroundColor: AppColors.medicalGreen,
                        ),
                      );
                      _notesController.clear();
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal menyimpan hasil monitoring'),
                          backgroundColor: AppColors.medicalRed,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Bagikan ke Dokter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Implement share to doctor functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fitur bagikan ke dokter akan segera tersedia',
                        ),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummary(FetalMonitoringResult result) {
    Color classificationColor;
    IconData classificationIcon;

    switch (result.overallClassification.toLowerCase()) {
      case 'normal':
        classificationColor = AppColors.medicalGreen;
        classificationIcon = Icons.check_circle;
        break;
      case 'concerning':
        classificationColor = AppColors.medicalOrange;
        classificationIcon = Icons.warning;
        break;
      case 'abnormal':
        classificationColor = AppColors.medicalRed;
        classificationIcon = Icons.error;
        break;
      default:
        classificationColor = AppColors.textSecondary;
        classificationIcon = Icons.help;
    }

    return Column(
      children: [
        // Overall Classification
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: classificationColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: classificationColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(classificationIcon, color: classificationColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasil: ${result.overallClassification.toUpperCase()}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: classificationColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Rata-rata BPM: ${result.averageBPM.round()}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: classificationColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Recommendations for patient
        if (result.recommendations.isNotEmpty)
          _buildSection('Rekomendasi:', result.recommendations),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: AppTextStyles.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
