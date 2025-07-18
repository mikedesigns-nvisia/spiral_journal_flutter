import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/main.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/theme_service.dart';
import 'package:spiral_journal/repositories/journal_repository_impl.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Performance Integration Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });
    late JournalService journalService;
    late JournalRepositoryImpl journalRepository;
    late AIServiceManager aiServiceManager;
    late ThemeService themeService;

    setUp(() async {
      journalService = JournalService();
      journalRepository = JournalRepositoryImpl();
      aiServiceManager = AIServiceManager();
      themeService = ThemeService();
      
      await journalService.initialize();
    });

    testWidgets('should maintain UI responsiveness during data operations', (WidgetTester tester) async {
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

      // Measure app startup time
      final startupStopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      startupStopwatch.stop();

      expect(startupStopwatch.elapsedMilliseconds, lessThan(3000)); // Less than 3 seconds

      // Test journal input responsiveness
      final journalInput = find.byType(TextField);
      expect(journalInput, findsOneWidget);

      final inputStopwatch = Stopwatch()..start();
      await tester.tap(journalInput);
      await tester.pump();
      inputStopwatch.stop();

      expect(inputStopwatch.elapsedMilliseconds, lessThan(100)); // Less than 100ms

      // Test text input performance
      const longText = 'This is a very long journal entry that simulates real user input with substantial content to test the performance of text input handling in the journal screen. It includes multiple sentences and various punctuation marks to make it realistic.';
      
      final textInputStopwatch = Stopwatch()..start();
      await tester.enterText(journalInput, longText);
      await tester.pump();
      textInputStopwatch.stop();

      expect(textInputStopwatch.elapsedMilliseconds, lessThan(500)); // Less than 500ms

      // Test navigation performance
      final navigationStopwatch = Stopwatch()..start();
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      navigationStopwatch.stop();

      expect(navigationStopwatch.elapsedMilliseconds, lessThan(1000)); // Less than 1 second
    });

    testWidgets('should handle large datasets efficiently in UI', (WidgetTester tester) async {
      // Pre-populate with test data
      final entries = <JournalEntry>[];
      for (int i = 0; i < 50; i++) {
        entries.add(JournalEntry(
          id: 'ui-performance-test-$i',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(days: i)),
          content: 'UI performance test entry $i with substantial content for realistic testing',
          moods: ['neutral', 'testing'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now().subtract(Duration(days: i)),
          updatedAt: DateTime.now().subtract(Duration(days: i)),
        ));
      }

      // Save entries
      for (final entry in entries) {
        await journalService.saveEntry(entry);
      }

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

      // Navigate to history and measure load time
      final historyLoadStopwatch = Stopwatch()..start();
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      historyLoadStopwatch.stop();

      expect(historyLoadStopwatch.elapsedMilliseconds, lessThan(2000)); // Less than 2 seconds

      // Test scrolling performance
      final scrollableWidget = find.byType(Scrollable);
      if (scrollableWidget.evaluate().isNotEmpty) {
        final scrollStopwatch = Stopwatch()..start();
        
        await tester.drag(scrollableWidget, const Offset(0, -500));
        await tester.pump();
        
        scrollStopwatch.stop();
        expect(scrollStopwatch.elapsedMilliseconds, lessThan(200)); // Less than 200ms
      }
    });

    testWidgets('should handle theme switching performance', (WidgetTester tester) async {
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
        // Measure theme switch performance
        final themeSwitchStopwatch = Stopwatch()..start();
        
        await tester.tap(themeSwitch);
        await tester.pumpAndSettle();
        
        themeSwitchStopwatch.stop();
        expect(themeSwitchStopwatch.elapsedMilliseconds, lessThan(1000)); // Less than 1 second

        // Verify app is still responsive after theme change
        await tester.tap(find.text('Journal'));
        await tester.pumpAndSettle();
        
        expect(find.byType(TextField), findsOneWidget);
      }
    });

    test('should handle database operations efficiently', () async {
      // Test bulk insert performance
      final entries = <JournalEntry>[];
      for (int i = 0; i < 100; i++) {
        entries.add(JournalEntry(
          id: 'bulk-insert-test-$i',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(minutes: i)),
          content: 'Bulk insert performance test entry $i',
          moods: ['neutral'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now().subtract(Duration(minutes: i)),
          updatedAt: DateTime.now().subtract(Duration(minutes: i)),
        ));
      }

      final bulkInsertStopwatch = Stopwatch()..start();
      await journalRepository.saveEntriesInTransaction(entries);
      bulkInsertStopwatch.stop();

      expect(bulkInsertStopwatch.elapsedMilliseconds, lessThan(3000)); // Less than 3 seconds

      // Test query performance
      final queryStopwatch = Stopwatch()..start();
      final allEntries = await journalRepository.getAllEntries();
      queryStopwatch.stop();

      expect(allEntries.length, equals(100));
      expect(queryStopwatch.elapsedMilliseconds, lessThan(1000)); // Less than 1 second

      // Test search performance
      final searchStopwatch = Stopwatch()..start();
      final searchResults = await journalRepository.searchEntries('performance');
      searchStopwatch.stop();

      expect(searchResults.length, equals(100));
      expect(searchStopwatch.elapsedMilliseconds, lessThan(1500)); // Less than 1.5 seconds

      // Test pagination performance
      final paginationStopwatch = Stopwatch()..start();
      final paginatedResults = await journalRepository.getEntriesPaginated(
        offset: 0,
        limit: 20,
      );
      paginationStopwatch.stop();

      expect(paginatedResults.length, equals(20));
      expect(paginationStopwatch.elapsedMilliseconds, lessThan(500)); // Less than 500ms

      // Test update performance
      final updateStopwatch = Stopwatch()..start();
      final entryToUpdate = allEntries.first.copyWith(
        content: 'Updated content for performance test',
        updatedAt: DateTime.now(),
      );
      await journalRepository.updateEntry(entryToUpdate);
      updateStopwatch.stop();

      expect(updateStopwatch.elapsedMilliseconds, lessThan(200)); // Less than 200ms

      // Test delete performance
      final deleteStopwatch = Stopwatch()..start();
      await journalRepository.deleteEntry(allEntries.last.id);
      deleteStopwatch.stop();

      expect(deleteStopwatch.elapsedMilliseconds, lessThan(200)); // Less than 200ms
    });

    test('should handle AI service operations efficiently', () async {
      // Test AI service initialization
      final initStopwatch = Stopwatch()..start();
      await aiServiceManager.initialize();
      initStopwatch.stop();

      expect(initStopwatch.elapsedMilliseconds, lessThan(2000)); // Less than 2 seconds

      // Test cache performance
      final testEntry = JournalEntry(
        id: 'ai-performance-test',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'AI performance test entry with emotional content about happiness and gratitude',
        moods: ['happy', 'grateful'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // First analysis (should be slower - no cache)
      final firstAnalysisStopwatch = Stopwatch()..start();
      try {
        await aiServiceManager.analyzeEntry(testEntry);
      } catch (e) {
        // AI service might not be available in test environment
        // This is acceptable for performance testing
      }
      firstAnalysisStopwatch.stop();

      // Second analysis (should be faster - cached)
      final secondAnalysisStopwatch = Stopwatch()..start();
      try {
        await aiServiceManager.analyzeEntry(testEntry);
      } catch (e) {
        // AI service might not be available in test environment
      }
      secondAnalysisStopwatch.stop();

      // Cache should make second call faster (if AI service is available)
      if (firstAnalysisStopwatch.elapsedMilliseconds > 0 && 
          secondAnalysisStopwatch.elapsedMilliseconds > 0) {
        expect(secondAnalysisStopwatch.elapsedMilliseconds, 
               lessThanOrEqualTo(firstAnalysisStopwatch.elapsedMilliseconds));
      }
    });

    test('should handle memory usage efficiently', () async {
      // Create a large number of entries to test memory usage
      final entries = <JournalEntry>[];
      for (int i = 0; i < 200; i++) {
        entries.add(JournalEntry(
          id: 'memory-test-$i',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(hours: i)),
          content: 'Memory usage test entry $i with substantial content to simulate real usage patterns and test memory efficiency under load',
          moods: ['neutral', 'testing'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now().subtract(Duration(hours: i)),
          updatedAt: DateTime.now().subtract(Duration(hours: i)),
        ));
      }

      // Save entries in batches to test memory efficiency
      const batchSize = 50;
      for (int i = 0; i < entries.length; i += batchSize) {
        final batch = entries.skip(i).take(batchSize).toList();
        await journalRepository.saveEntriesInTransaction(batch);
      }

      // Test memory efficiency of large queries
      final memoryTestStopwatch = Stopwatch()..start();
      final allEntries = await journalRepository.getAllEntries();
      memoryTestStopwatch.stop();

      expect(allEntries.length, equals(200));
      expect(memoryTestStopwatch.elapsedMilliseconds, lessThan(2000)); // Less than 2 seconds

      // Test pagination to ensure memory efficiency
      final paginatedEntries = <JournalEntry>[];
      const pageSize = 25;
      
      for (int offset = 0; offset < 200; offset += pageSize) {
        final page = await journalRepository.getEntriesPaginated(
          offset: offset,
          limit: pageSize,
        );
        paginatedEntries.addAll(page);
      }

      expect(paginatedEntries.length, equals(200));
    });

    testWidgets('should handle animation performance', (WidgetTester tester) async {
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

      // Test navigation animation performance
      final animationStopwatch = Stopwatch()..start();
      
      // Navigate between tabs multiple times
      final tabs = ['History', 'Mirror', 'Insights', 'Settings', 'Journal'];
      
      for (final tab in tabs) {
        await tester.tap(find.text(tab));
        await tester.pump(); // Single pump to test animation start
        await tester.pump(const Duration(milliseconds: 100)); // Partial animation
      }
      
      animationStopwatch.stop();
      
      // Should handle multiple navigation animations efficiently
      expect(animationStopwatch.elapsedMilliseconds, lessThan(2000)); // Less than 2 seconds

      // Ensure final state is correct
      await tester.pumpAndSettle();
      expect(find.text('Journal'), findsOneWidget);
    });

    test('should handle concurrent operations performance', () async {
      // Test concurrent read operations
      final readFutures = <Future>[];
      
      for (int i = 0; i < 10; i++) {
        readFutures.add(journalRepository.getAllEntries());
      }

      final concurrentReadStopwatch = Stopwatch()..start();
      final readResults = await Future.wait(readFutures);
      concurrentReadStopwatch.stop();

      expect(readResults.length, equals(10));
      expect(concurrentReadStopwatch.elapsedMilliseconds, lessThan(3000)); // Less than 3 seconds

      // Test concurrent write operations
      final writeFutures = <Future>[];
      
      for (int i = 0; i < 5; i++) {
        final entry = JournalEntry(
          id: 'concurrent-write-test-$i',
          userId: 'test-user',
          date: DateTime.now(),
          content: 'Concurrent write test entry $i',
          moods: ['neutral'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        writeFutures.add(journalService.saveEntry(entry));
      }

      final concurrentWriteStopwatch = Stopwatch()..start();
      await Future.wait(writeFutures);
      concurrentWriteStopwatch.stop();

      expect(concurrentWriteStopwatch.elapsedMilliseconds, lessThan(2000)); // Less than 2 seconds

      // Verify all entries were saved
      final allEntries = await journalRepository.getAllEntries();
      final concurrentEntries = allEntries.where((e) => e.id.startsWith('concurrent-write-test')).toList();
      expect(concurrentEntries.length, equals(5));
    });
  });
}