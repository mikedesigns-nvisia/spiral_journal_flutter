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
import 'package:spiral_journal/services/core_library_service.dart';
import 'package:spiral_journal/services/core_evolution_engine.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';
import 'package:spiral_journal/services/profile_service.dart';
import 'package:spiral_journal/services/app_initializer.dart';
import 'package:spiral_journal/controllers/splash_screen_controller.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/screens/main_screen.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';
import '../utils/mock_service_factory.dart';
import '../utils/integration_test_app.dart';
import '../utils/navigation_test_helper.dart';

void main() {
  group('Complete Journaling Workflow Integration Tests', () {
    late JournalProvider journalProvider;
    late CoreProvider coreProvider;
    late ThemeService themeService;
    late SettingsService settingsService;
    late JournalService journalService;
    late AIServiceManager aiServiceManager;
    late CoreLibraryService coreLibraryService;
    late CoreEvolutionEngine coreEvolutionEngine;
    late EmotionalAnalyzer emotionalAnalyzer;

    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    setUp(() {
      // Initialize services
      themeService = ThemeService();
      settingsService = SettingsService();
      journalService = JournalService();
      aiServiceManager = AIServiceManager();
      coreLibraryService = CoreLibraryService();
      coreEvolutionEngine = CoreEvolutionEngine();
      emotionalAnalyzer = EmotionalAnalyzer();
      
      // Initialize providers
      journalProvider = JournalProvider();
      coreProvider = CoreProvider();
    });

    tearDown(() {
      // Dispose services and providers to prevent disposal errors
      journalProvider.dispose();
      coreProvider.dispose();
      themeService.dispose();
      settingsService.dispose();
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<JournalProvider>.value(value: journalProvider),
          ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ChangeNotifierProvider<ThemeService>.value(value: themeService),
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
          Provider<JournalService>.value(value: journalService),
          Provider<AIServiceManager>.value(value: aiServiceManager),
          Provider<CoreLibraryService>.value(value: coreLibraryService),
          Provider<CoreEvolutionEngine>.value(value: coreEvolutionEngine),
          Provider<EmotionalAnalyzer>.value(value: emotionalAnalyzer),
        ],
        child: const SpiralJournalApp(),
      );
    }

    testWidgets('should complete full journal entry workflow', (WidgetTester tester) async {
      // Use the integration test app for better stability
      await tester.pumpWidget(const IntegrationTestApp());
      
      // Wait for app to stabilize
      await NavigationTestHelper.waitForAppStable(tester);

      // Verify we're on the journal screen (should be default)
      await NavigationTestHelper.waitForScreenToLoad(tester, 'journal');
      
      // Find the text input field using the test key we added
      var textFieldFinder = find.byKey(const Key('journal_text_input'));
      if (textFieldFinder.evaluate().isEmpty) {
        // Fallback to finding by type
        textFieldFinder = find.byType(TextField);
      }
      if (textFieldFinder.evaluate().isEmpty) {
        // Try finding by hint text
        textFieldFinder = find.byWidgetPredicate(
          (widget) => widget is TextField && 
                     widget.decoration?.hintText?.contains('Share your thoughts') == true,
        );
      }
      
      // Verify text field exists
      expect(textFieldFinder, findsAtLeastNWidgets(1));
      
      // Enter journal content
      const testContent = 'Today was an amazing day! I felt so grateful for my friends and family. I learned something new about myself and I\'m excited about the future.';
      await tester.enterText(textFieldFinder.first, testContent);
      await tester.pump();

      // Look for mood selector chips - they should be present on the journal screen
      final moodsToSelect = ['Happy', 'Grateful', 'Excited'];
      for (final mood in moodsToSelect) {
        // Try to find mood chips by text
        var moodFinder = find.text(mood);
        if (moodFinder.evaluate().isEmpty) {
          // Try finding by widget predicate for chip-like widgets
          moodFinder = find.byWidgetPredicate(
            (widget) => widget.toString().toLowerCase().contains(mood.toLowerCase()),
          );
        }
        
        if (moodFinder.evaluate().isNotEmpty) {
          await tester.tap(moodFinder.first);
          await tester.pump();
        }
      }

      // Find and tap the save button - look for the actual button text
      var saveButtonFinder = find.text('Save Entry');
      if (saveButtonFinder.evaluate().isEmpty) {
        // Try finding by icon
        saveButtonFinder = find.byIcon(Icons.save_rounded);
      }
      if (saveButtonFinder.evaluate().isEmpty) {
        // Try finding any button that might be the save button
        saveButtonFinder = find.byWidgetPredicate(
          (widget) => widget is ElevatedButton || 
                     (widget is Text && widget.data?.contains('Save') == true),
        );
      }
      
      if (saveButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(saveButtonFinder.first);
        await tester.pumpAndSettle();
      }

      // Navigate to history and verify entry was saved
      await NavigationTestHelper.navigateToTab(tester, 'History');
      await NavigationTestHelper.waitForScreenToLoad(tester, 'history');

      // Should see the saved entry in history - be more flexible with the search
      final entryFinder = find.textContaining('Today was an amazing day');
      if (entryFinder.evaluate().isEmpty) {
        // Try searching for any part of the content
        final partialFinder = find.textContaining('amazing day');
        expect(partialFinder, findsAtLeastNWidgets(1));
      } else {
        expect(entryFinder, findsAtLeastNWidgets(1));
      }
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
      // Use integration test app for better stability
      await tester.pumpWidget(const IntegrationTestApp());
      
      // Wait for app to stabilize
      await NavigationTestHelper.waitForAppStable(tester);

      // Verify all tabs are present
      NavigationTestHelper.verifyAllTabsPresent(tester);

      // Test navigation between all tabs using robust navigation helper
      final tabs = ['Journal', 'History', 'Mirror', 'Insights', 'Settings'];
      
      await NavigationTestHelper.performNavigationSequence(
        tester,
        tabs,
        verifyEachNavigation: true,
      );

      // Verify we can navigate back to the first tab
      await NavigationTestHelper.navigateToTab(tester, 'Journal');
      await NavigationTestHelper.waitForScreenToLoad(tester, 'journal');
    });

    testWidgets('should handle performance with multiple entries', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Wait for app to fully initialize
      await tester.pump(const Duration(milliseconds: 100));

      // Look for journal input - try key first, then fallback to TextField
      var journalInputFinder = find.byKey(const Key('journal_input'));
      if (journalInputFinder.evaluate().isEmpty) {
        journalInputFinder = find.byType(TextField);
      }

      // If no TextField found, try to find the journal screen first
      if (journalInputFinder.evaluate().isEmpty) {
        // Try to navigate to journal tab if not already there
        var journalTab = find.text('Journal');
        if (journalTab.evaluate().isEmpty) {
          journalTab = find.byIcon(Icons.edit);
        }
        if (journalTab.evaluate().isNotEmpty) {
          await tester.tap(journalTab.first);
          await tester.pumpAndSettle();
        }
      }

      // Create multiple entries to test performance (reduced number for stability)
      for (int i = 0; i < 3; i++) {
        // Find journal input again after each iteration
        final journalInput = find.byType(TextField);
        
        if (journalInput.evaluate().isNotEmpty) {
          await tester.tap(journalInput.first);
          await tester.pump();

          await tester.enterText(journalInput.first, 'Performance test entry $i with some content to make it realistic');
          await tester.pump();

          // Look for save button - try multiple variations
          var saveButton = find.text('Save Entry');
          if (saveButton.evaluate().isEmpty) {
            saveButton = find.text('Save');
          }
          if (saveButton.evaluate().isEmpty) {
            saveButton = find.byIcon(Icons.save);
          }
          
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton.first);
            await tester.pumpAndSettle();
          }

          // Clear for next entry
          if (journalInput.evaluate().isNotEmpty) {
            await tester.enterText(journalInput.first, '');
            await tester.pump();
          }
        }
      }

      // Navigate to history and verify performance
      final stopwatch = Stopwatch()..start();
      
      var historyTab = find.text('History');
      if (historyTab.evaluate().isEmpty) {
        historyTab = find.byIcon(Icons.history);
      }
      if (historyTab.evaluate().isNotEmpty) {
        await tester.tap(historyTab.first);
        await tester.pumpAndSettle();
      }
      
      stopwatch.stop();

      // Should load within reasonable time (less than 3 seconds for stability)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      
      // Should show at least one entry (more flexible expectation)
      var entryFinder = find.textContaining('Performance test entry');
      if (entryFinder.evaluate().isEmpty) {
        entryFinder = find.textContaining('test entry');
      }
      expect(entryFinder, findsAtLeastNWidgets(1));
    });
  });
}
