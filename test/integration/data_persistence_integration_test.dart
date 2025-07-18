import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/repositories/journal_repository.dart';
import 'package:spiral_journal/repositories/journal_repository_impl.dart';
import 'package:spiral_journal/database/database_helper.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/data_export_service.dart';
import 'package:spiral_journal/services/secure_data_deletion_service.dart';
import 'package:spiral_journal/models/export_data.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Data Persistence Integration Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });
    late JournalService journalService;
    late JournalRepository journalRepository;
    late DatabaseHelper databaseHelper;
    late DataExportService exportService;
    late SecureDataDeletionService deletionService;

    setUp(() async {
      journalService = JournalService();
      journalRepository = JournalRepositoryImpl();
      databaseHelper = DatabaseHelper();
      exportService = DataExportService();
      deletionService = SecureDataDeletionService();
      
      // Initialize services
      await journalService.initialize();
      await databaseHelper.database; // Initialize database
    });

    tearDown(() async {
      // Clean up test data
      await deletionService.deleteAllData();
    });

    test('should complete full data persistence workflow', () async {
      // Create test journal entry
      final entry = JournalEntry(
        id: 'integration-test-1',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Integration test entry with comprehensive data',
        moods: ['happy', 'grateful', 'excited'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save entry through service
      final savedEntry = await journalService.saveEntry(entry);
      expect(savedEntry.id, equals(entry.id));
      expect(savedEntry.content, equals(entry.content));

      // Retrieve entry through repository
      final retrievedEntry = await journalRepository.getEntryById(entry.id);
      expect(retrievedEntry, isNotNull);
      expect(retrievedEntry!.content, equals(entry.content));
      expect(retrievedEntry.moods, equals(entry.moods));

      // Update entry
      final updatedEntry = retrievedEntry.copyWith(
        content: 'Updated integration test content',
        updatedAt: DateTime.now(),
      );
      
      final savedUpdatedEntry = await journalService.updateEntry(updatedEntry);
      expect(savedUpdatedEntry.content, equals('Updated integration test content'));

      // Verify update persisted
      final reRetrievedEntry = await journalRepository.getEntryById(entry.id);
      expect(reRetrievedEntry!.content, equals('Updated integration test content'));
    });

    test('should handle multiple entries with search and filtering', () async {
      // Create multiple test entries
      final entries = [
        JournalEntry(
          id: 'search-test-1',
          userId: 'test-user',
          date: DateTime.now().subtract(const Duration(days: 5)),
          content: 'First entry about gratitude and happiness',
          moods: ['grateful', 'happy'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        JournalEntry(
          id: 'search-test-2',
          userId: 'test-user',
          date: DateTime.now().subtract(const Duration(days: 3)),
          content: 'Second entry about creativity and excitement',
          moods: ['excited', 'creative'],
          dayOfWeek: 'Wednesday',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        JournalEntry(
          id: 'search-test-3',
          userId: 'test-user',
          date: DateTime.now().subtract(const Duration(days: 1)),
          content: 'Third entry about reflection and growth',
          moods: ['reflective', 'hopeful'],
          dayOfWeek: 'Friday',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      // Save all entries
      for (final entry in entries) {
        await journalService.saveEntry(entry);
      }

      // Test full-text search
      final searchResults = await journalRepository.searchEntries('gratitude');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.content, contains('gratitude'));

      // Test mood filtering
      final moodResults = await journalRepository.getEntriesByMood('excited');
      expect(moodResults.length, equals(1));
      expect(moodResults.first.moods, contains('excited'));

      // Test date range filtering
      final dateRangeResults = await journalRepository.getEntriesByDateRange(
        DateTime.now().subtract(const Duration(days: 4)),
        DateTime.now(),
      );
      expect(dateRangeResults.length, equals(2)); // Should get entries from last 4 days

      // Test pagination
      final paginatedResults = await journalRepository.getEntriesPaginated(
        offset: 0,
        limit: 2,
      );
      expect(paginatedResults.length, equals(2));

      // Test getting all entries
      final allEntries = await journalRepository.getAllEntries();
      expect(allEntries.length, equals(3));
    });

    test('should handle data export and import workflow', () async {
      // Create test entries
      final entries = [
        JournalEntry(
          id: 'export-test-1',
          userId: 'test-user',
          date: DateTime.now(),
          content: 'Export test entry 1',
          moods: ['happy'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        JournalEntry(
          id: 'export-test-2',
          userId: 'test-user',
          date: DateTime.now(),
          content: 'Export test entry 2',
          moods: ['grateful'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Save entries
      for (final entry in entries) {
        await journalService.saveEntry(entry);
      }

      // Export data
      final exportData = await exportService.exportAllData();
      expect(exportData, isNotNull);
      expect(exportData.journalEntries.length, equals(2));
      expect(exportData.exportDate, isNotNull);
      expect(exportData.version, isNotEmpty);

      // Verify export contains correct data
      final exportedEntry1 = exportData.journalEntries
          .firstWhere((e) => e.id == 'export-test-1');
      expect(exportedEntry1.content, equals('Export test entry 1'));

      // Test JSON serialization
      final jsonString = exportData.toJson();
      expect(jsonString, isNotEmpty);
      expect(jsonString, contains('Export test entry 1'));

      // Test import functionality
      final importedData = ExportData.fromJson(jsonString);
      expect(importedData.journalEntries.length, equals(2));
      expect(importedData.version, equals(exportData.version));
    });

    test('should handle secure data deletion', () async {
      // Create test entry
      final entry = JournalEntry(
        id: 'deletion-test-1',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Entry to be deleted',
        moods: ['neutral'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await journalService.saveEntry(entry);

      // Verify entry exists
      final retrievedEntry = await journalRepository.getEntryById(entry.id);
      expect(retrievedEntry, isNotNull);

      // Delete specific entry
      await deletionService.deleteEntry(entry.id);

      // Verify entry is deleted
      final deletedEntry = await journalRepository.getEntryById(entry.id);
      expect(deletedEntry, isNull);

      // Create multiple entries for bulk deletion test
      final bulkEntries = [
        JournalEntry(
          id: 'bulk-delete-1',
          userId: 'test-user',
          date: DateTime.now(),
          content: 'Bulk delete test 1',
          moods: ['neutral'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        JournalEntry(
          id: 'bulk-delete-2',
          userId: 'test-user',
          date: DateTime.now(),
          content: 'Bulk delete test 2',
          moods: ['neutral'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final bulkEntry in bulkEntries) {
        await journalService.saveEntry(bulkEntry);
      }

      // Verify entries exist
      final allEntriesBeforeDelete = await journalRepository.getAllEntries();
      expect(allEntriesBeforeDelete.length, equals(2));

      // Delete all data
      await deletionService.deleteAllData();

      // Verify all entries are deleted
      final allEntriesAfterDelete = await journalRepository.getAllEntries();
      expect(allEntriesAfterDelete.length, equals(0));
    });

    test('should handle database transactions and rollback', () async {
      final entry1 = JournalEntry(
        id: 'transaction-test-1',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Transaction test entry 1',
        moods: ['happy'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final entry2 = JournalEntry(
        id: 'transaction-test-2',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Transaction test entry 2',
        moods: ['grateful'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test successful transaction
      await journalRepository.saveEntriesInTransaction([entry1, entry2]);

      final savedEntries = await journalRepository.getAllEntries();
      expect(savedEntries.length, equals(2));

      // Test transaction rollback (simulate by trying to save duplicate IDs)
      final duplicateEntry = JournalEntry(
        id: 'transaction-test-1', // Same ID as entry1
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Duplicate ID entry',
        moods: ['confused'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await journalRepository.saveEntriesInTransaction([duplicateEntry]);
        fail('Should have thrown an exception for duplicate ID');
      } catch (e) {
        // Expected to fail
        expect(e, isNotNull);
      }

      // Verify original entries are still intact
      final entriesAfterFailedTransaction = await journalRepository.getAllEntries();
      expect(entriesAfterFailedTransaction.length, equals(2));
      expect(entriesAfterFailedTransaction.first.content, equals('Transaction test entry 1'));
    });

    test('should handle concurrent operations safely', () async {
      final futures = <Future>[];

      // Create multiple concurrent save operations
      for (int i = 0; i < 10; i++) {
        final entry = JournalEntry(
          id: 'concurrent-test-$i',
          userId: 'test-user',
          date: DateTime.now(),
          content: 'Concurrent test entry $i',
          moods: ['neutral'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        futures.add(journalService.saveEntry(entry));
      }

      // Wait for all operations to complete
      await Future.wait(futures);

      // Verify all entries were saved
      final allEntries = await journalRepository.getAllEntries();
      expect(allEntries.length, equals(10));

      // Verify each entry has unique ID
      final ids = allEntries.map((e) => e.id).toSet();
      expect(ids.length, equals(10));
    });

    test('should handle database migration and schema changes', () async {
      // This test verifies that the database can handle schema migrations
      final db = await databaseHelper.database;
      
      // Verify current schema version
      final version = await db.getVersion();
      expect(version, greaterThan(0));

      // Verify required tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      
      final tableNames = tables.map((table) => table['name'] as String).toList();
      expect(tableNames, contains('journal_entries'));
      expect(tableNames, contains('emotional_cores'));

      // Verify journal_entries table structure
      final journalColumns = await db.rawQuery('PRAGMA table_info(journal_entries)');
      final columnNames = journalColumns.map((col) => col['name'] as String).toList();
      
      expect(columnNames, contains('id'));
      expect(columnNames, contains('user_id'));
      expect(columnNames, contains('content'));
      expect(columnNames, contains('moods'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
    });

    test('should handle performance with large datasets', () async {
      final stopwatch = Stopwatch()..start();

      // Create a large number of entries
      final entries = <JournalEntry>[];
      for (int i = 0; i < 100; i++) {
        entries.add(JournalEntry(
          id: 'performance-test-$i',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(days: i)),
          content: 'Performance test entry $i with some substantial content to make it realistic for testing database performance under load',
          moods: ['neutral', 'testing'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now().subtract(Duration(days: i)),
          updatedAt: DateTime.now().subtract(Duration(days: i)),
        ));
      }

      // Batch save entries
      await journalRepository.saveEntriesInTransaction(entries);
      
      stopwatch.stop();
      final saveTime = stopwatch.elapsedMilliseconds;

      // Should save 100 entries in reasonable time (less than 5 seconds)
      expect(saveTime, lessThan(5000));

      // Test query performance
      stopwatch.reset();
      stopwatch.start();

      final allEntries = await journalRepository.getAllEntries();
      
      stopwatch.stop();
      final queryTime = stopwatch.elapsedMilliseconds;

      expect(allEntries.length, equals(100));
      // Should query 100 entries in reasonable time (less than 1 second)
      expect(queryTime, lessThan(1000));

      // Test search performance
      stopwatch.reset();
      stopwatch.start();

      final searchResults = await journalRepository.searchEntries('performance');
      
      stopwatch.stop();
      final searchTime = stopwatch.elapsedMilliseconds;

      expect(searchResults.length, equals(100));
      // Should search through 100 entries in reasonable time (less than 2 seconds)
      expect(searchTime, lessThan(2000));
    });
  });
}