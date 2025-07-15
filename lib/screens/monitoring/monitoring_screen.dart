// =============================================================================
// Patient Monitoring Screen - Simplified BLE Monitoring
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
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
import 'package:http/http.dart';

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
  Patient? _currentPatient; // Untuk pasien, data dari JWT
  final TextEditingController _addPatientEmailController =
      TextEditingController();
  String? _monitoringResult;
  int? _monitoringResultId;
  String? _userRole;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setApiTokenFromStorage();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    // Ambil role dari StorageService, misal disimpan saat login
    final role = await StorageService.getRole();
    setState(() {
      _userRole = role;
    });
    debugPrint('[MonitoringScreen] User role: \u001b[32m$_userRole\u001b[0m');

    // Jika pasien, ambil data dari JWT
    if (role == 'patient') {
      final userJson = await StorageService.getUserData();
      if (userJson != null && userJson.isNotEmpty) {
        final userMap = jsonDecode(userJson);
        debugPrint('[MonitoringScreen] JWT user data: $userMap');
        // Use patient_id from JWT payload if available, fallback to id
        final patientId = userMap['patient_id'] ?? userMap['id'];
        setState(() {
          _currentPatient = Patient(
            id: patientId,
            name: userMap['name'] ?? '',
            email: userMap['email'] ?? '',
            gestationalAge: userMap['gestational_age'],
            hpht: null,
          );
        });
      }
    } else {
      _fetchPatients();
    }
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

    // Wait for _userRole to be loaded before showing UI
    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return WillPopScope(
      onWillPop: () async {
        debugPrint(
          '[MonitoringScreen] WillPopScope triggered, navigating to /patient',
        );
        context.go('/patient');
        return false;
      },
      child: Scaffold(
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
              if (_userRole != 'patient') ...[
                _buildPatientSelector(),
                _buildAddPatientForm(patientService),
              ],
              _buildConnectionStatusCard(monitoringState),
              const SizedBox(height: 16),
              if (monitoringState.isMonitoring) ...[
                _buildRealTimeChart(monitoringState.realTimeData),
                const SizedBox(height: 16),
              ],
              if (monitoringState.isMonitoring)
                _buildCurrentBpmDisplay(monitoringState.realTimeData),
              const SizedBox(height: 16),
              _buildControlButtons(monitoringState),
              if (monitoringState.error != null)
                _buildErrorDisplay(monitoringState.error!),
              if (_monitoringResult != null)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hasil Klasifikasi', style: AppTheme.heading3),
                        Text(_monitoringResult!, style: AppTheme.bodyText),
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'Share ke Dokter dan Simpan',
                          onPressed: () {
                            _shareMonitoringResult();
                          },
                          backgroundColor: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'Simpan Pribadi',
                          onPressed: () async {
                            await _saveMonitoringResult();
                          },
                          backgroundColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
                : Builder(
                  builder: (context) {
                    debugPrint(
                      '[Dropdown] _selectedPatientId: $_selectedPatientId',
                    );
                    debugPrint(
                      '[Dropdown] _patients: ${_patients.map((p) => p.id.toString()).toList()}',
                    );
                    debugPrint('[Dropdown] items count: ${_patients.length}');
                    return DropdownButtonFormField<String>(
                      value: _patients.isNotEmpty ? _selectedPatientId : null,
                      isExpanded: true,
                      items:
                          _patients.isNotEmpty
                              ? _patients.map((p) {
                                return DropdownMenuItem(
                                  value: p.id.toString(),
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList()
                              : [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Tidak ada pasien'),
                                ),
                              ],
                      onChanged:
                          _patients.isNotEmpty
                              ? (val) {
                                debugPrint('[Dropdown] onChanged: $val');
                                setState(() {
                                  _selectedPatientId = val;
                                });
                              }
                              : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Pasien',
                      ),
                    );
                  },
                ),
            const SizedBox(height: 8),
            if (_selectedPatientId != null)
              Builder(
                builder: (context) {
                  final selected = _patients.firstWhere(
                    (p) => p.id.toString() == _selectedPatientId,
                    orElse: () => _patients.first,
                  );
                  final gestAge =
                      selected.gestationalAge != null
                          ? '${selected.gestationalAge} minggu'
                          : '-';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama: ${selected.name}', style: AppTheme.bodyText),
                      Text(
                        'Email: ${selected.email}',
                        style: AppTheme.bodyText,
                      ),
                      if (gestAge != '-')
                        Text(
                          'Usia kehamilan: $gestAge',
                          style: AppTheme.bodyText,
                        ),
                      if (selected.hpht != null)
                        Text(
                          'HPHT: ${selected.hpht!.toLocal().toIso8601String().substring(0, 10)}',
                          style: AppTheme.bodyText,
                        ),
                    ],
                  );
                },
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
          // Selalu set ke id pasien pertama agar dropdown pasti match
          _selectedPatientId = _patients.first.id.toString();
        } else {
          _selectedPatientId = null;
        }
        debugPrint(
          '[fetchPatients] Setelah fetch: _patients=${_patients.map((p) => p.id.toString()).toList()}',
        );
        debugPrint(
          '[fetchPatients] Setelah fetch: _selectedPatientId=$_selectedPatientId',
        );
      });
    } catch (e) {
      debugPrint('[fetchPatients] ERROR: $e');
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
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grafik Real-time', style: AppTheme.heading3),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: data.length > 30 ? data.length * 10.0 : 300,
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
            text: 'Selesai',
            onPressed: () async {
              await _stopMonitoring();
              await _submitMonitoringSession();
            },
            backgroundColor: Colors.red,
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

  Future<void> _submitMonitoringSession() async {
    final state = ref.read(currentMonitoringProvider);
    if (state.realTimeData.isEmpty) return;

    try {
      final bpmDataRaw = state.realTimeData.map((point) => point.bpm).toList();
      final bpmDataFiltered =
          bpmDataRaw.where((bpm) => bpm >= 50 && bpm <= 200).toList();
      debugPrint('[MonitoringScreen] BPM Data Raw: $bpmDataRaw');
      debugPrint(
        '[MonitoringScreen] BPM Data Filtered (50-200): $bpmDataFiltered',
      );

      int patientId;
      int gestationalAge;
      Patient? patient;
      if (_userRole == 'patient' && _currentPatient != null) {
        patient = _currentPatient;
      } else {
        patient = _patients.firstWhere(
          (p) => p.id.toString() == _selectedPatientId,
          orElse: () => _patients.first,
        );
      }
      if (patient != null) {
        patientId = patient.id;
        gestationalAge = patient.gestationalAge ?? 0;
      } else {
        ref
            .read(currentMonitoringProvider.notifier)
            .setError('Data pasien tidak ditemukan.');
        return;
      }
      if (gestationalAge < 20 || gestationalAge > 42) {
        ref
            .read(currentMonitoringProvider.notifier)
            .setError('Usia kehamilan harus antara 20 dan 42 minggu.');
        debugPrint(
          '[MonitoringScreen] ERROR: gestational_age invalid ($gestationalAge)',
        );
        return;
      }
      debugPrint(
        '[MonitoringScreen] Submit Monitoring Classification Request: gestational_age=$gestationalAge, bpm_data=$bpmDataFiltered',
      );
      // Kirim data BPM ke backend hanya untuk klasifikasi, tanpa simpan ke database
      final apiClient = ApiClient();
      final dioResponse = await apiClient.dio.post(
        '/monitoring/classify',
        data: {
          'patient_id': patientId,
          'gestational_age': gestationalAge,
          'timestamp':
              state.realTimeData.isNotEmpty
                  ? state.realTimeData.first.timestamp.toIso8601String()
                  : DateTime.now().toIso8601String(),
          'bpm_data': bpmDataFiltered,
        },
      );
      final response = dioResponse.data;
      if (response != null) {
        final classification = response['classification']?.toString();
        final avgBpm = response['average_bpm']?.toString();
        setState(() {
          _monitoringResult =
              classification != null && classification.isNotEmpty
                  ? 'Klasifikasi: $classification\nRata-rata BPM: ${avgBpm ?? '-'}'
                  : 'Hasil monitoring tersedia.';
          _monitoringResultId =
              response['id']; // id bisa null jika hanya klasifikasi
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_monitoringResult ?? 'Hasil monitoring tersedia.'),
          ),
        );
      }
    } catch (e) {
      ref
          .read(currentMonitoringProvider.notifier)
          .setError('Gagal submit monitoring: $e');
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

  // Fungsi untuk share hasil monitoring ke dokter
  Future<void> _shareMonitoringResult() async {
    // Validasi record_id
    if (_monitoringResultId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasil monitoring belum tersedia untuk dibagikan.'),
        ),
      );
      return;
    }

    // Ambil daftar dokter dari backend (misal pasien bisa punya beberapa dokter)
    List<Patient> doctors = [];
    try {
      // Asumsi ada endpoint atau service untuk ambil daftar dokter user
      // Di sini hanya contoh, sesuaikan dengan implementasi Anda
      // Jika hanya satu dokter, bisa langsung ambil dari JWT atau relasi pasien
      // Misal: final doctorId = ...;
      // Untuk demo, tampilkan dialog pemilihan dokter
      // TODO: Ganti dengan service yang benar jika sudah ada
      doctors = await _fetchDoctorsForPatient();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil daftar dokter: $e')),
      );
      return;
    }

    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada dokter yang terhubung dengan Anda.'),
        ),
      );
      return;
    }

    // Tampilkan dialog pemilihan dokter
    int? selectedDoctorId = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Dokter Tujuan'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return ListTile(
                  title: Text(doctor.name),
                  subtitle: Text(doctor.email),
                  onTap: () {
                    Navigator.of(context).pop(doctor.id);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedDoctorId == null) {
      // User batal memilih dokter
      return;
    }

    // Panggil API share ke dokter
    try {
      final dioResponse = await ApiClient().dio.post(
        '/monitoring/share',
        data: {'record_id': _monitoringResultId, 'doctor_id': selectedDoctorId},
      );
      final response = dioResponse.data;
      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasil monitoring berhasil dibagikan ke dokter.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membagikan hasil monitoring: ${response?['message'] ?? 'Unknown error'}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membagikan hasil monitoring: $e')),
      );
    }
  }

  // Contoh fungsi untuk ambil daftar dokter user
  Future<List<Patient>> _fetchDoctorsForPatient() async {
    // Ambil semua dokter di database dari backend
    try {
      final dioResponse = await ApiClient().dio.get('/user/all-doctors');
      final data = dioResponse.data;
      final doctorsList =
          (data != null && data['doctors'] is List)
              ? data['doctors'] as List
              : [];
      if (doctorsList.isNotEmpty) {
        return doctorsList.map<Patient>((item) {
          return Patient(
            id: item['id'],
            name: item['name'] ?? '',
            email: item['email'] ?? '',
            gestationalAge: null,
            hpht: null,
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Gagal fetch semua dokter: $e');
      return [];
    }
  }

  // Fungsi untuk simpan hasil monitoring ke database
  Future<void> _saveMonitoringResult() async {
    // Simpan hasil monitoring ke database
    final state = ref.read(currentMonitoringProvider);
    int patientId;
    int gestationalAge;
    Patient? patient;
    if (_userRole == 'patient' && _currentPatient != null) {
      patient = _currentPatient;
    } else {
      patient = _patients.firstWhere(
        (p) => p.id.toString() == _selectedPatientId,
        orElse: () => _patients.first,
      );
    }
    if (patient != null) {
      patientId = patient.id;
      gestationalAge = patient.gestationalAge ?? 0;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pasien tidak ditemukan.')),
      );
      return;
    }
    if (state.realTimeData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data monitoring tidak tersedia.')),
      );
      return;
    }
    try {
      final patientService = ref.read(patientServiceProvider);
      final bpmDataRaw = state.realTimeData.map((point) => point.bpm).toList();
      final bpmDataFiltered =
          bpmDataRaw.where((bpm) => bpm >= 50 && bpm <= 200).toList();
      final response = await patientService.submitMonitoring(
        patientId,
        gestationalAge,
        state.realTimeData.isNotEmpty
            ? state.realTimeData.first.timestamp
            : DateTime.now(),
        bpmDataFiltered,
        _notesController.text.trim(),
      );
      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasil monitoring berhasil disimpan secara pribadi.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan hasil monitoring: ${response?['message'] ?? 'Unknown error'}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan hasil monitoring: $e')),
      );
    }
  }
}
