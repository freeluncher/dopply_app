import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Esp32BleBpmStreamWidgetController {
  _Esp32BleBpmStreamWidgetState? _state;
  void connect() => _state?._startScan();
  void disconnect() => _state?._disconnect();
  bool get isConnected => _state?._device != null;

  Future<void> sendCommand(String command) async {
    await _state?._sendCommand(command);
  }
}

class Esp32BleBpmStreamWidget extends StatefulWidget {
  final void Function(dynamic bpm) onBpmReceived;
  final Esp32BleBpmStreamWidgetController? controller;
  const Esp32BleBpmStreamWidget({
    Key? key,
    required this.onBpmReceived,
    this.controller,
  }) : super(key: key);

  @override
  State<Esp32BleBpmStreamWidget> createState() =>
      _Esp32BleBpmStreamWidgetState();
}

class _Esp32BleBpmStreamWidgetState extends State<Esp32BleBpmStreamWidget> {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandChar;
  bool _scanning = false;
  final String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String charUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  final String commandCharUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  final String timeCharUuid = "6e400004-b5a3-f393-e0a9-e50e24dcca9e";

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  Future<void> _startScan() async {
    if (_device != null) return;
    setState(() => _scanning = true);
    print('[BLE] Mulai scan...');
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        print('[BLE] Device ditemukan: ${r.device.name} - ${r.device.id}');
        // Cek service UUID pada advertisementData jika ada
        if (r.advertisementData.serviceUuids.contains(serviceUuid) ||
            r.device.name == "Dopply-FetalMonitor" ||
            r.device.id.id == "4C:11:AE:64:FD:62") {
          // MAC address ESP32 Anda
          print('[BLE] Device cocok, mencoba connect...');
          await FlutterBluePlus.stopScan();
          _device = r.device;
          await _device!.connect();
          print('[BLE] Berhasil connect ke ESP32!');
          var services = await _device!.discoverServices();
          for (var s in services) {
            if (s.uuid.toString() == serviceUuid) {
              for (var c in s.characteristics) {
                if (c.uuid.toString() == charUuid) {
                  await c.setNotifyValue(true);
                  c.onValueReceived.listen((value) {
                    try {
                      final str = utf8.decode(value);
                      if (str.contains(',')) {
                        // Format: "<elapsed_ms>,<bpm>"
                        widget.onBpmReceived(str);
                        print('[BLE] Data BPM+Time diterima: $str');
                      } else {
                        final bpm = int.parse(str);
                        widget.onBpmReceived(bpm);
                        print('[BLE] Data BPM diterima: $bpm');
                      }
                    } catch (e) {
                      print('[BLE] Error parsing BPM: $e');
                    }
                  });
                  setState(() => _scanning = false);
                } else if (c.uuid.toString() == commandCharUuid) {
                  _commandChar = c;
                }
              }
            }
          }
        }
      }
    });
  }

  Future<void> _disconnect() async {
    if (_device != null) {
      print('[BLE] Disconnect dari ESP32...');
      await _device?.disconnect();
      print('[BLE] Disconnected.');
    }
    _device = null;
    setState(() {});
  }

  Future<void> _sendCommand(String command) async {
    if (_commandChar != null) {
      try {
        await _commandChar!.write(utf8.encode(command), withoutResponse: true);
        print('[BLE] Command "$command" sent to ESP32');
      } catch (e) {
        print('[BLE] Failed to send command: $e');
      }
    } else {
      print('[BLE] Command characteristic not found!');
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_scanning) {
      return const Center(child: CircularProgressIndicator());
    }
    return const SizedBox.shrink();
  }
}
