import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/monitoring_history_view_model_patient.dart';

final monitoringHistoryViewModelPatientProvider = ChangeNotifierProvider(
  (ref) => MonitoringHistoryViewModelPatient(),
);

class MonitoringHistoryPagePatient extends ConsumerWidget {
  const MonitoringHistoryPagePatient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(monitoringHistoryViewModelPatientProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Monitoring Pasien')),
      body: RefreshIndicator(
        onRefresh:
            () async =>
                ref
                    .read(monitoringHistoryViewModelPatientProvider)
                    .fetchHistory(),
        child:
            vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                ? Center(child: Text('Error: ${vm.error}'))
                : vm.history.isEmpty
                ? const Center(child: Text('Belum ada riwayat monitoring'))
                : ListView.builder(
                  itemCount: vm.history.length,
                  itemBuilder: (context, i) {
                    final item = vm.history[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text('Tanggal: ${item['created_at'] ?? '-'}'),
                        subtitle: Text(
                          'Hasil: ${item['monitoring_result'] ?? '-'}\nKlasifikasi: ${item['classification'] ?? '-'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text('Detail Monitoring'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tanggal: ${item['created_at'] ?? '-'}',
                                        ),
                                        Text(
                                          'Hasil: ${item['monitoring_result'] ?? '-'}',
                                        ),
                                        Text(
                                          'Klasifikasi: ${item['classification'] ?? '-'}',
                                        ),
                                        const SizedBox(height: 8),
                                        Text('BPM Data:'),
                                        ...((item['bpm_data'] as List?)?.map(
                                              (bpm) => Text(
                                                '• ${bpm['time']}s: ${bpm['bpm']} BPM',
                                              ),
                                            ) ??
                                            []),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Tutup'),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () =>
                ref
                    .read(monitoringHistoryViewModelPatientProvider)
                    .fetchHistory(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
