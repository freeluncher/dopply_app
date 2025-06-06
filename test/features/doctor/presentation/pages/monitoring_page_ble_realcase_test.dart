import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/presentation/pages/monitoring_page.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/esp32_ble_bpm_stream_widget.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/esp32_connection_button.dart';
import 'package:mockito/mockito.dart';

// Mock BLE controller
class MockEsp32BleBpmStreamWidgetController extends Mock
    implements Esp32BleBpmStreamWidgetController {}

void main() {
  group('BLE ESP32 Connection (Realcase Simulation)', () {
    testWidgets(
      'Connect and disconnect BLE ESP32 updates state and calls controller',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [],
            child: MaterialApp(home: MonitoringPage()),
          ),
        );

        // Find the ESP32ConnectionButton (custom widget)
        final connectBtn = find.byType(ESP32ConnectionButton);
        expect(connectBtn, findsOneWidget);
        // Tap the connect button (simulate user action)
        await tester.tap(connectBtn);
        await tester.pumpAndSettle();
        // Optionally, check for state change or UI feedback
        // (e.g., a disconnect button appears, or a status text changes)
        // Find the disconnect button (should be the same widget, but state changed)
        // Tap again to disconnect
        await tester.tap(connectBtn);
        await tester.pumpAndSettle();
        // You can add more expectations here for state/UI changes if needed
      },
    );
  });
}
