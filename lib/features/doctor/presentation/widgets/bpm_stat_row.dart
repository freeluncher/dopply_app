import 'package:flutter/material.dart';
import 'stat_box.dart';

/// A row displaying min, max, and latest BPM values using [StatBox] widgets.
class BpmStatRow extends StatelessWidget {
  final int? minBpm;
  final int? maxBpm;
  final int? latestBpm;
  const BpmStatRow({this.minBpm, this.maxBpm, this.latestBpm, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StatBox(
          label: 'Min',
          value: minBpm?.toString() ?? '-',
          color: Colors.blue,
        ),
        StatBox(
          label: 'Max',
          value: maxBpm?.toString() ?? '-',
          color: Colors.red,
        ),
        StatBox(
          label: 'Terbaru',
          value: latestBpm?.toString() ?? '-',
          color: Colors.green,
        ),
      ],
    );
  }
}
