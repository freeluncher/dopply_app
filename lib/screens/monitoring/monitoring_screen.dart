// =============================================================================
// Patient Monitoring Screen - Simplified BLE Monitoring
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:dopply_app/services/monitoring_service.dart';
import 'package:dopply_app/services/ble_service.dart';
import 'package:dopply_app/models/monitoring.dart';
import 'package:dopply_app/services/patient_service.dart';
import 'package:dopply_app/models/patient.dart';
import 'package:dopply_app/widgets/common/button.dart';
import 'package:dopply_app/core/theme.dart';
import 'package:dopply_app/core/api_client.dart';
import 'package:dopply_app/core/storage.dart';

final fetalDopplerBLEServiceProvider =
    StateNotifierProvider<FetalDopplerBLEService, BLEConnectionState>(
      (ref) => FetalDopplerBLEService(),
    );

class PatientMonitoringScreen extends ConsumerStatefulWidget {
  const PatientMonitoringScreen({super.key});

  @override
  ConsumerState<PatientMonitoringScreen> createState() =>
      _PatientMonitoringScreenState();
}

class _PatientMonitoringScreenState
    extends ConsumerState<PatientMonitoringScreen> {
  bool _isScanning = false;
  List<BluetoothDevice> _foundDevices = [];
  String? _selectedPatientId;
  List<Patient> _patients = [];
  bool _isLoadingPatients = false;
  final TextEditingController _addPatientEmailController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _setApiTokenFromStorage();
  }

  Future<void> _setApiTokenFromStorage() async {
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      ApiClient().setAuthToken(token);
      debugPrint('[MonitoringScreen] JWT token set to ApiClient');
    } else {
      debugPrint('[MonitoringScreen] No JWT token found in storage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitoringState = ref.watch(currentMonitoringProvider);
    final patientService = ref.read(patientServiceProvider);

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
            _buildPatientSelector(),
            _buildAddPatientForm(patientService),
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

  Widget _buildPatientSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pilih Pasien', style: AppTheme.heading3),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchPatients,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoadingPatients
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  items:
                      _patients
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id.toString(),
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPatientId = val;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Pasien',
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPatientForm(PatientService patientService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tambah Pasien', style: AppTheme.heading3),
            const SizedBox(height: 8),
            TextField(
              controller: _addPatientEmailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email Pasien',
              ),
            ),
            const SizedBox(height: 8),
            AppButton(
              text: 'Tambah',
              onPressed: () async {
                final email = _addPatientEmailController.text.trim();
                if (email.isEmpty) return;
                final result = await patientService.addPatient(email);
                final success = result.$1;
                final errorMsg = result.$2;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pasien berhasil ditambahkan'),
                    ),
                  );
                  _addPatientEmailController.clear();
                  await _fetchPatients();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg ?? 'Gagal menambah pasien'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoadingPatients = true;
    });
    try {
      final patientService = ref.read(patientServiceProvider);
      final patients = await patientService.getPatients();
      setState(() {
        _patients = patients;
        if (_patients.isNotEmpty) {
          _selectedPatientId ??= _patients.first.id.toString();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data pasien: $e')),
      );
    } finally {
      setState(() {
        _isLoadingPatients = false;
      });
    }
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
        if (!state.isConnected)
          AppButton(
            text: _isScanning ? 'Menghubungkan ESP32...' : 'Hubungkan ESP32',
            onPressed: _isScanning ? null : _connectEsp32,
            isLoading: _isScanning,
          ),

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

  Future<void> _connectEsp32() async {
    setState(() {
      _isScanning = true;
    });
    try {
      final bleService = ref.read(fetalDopplerBLEServiceProvider.notifier);
      await bleService.startScan();
      StreamSubscription? subscription;
      bool connected = false;
      subscription = bleService.deviceListStream.listen((devices) async {
        BluetoothDevice? esp32Device;
        try {
          esp32Device = devices.firstWhere(
            (d) => d.name.startsWith('Dopply-FetalMonitor'),
          );
        } catch (_) {
          esp32Device = null;
        }
        if (esp32Device != null && !connected) {
          connected = true;
          await bleService.stopScan();
          await subscription?.cancel();
          _connectToDevice(esp32Device);
        }
      });
      // Timeout jika tidak ditemukan
      await Future.delayed(const Duration(seconds: 15));
      await bleService.stopScan();
      await subscription.cancel();
      if (!connected) {
        ref
            .read(currentMonitoringProvider.notifier)
            .setError(
              'Tidak ada perangkat ESP32 Dopply ditemukan. Pastikan perangkat sudah dinyalakan dan dalam jangkauan.',
            );
      }
    } catch (e) {
      ref
          .read(currentMonitoringProvider.notifier)
          .setError('Error saat menghubungkan ESP32: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      // Connecting state not used
    });
    try {
      final bleService = ref.read(fetalDopplerBLEServiceProvider.notifier);
      final connected = await bleService.connectToDevice(device);
      if (connected) {
        ref.read(currentMonitoringProvider.notifier).setConnected(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terhubung ke ${device.name}')));
      } else {
        ref
            .read(currentMonitoringProvider.notifier)
            .setError('Gagal menghubungkan ke perangkat BLE');
      }
    } catch (e) {
      ref
          .read(currentMonitoringProvider.notifier)
          .setError('Gagal menghubungkan ke perangkat: $e');
    } finally {
      setState(() {
        // Connecting state not used
      });
    }
  }

  Future<void> _startMonitoring() async {
    try {
      final bleService = ref.read(fetalDopplerBLEServiceProvider.notifier);
      ref.read(currentMonitoringProvider.notifier).setMonitoring(true);
      ref.read(currentMonitoringProvider.notifier).clearRealTimeData();
      await bleService.startMonitoring();
      // Listen BPM data
      bleService.heartRateStream.listen((data) {
        final dataPoint = BpmDataPoint(
          timestamp: data.timestamp,
          bpm: data.bpm,
        );
        ref.read(currentMonitoringProvider.notifier).addRealTimeData(dataPoint);
      });
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
      final bleService = ref.read(fetalDopplerBLEServiceProvider.notifier);
      await bleService.disconnect();

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

  // Mock data generation fully removed. Only real BLE data is used.

  String _classifyBpm(double averageBpm) {
    if (averageBpm < 110) return 'bradikardia';
    if (averageBpm > 160) return 'takikardia';
    return 'normal';
  }
}
