import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/main.dart';
import 'package:spiral_journal/screens/privacy_dashboard_screen.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Privacy Dashboard TestFlight Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    testWidgets('should have proper header styling and navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const SpiralJournalApp());
      await tester.pumpAndSettle();

      // Navigate to settings first
      final settingsTab = find.text('Settings');
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // Find and tap privacy dashboard link
        final privacyLink = find.textContaining('Privacy');
        if (privacyLink.evaluate().isNotEmpty) {
          await tester.tap(privacyLink.first);
          await tester.pumpAndSettle();

          // Verify proper AppBar
          final appBar = find.byType(AppBar);
          expect(appBar, findsOneWidget);

          // Verify title
          expect(find.text('Privacy Dashboard'), findsOneWidget);

          // Verify back button exists for navigation
          expect(find.byType(BackButton), findsOneWidget);

          // Test back navigation
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();

          // Should return to settings
          expect(find.text('Settings'), findsOneWidget);
        }
      }
    });

    testWidgets('should show zero data counts for fresh install', (WidgetTester tester) async {
      // Test the privacy dashboard directly
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacyDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show zero counts for fresh install
      expect(find.text('0'), findsWidgets);
      
      // Should show privacy information
      expect(find.text('Your Privacy Matters'), findsOneWidget);
      expect(find.text('Data Stored Locally'), findsOneWidget);
      expect(find.text('Privacy Controls'), findsOneWidget);
    });

    testWidgets('should have working privacy controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacyDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find privacy control switches
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // Test toggling personalized insights
      if (switches.evaluate().isNotEmpty) {
        final firstSwitch = switches.first;
        await tester.tap(firstSwitch);
        await tester.pumpAndSettle();

        // Should not crash
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should show proper security features', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacyDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify security features are displayed
      expect(find.text('Security Features'), findsOneWidget);
      expect(find.text('PIN Protection'), findsOneWidget);
      expect(find.text('Data Encryption'), findsOneWidget);
      expect(find.text('Secure API Keys'), findsOneWidget);
    });

    testWidgets('should have data management options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacyDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify data management section
      expect(find.text('Data Management'), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('Delete All Data'), findsOneWidget);

      // Test export button
      final exportButton = find.text('Export Data');
      if (exportButton.evaluate().isNotEmpty) {
        await tester.tap(exportButton);
        await tester.pumpAndSettle();

        // Should not crash (may show error dialog for missing navigation)
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should show data usage explanation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacyDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify data usage explanations
      expect(find.text('How Your Data is Used'), findsOneWidget);
      expect(find.text('Local Storage Only'), findsOneWidget);
      expect(find.text('AI Analysis'), findsOneWidget);
      expect(find.text('Encryption'), findsOneWidget);
      expect(find.text('No Account Required'), findsOneWidget);
    });
  });
}