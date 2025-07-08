import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/presentation/pages/modern_fetal_monitoring_page.dart';

void main() {
  group('Modern Fetal Monitoring Page Tests', () {
    testWidgets('ModernFetalMonitoringPage renders without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: ModernFetalMonitoringPage())),
      );

      // Verify the page loads without error
      expect(find.byType(ModernFetalMonitoringPage), findsOneWidget);

      // Verify the AppBar is present
      expect(find.byType(AppBar), findsOneWidget);

      // Verify the page title
      expect(find.text('Fetal Heart Rate Monitoring'), findsOneWidget);
    });

    testWidgets('Page contains monitoring controls and chart', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: ModernFetalMonitoringPage())),
      );

      await tester.pumpAndSettle();

      // Check for BLE monitoring widget
      expect(find.text('Device Connection'), findsOneWidget);

      // Check for real-time chart
      expect(find.text('Real-time Fetal Heart Rate'), findsOneWidget);
    });
  });
}
