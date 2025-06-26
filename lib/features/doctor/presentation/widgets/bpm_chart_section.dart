import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget section untuk menampilkan BPM dan placeholder chart.
class BpmChartSection extends StatelessWidget {
  final bool isConnected;
  final int bpm;
  final List<int> bpmData;
  const BpmChartSection({
    Key? key,
    required this.isConnected,
    required this.bpm,
    required this.bpmData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isConnected) return const SizedBox.shrink();

    // --- Optimasi Data: Downsampling jika data sangat panjang ---
    List<int> displayData = bpmData;
    const maxPoints =
        60; // tampilkan maksimal 60 titik agar chart tetap responsif
    if (bpmData.length > maxPoints) {
      // Downsampling sederhana: ambil setiap n-th point
      int step = (bpmData.length / maxPoints).ceil();
      displayData = [for (int i = 0; i < bpmData.length; i += step) bpmData[i]];
      // Pastikan titik terakhir tetap diambil
      if (displayData.last != bpmData.last) displayData.add(bpmData.last);
    }

    // --- Null Safety: Pastikan data tidak kosong sebelum akses ---
    final hasData = displayData.isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          'BPM Detak Jantung Janin',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            hasData ? '$bpm' : '-', // Tampilkan '-' jika tidak ada data
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  hasData
                      ? Semantics(
                        label: 'Grafik detak jantung janin', // aksesibilitas
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots:
                                    displayData
                                        .asMap()
                                        .entries
                                        .map(
                                          (e) => FlSpot(
                                            e.key.toDouble(),
                                            e.value.toDouble(),
                                          ),
                                        )
                                        .toList(),
                                isCurved: true,
                                color: Colors.red,
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      )
                      : Center(
                        child: Text(
                          'Belum ada data BPM',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
            ),
          ),
        ),
        // ...bisa tambahkan statistik lain di sini jika perlu...
      ],
    );
  }
}
