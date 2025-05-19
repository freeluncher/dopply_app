import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Esp32BpmStreamWidget extends StatefulWidget {
  final String esp32Ip;
  final bool monitoringActive;
  final void Function(int bpm, double signal)? onData;
  const Esp32BpmStreamWidget({
    Key? key,
    required this.esp32Ip,
    required this.monitoringActive,
    this.onData,
  }) : super(key: key);

  @override
  State<Esp32BpmStreamWidget> createState() => _Esp32BpmStreamWidgetState();
}

class _Esp32BpmStreamWidgetState extends State<Esp32BpmStreamWidget> {
  Timer? _timer;
  int bpm = 0;
  double signal = 0;
  bool active = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void didUpdateWidget(covariant Esp32BpmStreamWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monitoringActive != widget.monitoringActive) {
      if (widget.monitoringActive) {
        _startPolling();
      } else {
        _stopPolling();
      }
    }
  }

  void _startPolling() {
    _stopPolling();
    if (!widget.monitoringActive) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchBpm());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchBpm() async {
    try {
      final url = 'http://${widget.esp32Ip}/bpm';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bpm = data['bpm'] ?? 0;
          signal = (data['signal'] ?? 0).toDouble();
          active = data['active'] ?? false;
          error = null;
        });
        if (widget.onData != null) widget.onData!(bpm, signal);
      } else {
        setState(() {
          error = 'ESP32 error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Tidak dapat terhubung ke ESP32';
      });
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.monitoringActive) {
      return const SizedBox.shrink();
    }
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BPM dari ESP32: $bpm',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Sinyal: ${signal.toStringAsFixed(2)} V'),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
