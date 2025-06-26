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
    final appBarHeight = kToolbarHeight;
    return PopScope(
      canPop: true, // izinkan pop
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        _resetAndDisconnect();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Monitoring Detak Jantung Janin')),
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - appBarHeight - 32,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  PatientPickerButton(),
                  SizedBox(height: 16),
                  PatientSummarySection(),
                  SizedBox(height: 16),
                  BleConnectionSection(),
                  BleErrorSection(),
                  SizedBox(height: 16),
                  MonitoringControlSection(),
                  MonitoringProgressSection(),
                  BleStreamSection(),
                  ChartSection(),
                  MonitoringResultSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget tombol pilih/tambah pasien
class PatientPickerButton extends ConsumerWidget {
  const PatientPickerButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    final notifier = ref.read(monitoringNotifierProvider.notifier);
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_search),
      label: const Text('Pilih/Tambah Pasien'),
      onPressed:
          state.isMonitoring
              ? null
              : () async {
                await showDialog(
                  context: context,
                  builder: (context) => const PatientPickerDialog(),
                );
              },
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

/// Widget tombol koneksi BLE ke ESP32
class BleConnectionSection extends ConsumerWidget {
  const BleConnectionSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    final notifier = ref.read(monitoringNotifierProvider.notifier);
    final pageState = context.findAncestorStateOfType<_MonitoringPageState>();
    return ESP32ConnectionButton(
      isConnected: state.isConnected,
      isMonitoring: state.isMonitoring,
      onConnect: () {
        pageState?._bleController?.connect();
        notifier.connectESP32();
      },
      onDisconnect: () {
        pageState?._bleController?.disconnect();
        notifier.disconnectESP32();
      },
    );
  }
}

/// Widget error BLE jika ada
class BleErrorSection extends ConsumerWidget {
  const BleErrorSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    if (state.bleError == null || state.bleError!.isEmpty)
      return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        state.bleError!,
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Widget tombol monitoring dan stop monitoring
class MonitoringControlSection extends ConsumerWidget {
  const MonitoringControlSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    final notifier = ref.read(monitoringNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonitoringButton(
          isConnected: state.isConnected,
          isMonitoring: state.isMonitoring,
          monitoringDone: state.monitoringDone,
          onStart: notifier.startMonitoring,
        ),
        if (state.isMonitoring)
          ElevatedButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stop Monitoring'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              notifier.stopMonitoring();
            },
          ),
      ],
    );
  }
}

/// Widget progress bar monitoring
class MonitoringProgressSection extends ConsumerWidget {
  const MonitoringProgressSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
    return MonitoringProgress(isMonitoring: state.isMonitoring);
  }
}

/// Widget stream BPM dari ESP32
class BleStreamSection extends ConsumerWidget {
  const BleStreamSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = context.findAncestorStateOfType<_MonitoringPageState>();
    final state = ref.watch(monitoringNotifierProvider);
    final notifier = ref.read(monitoringNotifierProvider.notifier);
    if (pageState?._bleController == null) return const SizedBox.shrink();
    return Esp32BleBpmStreamWidget(
      controller: pageState!._bleController!,
      onBpmReceived: (bpm) {
        notifier.updateBpmFromEsp32(bpm);
      },
    );
  }
}

/// Widget chart BPM real-time
class ChartSection extends ConsumerWidget {
  const ChartSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringNotifierProvider);
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
    return MonitoringResultCard(
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
            ),
          );
        }
      },
      monitoringDone: state.monitoringDone,
    );
  }
}
