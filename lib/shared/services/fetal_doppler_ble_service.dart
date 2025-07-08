// =============================================================================
// Fetal Doppler BLE Service
//
// Specialized BLE service for connecting to ESP32-based fetal doppler devices
// Handles fetal heart rate monitoring with gestational age consideration
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Fetal Doppler BLE Configuration
class FetalDopplerConfig {
  static const String deviceNamePrefix = "FETAL_DOPPLER";
  static const String serviceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String rxCharacteristicUUID =
      "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String txCharacteristicUUID =
      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  static const Duration scanTimeout = Duration(seconds: 15);
  static const Duration connectionTimeout = Duration(seconds: 20);
}

// BLE Connection States
enum BLEConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
  monitoring,
}

// Fetal Heart Rate Data Model
class FetalHeartRateData {
  final int bpm;
  final DateTime timestamp;
  final double? signalQuality;
  final FetalBPMClassification classification;

  const FetalHeartRateData({
    required this.bpm,
    required this.timestamp,
    this.signalQuality,
    required this.classification,
  });

  factory FetalHeartRateData.fromBytes(Uint8List data, int gestationalAge) {
    // Parse ESP32 fetal doppler data format
    // Expected format: [BPM_HIGH, BPM_LOW, QUALITY, ...]
    if (data.length >= 3) {
      // Binary format (preferred)
      final bpm = (data[0] << 8) | data[1];
      final quality = data[2] / 100.0; // Signal quality percentage
      final classification = FetalBPMClassifier.classify(bpm, gestationalAge);

      return FetalHeartRateData(
        bpm: bpm,
        timestamp: DateTime.now(),
        signalQuality: quality,
        classification: classification,
      );
    } else {
      throw FormatException(
        'Invalid fetal doppler data format - insufficient data',
      );
    }
  }

  // Factory for string format (backward compatibility)
  factory FetalHeartRateData.fromString(String data, int gestationalAge) {
    final bpm = int.tryParse(data.trim()) ?? 0;
    final classification = FetalBPMClassifier.classify(bpm, gestationalAge);

    // Estimate signal quality based on BPM value
    double signalQuality = 0.0;
    if (bpm > 0) {
      signalQuality = bpm >= 60 && bpm <= 200 ? 0.85 : 0.60;
    }

    return FetalHeartRateData(
      bpm: bpm,
      timestamp: DateTime.now(),
      signalQuality: signalQuality,
      classification: classification,
    );
  }

  Map<String, dynamic> toJson() => {
    'bpm': bpm,
    'timestamp': timestamp.toIso8601String(),
    'signal_quality': signalQuality,
    'classification': classification.name,
  };
}

// Fetal BPM Classification
enum FetalBPMClassification { normal, bradycardia, tachycardia, irregular }

// Fetal BPM Classifier
class FetalBPMClassifier {
  static FetalBPMClassification classify(int bpm, int gestationalAge) {
    // Fetal heart rate ranges based on gestational age
    if (gestationalAge < 20) {
      // Early pregnancy: 120-180 BPM
      if (bpm < 120) return FetalBPMClassification.bradycardia;
      if (bpm > 180) return FetalBPMClassification.tachycardia;
    } else if (gestationalAge < 32) {
      // Mid pregnancy: 115-170 BPM
      if (bpm < 115) return FetalBPMClassification.bradycardia;
      if (bpm > 170) return FetalBPMClassification.tachycardia;
    } else {
      // Late pregnancy: 110-160 BPM
      if (bpm < 110) return FetalBPMClassification.bradycardia;
      if (bpm > 160) return FetalBPMClassification.tachycardia;
    }
    return FetalBPMClassification.normal;
  }

  static String getClassificationDescription(
    FetalBPMClassification classification,
  ) {
    switch (classification) {
      case FetalBPMClassification.normal:
        return 'Normal fetal heart rate';
      case FetalBPMClassification.bradycardia:
        return 'Fetal bradycardia - slow heart rate';
      case FetalBPMClassification.tachycardia:
        return 'Fetal tachycardia - fast heart rate';
      case FetalBPMClassification.irregular:
        return 'Irregular fetal heart rhythm';
    }
  }
}

// Fetal Doppler BLE Service
class FetalDopplerBLEService extends StateNotifier<BLEConnectionState> {
  FetalDopplerBLEService() : super(BLEConnectionState.disconnected);

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _deviceStateSubscription;
  StreamSubscription? _characteristicSubscription;

  // Stream controllers
  final _heartRateController = StreamController<FetalHeartRateData>.broadcast();
  final _deviceListController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<FetalHeartRateData> get heartRateStream => _heartRateController.stream;
  Stream<List<BluetoothDevice>> get deviceListStream =>
      _deviceListController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Current gestational age (set before monitoring)
  int _gestationalAge = 20;

