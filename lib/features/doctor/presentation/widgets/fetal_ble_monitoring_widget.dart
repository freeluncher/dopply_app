// =============================================================================
// Fetal BLE Monitoring Widget
//
// Modern widget for fetal heart rate monitoring using the new BLE service
// Replaces legacy ESP32 widgets with improved architecture
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:dopply_app/app/theme.dart';
import 'package:dopply_app/shared/services/fetal_doppler_ble_service.dart';

// Fetal BLE Connection Widget
class FetalBLEConnectionWidget extends ConsumerWidget {
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final VoidCallback? onError;

  const FetalBLEConnectionWidget({
    super.key,
    this.onConnected,
    this.onDisconnected,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(fetalDopplerBLEProvider);
    final bleService = ref.read(fetalDopplerBLEProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Connection Status Card
        _buildConnectionStatusCard(connectionState),

        const SizedBox(height: 16),

        // Connection Button
        _buildConnectionButton(context, connectionState, bleService),

        // Error Display
        if (connectionState == BLEConnectionState.error)
          _buildErrorDisplay(ref),
      ],
    );
  }

  Widget _buildConnectionStatusCard(BLEConnectionState state) {
    final isConnected =
        state == BLEConnectionState.connected ||
        state == BLEConnectionState.monitoring;
    final isConnecting =
        state == BLEConnectionState.connecting ||
        state == BLEConnectionState.scanning;

    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    String statusText;
    IconData statusIcon;

    if (isConnected) {
      backgroundColor = AppColors.medicalGreenLight;
      borderColor = AppColors.medicalGreen;
      iconColor = AppColors.medicalGreen;
      statusText = 'Fetal Doppler Terhubung';
      statusIcon = Icons.bluetooth_connected;
    } else if (isConnecting) {
      backgroundColor = AppColors.medicalOrangeLight;
      borderColor = AppColors.medicalOrange;
      iconColor = AppColors.medicalOrange;
      statusText = 'Menghubungkan...';
      statusIcon = Icons.bluetooth_searching;
    } else if (state == BLEConnectionState.error) {
      backgroundColor = AppColors.medicalRedLight;
      borderColor = AppColors.medicalRed;
      iconColor = AppColors.medicalRed;
      statusText = 'Koneksi Gagal';
      statusIcon = Icons.bluetooth_disabled;
    } else {
      backgroundColor = AppColors.medicalRedLight;
      borderColor = AppColors.medicalRed;
      iconColor = AppColors.medicalRed;
      statusText = 'Fetal Doppler Terputus';
      statusIcon = Icons.bluetooth_disabled;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isConnecting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton(
    BuildContext context,
    BLEConnectionState state,
    FetalDopplerBLEService bleService,
  ) {
    final isConnected =
        state == BLEConnectionState.connected ||
        state == BLEConnectionState.monitoring;
    final isConnecting =
        state == BLEConnectionState.connecting ||
        state == BLEConnectionState.scanning;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(
          isConnected ? Icons.bluetooth_disabled : Icons.bluetooth,
          color: AppColors.medicalWhite,
        ),
        label: Text(
          isConnected ? 'Putuskan Koneksi' : 'Hubungkan Fetal Doppler',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.medicalWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isConnected ? AppColors.medicalRed : AppColors.primaryBlue,
          foregroundColor: AppColors.medicalWhite,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed:
            isConnecting
                ? null
                : () async {
                  if (isConnected) {
                    await _handleDisconnect(bleService);
                  } else {
                    await _handleConnect(context, bleService);
                  }
                },
      ),
    );
  }

  Widget _buildErrorDisplay(WidgetRef ref) {
    final bleService = ref.read(fetalDopplerBLEProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.medicalRedLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.medicalRed, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.medicalRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<String>(
              stream: bleService.errorStream,
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? 'Terjadi kesalahan koneksi',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.medicalRed,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnect(
    BuildContext context,
    FetalDopplerBLEService bleService,
  ) async {
    try {
      // Start scanning for devices
      await bleService.startScan();

      // Listen to device list stream to get available devices
      final deviceCompleter = Completer<List<BluetoothDevice>>();
      late StreamSubscription subscription;

      subscription = bleService.deviceListStream.listen((devices) {
        if (devices.isNotEmpty && !deviceCompleter.isCompleted) {
          deviceCompleter.complete(devices);
          subscription.cancel();
        }
      });

      // Wait for devices to be discovered or timeout
      final devices = await deviceCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => <BluetoothDevice>[],
      );

      if (devices.isNotEmpty) {
        final success = await bleService.connectToDevice(devices.first);
        if (success) {
          onConnected?.call();
        } else {
          throw Exception('Failed to connect to device');
        }
      } else {
        throw Exception('No fetal doppler devices found');
      }
    } catch (e) {
      onError?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghubungkan: ${e.toString()}'),
            backgroundColor: AppColors.medicalRed,
          ),
        );
      }
    } finally {
      await bleService.stopScan();
    }
  }

