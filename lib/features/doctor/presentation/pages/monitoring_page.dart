import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/monitoring_notifier.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/patient_picker_dialog.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/patient_summary_card.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/esp32_connection_button.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/monitoring_button.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/monitoring_progress.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/bpm_realtime_chart_widget.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/monitoring_result_card.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/esp32_ble_bpm_stream_widget.dart';
import 'package:dopply_app/app/theme.dart';

// MonitoringPage: Halaman utama monitoring detak jantung janin untuk dokter
class MonitoringPage extends ConsumerStatefulWidget {
  const MonitoringPage({super.key});

  @override
  ConsumerState<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends ConsumerState<MonitoringPage> {
  // Controller untuk mengelola koneksi BLE dan stream BPM dari ESP32
  Esp32BleBpmStreamWidgetController? _bleController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller BLE setiap kali halaman dibuka
    _bleController = Esp32BleBpmStreamWidgetController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set controller ke ViewModel agar bisa diakses dan dikontrol
      ref
          .read(monitoringNotifierProvider.notifier)
          .setBleController(_bleController!);
    });
  }

  @override
  void dispose() {
    _resetAndDisconnect();
    _bleController = null;
    super.dispose();
  }

  // Helper untuk reset dan disconnect BLE/monitoring agar tidak duplikat
  void _resetAndDisconnect() {
    try {
      final notifier = ref.read(monitoringNotifierProvider.notifier);
      final state = ref.read(monitoringNotifierProvider);
      if (state.isMonitoring) {
        notifier.stopMonitoringESP32();
      }
      if (state.isConnected) {
        _bleController?.disconnect();
        notifier.disconnectESP32();
      }
      notifier.resetAllMonitoringState();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        _resetAndDisconnect();
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
                // Header Section dengan Medical Card
                const MedicalHeaderSection(),
                const SizedBox(height: 20),

                // Patient Section
                const PatientManagementSection(),
                const SizedBox(height: 20),

                // Device Connection Section
                const DeviceConnectionSection(),
                const SizedBox(height: 20),

                // Monitoring Control Section
                const MonitoringControlSection(),
                const SizedBox(height: 20),

                // Live Data Section
                const LiveDataSection(),
                const SizedBox(height: 20),

                // Results Section
                const MonitoringResultSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget tombol pilih/tambah pasien dengan medical theme
class PatientPickerButton extends ConsumerWidget {
  const PatientPickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(
          Icons.person_search,
          color:
              state.isMonitoring
                  ? AppColors.textTertiary
                  : AppColors.medicalWhite,
        ),
        label: Text(
          'Pilih/Tambah Pasien',
          style: AppTextStyles.labelLarge.copyWith(
            color:
                state.isMonitoring
                    ? AppColors.textTertiary
                    : AppColors.medicalWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              state.isMonitoring ? AppColors.border : AppColors.primaryBlue,
          foregroundColor:
              state.isMonitoring
                  ? AppColors.textTertiary
                  : AppColors.medicalWhite,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: state.isMonitoring ? 0 : 2,
          shadowColor: AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
        onPressed:
            state.isMonitoring
                ? null
                : () async {
                  await showDialog(
                    context: context,
                    builder: (context) => const PatientPickerDialog(),
                  );
                },
      ),
    );
  }
}

/// Widget ringkasan pasien yang dipilih
class PatientSummarySection extends ConsumerWidget {
  const PatientSummarySection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    return PatientSummaryCard(
      patientName:
          state.selectedPatientName.isEmpty
              ? 'Belum ada pasien dipilih'
              : state.selectedPatientName,
      patientId:
          state.selectedPatientId.isEmpty ? '-' : state.selectedPatientId,
    );
  }
}

/// Widget tombol koneksi BLE ke ESP32 dengan medical theme
class BleConnectionSection extends ConsumerWidget {
  const BleConnectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    final pageState = context.findAncestorStateOfType<_MonitoringPageState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Connection Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                state.isConnected
                    ? AppColors.medicalGreenLight
                    : AppColors.medicalRedLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  state.isConnected
                      ? AppColors.medicalGreen
                      : AppColors.medicalRed,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                state.isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color:
                    state.isConnected
                        ? AppColors.medicalGreen
                        : AppColors.medicalRed,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                state.isConnected ? 'ESP32 Terhubung' : 'ESP32 Terputus',
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      state.isConnected
                          ? AppColors.medicalGreen
                          : AppColors.medicalRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Connection Button
        ESP32ConnectionButton(
          isConnected: state.isConnected,
          isMonitoring: state.isMonitoring,
          onConnect: () {
            pageState?._bleController?.connect();
            ref.read(monitoringNotifierProvider.notifier).connectESP32();
          },
          onDisconnect: () {
            pageState?._bleController?.disconnect();
            ref.read(monitoringNotifierProvider.notifier).disconnectESP32();
          },
        ),
      ],
    );
  }
}

