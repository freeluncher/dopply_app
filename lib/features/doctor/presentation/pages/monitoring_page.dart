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
  final Esp32BleBpmStreamWidgetController _bleController =
      Esp32BleBpmStreamWidgetController();

  @override
  void initState() {
    super.initState();
    // Hubungkan controller BLE ke ViewModel
    final vm = ref.read(monitoringViewModelProvider);
    vm.setBleController(_bleController);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(monitoringViewModelProvider);
    final appBarHeight = kToolbarHeight;
    return Scaffold(
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
                              builder: (context) => const PatientPickerDialog(),
                            );
                          },
                ),
                const SizedBox(height: 16),
                PatientSummaryCard(
                  patientName: vm.patientName,
                  patientId: vm.patientId,
                ),
                const SizedBox(height: 16),
                ESP32ConnectionButton(
                  isConnected: vm.isConnected,
                  isMonitoring: vm.isMonitoring,
                  onConnect: () {
                    _bleController.connect();
                    vm.connectESP32();
                  },
                  onDisconnect: () {
                    _bleController.disconnect();
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
                Esp32BleBpmStreamWidget(
                  controller: _bleController,
                  onBpmReceived: (bpm) {
                    vm.updateBpmFromEsp32(bpm);
                  },
                ),
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
    );
  }
}
