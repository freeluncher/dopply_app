import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ESP32ConnectionButton extends StatelessWidget {
  final bool isConnected;
  final bool isMonitoring;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  const ESP32ConnectionButton({
    Key? key,
    required this.isConnected,
    required this.isMonitoring,
    required this.onConnect,
    required this.onDisconnect,
  }) : super(key: key);

  Future<void> _handleConnectESP32(
    BuildContext context,
    VoidCallback onConnect,
  ) async {
    // Cek status Bluetooth dengan adapterStateNow
    final state = FlutterBluePlus.adapterStateNow;
    if (state != BluetoothAdapterState.on) {
      // Minta izin Bluetooth
      final status = await Permission.bluetooth.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktifkan Bluetooth untuk melanjutkan.'),
          ),
        );
        return;
      }
      // Coba aktifkan Bluetooth (Android only)
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
      // Tunggu sampai Bluetooth benar-benar ON
      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first;
    }
    // Tambahkan delay sebelum connect BLE (hindari error 133)
    await Future.delayed(const Duration(milliseconds: 800));
    // Retry logic untuk koneksi BLE (maks 3x)
    int retry = 0;
    while (retry < 3) {
      try {
        // Jalankan onConnect, support async jika perlu
        final future = Future.sync(() => onConnect());
        await future;
        break;
      } catch (e) {
        retry++;
        if (retry >= 3) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: Icon(isConnected ? Icons.usb_off : Icons.usb),
                label: Text(isConnected ? 'Disconnect ESP32' : 'Connect ESP32'),
                onPressed:
                    isMonitoring
                        ? null
                        : isConnected
                        ? onDisconnect
                        : () => _handleConnectESP32(context, onConnect),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? Colors.red : null,
                ),
              ),
              // Feedback error BLE sebaiknya ditampilkan di parent (MonitoringPage),
              // jadi bagian ini cukup return SizedBox.shrink saja.
              // Jika ingin menampilkan error di sini, tambahkan parameter error ke widget ini.
              const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}
