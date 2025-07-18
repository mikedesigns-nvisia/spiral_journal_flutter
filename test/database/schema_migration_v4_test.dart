import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spiral_journal/database/migrations/schema_migration_v4.dart';
import 'package:spiral_journal/models/journal_entry.dart';

void main() {
  group('Schema Migration V4 Tests', () {
    late Database database;

    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory for unit testing calls for SQFlite
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create a test database in memory
      database = await openDatabase(
        inMemoryDatabasePath,
        version: 3,
        onCreate: (db, version) async {
          // Create version 3 schema (without AI analysis fields)
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
              metadata TEXT NOT NULL DEFAULT '{}'
            )
          ''');
        },
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('should migrate journal_entries table to v4 successfully', () async {
      // Insert test data in v3 format
      await database.insert('journal_entries', {
        'id': 'test-id-1',
        'userId': 'test-user',
        'date': DateTime.now().toIso8601String(),
        'content': 'Test journal entry content',
        'moods': 'happy,grateful',
        'dayOfWeek': 'Monday',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isSynced': 1,
        'metadata': '{}',
      });

      // Run migration to v4
      await SchemaMigrationV4.migrate(database);

      // Verify new columns exist
      final result = await database.rawQuery('PRAGMA table_info(journal_entries)');
      final columnNames = result.map((row) => row['name'] as String).toSet();

      expect(columnNames.contains('aiAnalysis'), isTrue);
      expect(columnNames.contains('isAnalyzed'), isTrue);
      expect(columnNames.contains('draftContent'), isTrue);
      expect(columnNames.contains('aiDetectedMoods'), isTrue);
      expect(columnNames.contains('emotionalIntensity'), isTrue);
      expect(columnNames.contains('keyThemes'), isTrue);
      expect(columnNames.contains('personalizedInsight'), isTrue);

      // Verify existing data is preserved
      final entries = await database.query('journal_entries');
      expect(entries.length, equals(1));
      expect(entries.first['id'], equals('test-id-1'));
      expect(entries.first['content'], equals('Test journal entry content'));

      // Verify new columns have default values
      expect(entries.first['isAnalyzed'], equals(0));
      expect(entries.first['aiDetectedMoods'], equals('[]'));
      expect(entries.first['keyThemes'], equals('[]'));

      debugPrint('Database migration to v4 completed successfully');
    });

    test('should create proper indexes for AI analysis fields', () async {
      // Run migration to v4
      await SchemaMigrationV4.migrate(database);

      // Check if indexes were created
      final indexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='journal_entries'"
      );
      
      final indexNames = indexes.map((row) => row['name'] as String).toSet();
      expect(indexNames.contains('idx_journal_entries_analyzed'), isTrue);
      expect(indexNames.contains('idx_journal_entries_intensity'), isTrue);

      debugPrint('AI analysis indexes created successfully');
    });

    test('should handle migration with existing AI analysis data', () async {
      // Run migration to v4
      await SchemaMigrationV4.migrate(database);

      // Insert entry with AI analysis data
      final analysisData = EmotionalAnalysis(
        primaryEmotions: ['joy', 'gratitude'],
        emotionalIntensity: 0.8,
        keyThemes: ['personal growth', 'reflection'],
        personalizedInsight: 'You seem to be in a positive mindset today.',
        coreImpacts: {'optimism': 0.7, 'self-awareness': 0.6},
        analyzedAt: DateTime.now(),
      );

      await database.insert('journal_entries', {
        'id': 'test-ai-entry',
        'userId': 'test-user',
        'date': DateTime.now().toIso8601String(),
        'content': 'Today I feel grateful for all the opportunities in my life.',
        'moods': 'grateful,optimistic',
        'dayOfWeek': 'Tuesday',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isSynced': 1,
        'metadata': '{}',
        'aiAnalysis': analysisData.toJson().toString(),
        'isAnalyzed': 1,
        'aiDetectedMoods': '["joy", "gratitude"]',
        'emotionalIntensity': 0.8,
        'keyThemes': '["personal growth", "reflection"]',
        'personalizedInsight': 'You seem to be in a positive mindset today.',
      });

      // Verify data was inserted correctly
      final entries = await database.query(
        'journal_entries',
        where: 'id = ?',
        whereArgs: ['test-ai-entry'],
      );

      expect(entries.length, equals(1));
      expect(entries.first['isAnalyzed'], equals(1));
      expect(entries.first['emotionalIntensity'], equals(0.8));
      expect(entries.first['personalizedInsight'], equals('You seem to be in a positive mindset today.'));

      debugPrint('AI analysis data handling verified successfully');
    });
  });
}
