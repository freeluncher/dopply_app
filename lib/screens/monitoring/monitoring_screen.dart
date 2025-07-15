// =============================================================================
// Patient Monitoring Screen - Simplified BLE Monitoring
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dopply_app/services/monitoring_service.dart';
import 'package:dopply_app/models/monitoring.dart';
import 'package:dopply_app/widgets/common/button.dart';
import 'package:dopply_app/core/theme.dart';

class PatientMonitoringScreen extends ConsumerStatefulWidget {
  const PatientMonitoringScreen({super.key});

  @override
  ConsumerState<PatientMonitoringScreen> createState() =>
      _PatientMonitoringScreenState();
}

class _PatientMonitoringScreenState
    extends ConsumerState<PatientMonitoringScreen> {
  bool _isScanning = false;
  bool _isConnecting = false;
  List<String> _foundDevices = [];

  @override
  Widget build(BuildContext context) {
    final monitoringState = ref.watch(currentMonitoringProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Janin'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            _buildConnectionStatusCard(monitoringState),
            const SizedBox(height: 16),

            // Real-time Chart
            if (monitoringState.isMonitoring) ...[
              _buildRealTimeChart(monitoringState.realTimeData),
              const SizedBox(height: 16),
            ],

            // Current BPM Display
            if (monitoringState.isMonitoring)
              _buildCurrentBpmDisplay(monitoringState.realTimeData),

            const SizedBox(height: 16),

            // Control Buttons
            _buildControlButtons(monitoringState),

            // Error Display
            if (monitoringState.error != null)
              _buildErrorDisplay(monitoringState.error!),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(MonitoringState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: state.isConnected ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text('Status Koneksi', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              state.isConnected
                  ? 'Terhubung ke perangkat Dopply'
                  : 'Tidak terhubung',
              style: AppTheme.bodyText.copyWith(
                color: state.isConnected ? Colors.green : Colors.grey,
              ),
            ),
            if (state.isMonitoring) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Monitoring aktif',
                    style: AppTheme.caption.copyWith(color: Colors.green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeChart(List<BpmDataPoint> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Menunggu data...')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grafik Real-time', style: AppTheme.heading3),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget:
                            (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          data.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.bpm.toDouble(),
                            );
                          }).toList(),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minY: 100,
                  maxY: 180,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBpmDisplay(List<BpmDataPoint> data) {
    final currentBpm = data.isNotEmpty ? data.last.bpm : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('BPM Saat Ini', style: AppTheme.heading3),
            const SizedBox(height: 8),
            Text(
              '$currentBpm',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Text('beats per minute', style: AppTheme.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(MonitoringState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!state.isConnected) ...[
          AppButton(
            text: _isScanning ? 'Mencari Perangkat...' : 'Cari Perangkat',
            onPressed: _isScanning ? null : _scanForDevices,
            isLoading: _isScanning,
          ),
          if (_foundDevices.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Perangkat Ditemukan:', style: AppTheme.heading3),
            const SizedBox(height: 8),
            ..._foundDevices
                .map(
                  (device) => Card(
                    child: ListTile(
                      title: Text(device),
                      trailing: AppButton(
                        text: _isConnecting ? 'Menghubungkan...' : 'Hubungkan',
                        onPressed:
                            _isConnecting
                                ? null
                                : () => _connectToDevice(device),
                        isLoading: _isConnecting,
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        ],

        if (state.isConnected && !state.isMonitoring)
          AppButton(text: 'Mulai Monitoring', onPressed: _startMonitoring),

        if (state.isMonitoring) ...[
          AppButton(
            text: 'Berhenti Monitoring',
            onPressed: _stopMonitoring,
            backgroundColor: Colors.red,
          ),
          const SizedBox(height: 8),
          AppButton(
            text: 'Simpan Session',
            onPressed: _saveSession,
            backgroundColor: Colors.green,
          ),
        ],

        if (state.isConnected)
          AppButton(
            text: 'Putuskan Koneksi',
            onPressed: _disconnect,
            backgroundColor: Colors.orange,
          ),
      ],
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error, style: const TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                ref.read(currentMonitoringProvider.notifier).clearError();
              },
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    try {
      final service = ref.read(monitoringServiceProvider);
      final devices = await service.scanForDopplyDevices();

      setState(() {
        _foundDevices = devices.map((d) => d.platformName).toList();
      });

      if (_foundDevices.isEmpty) {
        ref
            .read(currentMonitoringProvider.notifier)
            .setError(
              'Tidak ada perangkat Dopply ditemukan. Pastikan perangkat sudah dinyalakan dan dalam jangkauan.',
            );
      }
    } catch (e) {
      ref
          .read(currentMonitoringProvider.notifier)
          .setError('Error saat mencari perangkat: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(String deviceName) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // For demo purposes, we'll simulate connection
      await Future.delayed(const Duration(seconds: 2));
      ref.read(currentMonitoringProvider.notifier).setConnected(true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terhubung ke $deviceName')));
    } catch (e) {
      ref
          .read(currentMonitoringProvider.notifier)
          .setError('Gagal menghubungkan ke perangkat: $e');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _startMonitoring() async {
    try {
      ref.read(currentMonitoringProvider.notifier).setMonitoring(true);
      ref.read(currentMonitoringProvider.notifier).clearRealTimeData();

      // Start generating mock data for demo
      _startMockDataGeneration();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Monitoring dimulai')));
    } catch (e) {
      ref
          .read(currentMonitoringProvider.notifier)
          .setError('Gagal memulai monitoring: $e');
    }
  }

  Future<void> _stopMonitoring() async {
    try {
      ref.read(currentMonitoringProvider.notifier).setMonitoring(false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Monitoring dihentikan')));
    } catch (e) {
      ref
          .read(currentMonitoringProvider.notifier)
          .setError('Gagal menghentikan monitoring: $e');
    }
  }

  Future<void> _saveSession() async {
    final state = ref.read(currentMonitoringProvider);
    if (state.realTimeData.isEmpty) return;

    try {
      final bpmData = state.realTimeData.map((point) => point.bpm).toList();
      final averageBpm = bpmData.reduce((a, b) => a + b) / bpmData.length;

      final result = MonitoringResult(
        id: DateTime.now().millisecondsSinceEpoch,
        bpmData: bpmData,
        classification: _classifyBpm(averageBpm),
        createdAt: DateTime.now(),
        notes: 'Monitoring session dari aplikasi',
        averageBpm: averageBpm,
        maxBpm: bpmData.reduce((a, b) => a > b ? a : b),
        minBpm: bpmData.reduce((a, b) => a < b ? a : b),
      );

      final service = ref.read(monitoringServiceProvider);
      await service.saveMonitoringResult(result);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session berhasil disimpan')),
      );
    } catch (e) {
      ref
          .read(currentMonitoringProvider.notifier)
          .setError('Gagal menyimpan session: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      final service = ref.read(monitoringServiceProvider);
      await service.disconnectDevice();

      ref.read(currentMonitoringProvider.notifier).setConnected(false);
      ref.read(currentMonitoringProvider.notifier).setMonitoring(false);
      ref.read(currentMonitoringProvider.notifier).clearRealTimeData();

      setState(() {
        _foundDevices.clear();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perangkat diputuskan')));
    } catch (e) {
      ref
          .read(currentMonitoringProvider.notifier)
          .setError('Gagal memutuskan koneksi: $e');
    }
  }

  void _startMockDataGeneration() {
    // Generate mock data for demo purposes
    Timer.periodic(const Duration(seconds: 1), (timer) {
      final state = ref.read(currentMonitoringProvider);
      if (!state.isMonitoring) {
        timer.cancel();
        return;
      }

      // Generate random BPM between 120-160
      final bpm =
          120 +
          (40 * (0.5 + 0.5 * (DateTime.now().millisecond / 1000))).round();
      final dataPoint = BpmDataPoint(timestamp: DateTime.now(), bpm: bpm);

      ref.read(currentMonitoringProvider.notifier).addRealTimeData(dataPoint);
    });
  }

  String _classifyBpm(double averageBpm) {
    if (averageBpm < 110) return 'bradikardia';
    if (averageBpm > 160) return 'takikardia';
    return 'normal';
  }
}
