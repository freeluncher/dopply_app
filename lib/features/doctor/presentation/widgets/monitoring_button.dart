import 'package:flutter/material.dart';

class MonitoringButton extends StatelessWidget {
  final bool isConnected;
  final bool isMonitoring;
  final bool monitoringDone;
  final VoidCallback onStart;
  const MonitoringButton({
    Key? key,
    required this.isConnected,
    required this.isMonitoring,
    required this.monitoringDone,
    required this.onStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isConnected && !isMonitoring && !monitoringDone) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Mulai Monitoring'),
        onPressed: onStart,
      );
    }
    return const SizedBox.shrink();
  }
}
