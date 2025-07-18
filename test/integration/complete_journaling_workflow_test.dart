import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/main.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/settings_service.dart';
import 'package:spiral_journal/services/theme_service.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Complete Journaling Workflow Integration Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    testWidgets('should complete full journal entry workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to journal screen (should be default)
      expect(find.text('Journal'), findsOneWidget);
      
      // Find and tap on journal input
      final journalInput = find.byType(TextField);
      expect(journalInput, findsOneWidget);
      
      await tester.tap(journalInput);
      await tester.pump();

      // Enter journal content
      const testContent = 'Today was an amazing day! I felt so grateful for my friends and family. I learned something new about myself and I\'m excited about the future.';
      await tester.enterText(journalInput, testContent);
      await tester.pump();

      // Select moods
      await tester.tap(find.text('Happy'));
      await tester.pump();
      await tester.tap(find.text('Grateful'));
      await tester.pump();
      await tester.tap(find.text('Excited'));
      await tester.pump();

      // Save the entry
      final saveButton = find.text('Save Entry');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }

      // Verify entry was saved by checking history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Should see the saved entry in history
      expect(find.textContaining('Today was an amazing day'), findsOneWidget);
    });

    testWidgets('should handle AI analysis workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Create journal entry
      final journalInput = find.byType(TextField);
      await tester.tap(journalInput);
      await tester.pump();

      await tester.enterText(journalInput, 'I overcame a difficult challenge today and feel proud of my growth.');
      await tester.pump();

      // Trigger AI analysis
      final analyzeButton = find.text('Analyze');
      if (analyzeButton.evaluate().isNotEmpty) {
        await tester.tap(analyzeButton);
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Wait for analysis to complete
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should show analysis results
        expect(find.textContaining('Analysis'), findsOneWidget);
      }

      // Check emotional mirror for analysis results
      await tester.tap(find.text('Mirror'));
      await tester.pumpAndSettle();

      // Should show emotional analysis data
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should handle core evolution workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to core library
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();

      // Should show all six cores
      expect(find.text('Optimism'), findsOneWidget);
      expect(find.text('Resilience'), findsOneWidget);
      expect(find.text('Self-Awareness'), findsOneWidget);
      expect(find.text('Creativity'), findsOneWidget);
      expect(find.text('Social Connection'), findsOneWidget);
      expect(find.text('Growth Mindset'), findsOneWidget);

      // Tap on a core to see details
      await tester.tap(find.text('Optimism'));
      await tester.pumpAndSettle();

      // Should show core details
      expect(find.textContaining('progress'), findsOneWidget);
    });

    testWidgets('should handle search and filtering workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Create multiple entries first
      for (int i = 0; i < 3; i++) {
        final journalInput = find.byType(TextField);
        await tester.tap(journalInput);
        await tester.pump();

        await tester.enterText(journalInput, 'Test entry $i with unique content');
        await tester.pump();

        final saveButton = find.text('Save Entry');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }

        // Clear input for next entry
        await tester.enterText(journalInput, '');
        await tester.pump();
      }

      // Navigate to history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Should see multiple entries
      expect(find.textContaining('Test entry'), findsWidgets);

      // Test search functionality
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.tap(searchField);
        await tester.pump();
        
        await tester.enterText(searchField, 'unique');
        await tester.pump();

        // Should filter results
        expect(find.textContaining('unique content'), findsWidgets);
      }
    });

    testWidgets('should handle theme switching workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Find theme toggle
      final themeSwitch = find.byType(Switch);
      if (themeSwitch.evaluate().isNotEmpty) {
        // Toggle theme
        await tester.tap(themeSwitch);
        await tester.pumpAndSettle();

        // Theme should change - verify by checking if app still renders
        expect(find.text('Settings'), findsOneWidget);
        
        // Navigate back to journal to verify theme applied
        await tester.tap(find.text('Journal'));
        await tester.pumpAndSettle();
        
        expect(find.byType(TextField), findsOneWidget);
      }
    });

    testWidgets('should handle data export workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Create a journal entry first
      final journalInput = find.byType(TextField);
      await tester.tap(journalInput);
      await tester.pump();

      await tester.enterText(journalInput, 'Entry for export test');
      await tester.pump();

      final saveButton = find.text('Save Entry');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Find export button
      final exportButton = find.text('Export Data');
      if (exportButton.evaluate().isNotEmpty) {
        await tester.tap(exportButton);
        await tester.pumpAndSettle();

        // Should show export dialog or screen
        expect(find.textContaining('export'), findsOneWidget);
      }
    });

    testWidgets('should handle error recovery workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate error condition by entering problematic content
      final journalInput = find.byType(TextField);
      await tester.tap(journalInput);
      await tester.pump();

      // Enter content that might cause issues
      await tester.enterText(journalInput, 'Test entry with special characters: @#\$%^&*()');
      await tester.pump();

      // Try to save
      final saveButton = find.text('Save Entry');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }

      // App should still be functional
      expect(find.text('Journal'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should handle navigation workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test navigation between all tabs
      final tabs = ['Journal', 'History', 'Mirror', 'Insights', 'Settings'];
      
      for (final tab in tabs) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        
        // Verify we're on the correct tab
        expect(find.text(tab), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      }
    });

    testWidgets('should handle performance with multiple entries', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Create multiple entries to test performance
      for (int i = 0; i < 10; i++) {
        final journalInput = find.byType(TextField);
        await tester.tap(journalInput);
        await tester.pump();

        await tester.enterText(journalInput, 'Performance test entry $i with some content to make it realistic');
        await tester.pump();

        final saveButton = find.text('Save Entry');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pump();
        }

        // Clear for next entry
        await tester.enterText(journalInput, '');
        await tester.pump();
      }

      // Navigate to history and verify performance
      final stopwatch = Stopwatch()..start();
      
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      
      stopwatch.stop();

      // Should load within reasonable time (less than 2 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      
      // Should show entries
      expect(find.textContaining('Performance test entry'), findsWidgets);
    });
  });
}
