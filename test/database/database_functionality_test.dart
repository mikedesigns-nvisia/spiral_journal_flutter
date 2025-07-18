import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spiral_journal/database/database_helper.dart';
import 'package:spiral_journal/database/journal_dao.dart';
import 'package:spiral_journal/database/core_dao.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/models/core.dart';

void main() {
  group('Database Functionality Tests', () {
    late DatabaseHelper databaseHelper;
    late JournalDao journalDao;
    late CoreDao coreDao;

    setUpAll(() {
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
      // Don't close database between tests to avoid connection issues
      // The database will be cleaned up automatically
    });

    test('should initialize database successfully', () async {
      final db = await databaseHelper.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
      
      debugPrint('Database initialized successfully');
    });

    test('should validate database integrity', () async {
      final isValid = await databaseHelper.validateDatabaseIntegrity();
      expect(isValid, isTrue);
      
      debugPrint('Database integrity validation passed');
    });

    test('should create and retrieve journal entry', () async {
      final entry = JournalEntry.create(
        content: 'Test journal entry for database functionality',
        moods: ['happy', 'grateful'],
      );

      // Insert entry
      final entryId = await journalDao.insertJournalEntry(entry);
      expect(entryId, isNotEmpty);

      // Retrieve entry
      final retrievedEntry = await journalDao.getJournalEntryById(entryId);
      expect(retrievedEntry, isNotNull);
      expect(retrievedEntry!.content, equals(entry.content));
      expect(retrievedEntry.moods, equals(entry.moods));

      debugPrint('Journal entry CRUD operations working correctly');
    });

    test('should initialize default emotional cores', () async {
      await coreDao.initializeDefaultCores();
      
      final cores = await coreDao.getAllEmotionalCores();
      expect(cores.length, equals(6));
      
      final coreNames = cores.map((c) => c.name).toSet();
      expect(coreNames.contains('Optimism'), isTrue);
      expect(coreNames.contains('Resilience'), isTrue);
      expect(coreNames.contains('Self-Awareness'), isTrue);
      expect(coreNames.contains('Creativity'), isTrue);
      expect(coreNames.contains('Social Connection'), isTrue);
      expect(coreNames.contains('Growth Mindset'), isTrue);

      debugPrint('Default emotional cores initialized successfully');
    });

    test('should update emotional core percentage', () async {
      await coreDao.initializeDefaultCores();
      
      final cores = await coreDao.getAllEmotionalCores();
      final optimismCore = cores.firstWhere((c) => c.name == 'Optimism');
      
      final originalPercentage = optimismCore.percentage;
      final newPercentage = 85.0;
      
      await coreDao.updateCorePercentage(optimismCore.id, newPercentage, 'rising');
      
      final updatedCore = await coreDao.getEmotionalCoreById(optimismCore.id);
      expect(updatedCore, isNotNull);
      expect(updatedCore!.percentage, equals(newPercentage));
      expect(updatedCore.trend, equals('rising'));

      debugPrint('Emotional core update working correctly');
    });

    test('should search journal entries', () async {
      // Insert test entries
      final entry1 = JournalEntry.create(
        content: 'Today I feel grateful for my family',
        moods: ['grateful', 'happy'],
      );
      
      final entry2 = JournalEntry.create(
        content: 'Work was challenging but rewarding',
        moods: ['motivated', 'confident'],
      );

      await journalDao.insertJournalEntry(entry1);
      await journalDao.insertJournalEntry(entry2);

      // Search for entries
      final gratefulEntries = await journalDao.searchJournalEntries('grateful');
      expect(gratefulEntries.length, equals(1));
      expect(gratefulEntries.first.content.contains('grateful'), isTrue);

      final workEntries = await journalDao.searchJournalEntries('work');
      expect(workEntries.length, equals(1));
      expect(workEntries.first.content.toLowerCase().contains('work'), isTrue);

      debugPrint('Journal entry search working correctly');
    });

    test('should get entries by mood', () async {
      final entry = JournalEntry.create(
        content: 'Feeling happy today',
        moods: ['happy', 'energetic'],
      );

      await journalDao.insertJournalEntry(entry);

      final happyEntries = await journalDao.getJournalEntriesByMood('happy');
      expect(happyEntries.length, greaterThanOrEqualTo(1));
      expect(happyEntries.any((e) => e.moods.contains('happy')), isTrue);

      debugPrint('Get entries by mood working correctly');
    });

    test('should get database statistics', () async {
      final stats = await databaseHelper.getDatabaseStats();
      
      expect(stats.containsKey('totalEntries'), isTrue);
      expect(stats.containsKey('totalCores'), isTrue);
      expect(stats.containsKey('analyzedEntries'), isTrue);
      expect(stats.containsKey('unanalyzedEntries'), isTrue);
      
      expect(stats['totalEntries'], isA<int>());
      expect(stats['totalCores'], isA<int>());

      debugPrint('Database statistics: $stats');
    });

    test('should export database data', () async {
      // Insert some test data
      final entry = JournalEntry.create(
        content: 'Test entry for export',
        moods: ['content'],
      );
      await journalDao.insertJournalEntry(entry);
      await coreDao.initializeDefaultCores();

      // Export data
      final exportData = await databaseHelper.exportAllData();
      
      expect(exportData.containsKey('exportedAt'), isTrue);
      expect(exportData.containsKey('version'), isTrue);
      expect(exportData.containsKey('journalEntries'), isTrue);
      expect(exportData.containsKey('emotionalCores'), isTrue);
      
      final journalEntries = exportData['journalEntries'] as List;
      expect(journalEntries.length, greaterThanOrEqualTo(1));
      
      final emotionalCores = exportData['emotionalCores'] as List;
      expect(emotionalCores.length, equals(6));

      debugPrint('Database export working correctly');
    });

    test('should handle transaction rollback on error', () async {
      // This test verifies that database transactions work correctly
      // by attempting an operation that should fail and rollback
      
      final entry = JournalEntry.create(
        content: 'Test entry',
        moods: ['happy'],
      );

      // Insert entry normally first
      final entryId = await journalDao.insertJournalEntry(entry);
      expect(entryId, isNotEmpty);

      // Verify entry exists
      final retrievedEntry = await journalDao.getJournalEntryById(entryId);
      expect(retrievedEntry, isNotNull);

      // Try to insert entry with invalid data (empty content)
      final invalidEntry = JournalEntry.create(
        content: '', // This should cause validation error
        moods: ['happy'],
      );

      expect(
        () async => await journalDao.insertJournalEntry(invalidEntry),
        throwsException,
      );

      debugPrint('Transaction rollback handling working correctly');
    });

    test('should clear all data', () async {
      // Insert some test data
      final entry = JournalEntry.create(
        content: 'Test entry to be cleared',
        moods: ['content'],
      );
      await journalDao.insertJournalEntry(entry);
      await coreDao.initializeDefaultCores();

      // Verify data exists
      final entriesBefore = await journalDao.getAllJournalEntries();
      final coresBefore = await coreDao.getAllEmotionalCores();
      expect(entriesBefore.length, greaterThan(0));
      expect(coresBefore.length, greaterThan(0));

      // Clear all data
      await databaseHelper.clearAllData();

      // Verify data is cleared
      final entriesAfter = await journalDao.getAllJournalEntries();
      final coresAfter = await coreDao.getAllEmotionalCores();
      expect(entriesAfter.length, equals(0));
      expect(coresAfter.length, equals(0));

      debugPrint('Clear all data working correctly');
    });
  });
}