  void setGestationalAge(int weeks) {
    _gestationalAge = weeks;
  }

  // Scan for fetal doppler devices
  Future<void> startScan() async {
    try {
      state = BLEConnectionState.scanning;

      if (!(await FlutterBluePlus.isOn)) {
        throw Exception('Bluetooth is not enabled');
      }

      final List<BluetoothDevice> devices = [];

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        devices.clear();
        for (var result in results) {
          if (result.device.name.startsWith(
            FetalDopplerConfig.deviceNamePrefix,
          )) {
            devices.add(result.device);
          }
        }
        _deviceListController.add(devices);
      });

      await FlutterBluePlus.startScan(
        timeout: FetalDopplerConfig.scanTimeout,
        withServices: [Guid(FetalDopplerConfig.serviceUUID)],
      );
    } catch (e) {
      state = BLEConnectionState.error;
      _errorController.add('Scan failed: ${e.toString()}');
    }
  }

  // Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    if (state == BLEConnectionState.scanning) {
      state = BLEConnectionState.disconnected;
    }
  }

  // Connect to fetal doppler device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      state = BLEConnectionState.connecting;

      await device.connect(timeout: FetalDopplerConfig.connectionTimeout);
      _connectedDevice = device;

      // Discover services
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid == Guid(FetalDopplerConfig.serviceUUID),
        orElse: () => throw Exception('Fetal doppler service not found'),
      );

      // Get characteristics
      _rxCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid == Guid(FetalDopplerConfig.rxCharacteristicUUID),
        orElse: () => throw Exception('RX characteristic not found'),
      );

      _txCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid == Guid(FetalDopplerConfig.txCharacteristicUUID),
        orElse: () => throw Exception('TX characteristic not found'),
      );

      // Setup notifications for heart rate data
      await _txCharacteristic!.setNotifyValue(true);
      _characteristicSubscription = _txCharacteristic!.value.listen((data) {
        _processHeartRateData(data);
      });

      // Monitor device connection state
      _deviceStateSubscription = device.state.listen((deviceState) {
        if (deviceState == BluetoothDeviceState.disconnected) {
          _handleDisconnection();
        }
      });

      state = BLEConnectionState.connected;
      return true;
    } catch (e) {
      state = BLEConnectionState.error;
      _errorController.add('Connection failed: ${e.toString()}');
      return false;
    }
  }

  // Start fetal heart rate monitoring
  Future<void> startMonitoring() async {
    if (state != BLEConnectionState.connected) {
      throw Exception('Device not connected');
    }

    try {
      // Send start monitoring command to ESP32
      final command = jsonEncode({'action': 'start_monitoring'});
      await _rxCharacteristic!.write(command.codeUnits);

      state = BLEConnectionState.monitoring;
    } catch (e) {
      _errorController.add('Failed to start monitoring: ${e.toString()}');
    }
  }

  // Stop monitoring
  Future<void> stopMonitoring() async {
    if (state == BLEConnectionState.monitoring) {
      try {
        // Send stop command to ESP32
        final command = jsonEncode({'action': 'stop_monitoring'});
        await _rxCharacteristic!.write(command.codeUnits);

        state = BLEConnectionState.connected;
      } catch (e) {
        _errorController.add('Failed to stop monitoring: ${e.toString()}');
      }
    }
  }

  // Disconnect from device
  Future<void> disconnect() async {
    await stopMonitoring();

    _characteristicSubscription?.cancel();
    _deviceStateSubscription?.cancel();

    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }

    _rxCharacteristic = null;
    _txCharacteristic = null;

    state = BLEConnectionState.disconnected;
  }

  // Process incoming heart rate data
  void _processHeartRateData(List<int> data) {
    try {
      // Try binary format first (preferred)
      if (data.length >= 3) {
        final uint8Data = Uint8List.fromList(data);
        final heartRateData = FetalHeartRateData.fromBytes(
          uint8Data,
          _gestationalAge,
        );
        _heartRateController.add(heartRateData);
      } else {
        // Fallback to string format for backward compatibility
        final stringData = String.fromCharCodes(data);
        final heartRateData = FetalHeartRateData.fromString(
          stringData,
          _gestationalAge,
        );
        _heartRateController.add(heartRateData);
      }
    } catch (e) {
      _errorController.add('Data processing error: ${e.toString()}');
    }
  }

  // Handle device disconnection
  void _handleDisconnection() {
    _connectedDevice = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    state = BLEConnectionState.disconnected;
  }

  @override
  void dispose() {
    stopScan();
    disconnect();
    _heartRateController.close();
    _deviceListController.close();
    _errorController.close();
    super.dispose();
  }
}

// Provider for Fetal Doppler BLE Service
final fetalDopplerBLEProvider =
    StateNotifierProvider<FetalDopplerBLEService, BLEConnectionState>((ref) {
      return FetalDopplerBLEService();
    });
