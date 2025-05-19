import 'package:flutter/material.dart';

class BpmChartSection extends StatelessWidget {
  final bool isConnected;
  final int bpm;
  const BpmChartSection({
    Key? key,
    required this.isConnected,
    required this.bpm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isConnected) return const SizedBox.shrink();
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
            '{bpm}',
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
    );
  }
}
