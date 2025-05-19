import 'package:flutter/material.dart';

class MonitoringProgress extends StatelessWidget {
  final bool isMonitoring;
  const MonitoringProgress({Key? key, required this.isMonitoring})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMonitoring) {
      return const Center(child: CircularProgressIndicator());
    }
    return const SizedBox.shrink();
  }
}
