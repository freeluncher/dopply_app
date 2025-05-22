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
    final state = FlutterBluePlus.adapterStateNow;
    if (state != BluetoothAdapterState.on) {
      final status = await Permission.bluetooth.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktifkan Bluetooth untuk melanjutkan.'),
          ),
        );
        return;
      }
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first;
    }
    onConnect();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
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
        ),
      ],
    );
  }
}
