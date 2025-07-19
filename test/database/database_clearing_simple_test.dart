import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spiral_journal/database/database_helper.dart';
import 'package:spiral_journal/database/journal_dao.dart';
import 'package:spiral_journal/database/core_dao.dart';
import 'package:spiral_journal/models/journal_entry.dart';

void main() {
  group('Database Clearing Simple Tests', () {
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

    test('should clear database tables successfully', () async {
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

    test('should perform safe database reset', () async {
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
      expect(result, isNotNull);
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
    });

    test('should detect when database is empty', () async {
      // Clear database first
      await databaseHelper.clearAllTables();
      
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

    test('should provide accurate database statistics', () async {
      // Clear database first
      await databaseHelper.clearAllTables();
      
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
      
      expect(stats['totalEntries'], equals(2));
      expect(stats['totalCores'], equals(6));
      expect(stats['analyzedEntries'], equals(0));
      expect(stats['unanalyzedEntries'], equals(2));
    });

    test('should handle clearing empty database gracefully', () async {
      // Ensure database is empty
      await databaseHelper.clearAllTables();
        
      // Clear again - should not throw error
      final result = await databaseHelper.safeDatabaseReset();
        
      expect(result, isNotNull);
      expect(result.totalRowsCleared, equals(0));
      expect(result.sequencesReset, isTrue);
      expect(result.encryptionKeyCleared, isTrue);
    });
  });
}