  Future<void> _handleDisconnect(FetalDopplerBLEService bleService) async {
    try {
      await bleService.disconnect();
      onDisconnected?.call();
    } catch (e) {
      onError?.call();
    }
  }
}

// Fetal Heart Rate Stream Widget
class FetalHeartRateStreamWidget extends ConsumerWidget {
  final Function(FetalHeartRateData) onHeartRateReceived;
  final int gestationalAge;

  const FetalHeartRateStreamWidget({
    super.key,
    required this.onHeartRateReceived,
    required this.gestationalAge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleService = ref.read(fetalDopplerBLEProvider.notifier);

    // Listen to heart rate data stream
    return StreamBuilder<FetalHeartRateData>(
      stream: bleService.heartRateStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Call callback with new data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onHeartRateReceived(snapshot.data!);
          });
        }

        return const SizedBox.shrink(); // This widget doesn't render anything
      },
    );
  }
}

// Current BPM Display Widget
class CurrentFetalBPMDisplay extends ConsumerWidget {
  final FetalHeartRateData? latestReading;

  const CurrentFetalBPMDisplay({super.key, this.latestReading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(fetalDopplerBLEProvider);

    if (connectionState != BLEConnectionState.monitoring ||
        latestReading == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.medicalGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // BPM Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detak Jantung Janin',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${latestReading!.bpm}',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'BPM',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status and Quality Indicators
          Column(
            children: [
              _buildClassificationIndicator(latestReading!.classification),
              const SizedBox(height: 8),
              if (latestReading!.signalQuality != null)
                _buildSignalQualityIndicator(latestReading!.signalQuality!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationIndicator(FetalBPMClassification classification) {
    Color color;
    String label;

    switch (classification) {
      case FetalBPMClassification.normal:
        color = AppColors.medicalGreen;
        label = 'NORMAL';
        break;
      case FetalBPMClassification.bradycardia:
        color = AppColors.medicalOrange;
        label = 'BRADIKARDIA';
        break;
      case FetalBPMClassification.tachycardia:
        color = AppColors.medicalRed;
        label = 'TACHIKARDIA';
        break;
      case FetalBPMClassification.irregular:
        color = AppColors.medicalPurple;
        label = 'IRREGULAR';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSignalQualityIndicator(double quality) {
    final percentage = (quality * 100).round();
    Color color;

    if (percentage >= 80) {
      color = AppColors.medicalGreen;
    } else if (percentage >= 60) {
      color = AppColors.medicalOrange;
    } else {
      color = AppColors.medicalRed;
    }

    return Row(
      children: [
        Icon(Icons.signal_cellular_alt, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$percentage%',
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Monitoring Control Widget
class FetalMonitoringControlWidget extends ConsumerWidget {
  final VoidCallback? onStartMonitoring;
  final VoidCallback? onStopMonitoring;
  final bool isMonitoring;

  const FetalMonitoringControlWidget({
    super.key,
    this.onStartMonitoring,
    this.onStopMonitoring,
    this.isMonitoring = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(fetalDopplerBLEProvider);
    final bleService = ref.read(fetalDopplerBLEProvider.notifier);
    final isConnected =
        connectionState == BLEConnectionState.connected ||
        connectionState == BLEConnectionState.monitoring;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Start Monitoring Button
        if (!isMonitoring && isConnected)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Mulai Monitoring Janin',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.medicalWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medicalGreen,
                foregroundColor: AppColors.medicalWhite,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: AppColors.medicalGreen.withValues(alpha: 0.3),
              ),
              onPressed: () async {
                await bleService.startMonitoring();
                onStartMonitoring?.call();
              },
            ),
          ),

        // Stop Monitoring Button
        if (isMonitoring)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: Text(
                'Stop Monitoring',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.medicalWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medicalRed,
                foregroundColor: AppColors.medicalWhite,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: AppColors.medicalRed.withValues(alpha: 0.3),
              ),
              onPressed: () async {
                await bleService.stopMonitoring();
                onStopMonitoring?.call();
              },
            ),
          ),
      ],
    );
  }
}
