import 'package:dopply_app/features/doctor/presentation/widgets/esp32_ble_bpm_stream_widget.dart';

/// Service untuk mengelola koneksi dan perintah BLE ESP32.
class Esp32BleService {
  Esp32BleBpmStreamWidgetController? bleController;
  String? bleError;
  bool isConnected = false;

  void setBleController(Esp32BleBpmStreamWidgetController controller) {
    bleController = controller;
  }

  void connect() {
    try {
      bleController?.connect();
      isConnected = true;
      bleError = null;
    } catch (e) {
      isConnected = false;
      bleError = 'Gagal koneksi BLE: $e';
    }
  }

  void disconnect() {
    try {
      bleController?.disconnect();
      isConnected = false;
      bleError = null;
    } catch (e) {
      bleError = 'Gagal disconnect BLE: $e';
    }
  }

  void stopMonitoring() {
    try {
      bleController?.sendCommand('stop');
      bleError = null;
    } catch (e) {
      bleError = 'Gagal stop monitoring BLE: $e';
    }
  }
}
