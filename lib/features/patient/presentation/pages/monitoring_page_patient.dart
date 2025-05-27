import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/monitoring_view_model_patient.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/monitoring_button.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/monitoring_progress.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/bpm_realtime_chart_widget.dart';
import 'package:dopply_app/features/patient/presentation/widgets/esp32_ble_bpm_stream_widget.dart';
import 'package:dopply_app/features/patient/presentation/widgets/patient_summary_card_patient.dart';
import 'package:dopply_app/features/patient/presentation/widgets/esp32_connection_button.dart'
    as patient_btn;
import 'package:dopply_app/features/doctor/presentation/viewmodels/bpm_point.dart'
    as doctor_bpm;
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';

class MonitoringPagePatient extends ConsumerStatefulWidget {
  const MonitoringPagePatient({Key? key}) : super(key: key);

  @override
  ConsumerState<MonitoringPagePatient> createState() =>
      _MonitoringPagePatientState();
}

class _MonitoringPagePatientState extends ConsumerState<MonitoringPagePatient> {
  Esp32BleBpmStreamWidgetController? _bleController;

  @override
  void initState() {
    super.initState();
    debugPrint('[MonitoringPagePatient] initState called');
    _bleController = Esp32BleBpmStreamWidgetController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ambil user dari provider dan set ke ViewModel jika belum ada
      final user = ref.read(userProvider);
      final notifier = ref.read(monitoringViewModelPatientProvider.notifier);
      debugPrint(
        '[MonitoringPagePatient] user: \\${user?.id} / \\${user?.email}',
      );
      if (user != null &&
          (notifier.patientName.isEmpty || notifier.patientId.isEmpty)) {
        notifier.setPatientName(
          user.email,
        ); // Ganti ke nama jika ada field nama
        notifier.setPatientId(user.id);
        debugPrint(
          '[MonitoringPagePatient] setPatientName/id: \\${user.email} / \\${user.id}',
        );
      }
      notifier.setBleController(_bleController!);
      debugPrint('[MonitoringPagePatient] BLE controller set');
    });
  }

  @override
  void dispose() {
    final notifier = ref.read(monitoringViewModelPatientProvider.notifier);
    final vm = ref.read(monitoringViewModelPatientProvider);
    if (vm.isMonitoring) {
      notifier.stopMonitoringESP32();
    }
    if (vm.isConnected) {
      _bleController?.disconnect();
      notifier.disconnectESP32();
    }
    notifier.resetAllMonitoringState();
    _bleController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[MonitoringPagePatient] build called');
    final vm = ref.watch(monitoringViewModelPatientProvider);
    final appBarHeight = kToolbarHeight;
    debugPrint(
      '[MonitoringPagePatient] patientName: \\${vm.patientName}, patientId: \\${vm.patientId}',
    );
    debugPrint(
      '[MonitoringPagePatient] isConnected: \\${vm.isConnected}, isMonitoring: \\${vm.isMonitoring}, monitoringDone: \\${vm.monitoringDone}',
    );
    debugPrint(
      '[MonitoringPagePatient] bpm: \\${vm.bpm}, bpmData.length: \\${vm.bpmDataForChart.length}',
    );
    return WillPopScope(
      onWillPop: () async {
        final notifier = ref.read(monitoringViewModelPatientProvider.notifier);
        final vm = ref.read(monitoringViewModelPatientProvider);
        if (vm.isMonitoring) {
          notifier.stopMonitoringESP32();
        }
        if (vm.isConnected) {
          _bleController?.disconnect();
          notifier.disconnectESP32();
        }
        notifier.resetAllMonitoringState();
        _bleController = null;
        return true;
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
                  const Text(
                    'DEBUG: MonitoringPagePatient loaded',
                    style: TextStyle(color: Colors.red),
                  ),
                  // Tidak ada pemilihan pasien, hanya info pasien sendiri
                  PatientSummaryCardPatient(
                    patientName: vm.patientName,
                    patientId: vm.patientId,
                  ),
                  const SizedBox(height: 16),
                  patient_btn.ESP32ConnectionButton(
                    isConnected: vm.isConnected,
                    isMonitoring: vm.isMonitoring,
                    onConnect: () {
                      debugPrint(
                        '[MonitoringPagePatient] ESP32ConnectionButton onConnect',
                      );
                      _bleController?.connect();
                      debugPrint(
                        '[MonitoringPagePatient] _bleController.connect() dipanggil',
                      );
                      vm.connectESP32();
                      debugPrint(
                        '[MonitoringPagePatient] vm.connectESP32() dipanggil',
                      );
                    },
                    onDisconnect: () {
                      debugPrint(
                        '[MonitoringPagePatient] ESP32ConnectionButton onDisconnect',
                      );
                      _bleController?.disconnect();
                      debugPrint(
                        '[MonitoringPagePatient] _bleController.disconnect() dipanggil',
                      );
                      vm.disconnectESP32();
                      debugPrint(
                        '[MonitoringPagePatient] vm.disconnectESP32() dipanggil',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  MonitoringButton(
                    isConnected: vm.isConnected,
                    isMonitoring: vm.isMonitoring,
                    monitoringDone: vm.monitoringDone,
                    onStart: () {
                      debugPrint(
                        '[MonitoringPagePatient] MonitoringButton onStart',
                      );
                      vm.startMonitoring();
                    },
                  ),
                  if (vm.isMonitoring)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Monitoring'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        debugPrint(
                          '[MonitoringPagePatient] Stop Monitoring pressed',
                        );
                        vm.stopMonitoring(context);
                      },
                    ),
                  MonitoringProgress(isMonitoring: vm.isMonitoring),
                  // BPM realtime
                  if (vm.isMonitoring || vm.monitoringDone)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BPM: ${vm.bpm}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BpmRealtimeChartWidget(
                          bpmData:
                              vm.bpmDataForChart
                                  .map(
                                    (e) => doctor_bpm.BpmPoint(e.time, e.bpm),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  // Tombol simpan hasil setelah monitoring selesai
                  if (vm.monitoringDone)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Hasil Monitoring'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        debugPrint(
                          '[MonitoringPagePatient] Simpan Hasil Monitoring pressed',
                        );
                        await vm.saveResult(context);
                      },
                    ),
                  // Hasil monitoring
                  if (vm.monitoringResult != null)
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasil Monitoring:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(vm.monitoringResult ?? '-'),
                            if (vm.classification != null)
                              Text('Klasifikasi: ${vm.classification}'),
                          ],
                        ),
                      ),
                    ),
                  // Tambahkan log saat widget BLE di-render
                  Builder(
                    builder: (context) {
                      debugPrint(
                        '[MonitoringPagePatient] Esp32BleBpmStreamWidget rendered, controller: \\${_bleController != null}',
                      );
                      return _bleController != null
                          ? Esp32BleBpmStreamWidget(
                            controller: _bleController!,
                            onBpmReceived: (bpm) {
                              debugPrint(
                                '[MonitoringPagePatient] onBpmReceived: \\${bpm.toString()}',
                              );
                              vm.updateBpmFromEsp32(bpm);
                            },
                          )
                          : const SizedBox.shrink();
                    },
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
