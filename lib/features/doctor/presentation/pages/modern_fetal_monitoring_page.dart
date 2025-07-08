// =============================================================================
// Modern Fetal Monitoring Page
//
// New fetal heart rate monitoring page using improved architecture
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/app/theme.dart';
import 'package:dopply_app/shared/services/fetal_doppler_ble_service.dart';
import 'package:dopply_app/shared/models/fetal_monitoring.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/fetal_monitoring_notifier.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/fetal_ble_monitoring_widget.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/fetal_bpm_realtime_chart_widget.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/patient_picker_dialog.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/patient_summary_card.dart';
import 'package:dopply_app/features/doctor/presentation/models/monitoring_patient.dart';

class ModernFetalMonitoringPage extends ConsumerStatefulWidget {
  const ModernFetalMonitoringPage({super.key});

  @override
  ConsumerState<ModernFetalMonitoringPage> createState() =>
      _ModernFetalMonitoringPageState();
}

class _ModernFetalMonitoringPageState
    extends ConsumerState<ModernFetalMonitoringPage> {
  @override
  void dispose() {
    // Clean up when leaving page
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
            'Monitoring Detak Jantung Janin',
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
                const ModernHeaderSection(),
                const SizedBox(height: 20),

                // Patient Selection Section
                const PatientSelectionSection(),
                const SizedBox(height: 20),

                // BLE Connection Section
                const BLEConnectionSection(),
                const SizedBox(height: 20),

                // Monitoring Control Section
                const MonitoringControlSection(),
                const SizedBox(height: 20),

                // Current BPM Display
                const CurrentBPMSection(),
                const SizedBox(height: 20),

                // Chart Section
                const ChartSection(),
                const SizedBox(height: 20),

                // Results Section
                const ResultsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Header Section
class ModernHeaderSection extends StatelessWidget {
  const ModernHeaderSection({super.key});

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
              Icons.monitor_heart,
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
                  'Fetal Heart Rate Monitoring',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistem monitoring detak jantung janin modern dengan analisis real-time',
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

// Patient Selection Section
class PatientSelectionSection extends ConsumerWidget {
  const PatientSelectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Icons.person_search,
                  color: AppColors.medicalWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pilih Pasien',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Patient Picker Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.person_search,
                color:
                    monitoringState.isMonitoring
                        ? AppColors.textTertiary
                        : AppColors.medicalWhite,
              ),
              label: Text(
                'Pilih/Tambah Pasien',
                style: AppTextStyles.labelLarge.copyWith(
                  color:
                      monitoringState.isMonitoring
                          ? AppColors.textTertiary
                          : AppColors.medicalWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    monitoringState.isMonitoring
                        ? AppColors.border
                        : AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: monitoringState.isMonitoring ? 0 : 2,
              ),
              onPressed:
                  monitoringState.isMonitoring
                      ? null
                      : () async {
                        final selectedPatient =
                            await showDialog<MonitoringPatient>(
                              context: context,
                              builder: (context) => const PatientPickerDialog(),
                            );

                        if (selectedPatient != null) {
                          final monitoringNotifier = ref.read(
                            fetalMonitoringProvider.notifier,
                          );
                          // Use default gestational age or patient's age-based estimate
                          final gestationalAge =
                              selectedPatient.age != null &&
                                      selectedPatient.age! > 0
                                  ? (selectedPatient.age! < 20
                                      ? 20
                                      : (selectedPatient.age! > 35 ? 35 : 30))
                                  : 30;
                          monitoringNotifier.selectPatientObject(
                            selectedPatient,
                            gestationalAge: gestationalAge,
                          );
                        }
                      },
            ),
          ),

          const SizedBox(height: 12),

          // Patient Summary
          PatientSummaryCard(
            patientName: monitoringState.selectedPatientName,
            patientId: monitoringState.selectedPatientId ?? '-',
            patient: monitoringState.selectedPatient,
          ),
        ],
      ),
    );
  }
}

// BLE Connection Section
class BLEConnectionSection extends ConsumerWidget {
  const BLEConnectionSection({super.key});

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
}

// Monitoring Control Section
class MonitoringControlSection extends ConsumerWidget {
  const MonitoringControlSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringState = ref.watch(fetalMonitoringProvider);
    final monitoringNotifier = ref.read(fetalMonitoringProvider.notifier);
    final bleState = ref.watch(fetalDopplerBLEProvider);

    final isConnected =
        bleState == BLEConnectionState.connected ||
        bleState == BLEConnectionState.monitoring;
    final canStartMonitoring =
        isConnected &&
        !monitoringState.isMonitoring &&
        monitoringState.selectedPatientId != null;

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
                        type: MonitoringType.clinic,
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

          if (isConnected && monitoringState.selectedPatientId == null)
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
                      'Pilih pasien terlebih dahulu',
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

// Current BPM Section
class CurrentBPMSection extends ConsumerWidget {
  const CurrentBPMSection({super.key});

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

// Chart Section
class ChartSection extends ConsumerWidget {
  const ChartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringState = ref.watch(fetalMonitoringProvider);

    if (!monitoringState.isMonitoring && monitoringState.readings.isEmpty) {
      return const SizedBox.shrink();
    }

    return const FetalBpmRealtimeChartWidget();
  }
}

// Results Section
class ResultsSection extends ConsumerStatefulWidget {
  const ResultsSection({super.key});

  @override
  ConsumerState<ResultsSection> createState() => _ResultsSectionState();
}

class _ResultsSectionState extends ConsumerState<ResultsSection> {
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

          // Doctor Notes Input
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Catatan Dokter',
              hintText: 'Tambahkan catatan atau rekomendasi untuk pasien...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Simpan Hasil Monitoring'),
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

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hasil monitoring berhasil disimpan!'),
                      backgroundColor: AppColors.medicalGreen,
                    ),
                  );
                  _notesController.clear();
                } else {
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
                      'Klasifikasi: ${result.overallClassification.toUpperCase()}',
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

        // Findings
        if (result.findings.isNotEmpty) ...[
          _buildSection('Temuan Klinis:', result.findings),
          const SizedBox(height: 12),
        ],

        // Recommendations
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
