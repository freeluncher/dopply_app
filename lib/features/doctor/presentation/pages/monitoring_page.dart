import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/monitoring_view_model.dart';

class MonitoringPage extends ConsumerWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          : () => vm.selectPatient(
                            'Pasien: Siti Aminah, 27th, G2P1',
                          ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vm.selectedPatient,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('Data singkat: ...'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(vm.isConnected ? Icons.usb_off : Icons.usb),
                        label: Text(
                          vm.isConnected ? 'Disconnect ESP32' : 'Connect ESP32',
                        ),
                        onPressed:
                            vm.isMonitoring
                                ? null
                                : vm.isConnected
                                ? () => vm.disconnectESP32()
                                : () => vm.connectESP32(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (vm.isConnected && !vm.isMonitoring && !vm.monitoringDone)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Mulai Monitoring'),
                    onPressed: () => vm.startMonitoring(),
                  ),
                if (vm.isMonitoring)
                  const Center(child: CircularProgressIndicator()),
                if (vm.isConnected)
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'BPM Detak Jantung Janin',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '${vm.bpm}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                'Grafik BPM (implementasi: gunakan package chart_flutter atau fl_chart)',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (vm.monitoringDone)
                  Card(
                    color:
                        vm.monitoringResult == 'Normal'
                            ? Colors.green[50]
                            : Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hasil Monitoring: ${vm.monitoringResult}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  vm.monitoringResult == 'Normal'
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                          if (vm.classification != null)
                            Text('Klasifikasi: ${vm.classification}'),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Catatan Dokter',
                            ),
                            minLines: 2,
                            maxLines: 4,
                            onChanged: (val) => vm.updateDoctorNote(val),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan Hasil Pemeriksaan'),
                            onPressed: () => vm.saveResult(context),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
