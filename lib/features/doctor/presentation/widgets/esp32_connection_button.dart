import 'package:flutter/material.dart';

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
                    : onConnect,
          ),
        ),
      ],
    );
  }
}
