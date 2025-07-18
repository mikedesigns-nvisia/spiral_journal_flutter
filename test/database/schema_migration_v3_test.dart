import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spiral_journal/database/migrations/schema_migration_v3.dart';

void main() {
  late Database testDb;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create in-memory database for testing
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onCreate: (db, version) async {
        // Create v2 schema with snake_case fields
        await _createV2Schema(db);
        // Insert sample data
        await _insertSampleData(db);
      },
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Schema Migration V3 Tests', () {
    test('should migrate journal_entries table successfully', () async {
      // Verify initial data exists with snake_case fields
      final initialData = await testDb.query('journal_entries');
      expect(initialData.length, 2);
      expect(initialData.first.containsKey('user_id'), true);
      expect(initialData.first.containsKey('day_of_week'), true);
      expect(initialData.first.containsKey('created_at'), true);

      // Execute migration
      await SchemaMigrationV3.migrate(testDb);

      // Verify data exists with camelCase fields
      final migratedData = await testDb.query('journal_entries');
      expect(migratedData.length, 2);
      expect(migratedData.first.containsKey('userId'), true);
      expect(migratedData.first.containsKey('dayOfWeek'), true);
      expect(migratedData.first.containsKey('createdAt'), true);
      
      // Verify old fields don't exist
      expect(migratedData.first.containsKey('user_id'), false);
      expect(migratedData.first.containsKey('day_of_week'), false);
      expect(migratedData.first.containsKey('created_at'), false);

      // Verify data integrity
      expect(migratedData.first['userId'], 'test_user_1');
      expect(migratedData.first['dayOfWeek'], 'Monday');
      expect(migratedData.first['content'], 'Test journal entry 1');
    });

    test('should migrate emotional_cores table successfully', () async {
      // Verify initial data exists with snake_case fields
      final initialData = await testDb.query('emotional_cores');
      expect(initialData.length, 2);
      expect(initialData.first.containsKey('icon_path'), true);
      expect(initialData.first.containsKey('related_cores'), true);
      expect(initialData.first.containsKey('created_at'), true);

      // Execute migration
      await SchemaMigrationV3.migrate(testDb);

      // Verify data exists with camelCase fields
      final migratedData = await testDb.query('emotional_cores');
      expect(migratedData.length, 2);
      expect(migratedData.first.containsKey('iconPath'), true);
      expect(migratedData.first.containsKey('relatedCores'), true);
      expect(migratedData.first.containsKey('createdAt'), true);
      
      // Verify old fields don't exist
      expect(migratedData.first.containsKey('icon_path'), false);
      expect(migratedData.first.containsKey('related_cores'), false);
      expect(migratedData.first.containsKey('created_at'), false);

      // Verify data integrity
      expect(migratedData.first['iconPath'], 'assets/icons/optimism.png');
      expect(migratedData.first['relatedCores'], 'Resilience,Growth Mindset');
      expect(migratedData.first['name'], 'Optimism');
    });

    test('should migrate monthly_summaries table successfully', () async {
      // Verify initial data exists with snake_case fields
      final initialData = await testDb.query('monthly_summaries');
      expect(initialData.length, 1);
      expect(initialData.first.containsKey('dominant_moods'), true);
      expect(initialData.first.containsKey('emotional_journey_data'), true);
      expect(initialData.first.containsKey('entry_count'), true);

      // Execute migration
      await SchemaMigrationV3.migrate(testDb);

      // Verify data exists with camelCase fields
      final migratedData = await testDb.query('monthly_summaries');
      expect(migratedData.length, 1);
      expect(migratedData.first.containsKey('dominantMoods'), true);
      expect(migratedData.first.containsKey('emotionalJourneyData'), true);
      expect(migratedData.first.containsKey('entryCount'), true);
      
      // Verify old fields don't exist
      expect(migratedData.first.containsKey('dominant_moods'), false);
      expect(migratedData.first.containsKey('emotional_journey_data'), false);
      expect(migratedData.first.containsKey('entry_count'), false);

      // Verify data integrity
      expect(migratedData.first['dominantMoods'], 'happy,content');
      expect(migratedData.first['entryCount'], 5);
    });

    test('should migrate core_combinations table successfully', () async {
      // Verify initial data exists with snake_case fields
      final initialData = await testDb.query('core_combinations');
      expect(initialData.length, 1);
      expect(initialData.first.containsKey('core_ids'), true);
      expect(initialData.first.containsKey('created_at'), true);

      // Execute migration
      await SchemaMigrationV3.migrate(testDb);

      // Verify data exists with camelCase fields
      final migratedData = await testDb.query('core_combinations');
      expect(migratedData.length, 1);
      expect(migratedData.first.containsKey('coreIds'), true);
      expect(migratedData.first.containsKey('createdAt'), true);
      
      // Verify old fields don't exist
      expect(migratedData.first.containsKey('core_ids'), false);
      expect(migratedData.first.containsKey('created_at'), false);

      // Verify data integrity
      expect(migratedData.first['coreIds'], 'core1,core2');
      expect(migratedData.first['name'], 'Test Combination');
    });

    test('should migrate emotional_patterns table successfully', () async {
      // Verify initial data exists with snake_case fields
      final initialData = await testDb.query('emotional_patterns');
      expect(initialData.length, 1);
      expect(initialData.first.containsKey('created_at'), true);

      // Execute migration
      await SchemaMigrationV3.migrate(testDb);

      // Verify data exists with camelCase fields
      final migratedData = await testDb.query('emotional_patterns');
      expect(migratedData.length, 1);
      expect(migratedData.first.containsKey('createdAt'), true);
      
      // Verify old fields don't exist
      expect(migratedData.first.containsKey('created_at'), false);

      // Verify data integrity
      expect(migratedData.first['category'], 'growth');
      expect(migratedData.first['title'], 'Test Pattern');
    });

    test('should rollback migration successfully', () async {
      // Execute migration first
      await SchemaMigrationV3.migrate(testDb);

      // Verify camelCase fields exist
      final migratedData = await testDb.query('journal_entries');
      expect(migratedData.first.containsKey('userId'), true);
      expect(migratedData.first.containsKey('dayOfWeek'), true);

      // Execute rollback
      await SchemaMigrationV3.rollback(testDb);

      // Verify snake_case fields are restored
      final rolledBackData = await testDb.query('journal_entries');
      expect(rolledBackData.first.containsKey('user_id'), true);
      expect(rolledBackData.first.containsKey('day_of_week'), true);
      expect(rolledBackData.first.containsKey('userId'), false);
      expect(rolledBackData.first.containsKey('dayOfWeek'), false);

      // Verify data integrity after rollback
      expect(rolledBackData.first['user_id'], 'test_user_1');
      expect(rolledBackData.first['day_of_week'], 'Monday');
      expect(rolledBackData.length, 2);
    });

    test('should handle migration errors gracefully', () async {
      // Close the database to simulate an error condition
      await testDb.close();

      // Attempt migration on closed database should throw
      expect(
        () async => await SchemaMigrationV3.migrate(testDb),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('should preserve all data during migration', () async {
      // Get initial row counts
      final initialJournalCount = (await testDb.query('journal_entries')).length;
      final initialCoreCount = (await testDb.query('emotional_cores')).length;
      final initialSummaryCount = (await testDb.query('monthly_summaries')).length;
      final initialCombinationCount = (await testDb.query('core_combinations')).length;
      final initialPatternCount = (await testDb.query('emotional_patterns')).length;

      // Execute migration
      await SchemaMigrationV3.migrate(testDb);

      // Verify row counts are preserved
      expect((await testDb.query('journal_entries')).length, initialJournalCount);
      expect((await testDb.query('emotional_cores')).length, initialCoreCount);
      expect((await testDb.query('monthly_summaries')).length, initialSummaryCount);
      expect((await testDb.query('core_combinations')).length, initialCombinationCount);
      expect((await testDb.query('emotional_patterns')).length, initialPatternCount);
    });
  });
}

/// Create version 2 database schema with snake_case field names
Future<void> _createV2Schema(Database db) async {
  // Journal entries table
  await db.execute('''
    CREATE TABLE journal_entries (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL DEFAULT 'local_user',
      date TEXT NOT NULL,
      content TEXT NOT NULL,
      moods TEXT NOT NULL,
      day_of_week TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 1,
      metadata TEXT NOT NULL DEFAULT '{}'
    )
  ''');

  // Emotional cores table
  await db.execute('''
    CREATE TABLE emotional_cores (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      percentage REAL NOT NULL,
      trend TEXT NOT NULL,
      color TEXT NOT NULL,
      icon_path TEXT NOT NULL,
      insight TEXT NOT NULL,
      related_cores TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  // Monthly summaries table
  await db.execute('''
    CREATE TABLE monthly_summaries (
      id TEXT PRIMARY KEY,
      month TEXT NOT NULL,
      year INTEGER NOT NULL,
      dominant_moods TEXT NOT NULL,
      emotional_journey_data TEXT NOT NULL,
      insight TEXT NOT NULL,
      entry_count INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE(month, year)
    )
  ''');

  // Core combinations table
  await db.execute('''
    CREATE TABLE core_combinations (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      core_ids TEXT NOT NULL,
      description TEXT NOT NULL,
      benefit TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  // Emotional patterns table
  await db.execute('''
    CREATE TABLE emotional_patterns (
      id TEXT PRIMARY KEY,
      category TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      type TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  // Create indexes
  await db.execute('CREATE INDEX idx_journal_entries_date ON journal_entries(date)');
  await db.execute('CREATE INDEX idx_monthly_summaries_year_month ON monthly_summaries(year, month)');
}

/// Insert sample data for testing migration
Future<void> _insertSampleData(Database db) async {
  final now = DateTime.now().toIso8601String();

  // Insert sample journal entries
  await db.insert('journal_entries', {
    'id': 'entry1',
    'user_id': 'test_user_1',
    'date': now,
    'content': 'Test journal entry 1',
    'moods': 'happy,content',
    'day_of_week': 'Monday',
    'created_at': now,
    'updated_at': now,
    'is_synced': 1,
    'metadata': '{}',
  });

  await db.insert('journal_entries', {
    'id': 'entry2',
    'user_id': 'test_user_2',
    'date': now,
    'content': 'Test journal entry 2',
    'moods': 'excited,motivated',
    'day_of_week': 'Tuesday',
    'created_at': now,
    'updated_at': now,
    'is_synced': 0,
    'metadata': '{}',
  });

  // Insert sample emotional cores
  await db.insert('emotional_cores', {
    'id': 'core1',
    'name': 'Optimism',
    'description': 'Test optimism core',
    'percentage': 75.0,
    'trend': 'rising',
    'color': 'AFCACD',
    'icon_path': 'assets/icons/optimism.png',
    'insight': 'Test insight',
    'related_cores': 'Resilience,Growth Mindset',
    'created_at': now,
    'updated_at': now,
  });

  await db.insert('emotional_cores', {
    'id': 'core2',
    'name': 'Resilience',
    'description': 'Test resilience core',
    'percentage': 68.0,
    'trend': 'stable',
    'color': 'EBA751',
    'icon_path': 'assets/icons/resilience.png',
    'insight': 'Test insight 2',
    'related_cores': 'Optimism,Self-Awareness',
    'created_at': now,
    'updated_at': now,
  });

  // Insert sample monthly summary
  await db.insert('monthly_summaries', {
    'id': 'summary1',
    'month': 'January',
    'year': 2024,
    'dominant_moods': 'happy,content',
    'emotional_journey_data': '{"data": "test"}',
    'insight': 'Test monthly insight',
    'entry_count': 5,
    'created_at': now,
    'updated_at': now,
  });

  // Insert sample core combination
  await db.insert('core_combinations', {
    'id': 'combination1',
    'name': 'Test Combination',
    'core_ids': 'core1,core2',
    'description': 'Test combination description',
    'benefit': 'Test benefit',
    'created_at': now,
  });

  // Insert sample emotional pattern
  await db.insert('emotional_patterns', {
    'id': 'pattern1',
    'category': 'growth',
    'title': 'Test Pattern',
    'description': 'Test pattern description',
    'type': 'growth',
    'created_at': now,
  });
}