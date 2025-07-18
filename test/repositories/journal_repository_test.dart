import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spiral_journal/database/journal_dao.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/repositories/journal_repository.dart';
import 'package:spiral_journal/repositories/journal_repository_impl.dart';
import 'package:spiral_journal/utils/database_exceptions.dart';

void main() {
  group('Journal Repository Tests', () {
    late JournalRepository repository;
    late Database database;

    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory for unit testing calls for SQFlite
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create a fresh in-memory database for each test
      database = await openDatabase(
        inMemoryDatabasePath,
        version: 4,
        onCreate: (db, version) async {
          // Create version 4 schema with AI analysis fields
          await db.execute('''
            CREATE TABLE journal_entries (
              id TEXT PRIMARY KEY,
              userId TEXT NOT NULL DEFAULT 'local_user',
              date TEXT NOT NULL,
              content TEXT NOT NULL,
              moods TEXT NOT NULL,
              dayOfWeek TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              isSynced INTEGER NOT NULL DEFAULT 1,
              metadata TEXT NOT NULL DEFAULT '{}',
              aiAnalysis TEXT,
              isAnalyzed INTEGER NOT NULL DEFAULT 0,
              draftContent TEXT,
              aiDetectedMoods TEXT NOT NULL DEFAULT '[]',
              emotionalIntensity REAL,
              keyThemes TEXT NOT NULL DEFAULT '[]',
              personalizedInsight TEXT
            )
          ''');

          // Create other required tables
          await db.execute('''
            CREATE TABLE emotional_cores (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              percentage REAL NOT NULL,
              trend TEXT NOT NULL,
              color TEXT NOT NULL,
              iconPath TEXT NOT NULL,
              insight TEXT NOT NULL,
              relatedCores TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');

          // Create indexes
          await db.execute('CREATE INDEX idx_journal_entries_date ON journal_entries(date)');
          await db.execute('CREATE INDEX idx_journal_entries_analyzed ON journal_entries(isAnalyzed)');
          await db.execute('CREATE INDEX idx_journal_entries_intensity ON journal_entries(emotionalIntensity)');
        },
      );

      // Create repository with a DAO that uses our test database
      final journalDao = JournalDao();
      repository = JournalRepositoryImpl(journalDao: journalDao);
    });

    tearDown(() async {
      await database.close();
    });

    group('Basic CRUD Operations', () {
      test('should create and retrieve journal entry', () async {
        final entry = JournalEntry.create(
          content: 'Test journal entry content',
          moods: ['happy', 'grateful'],
        );

        final entryId = await repository.createEntry(entry);
        expect(entryId, isNotEmpty);

        final retrievedEntry = await repository.getEntryById(entryId);
        expect(retrievedEntry, isNotNull);
        expect(retrievedEntry!.content, equals('Test journal entry content'));
        expect(retrievedEntry.moods, containsAll(['happy', 'grateful']));
      });

      test('should update journal entry', () async {
        final entry = JournalEntry.create(
          content: 'Original content',
          moods: ['content'],
        );

        final entryId = await repository.createEntry(entry);
        final originalEntry = await repository.getEntryById(entryId);

        final updatedEntry = originalEntry!.copyWith(
          content: 'Updated content',
          moods: ['happy', 'excited'],
        );

        await repository.updateEntry(updatedEntry);

        final retrievedEntry = await repository.getEntryById(entryId);
        expect(retrievedEntry!.content, equals('Updated content'));
        expect(retrievedEntry.moods, containsAll(['happy', 'excited']));
      });

      test('should delete journal entry', () async {
        final entry = JournalEntry.create(
          content: 'Entry to be deleted',
          moods: ['sad'],
        );

        final entryId = await repository.createEntry(entry);
        expect(await repository.getEntryById(entryId), isNotNull);

        await repository.deleteEntry(entryId);
        expect(await repository.getEntryById(entryId), isNull);
      });

      test('should handle batch operations', () async {
        final entries = [
          JournalEntry.create(content: 'Entry 1', moods: ['happy']),
          JournalEntry.create(content: 'Entry 2', moods: ['sad']),
          JournalEntry.create(content: 'Entry 3', moods: ['excited']),
        ];

        final entryIds = await repository.createMultipleEntries(entries);
        expect(entryIds.length, equals(3));

        // Verify all entries were created
        for (final entryId in entryIds) {
          final entry = await repository.getEntryById(entryId);
          expect(entry, isNotNull);
        }

        // Delete all entries
        await repository.deleteMultipleEntries(entryIds);

        // Verify all entries were deleted
        for (final entryId in entryIds) {
          final entry = await repository.getEntryById(entryId);
          expect(entry, isNull);
        }
      });
    });

    group('Search and Filter Operations', () {
      late List<JournalEntry> testEntries;

      setUp(() async {
        // Create test entries with various properties
        testEntries = [
          JournalEntry.create(
            content: 'I feel grateful for this beautiful day',
            moods: ['grateful', 'happy'],
          ).copyWith(
            aiAnalysis: EmotionalAnalysis(
              primaryEmotions: ['gratitude', 'joy'],
              emotionalIntensity: 0.8,
              keyThemes: ['gratitude', 'nature'],
              personalizedInsight: 'You seem to appreciate the simple things in life.',
              coreImpacts: {'optimism': 0.7},
              analyzedAt: DateTime.now(),
            ),
            isAnalyzed: true,
            aiDetectedMoods: ['gratitude', 'joy'],
            emotionalIntensity: 0.8,
            keyThemes: ['gratitude', 'nature'],
            personalizedInsight: 'You seem to appreciate the simple things in life.',
          ),
          JournalEntry.create(
            content: 'Today was challenging but I learned a lot',
            moods: ['reflective', 'motivated'],
          ).copyWith(
            aiAnalysis: EmotionalAnalysis(
              primaryEmotions: ['reflection', 'determination'],
              emotionalIntensity: 0.6,
              keyThemes: ['learning', 'growth'],
              personalizedInsight: 'Challenges are opportunities for growth.',
              coreImpacts: {'resilience': 0.8},
              analyzedAt: DateTime.now(),
            ),
            isAnalyzed: true,
            aiDetectedMoods: ['reflection', 'determination'],
            emotionalIntensity: 0.6,
            keyThemes: ['learning', 'growth'],
            personalizedInsight: 'Challenges are opportunities for growth.',
          ),
          JournalEntry.create(
            content: 'Feeling overwhelmed with work tasks',
            moods: ['stressed', 'tired'],
          ).copyWith(
            isAnalyzed: false,
          ),
        ];

        // Create all test entries
        for (final entry in testEntries) {
          await repository.createEntry(entry);
        }
      });

      test('should search entries by text content', () async {
        final results = await repository.searchEntries('grateful');
        expect(results.length, equals(1));
        expect(results.first.content, contains('grateful'));
      });

      test('should perform full-text search across content and insights', () async {
        final results = await repository.searchEntriesFullText('growth');
        expect(results.length, equals(1));
        expect(results.first.keyThemes, contains('growth'));
      });

      test('should filter entries by mood', () async {
        final results = await repository.getEntriesByMood('happy');
        expect(results.length, equals(1));
        expect(results.first.moods, contains('happy'));
      });

      test('should filter entries by AI detected mood', () async {
        final results = await repository.getEntriesByAIMood('gratitude');
        expect(results.length, equals(1));
        expect(results.first.aiDetectedMoods, contains('gratitude'));
      });

      test('should filter entries by theme', () async {
        final results = await repository.getEntriesByTheme('learning');
        expect(results.length, equals(1));
        expect(results.first.keyThemes, contains('learning'));
      });

      test('should filter entries by emotional intensity range', () async {
        final results = await repository.getEntriesByIntensityRange(0.7, 1.0);
        expect(results.length, equals(1));
        expect(results.first.emotionalIntensity, equals(0.8));
      });

      test('should filter analyzed vs unanalyzed entries', () async {
        final analyzedResults = await repository.getAnalyzedEntries(analyzed: true);
        expect(analyzedResults.length, equals(2));

        final unanalyzedResults = await repository.getAnalyzedEntries(analyzed: false);
        expect(unanalyzedResults.length, equals(1));
        expect(unanalyzedResults.first.isAnalyzed, isFalse);
      });

      test('should perform advanced search with multiple filters', () async {
        final results = await repository.searchEntriesAdvanced(
          textQuery: 'day',
          moods: ['grateful'],
          minIntensity: 0.5,
          isAnalyzed: true,
        );

        expect(results.length, equals(1));
        expect(results.first.content, contains('day'));
        expect(results.first.moods, contains('grateful'));
        expect(results.first.emotionalIntensity! >= 0.5, isTrue);
        expect(results.first.isAnalyzed, isTrue);
      });
    });

    group('Pagination', () {
      setUp(() async {
        // Create multiple entries for pagination testing
        for (int i = 1; i <= 25; i++) {
          final entry = JournalEntry.create(
            content: 'Entry number $i',
            moods: ['content'],
          );
          await repository.createEntry(entry);
        }
      });

      test('should support pagination for getAllEntries', () async {
        final firstPage = await repository.getAllEntries(limit: 10, offset: 0);
        expect(firstPage.length, equals(10));

        final secondPage = await repository.getAllEntries(limit: 10, offset: 10);
        expect(secondPage.length, equals(10));

        final thirdPage = await repository.getAllEntries(limit: 10, offset: 20);
        expect(thirdPage.length, equals(5)); // Remaining entries

        // Verify no overlap between pages
        final firstPageIds = firstPage.map((e) => e.id).toSet();
        final secondPageIds = secondPage.map((e) => e.id).toSet();
        expect(firstPageIds.intersection(secondPageIds).isEmpty, isTrue);
      });

      test('should support pagination with search', () async {
        final results = await repository.searchEntries('Entry', limit: 5, offset: 0);
        expect(results.length, equals(5));

        final nextResults = await repository.searchEntries('Entry', limit: 5, offset: 5);
        expect(nextResults.length, equals(5));

        // Verify no overlap
        final firstIds = results.map((e) => e.id).toSet();
        final nextIds = nextResults.map((e) => e.id).toSet();
        expect(firstIds.intersection(nextIds).isEmpty, isTrue);
      });

      test('should handle pagination edge cases', () async {
        // Request beyond available entries
        final results = await repository.getAllEntries(limit: 10, offset: 100);
        expect(results.isEmpty, isTrue);

        // Request with large limit
        final allResults = await repository.getAllEntries(limit: 1000, offset: 0);
        expect(allResults.length, equals(25));
      });
    });

    group('Statistics and Analytics', () {
      setUp(() async {
        // Create entries with different moods and dates
        final entries = [
          JournalEntry.create(content: 'Happy day', moods: ['happy']),
          JournalEntry.create(content: 'Another happy day', moods: ['happy', 'grateful']),
          JournalEntry.create(content: 'Sad moment', moods: ['sad']),
          JournalEntry.create(content: 'Reflective time', moods: ['reflective']),
        ];

        for (final entry in entries) {
          await repository.createEntry(entry);
        }
      });

      test('should get entry count', () async {
        final count = await repository.getEntryCount();
        expect(count, equals(4));
      });

      test('should get mood frequency', () async {
        final moodFreq = await repository.getMoodFrequency();
        expect(moodFreq['happy'], equals(2));
        expect(moodFreq['grateful'], equals(1));
        expect(moodFreq['sad'], equals(1));
        expect(moodFreq['reflective'], equals(1));
      });

      test('should export all entries', () async {
        final exportData = await repository.exportAllEntries();
        expect(exportData['totalEntries'], equals(4));
        expect(exportData['entries'], isA<List>());
        expect(exportData['exportedAt'], isNotNull);
        expect(exportData['version'], equals('1.0'));
      });
    });

    group('Error Handling', () {
      test('should throw validation error for empty entry ID', () async {
        expect(
          () => repository.getEntryById(''),
          throwsA(isA<DatabaseValidationException>()),
        );
      });

      test('should throw validation error for invalid date range', () async {
        final endDate = DateTime.now();
        final startDate = endDate.add(Duration(days: 1));

        expect(
          () => repository.getEntriesByDateRange(startDate, endDate),
          throwsA(isA<DatabaseValidationException>()),
        );
      });

      test('should throw validation error for invalid intensity range', () async {
        expect(
          () => repository.getEntriesByIntensityRange(-0.1, 0.5),
          throwsA(isA<DatabaseValidationException>()),
        );

        expect(
          () => repository.getEntriesByIntensityRange(0.8, 0.5),
          throwsA(isA<DatabaseValidationException>()),
        );
      });

      test('should handle empty search queries gracefully', () async {
        final results = await repository.searchEntries('');
        expect(results, isA<List<JournalEntry>>());
      });
    });

    group('JournalSearchFilters', () {
      test('should create filters and detect when filters are applied', () async {
        final emptyFilters = JournalSearchFilters();
        expect(emptyFilters.hasFilters, isFalse);

        final filtersWithText = JournalSearchFilters(textQuery: 'test');
        expect(filtersWithText.hasFilters, isTrue);

        final filtersWithMoods = JournalSearchFilters(moods: ['happy']);
        expect(filtersWithMoods.hasFilters, isTrue);

        final filtersWithDate = JournalSearchFilters(startDate: DateTime.now());
        expect(filtersWithDate.hasFilters, isTrue);
      });

      test('should copy filters with updated values', () async {
        final originalFilters = JournalSearchFilters(
          textQuery: 'original',
          moods: ['happy'],
        );

        final updatedFilters = originalFilters.copyWith(
          textQuery: 'updated',
          themes: ['growth'],
        );

        expect(updatedFilters.textQuery, equals('updated'));
        expect(updatedFilters.moods, equals(['happy'])); // Preserved
        expect(updatedFilters.themes, equals(['growth'])); // Added
      });
    });

    group('JournalPagination', () {
      test('should calculate pagination properties correctly', () async {
        final pagination = JournalPagination(
          limit: 10,
          offset: 20,
          totalCount: 100,
        );

        expect(pagination.currentPage, equals(3)); // (20 / 10) + 1
        expect(pagination.totalPages, equals(10)); // 100 / 10
        expect(pagination.hasNextPage, isTrue);
        expect(pagination.hasPreviousPage, isTrue);
      });

      test('should generate next and previous page pagination', () async {
        final pagination = JournalPagination(
          limit: 10,
          offset: 20,
          totalCount: 100,
        );

        final nextPage = pagination.nextPage;
        expect(nextPage.offset, equals(30));
        expect(nextPage.limit, equals(10));

        final previousPage = pagination.previousPage;
        expect(previousPage.offset, equals(10));
        expect(previousPage.limit, equals(10));
      });

      test('should handle edge cases for pagination', () async {
        final firstPage = JournalPagination(
          limit: 10,
          offset: 0,
          totalCount: 5,
        );

        expect(firstPage.currentPage, equals(1));
        expect(firstPage.hasNextPage, isFalse);
        expect(firstPage.hasPreviousPage, isFalse);

        final previousFromFirst = firstPage.previousPage;
        expect(previousFromFirst.offset, equals(0)); // Clamped to 0
      });
    });
  });
}