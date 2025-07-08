// =============================================================================
// Connection Status Card Widget
//
// Displays ESP32 BLE connection status with connection controls
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../shared/services/fetal_doppler_ble_service.dart';

class ConnectionStatusCard extends StatelessWidget {
  final BLEConnectionState connectionState;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const ConnectionStatusCard({
    super.key,
    required this.connectionState,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatusIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getStatusDescription(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (connectionState) {
      case BLEConnectionState.connected:
        icon = Icons.bluetooth_connected;
        color = Colors.green;
        break;
      case BLEConnectionState.connecting:
        icon = Icons.bluetooth_searching;
        color = Colors.orange;
        break;
      case BLEConnectionState.scanning:
        icon = Icons.bluetooth_searching;
        color = Colors.blue;
        break;
      case BLEConnectionState.error:
        icon = Icons.bluetooth_disabled;
        color = Colors.red;
        break;
      default:
        icon = Icons.bluetooth;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getStatusTitle() {
    switch (connectionState) {
      case BLEConnectionState.connected:
        return 'Connected';
      case BLEConnectionState.connecting:
        return 'Connecting...';
      case BLEConnectionState.scanning:
        return 'Scanning...';
      case BLEConnectionState.error:
        return 'Connection Error';
      default:
        return 'Disconnected';
    }
  }

  String _getStatusDescription() {
    switch (connectionState) {
      case BLEConnectionState.connected:
        return 'ESP32 device is connected and ready';
      case BLEConnectionState.connecting:
        return 'Establishing connection to ESP32';
      case BLEConnectionState.scanning:
        return 'Looking for ESP32 devices';
      case BLEConnectionState.error:
        return 'Failed to connect to device';
      default:
        return 'No device connected';
    }
  }

  Widget _buildActionButton() {
    if (connectionState == BLEConnectionState.connected) {
      return ElevatedButton(
        onPressed: onDisconnect,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Disconnect'),
      );
    } else if (connectionState == BLEConnectionState.connecting ||
        connectionState == BLEConnectionState.scanning) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      return ElevatedButton(
        onPressed: onConnect,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E8B57),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Connect'),
      );
    }
  }
}
