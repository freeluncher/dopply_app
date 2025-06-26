import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/monitoring_view_model.dart';
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
          .read(monitoringViewModelProvider.notifier)
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
      final notifier = ref.read(monitoringViewModelProvider.notifier);
      final vm = ref.read(monitoringViewModelProvider);
      if (vm.isMonitoring) {
        notifier.stopMonitoringESP32();
      }
      if (vm.isConnected) {
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
    final vm = ref.watch(monitoringViewModelProvider);
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_search),
      label: const Text('Pilih/Tambah Pasien'),
      onPressed:
          vm.isMonitoring
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
    final vm = ref.watch(monitoringViewModelProvider);
    return PatientSummaryCard(
      patientName:
          vm.patientName.isEmpty ? 'Belum ada pasien dipilih' : vm.patientName,
      patientId: vm.patientId.isEmpty ? '-' : vm.patientId,
    );
  }
}

/// Widget tombol koneksi BLE ke ESP32
class BleConnectionSection extends ConsumerWidget {
  const BleConnectionSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(monitoringViewModelProvider);
    final state = context.findAncestorStateOfType<_MonitoringPageState>();
    return ESP32ConnectionButton(
      isConnected: vm.isConnected,
      isMonitoring: vm.isMonitoring,
      onConnect: () {
        state?._bleController?.connect();
        vm.connectESP32();
      },
      onDisconnect: () {
        state?._bleController?.disconnect();
        vm.disconnectESP32();
      },
    );
  }
}

/// Widget error BLE jika ada
class BleErrorSection extends ConsumerWidget {
  const BleErrorSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(monitoringViewModelProvider);
    if (vm.bleError == null || vm.bleError!.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        vm.bleError!,
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
    final vm = ref.watch(monitoringViewModelProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonitoringButton(
          isConnected: vm.isConnected,
          isMonitoring: vm.isMonitoring,
          monitoringDone: vm.monitoringDone,
          onStart: vm.startMonitoring,
        ),
        if (vm.isMonitoring)
          ElevatedButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stop Monitoring'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              vm.stopMonitoring(context);
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
    final vm = ref.watch(monitoringViewModelProvider);
    return MonitoringProgress(isMonitoring: vm.isMonitoring);
  }
}

/// Widget stream BPM dari ESP32
class BleStreamSection extends ConsumerWidget {
  const BleStreamSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = context.findAncestorStateOfType<_MonitoringPageState>();
    final vm = ref.watch(monitoringViewModelProvider);
    if (state?._bleController == null) return const SizedBox.shrink();
    return Esp32BleBpmStreamWidget(
      controller: state!._bleController!,
      onBpmReceived: (bpm) {
        vm.updateBpmFromEsp32(bpm);
      },
    );
  }
}

/// Widget chart BPM real-time
class ChartSection extends ConsumerWidget {
  const ChartSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(monitoringViewModelProvider);
    return BpmRealtimeChartWidget(bpmData: vm.bpmDataForChart);
  }
}

/// Widget hasil monitoring dan input catatan dokter
class MonitoringResultSection extends ConsumerWidget {
  const MonitoringResultSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(monitoringViewModelProvider);
    return MonitoringResultCard(
      monitoringResult: vm.monitoringResult,
      classification: vm.classification,
      doctorNote: vm.doctorNote,
      onNoteChanged: vm.updateDoctorNote,
      onSave: () => vm.saveResult(context),
      monitoringDone: vm.monitoringDone,
    );
  }
}
