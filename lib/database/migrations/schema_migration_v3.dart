import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Database migration from version 2 to version 3
/// Converts snake_case field names to camelCase for consistency with Dart conventions
class SchemaMigrationV3 {
  
  /// Execute the migration from version 2 to version 3
  static Future<void> migrate(Database db) async {
    await db.transaction((txn) async {
      try {
        // Migrate journal_entries table
        await _migrateJournalEntriesTable(txn);
        
        // Migrate emotional_cores table
        await _migrateEmotionalCoresTable(txn);
        
        // Migrate monthly_summaries table
        await _migrateMonthlySummariesTable(txn);
        
        // Migrate core_combinations table
        await _migrateCoreCombinationsTable(txn);
        
        // Migrate emotional_patterns table
        await _migrateEmotionalPatternsTable(txn);
        
        debugPrint('Database migration to v3 completed successfully');
      } catch (e) {
        debugPrint('Database migration to v3 failed: $e');
        rethrow;
      }
    });
  }
  
  /// Migrate journal_entries table from snake_case to camelCase
  static Future<void> _migrateJournalEntriesTable(Transaction txn) async {
    // Create new table with camelCase field names
    await txn.execute('''
      CREATE TABLE journal_entries_new (
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
    
    // Copy data from old table to new table
    await txn.execute('''
      INSERT INTO journal_entries_new (
        id, userId, date, content, moods, dayOfWeek, 
        createdAt, updatedAt, isSynced, metadata
      )
      SELECT 
        id, user_id, date, content, moods, day_of_week,
        created_at, updated_at, is_synced, metadata
      FROM journal_entries
    ''');
    
    // Drop old table and rename new table
    await txn.execute('DROP TABLE journal_entries');
    await txn.execute('ALTER TABLE journal_entries_new RENAME TO journal_entries');
    
    // Recreate index with new field name
    await txn.execute('CREATE INDEX idx_journal_entries_date ON journal_entries(date)');
  }
  
  /// Migrate emotional_cores table from snake_case to camelCase
  static Future<void> _migrateEmotionalCoresTable(Transaction txn) async {
    // Create new table with camelCase field names
    await txn.execute('''
      CREATE TABLE emotional_cores_new (
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
    
    // Copy data from old table to new table
    await txn.execute('''
      INSERT INTO emotional_cores_new (
        id, name, description, percentage, trend, color,
        iconPath, insight, relatedCores, createdAt, updatedAt
      )
      SELECT 
        id, name, description, percentage, trend, color,
        icon_path, insight, related_cores, created_at, updated_at
      FROM emotional_cores
    ''');
    
    // Drop old table and rename new table
    await txn.execute('DROP TABLE emotional_cores');
    await txn.execute('ALTER TABLE emotional_cores_new RENAME TO emotional_cores');
  }
  
  /// Migrate monthly_summaries table from snake_case to camelCase
  static Future<void> _migrateMonthlySummariesTable(Transaction txn) async {
    // Create new table with camelCase field names
    await txn.execute('''
      CREATE TABLE monthly_summaries_new (
        id TEXT PRIMARY KEY,
        month TEXT NOT NULL,
        year INTEGER NOT NULL,
        dominantMoods TEXT NOT NULL,
        emotionalJourneyData TEXT NOT NULL,
        insight TEXT NOT NULL,
        entryCount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(month, year)
      )
    ''');
    
    // Copy data from old table to new table
    await txn.execute('''
      INSERT INTO monthly_summaries_new (
        id, month, year, dominantMoods, emotionalJourneyData,
        insight, entryCount, createdAt, updatedAt
      )
      SELECT 
        id, month, year, dominant_moods, emotional_journey_data,
        insight, entry_count, created_at, updated_at
      FROM monthly_summaries
    ''');
    
    // Drop old table and rename new table
    await txn.execute('DROP TABLE monthly_summaries');
    await txn.execute('ALTER TABLE monthly_summaries_new RENAME TO monthly_summaries');
    
    // Recreate index with new field names
    await txn.execute('CREATE INDEX idx_monthly_summaries_year_month ON monthly_summaries(year, month)');
  }
  
  /// Migrate core_combinations table from snake_case to camelCase
  static Future<void> _migrateCoreCombinationsTable(Transaction txn) async {
    // Create new table with camelCase field names
    await txn.execute('''
      CREATE TABLE core_combinations_new (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        coreIds TEXT NOT NULL,
        description TEXT NOT NULL,
        benefit TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    
    // Copy data from old table to new table
    await txn.execute('''
      INSERT INTO core_combinations_new (
        id, name, coreIds, description, benefit, createdAt
      )
      SELECT 
        id, name, core_ids, description, benefit, created_at
      FROM core_combinations
    ''');
    
    // Drop old table and rename new table
    await txn.execute('DROP TABLE core_combinations');
    await txn.execute('ALTER TABLE core_combinations_new RENAME TO core_combinations');
  }
  
  /// Migrate emotional_patterns table from snake_case to camelCase
  static Future<void> _migrateEmotionalPatternsTable(Transaction txn) async {
    // Create new table with camelCase field names
    await txn.execute('''
      CREATE TABLE emotional_patterns_new (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    
    // Copy data from old table to new table
    await txn.execute('''
      INSERT INTO emotional_patterns_new (
        id, category, title, description, type, createdAt
      )
      SELECT 
        id, category, title, description, type, created_at
      FROM emotional_patterns
    ''');
    
    // Drop old table and rename new table
    await txn.execute('DROP TABLE emotional_patterns');
    await txn.execute('ALTER TABLE emotional_patterns_new RENAME TO emotional_patterns');
  }
  
  /// Rollback migration from version 3 to version 2
  /// This method provides a way to revert the camelCase changes back to snake_case
  static Future<void> rollback(Database db) async {
    await db.transaction((txn) async {
      try {
        // Rollback journal_entries table
        await _rollbackJournalEntriesTable(txn);
        
        // Rollback emotional_cores table
        await _rollbackEmotionalCoresTable(txn);
        
        // Rollback monthly_summaries table
        await _rollbackMonthlySummariesTable(txn);
        
        // Rollback core_combinations table
        await _rollbackCoreCombinationsTable(txn);
        
        // Rollback emotional_patterns table
        await _rollbackEmotionalPatternsTable(txn);
        
        debugPrint('Database rollback from v3 to v2 completed successfully');
      } catch (e) {
        debugPrint('Database rollback from v3 to v2 failed: $e');
        rethrow;
      }
    });
  }
  
  /// Rollback journal_entries table from camelCase to snake_case
  static Future<void> _rollbackJournalEntriesTable(Transaction txn) async {
    // Create table with snake_case field names
    await txn.execute('''
      CREATE TABLE journal_entries_rollback (
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
    
    // Copy data from current table to rollback table
    await txn.execute('''
      INSERT INTO journal_entries_rollback (
        id, user_id, date, content, moods, day_of_week,
        created_at, updated_at, is_synced, metadata
      )
      SELECT 
        id, userId, date, content, moods, dayOfWeek,
        createdAt, updatedAt, isSynced, metadata
      FROM journal_entries
    ''');
    
    // Drop current table and rename rollback table
    await txn.execute('DROP TABLE journal_entries');
    await txn.execute('ALTER TABLE journal_entries_rollback RENAME TO journal_entries');
    
    // Recreate index
    await txn.execute('CREATE INDEX idx_journal_entries_date ON journal_entries(date)');
  }
  
  /// Rollback emotional_cores table from camelCase to snake_case
  static Future<void> _rollbackEmotionalCoresTable(Transaction txn) async {
    // Create table with snake_case field names
    await txn.execute('''
      CREATE TABLE emotional_cores_rollback (
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
    
    // Copy data from current table to rollback table
    await txn.execute('''
      INSERT INTO emotional_cores_rollback (
        id, name, description, percentage, trend, color,
        icon_path, insight, related_cores, created_at, updated_at
      )
      SELECT 
        id, name, description, percentage, trend, color,
        iconPath, insight, relatedCores, createdAt, updatedAt
      FROM emotional_cores
    ''');
    
    // Drop current table and rename rollback table
    await txn.execute('DROP TABLE emotional_cores');
    await txn.execute('ALTER TABLE emotional_cores_rollback RENAME TO emotional_cores');
  }
  
  /// Rollback monthly_summaries table from camelCase to snake_case
  static Future<void> _rollbackMonthlySummariesTable(Transaction txn) async {
    // Create table with snake_case field names
    await txn.execute('''
      CREATE TABLE monthly_summaries_rollback (
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
    
    // Copy data from current table to rollback table
    await txn.execute('''
      INSERT INTO monthly_summaries_rollback (
        id, month, year, dominant_moods, emotional_journey_data,
        insight, entry_count, created_at, updated_at
      )
      SELECT 
        id, month, year, dominantMoods, emotionalJourneyData,
        insight, entryCount, createdAt, updatedAt
      FROM monthly_summaries
    ''');
    
    // Drop current table and rename rollback table
    await txn.execute('DROP TABLE monthly_summaries');
    await txn.execute('ALTER TABLE monthly_summaries_rollback RENAME TO monthly_summaries');
    
    // Recreate index
    await txn.execute('CREATE INDEX idx_monthly_summaries_year_month ON monthly_summaries(year, month)');
  }
  
  /// Rollback core_combinations table from camelCase to snake_case
  static Future<void> _rollbackCoreCombinationsTable(Transaction txn) async {
    // Create table with snake_case field names
    await txn.execute('''
      CREATE TABLE core_combinations_rollback (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        core_ids TEXT NOT NULL,
        description TEXT NOT NULL,
        benefit TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Copy data from current table to rollback table
    await txn.execute('''
      INSERT INTO core_combinations_rollback (
        id, name, core_ids, description, benefit, created_at
      )
      SELECT 
        id, name, coreIds, description, benefit, createdAt
      FROM core_combinations
    ''');
    
    // Drop current table and rename rollback table
    await txn.execute('DROP TABLE core_combinations');
    await txn.execute('ALTER TABLE core_combinations_rollback RENAME TO core_combinations');
  }
  
  /// Rollback emotional_patterns table from camelCase to snake_case
  static Future<void> _rollbackEmotionalPatternsTable(Transaction txn) async {
    // Create table with snake_case field names
    await txn.execute('''
      CREATE TABLE emotional_patterns_rollback (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Copy data from current table to rollback table
    await txn.execute('''
      INSERT INTO emotional_patterns_rollback (
        id, category, title, description, type, created_at
      )
      SELECT 
        id, category, title, description, type, createdAt
      FROM emotional_patterns
    ''');
    
    // Drop current table and rename rollback table
    await txn.execute('DROP TABLE emotional_patterns');
    await txn.execute('ALTER TABLE emotional_patterns_rollback RENAME TO emotional_patterns');
  }
}