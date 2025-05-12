import 'package:flutter/material.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  // Dummy data, ganti dengan provider/stream dari ESP32
  int bpm = 120;
  String selectedPatient = 'Belum ada pasien dipilih';

  // Simulasi update BPM (ganti dengan stream dari ESP32 di implementasi nyata)
  @override
  void initState() {
    super.initState();
    // Simulasi BPM update
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        bpm = 110 + (bpm + 1) % 30;
      });
      return mounted;
    });
  }

  void _selectPatient() async {
    // TODO: Implementasi pilih/tambah pasien
    setState(() {
      selectedPatient = 'Pasien: Siti Aminah, 27th, G2P1';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring Detak Jantung Janin')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person_search),
              label: const Text('Pilih/Tambah Pasien'),
              onPressed: _selectPatient,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPatient,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Data singkat: ...'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'BPM Detak Jantung Janin',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$bpm',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
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
      ),
    );
  }
}