/// Widget error BLE jika ada dengan medical theme
class BleErrorSection extends ConsumerWidget {
  const BleErrorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);

    if (state.bleError == null || state.bleError!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.medicalRedLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.medicalRed, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.medicalRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.bleError!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.medicalRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget tombol monitoring dan stop monitoring dengan medical theme
class MonitoringControlSection extends ConsumerWidget {
  const MonitoringControlSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    final notifier = ref.read(monitoringNotifierProvider.notifier);

    return MedicalCard(
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
                  state.isMonitoring ? Icons.stop : Icons.play_arrow,
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

          // Main monitoring button
          SizedBox(
            width: double.infinity,
            child: MonitoringButton(
              isConnected: state.isConnected,
              isMonitoring: state.isMonitoring,
              monitoringDone: state.monitoringDone,
              onStart: notifier.startMonitoring,
            ),
          ),

          // Stop button when monitoring
          if (state.isMonitoring) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: Text(
                  'Stop Monitoring',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.medicalWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicalRed,
                  foregroundColor: AppColors.medicalWhite,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.medicalRed.withValues(alpha: 0.3),
                ),
                onPressed: () async {
                  notifier.stopMonitoring();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget progress bar monitoring dengan medical theme
class MonitoringProgressSection extends ConsumerWidget {
  const MonitoringProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);

    if (!state.isMonitoring) {
      return const SizedBox.shrink();
    }

    return MonitoringProgress(isMonitoring: state.isMonitoring);
  }
}

/// Widget stream BPM dari ESP32
class BleStreamSection extends ConsumerWidget {
  const BleStreamSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = context.findAncestorStateOfType<_MonitoringPageState>();
    final notifier = ref.read(monitoringNotifierProvider.notifier);

    if (pageState?._bleController == null) {
      return const SizedBox.shrink();
    }

    return Esp32BleBpmStreamWidget(
      controller: pageState!._bleController!,
      onBpmReceived: (bpm) {
        notifier.updateBpmFromEsp32(bpm);
      },
    );
  }
}

/// Widget chart BPM real-time dengan medical theme
class ChartSection extends ConsumerWidget {
  const ChartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(monitoringNotifierProvider.notifier);

    return BpmRealtimeChartWidget(bpmData: notifier.bpmDataForChart);
  }
}

/// Widget hasil monitoring dan input catatan dokter
class MonitoringResultSection extends ConsumerWidget {
  const MonitoringResultSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    final notifier = ref.read(monitoringNotifierProvider.notifier);

    if (!state.monitoringDone && state.monitoringResult == null) {
      return const SizedBox.shrink();
    }

    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in,
                color: AppColors.primaryBlue,
                size: 24,
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

          MonitoringResultCard(
            monitoringResult: state.monitoringResult,
            classification: state.classification,
            doctorNote: state.doctorNote,
            onNoteChanged: notifier.updateDoctorNote,
            onSave: () async {
              final success = await notifier.saveResult();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hasil pemeriksaan berhasil disimpan!'),
                    backgroundColor: AppColors.medicalGreen,
                  ),
                );
              }
            },
            monitoringDone: state.monitoringDone,
          ),
        ],
      ),
    );
  }
}

/// Header Section dengan informasi monitoring
class MedicalHeaderSection extends ConsumerWidget {
  const MedicalHeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MedicalCard(
      child: Column(
        children: [
          Row(
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
                      'Pemantauan detak jantung janin real-time',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section untuk manajemen pasien
class PatientManagementSection extends ConsumerWidget {
  const PatientManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MedicalCard(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Pasien',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Pilih pasien untuk monitoring',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Patient Picker Button
          const PatientPickerButton(),

          const SizedBox(height: 12),

          // Patient Summary
          const PatientSummarySection(),
        ],
      ),
    );
  }
}

/// Section untuk koneksi device
class DeviceConnectionSection extends ConsumerWidget {
  const DeviceConnectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MedicalCard(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koneksi ESP32',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Hubungkan dengan perangkat monitoring',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Connection controls
          const BleConnectionSection(),

          // Error display
          const BleErrorSection(),
        ],
      ),
    );
  }
}

/// Section untuk live data monitoring
class LiveDataSection extends ConsumerWidget {
  const LiveDataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);

    if (!state.isMonitoring && !state.monitoringDone) {
      return const SizedBox.shrink();
    }

    return MedicalCard(
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
                  Icons.show_chart,
                  color: AppColors.medicalWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Real-time',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Monitoring detak jantung janin aktif',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isMonitoring)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.medicalGreenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.medicalGreen),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.medicalGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.medicalGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Current BPM Display
          const CurrentBpmDisplay(),

          // Progress
          const MonitoringProgressSection(),

          // BLE Stream
          const BleStreamSection(),

          // Chart
          const ChartSection(),
        ],
      ),
    );
  }
}

/// Widget untuk menampilkan BPM real-time dengan status
class CurrentBpmDisplay extends ConsumerWidget {
  const CurrentBpmDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    final notifier = ref.read(monitoringNotifierProvider.notifier);

    // Get latest BPM from chart data
    final bpmData = notifier.bpmDataForChart;
    final latestBpm = bpmData.isNotEmpty ? bpmData.last.bpm : 0;

    if (!state.isMonitoring || latestBpm == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.medicalGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // BPM Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BPM Saat Ini',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$latestBpm',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'BPM',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Indicator
          Column(
            children: [
              BpmStatusIndicator(bpm: latestBpm, size: 32, showLabel: false),
              const SizedBox(height: 8),
              BpmStatusIndicator(bpm: latestBpm, size: 16, showLabel: true),
            ],
          ),
        ],
      ),
    );
  }
}
