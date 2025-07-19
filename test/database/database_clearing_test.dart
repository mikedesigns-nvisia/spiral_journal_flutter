import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spiral_journal/database/database_helper.dart';
import 'package:spiral_journal/database/journal_dao.dart';
import 'package:spiral_journal/database/core_dao.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/data_clearing_service.dart';

void main() {
  group('Database Clearing Tests', () {
    late DatabaseHelper databaseHelper;
    late JournalDao journalDao;
    late CoreDao coreDao;

    setUpAll(() {
      // Initialize test environment
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory for unit testing calls for SQFlite
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      databaseHelper = DatabaseHelper();
      journalDao = JournalDao();
      coreDao = CoreDao();
    });

    tearDown(() async {
      // Clean up after each test
      try {
        await databaseHelper.clearAllTables();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('DatabaseHelper clearing methods', () {
      test('should clear all tables successfully', () async {
        // Insert test data
        final entry = JournalEntry.create(
          content: 'Test entry to be cleared',
          moods: ['happy'],
        );
        await journalDao.insertJournalEntry(entry);
        await coreDao.initializeDefaultCores();

        // Verify data exists
        final entriesBefore = await journalDao.getAllJournalEntries();
        final coresBefore = await coreDao.getAllEmotionalCores();
        expect(entriesBefore.length, greaterThan(0));
        expect(coresBefore.length, greaterThan(0));

        // Clear all tables
        await databaseHelper.clearAllTables();

        // Verify data is cleared
        final entriesAfter = await journalDao.getAllJournalEntries();
        final coresAfter = await coreDao.getAllEmotionalCores();
        expect(entriesAfter.length, equals(0));
        expect(coresAfter.length, equals(0));
      });

      test('should perform safe database reset with detailed results', () async {
        // Insert test data
        final entry1 = JournalEntry.create(
          content: 'First test entry',
          moods: ['happy'],
        );
        final entry2 = JournalEntry.create(
          content: 'Second test entry',
          moods: ['grateful'],
        );
        
        await journalDao.insertJournalEntry(entry1);
        await journalDao.insertJournalEntry(entry2);
        await coreDao.initializeDefaultCores();

        // Perform safe database reset
        final result = await databaseHelper.safeDatabaseReset();

        // Verify result
        expect(result.success, isTrue);
        expect(result.hasErrors, isFalse);
        expect(result.totalRowsCleared, greaterThan(0));
        expect(result.clearedTables.containsKey('journal_entries'), isTrue);
        expect(result.clearedTables.containsKey('emotional_cores'), isTrue);
        expect(result.clearedTables['journal_entries'], equals(2));
        expect(result.clearedTables['emotional_cores'], equals(6));
        expect(result.sequencesReset, isTrue);
        expect(result.encryptionKeyCleared, isTrue);

        // Verify database is empty
        final isEmpty = await databaseHelper.isDatabaseEmpty();
        expect(isEmpty, isTrue);

        // Verify final counts
        expect(result.finalCounts['totalEntries'], equals(0));
        expect(result.finalCounts['totalCores'], equals(0));
      });

      test('should detect when database is empty', () async {
        // Initially database should be empty
        final isEmptyInitially = await databaseHelper.isDatabaseEmpty();
        expect(isEmptyInitially, isTrue);

        // Add some data
        final entry = JournalEntry.create(
          content: 'Test entry',
          moods: ['content'],
        );
        await journalDao.insertJournalEntry(entry);

        // Database should not be empty now
        final isEmptyWithData = await databaseHelper.isDatabaseEmpty();
        expect(isEmptyWithData, isFalse);

        // Clear data
        await databaseHelper.clearAllTables();

        // Database should be empty again
        final isEmptyAfterClear = await databaseHelper.isDatabaseEmpty();
        expect(isEmptyAfterClear, isTrue);
      });

      test('should handle clearing empty database gracefully', () async {
        // Ensure database is empty
        await databaseHelper.clearAllTables();
        
        // Clear again - should not throw error
        final result = await databaseHelper.safeDatabaseReset();
        
        expect(result.success, isTrue);
        expect(result.totalRowsCleared, equals(0));
        expect(result.hasErrors, isFalse);
      });

      test('should provide accurate database statistics', () async {
        // Add test data
        final entry1 = JournalEntry.create(
          content: 'First entry',
          moods: ['happy'],
        );
        final entry2 = JournalEntry.create(
          content: 'Second entry',
          moods: ['grateful'],
        );
        
        await journalDao.insertJournalEntry(entry1);
        await journalDao.insertJournalEntry(entry2);
        await coreDao.initializeDefaultCores();

        // Get statistics
        final stats = await databaseHelper.getDatabaseStats();
        
        expect(stats['totalEntries'], greaterThanOrEqualTo(2));
        expect(stats['totalCores'], greaterThanOrEqualTo(6));
        expect(stats['analyzedEntries'], isA<int>());
        expect(stats['unanalyzedEntries'], isA<int>());
      });
    });

    group('DataClearingService database clearing', () {
      test('should clear database with comprehensive result tracking', () async {
        // Insert test data
        final entry = JournalEntry.create(
          content: 'Test entry for service clearing',
          moods: ['excited'],
        );
        await journalDao.insertJournalEntry(entry);
        await coreDao.initializeDefaultCores();

        // Clear database using service
        final result = await DataClearingService.clearDatabase();

        // Verify result
        expect(result.success, isTrue);
        expect(result.hasErrors, isFalse);
        expect(result.totalRowsCleared, greaterThan(0));
        expect(result.summary, contains('successfully'));

        // Verify database is actually cleared
        final isEmpty = await databaseHelper.isDatabaseEmpty();
        expect(isEmpty, isTrue);
      });

      test('should handle database clearing errors gracefully', () async {
        // This test simulates error handling by attempting to clear
        // after closing the database connection
        await databaseHelper.close();

        // Attempt to clear - should handle error gracefully
        final result = await DataClearingService.clearDatabase();

        // Should not throw, but should report failure
        expect(result.success, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.errors.containsKey('general'), isTrue);
      });

      test('should clear all data types comprehensively', () async {
        // Insert various types of test data
        final entry = JournalEntry.create(
          content: 'Comprehensive test entry',
          moods: ['motivated'],
        );
        await journalDao.insertJournalEntry(entry);
        await coreDao.initializeDefaultCores();

        // Clear all data using service
        final result = await DataClearingService.clearAllData();

        // Verify comprehensive clearing
        expect(result.success, isTrue);
        expect(result.databaseResult.success, isTrue);
        expect(result.preferencesCleared, isTrue);
        expect(result.secureStorageCleared, isTrue);
        expect(result.cachesCleared, isTrue);
        expect(result.hasErrors, isFalse);

        // Verify database is empty
        final isEmpty = await databaseHelper.isDatabaseEmpty();
        expect(isEmpty, isTrue);
      });

      test('should provide detailed clearing summary', () async {
        // Add test data
        final entry1 = JournalEntry.create(
          content: 'First summary test entry',
          moods: ['happy'],
        );
        final entry2 = JournalEntry.create(
          content: 'Second summary test entry',
          moods: ['grateful'],
        );
        
        await journalDao.insertJournalEntry(entry1);
        await journalDao.insertJournalEntry(entry2);
        await coreDao.initializeDefaultCores();

        // Clear all data
        final result = await DataClearingService.clearAllData();

        // Verify summary contains useful information
        expect(result.summary, contains('rows removed'));
        expect(result.databaseResult.summary, contains('rows'));
        expect(result.databaseResult.totalRowsCleared, greaterThan(0));
      });
    });

    group('Error handling and edge cases', () {
      test('should handle partial clearing failures', () async {
        // Insert test data
        final entry = JournalEntry.create(
          content: 'Test entry for partial failure',
          moods: ['content'],
        );
        await journalDao.insertJournalEntry(entry);

        // Perform clearing
        final result = await databaseHelper.safeDatabaseReset();

        // Even if some operations fail, should continue with others
        expect(result, isNotNull);
        expect(result.clearedTables, isNotEmpty);
      });

      test('should reset auto-increment sequences', () async {
        // Insert and delete data to create gaps in sequences
        final entry1 = JournalEntry.create(
          content: 'First entry',
          moods: ['happy'],
        );
        final entry2 = JournalEntry.create(
          content: 'Second entry',
          moods: ['grateful'],
        );
        
        await journalDao.insertJournalEntry(entry1);
        await journalDao.insertJournalEntry(entry2);

        // Clear with sequence reset
        final result = await databaseHelper.safeDatabaseReset();

        expect(result.sequencesReset, isTrue);
        expect(result.success, isTrue);
      });

      test('should clear encryption keys', () async {
        // Perform database reset
        final result = await databaseHelper.safeDatabaseReset();

        // Verify encryption key was cleared
        expect(result.encryptionKeyCleared, isTrue);
      });

      test('should handle concurrent clearing operations', () async {
        // Insert test data
        final entry = JournalEntry.create(
          content: 'Concurrent test entry',
          moods: ['focused'],
        );
        await journalDao.insertJournalEntry(entry);

        // Attempt multiple concurrent clearing operations
        final futures = List.generate(3, (_) => DataClearingService.clearDatabase());
        final results = await Future.wait(futures);

        // At least one should succeed
        expect(results.any((r) => r.success), isTrue);
        
        // Database should be empty
        final isEmpty = await databaseHelper.isDatabaseEmpty();
        expect(isEmpty, isTrue);
      });
    });
  });
}