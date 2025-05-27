import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _disposed = false;
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
    // CEK PERMISSION BLUETOOTH & LOCATION
    final bluetoothStatus = await Permission.bluetooth.status;
    final locationStatus = await Permission.location.status;
    if (!bluetoothStatus.isGranted) {
      print('[BLE][PERMISSION] Bluetooth permission NOT granted!');
      await Permission.bluetooth.request();
      if (!await Permission.bluetooth.isGranted) {
        print(
          '[BLE][PERMISSION] Bluetooth permission still NOT granted. Abort scan.',
        );
        setState(() => _scanning = false);
        return;
      }
    }
    if (!locationStatus.isGranted) {
      print('[BLE][PERMISSION] Location permission NOT granted!');
      await Permission.location.request();
      if (!await Permission.location.isGranted) {
        print(
          '[BLE][PERMISSION] Location permission still NOT granted. Abort scan.',
        );
        setState(() => _scanning = false);
        return;
      }
    }
    setState(() => _scanning = true);
    print('[BLE] Mulai scan...');
    late final StreamSubscription<List<ScanResult>> scanSubscription;
    scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      print('[BLE] Jumlah device ditemukan: \\${results.length}');
      for (var r in results) {
        print(
          '[BLE] Device ditemukan: name=\\${r.device.name}, id=\\${r.device.id}, serviceUuids=\\${r.advertisementData.serviceUuids}',
        );
        if (r.advertisementData.serviceUuids.contains(serviceUuid) ||
            r.device.name == "Dopply-FetalMonitor" ||
            r.device.id.id == "4C:11:AE:64:FD:62") {
          print(
            '[BLE] Device cocok, mencoba connect ke: name=\\${r.device.name}, id=\\${r.device.id}',
          );
          await FlutterBluePlus.stopScan();
          await Future.delayed(
            const Duration(
              milliseconds: 2000,
            ), // Delay lebih lama sebelum connect
          ); // Tambah delay sebelum connect
          try {
            _device = r.device;
            print('[BLE] Mulai proses connect...');
            await _device!.connect();
            print('[BLE] Berhasil connect ke ESP32!');
            var services = await _device!.discoverServices();
            print('[BLE] Jumlah service ditemukan: \\${services.length}');
            for (var s in services) {
              print('[BLE] Service UUID: \\${s.uuid}');
              if (s.uuid.toString() == serviceUuid) {
                for (var c in s.characteristics) {
                  print('[BLE]  - Char UUID: \\${c.uuid}');
                  if (c.uuid.toString() == charUuid) {
                    print(
                      '[BLE]  - Char cocok (notify BPM), setNotifyValue...',
                    );
                    await c.setNotifyValue(true);
                    c.onValueReceived.listen((value) {
                      try {
                        final str = utf8.decode(value);
                        if (str.contains(',')) {
                          widget.onBpmReceived(str);
                          print('[BLE] Data BPM+Time diterima: \\${str}');
                        } else {
                          final bpm = int.parse(str);
                          widget.onBpmReceived(bpm);
                          print('[BLE] Data BPM diterima: \\${bpm}');
                        }
                      } catch (e) {
                        print('[BLE] Error parsing BPM: \\${e}');
                      }
                    });
                    setState(() => _scanning = false);
                  } else if (c.uuid.toString() == commandCharUuid) {
                    print('[BLE]  - Char cocok (command characteristic)');
                    _commandChar = c;
                  }
                }
              }
            }
          } catch (e) {
            print('[BLE] ERROR connect: \\${e}');
            _device = null;
            setState(() => _scanning = false);
          }
          await scanSubscription.cancel();
          break;
        }
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  Future<void> _disconnect() async {
    if (_device != null) {
      print('[BLE] Disconnect dari ESP32...');
      await _device?.disconnect();
      print('[BLE] Disconnected.');
    }
    _device = null;
    if (mounted && !_disposed) {
      setState(() {});
    }
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
    _disposed = true;
    widget.controller?._state = null;
    // Do not call async _disconnect in dispose
    _device = null;
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
