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

class MonitoringPage extends ConsumerStatefulWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends ConsumerState<MonitoringPage> {
  Esp32BleBpmStreamWidgetController? _bleController;

  @override
  void initState() {
    super.initState();
    // Buat controller baru setiap halaman dibuka
    _bleController = Esp32BleBpmStreamWidgetController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(monitoringViewModelProvider.notifier)
          .setBleController(_bleController!);
    });
  }

  @override
  void dispose() {
    debugPrint('[MONITORING_PAGE] dispose dipanggil pada ${DateTime.now()}');
    final notifier = ref.read(monitoringViewModelProvider.notifier);
    final vm = ref.read(monitoringViewModelProvider);
    debugPrint(
      '[MONITORING_PAGE] Sebelum reset: isMonitoring=${vm.isMonitoring}, isConnected=${vm.isConnected}',
    );
    if (vm.isMonitoring) {
      notifier.stopMonitoringESP32();
    }
    if (vm.isConnected) {
      _bleController?.disconnect();
      notifier.disconnectESP32(silent: true);
    }
    notifier.resetAllMonitoringState();
    _bleController = null; // pastikan controller dihapus
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(monitoringViewModelProvider);
    final appBarHeight = kToolbarHeight;
    return WillPopScope(
      onWillPop: () async {
        // Panggil semua reset/disconnect logic sebelum keluar
        final notifier = ref.read(monitoringViewModelProvider.notifier);
        final vm = ref.read(monitoringViewModelProvider);
        debugPrint(
          '[MONITORING_PAGE] WillPopScope triggered at \\${DateTime.now()}',
        );
        if (vm.isMonitoring) {
          notifier.stopMonitoringESP32();
        }
        if (vm.isConnected) {
          _bleController?.disconnect();
          notifier.disconnectESP32(silent: true);
        }
        notifier.resetAllMonitoringState();
        _bleController = null;
        return true; // izinkan pop
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
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_search),
                    label: const Text('Pilih/Tambah Pasien'),
                    onPressed:
                        vm.isMonitoring
                            ? null
                            : () async {
                              await showDialog(
                                context: context,
                                builder:
                                    (context) => const PatientPickerDialog(),
                              );
                            },
                  ),
                  const SizedBox(height: 16),
                  PatientSummaryCard(
                    patientName:
                        vm.patientName.isEmpty
                            ? 'Belum ada pasien dipilih'
                            : vm.patientName,
                    patientId: vm.patientId.isEmpty ? '-' : vm.patientId,
                  ),
                  const SizedBox(height: 16),
                  ESP32ConnectionButton(
                    isConnected: vm.isConnected,
                    isMonitoring: vm.isMonitoring,
                    onConnect: () {
                      _bleController?.connect();
                      vm.connectESP32();
                    },
                    onDisconnect: () {
                      _bleController?.disconnect();
                      vm.disconnectESP32();
                    },
                  ),
                  const SizedBox(height: 16),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        vm.stopMonitoring(context);
                      },
                    ),
                  MonitoringProgress(isMonitoring: vm.isMonitoring),
                  _bleController != null
                      ? Esp32BleBpmStreamWidget(
                        controller: _bleController!,
                        onBpmReceived: (bpm) {
                          vm.updateBpmFromEsp32(bpm);
                        },
                      )
                      : const SizedBox.shrink(),
                  BpmRealtimeChartWidget(bpmData: vm.bpmDataForChart),
                  MonitoringResultCard(
                    monitoringResult: vm.monitoringResult,
                    classification: vm.classification,
                    doctorNote: vm.doctorNote,
                    onNoteChanged: vm.updateDoctorNote,
                    onSave: () => vm.saveResult(context),
                    monitoringDone: vm.monitoringDone,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
