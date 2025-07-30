import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/database_exceptions.dart';

/// Database migration system with version tracking and rollback capability.
/// 
/// This class manages database schema changes through versioned migrations,
/// providing transaction safety, rollback capability, and comprehensive error handling.
/// 
/// ## Key Features
/// - **Version Tracking**: Uses SharedPreferences to track current schema version
/// - **Transaction Safety**: All migrations run within database transactions
/// - **Rollback Capability**: Automatic rollback on migration failure
/// - **Migration Scripts**: Static methods for each migration with clear naming
/// - **Error Recovery**: Comprehensive error handling with detailed context
/// 
/// ## Usage Example
/// ```dart
/// final migrator = DatabaseMigrator();
/// await migrator.runPendingMigrations(database);
/// ```
/// 
/// ## Migration Architecture
/// - Each migration is a static method named `migration_vX_to_vY`
/// - Migrations include both forward and rollback SQL
/// - Version numbers are stored in SharedPreferences
/// - Failed migrations trigger automatic rollback
class DatabaseMigrator {
  static const String _versionKey = 'spiral_journal_db_version';
  static const int _currentVersion = 4;
  static const int _baseVersion = 1;

  /// Get the current database version from SharedPreferences
  Future<int> getCurrentVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_versionKey) ?? _baseVersion;
    } catch (e) {
      throw DatabaseMigrationException('Failed to get current database version: $e');
    }
  }

  /// Set the database version in SharedPreferences
  Future<void> setCurrentVersion(int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_versionKey, version);
      debugPrint('Database version updated to: $version');
    } catch (e) {
      throw DatabaseMigrationException('Failed to set database version: $e');
    }
  }

  /// Check if there are pending migrations
  Future<bool> hasPendingMigrations() async {
    final currentVersion = await getCurrentVersion();
    return currentVersion < _currentVersion;
  }

  /// Get list of pending migration versions
  Future<List<int>> getPendingMigrations() async {
    final currentVersion = await getCurrentVersion();
    final pendingVersions = <int>[];
    
    for (int version = currentVersion + 1; version <= _currentVersion; version++) {
      pendingVersions.add(version);
    }
    
    return pendingVersions;
  }

  /// Run all pending migrations
  Future<void> runPendingMigrations(Database database) async {
    int currentVersion = await getCurrentVersion();
    
    if (currentVersion >= _currentVersion) {
      debugPrint('Database is already at the latest version: $currentVersion');
      return;
    }

    debugPrint('Running database migrations from version $currentVersion to $_currentVersion');
    
    // Run migrations sequentially, one version at a time
    while (currentVersion < _currentVersion) {
      final nextVersion = currentVersion + 1;
      await _runSingleMigration(database, currentVersion, nextVersion);
      currentVersion = nextVersion;
    }
    
    debugPrint('All database migrations completed successfully');
  }

  /// Run a single migration with transaction safety and rollback capability
  Future<void> _runSingleMigration(Database database, int fromVersion, int toVersion) async {
    debugPrint('Running migration from version $fromVersion to $toVersion');
    
    try {
      await database.transaction((txn) async {
        // Run the specific migration
        await _executeMigration(txn, fromVersion, toVersion);
        
        // Update version only after successful migration
        await setCurrentVersion(toVersion);
        
        debugPrint('Migration from version $fromVersion to $toVersion completed successfully');
      });
    } catch (e) {
      // Transaction automatically rolls back on exception
      debugPrint('Migration from version $fromVersion to $toVersion failed: $e');
      
      // Attempt to run rollback if available
      try {
        await _runRollback(database, fromVersion, toVersion);
      } catch (rollbackError) {
        debugPrint('Rollback failed: $rollbackError');
        throw DatabaseMigrationException(
          'Migration failed and rollback also failed. '
          'Original error: $e. Rollback error: $rollbackError'
        );
      }
      
      throw DatabaseMigrationException('Migration from version $fromVersion to $toVersion failed: $e');
    }
  }

  /// Execute the appropriate migration based on version numbers
  Future<void> _executeMigration(Transaction txn, int fromVersion, int toVersion) async {
    switch ('${fromVersion}_to_$toVersion') {
      case '1_to_2':
        await _migration_v1_to_v2(txn);
        break;
      case '2_to_3':
        await _migration_v2_to_v3(txn);
        break;
      case '3_to_4':
        await _migration_v3_to_v4(txn);
        break;
      case '4_to_5':
        await _migration_v4_to_v5(txn);
        break;
      default:
        throw DatabaseMigrationException('No migration available from version $fromVersion to $toVersion');
    }
  }

  /// Run rollback for a failed migration
  Future<void> _runRollback(Database database, int fromVersion, int toVersion) async {
    debugPrint('Attempting rollback from version $toVersion to $fromVersion');
    
    await database.transaction((txn) async {
      switch ('${toVersion}_to_$fromVersion') {
        case '2_to_1':
          await _rollback_v2_to_v1(txn);
          break;
        case '3_to_2':
          await _rollback_v3_to_v2(txn);
          break;
        case '4_to_3':
          await _rollback_v4_to_v3(txn);
          break;
        case '5_to_4':
          await _rollback_v5_to_v4(txn);
          break;
        default:
          throw DatabaseMigrationException('No rollback available from version $toVersion to $fromVersion');
      }
      
      // Reset version after successful rollback
      await setCurrentVersion(fromVersion);
    });
    
    debugPrint('Rollback from version $toVersion to $fromVersion completed');
  }

  // Migration Scripts
  // =================

  /// Migration from version 1 to 2: Add metadata column to journal_entries
  static Future<void> _migration_v1_to_v2(Transaction txn) async {
    debugPrint('Executing migration v1 to v2: Adding metadata column');
    
    // Check if metadata column already exists
    final result = await txn.rawQuery("PRAGMA table_info(journal_entries)");
    final hasMetadata = result.any((column) => column['name'] == 'metadata');
    
    if (!hasMetadata) {
      // Add metadata column with default empty JSON
      await txn.execute('ALTER TABLE journal_entries ADD COLUMN metadata TEXT NOT NULL DEFAULT "{}"');
    } else {
      debugPrint('metadata column already exists, skipping column addition');
    }
    
    // Check if index exists before creating it
    final indexResult = await txn.rawQuery("PRAGMA index_list(journal_entries)");
    final hasIndex = indexResult.any((index) => index['name'] == 'idx_journal_metadata');
    
    if (!hasIndex) {
      // Create index for better query performance
      await txn.execute('CREATE INDEX idx_journal_metadata ON journal_entries(metadata)');
    } else {
      debugPrint('idx_journal_metadata already exists, skipping index creation');
    }
  }

  /// Migration from version 2 to 3: Add AI analysis fields
  static Future<void> _migration_v2_to_v3(Transaction txn) async {
    debugPrint('Executing migration v2 to v3: Adding AI analysis fields');
    
    // Check existing columns
    final result = await txn.rawQuery("PRAGMA table_info(journal_entries)");
    final columnNames = result.map((column) => column['name'] as String).toSet();
    
    // Add AI analysis fields only if they don't exist
    if (!columnNames.contains('aiAnalysis')) {
      await txn.execute('ALTER TABLE journal_entries ADD COLUMN aiAnalysis TEXT');
    }
    if (!columnNames.contains('isAnalyzed')) {
      await txn.execute('ALTER TABLE journal_entries ADD COLUMN isAnalyzed INTEGER NOT NULL DEFAULT 0');
    }
    if (!columnNames.contains('draftContent')) {
      await txn.execute('ALTER TABLE journal_entries ADD COLUMN draftContent TEXT');
    }
    
    // Check if index exists before creating it
    final indexResult = await txn.rawQuery("PRAGMA index_list(journal_entries)");
    final hasIndex = indexResult.any((index) => index['name'] == 'idx_journal_analyzed');
    
    if (!hasIndex) {
      await txn.execute('CREATE INDEX idx_journal_analyzed ON journal_entries(isAnalyzed)');
    }
  }

  /// Migration from version 3 to 4: Add enhanced AI analysis fields
  static Future<void> _migration_v3_to_v4(Transaction txn) async {
    debugPrint('Executing migration v3 to v4: Adding enhanced AI analysis fields');
    
    // Add enhanced AI fields
    await txn.execute('ALTER TABLE journal_entries ADD COLUMN aiDetectedMoods TEXT NOT NULL DEFAULT "[]"');
    await txn.execute('ALTER TABLE journal_entries ADD COLUMN emotionalIntensity REAL');
    await txn.execute('ALTER TABLE journal_entries ADD COLUMN keyThemes TEXT NOT NULL DEFAULT "[]"');
    await txn.execute('ALTER TABLE journal_entries ADD COLUMN personalizedInsight TEXT');
    
    // Create indexes for enhanced AI queries
    await txn.execute('CREATE INDEX idx_journal_ai_moods ON journal_entries(aiDetectedMoods)');
    await txn.execute('CREATE INDEX idx_journal_intensity ON journal_entries(emotionalIntensity)');
    await txn.execute('CREATE INDEX idx_journal_themes ON journal_entries(keyThemes)');
  }

  /// Test migration from version 4 to 5: Add voice journal support
  static Future<void> _migration_v4_to_v5(Transaction txn) async {
    debugPrint('Executing migration v4 to v5: Adding voice journal support');
    
    // Add voice journal fields safely
    await txn.execute('ALTER TABLE journal_entries ADD COLUMN audioPath TEXT');
    await txn.execute('ALTER TABLE journal_entries ADD COLUMN transcriptionStatus TEXT DEFAULT "none"');
    await txn.execute('ALTER TABLE journal_entries ADD COLUMN voiceAnalysisData TEXT');
    
    // Create index for voice journal queries
    await txn.execute('CREATE INDEX idx_journal_audio ON journal_entries(audioPath)');
    await txn.execute('CREATE INDEX idx_journal_transcription ON journal_entries(transcriptionStatus)');
  }

  // Rollback Scripts
  // ================

  /// Rollback from version 2 to 1: Remove metadata column
  static Future<void> _rollback_v2_to_v1(Transaction txn) async {
    debugPrint('Executing rollback v2 to v1: Removing metadata column');
    
    // Drop the index first
    await txn.execute('DROP INDEX IF EXISTS idx_journal_metadata');
    
    // SQLite doesn't support DROP COLUMN, so we need to recreate the table
    await txn.execute('''
      CREATE TABLE journal_entries_backup AS
      SELECT id, userId, date, content, moods, dayOfWeek, createdAt, updatedAt, isSynced
      FROM journal_entries
    ''');
    
    await txn.execute('DROP TABLE journal_entries');
    await txn.execute('ALTER TABLE journal_entries_backup RENAME TO journal_entries');
    
    // Recreate original indexes
    await txn.execute('CREATE INDEX idx_journal_date ON journal_entries(date)');
    await txn.execute('CREATE INDEX idx_journal_moods ON journal_entries(moods)');
  }

  /// Rollback from version 3 to 2: Remove AI analysis fields
  static Future<void> _rollback_v3_to_v2(Transaction txn) async {
    debugPrint('Executing rollback v3 to v2: Removing AI analysis fields');
    
    // Drop AI analysis indexes
    await txn.execute('DROP INDEX IF EXISTS idx_journal_analyzed');
    
    // Recreate table without AI fields
    await txn.execute('''
      CREATE TABLE journal_entries_backup AS
      SELECT id, userId, date, content, moods, dayOfWeek, createdAt, updatedAt, isSynced, metadata
      FROM journal_entries
    ''');
    
    await txn.execute('DROP TABLE journal_entries');
    await txn.execute('ALTER TABLE journal_entries_backup RENAME TO journal_entries');
    
    // Recreate v2 indexes
    await txn.execute('CREATE INDEX idx_journal_date ON journal_entries(date)');
    await txn.execute('CREATE INDEX idx_journal_moods ON journal_entries(moods)');
    await txn.execute('CREATE INDEX idx_journal_metadata ON journal_entries(metadata)');
  }

  /// Rollback from version 4 to 3: Remove enhanced AI analysis fields
  static Future<void> _rollback_v4_to_v3(Transaction txn) async {
    debugPrint('Executing rollback v4 to v3: Removing enhanced AI analysis fields');
    
    // Drop enhanced AI indexes
    await txn.execute('DROP INDEX IF EXISTS idx_journal_ai_moods');
    await txn.execute('DROP INDEX IF EXISTS idx_journal_intensity');
    await txn.execute('DROP INDEX IF EXISTS idx_journal_themes');
    
    // Recreate table without enhanced AI fields
    await txn.execute('''
      CREATE TABLE journal_entries_backup AS
      SELECT id, userId, date, content, moods, dayOfWeek, createdAt, updatedAt, isSynced, 
             metadata, aiAnalysis, isAnalyzed, draftContent
      FROM journal_entries
    ''');
    
    await txn.execute('DROP TABLE journal_entries');
    await txn.execute('ALTER TABLE journal_entries_backup RENAME TO journal_entries');
    
    // Recreate v3 indexes
    await txn.execute('CREATE INDEX idx_journal_date ON journal_entries(date)');
    await txn.execute('CREATE INDEX idx_journal_moods ON journal_entries(moods)');
    await txn.execute('CREATE INDEX idx_journal_metadata ON journal_entries(metadata)');
    await txn.execute('CREATE INDEX idx_journal_analyzed ON journal_entries(isAnalyzed)');
  }

  /// Rollback from version 5 to 4: Remove voice journal support
  static Future<void> _rollback_v5_to_v4(Transaction txn) async {
    debugPrint('Executing rollback v5 to v4: Removing voice journal support');
    
    // Drop voice journal indexes
    await txn.execute('DROP INDEX IF EXISTS idx_journal_audio');
    await txn.execute('DROP INDEX IF EXISTS idx_journal_transcription');
    
    // Recreate table without voice journal fields
    await txn.execute('''
      CREATE TABLE journal_entries_backup AS
      SELECT id, userId, date, content, moods, dayOfWeek, createdAt, updatedAt, isSynced,
             metadata, aiAnalysis, isAnalyzed, draftContent, aiDetectedMoods,
             emotionalIntensity, keyThemes, personalizedInsight
      FROM journal_entries
    ''');
    
    await txn.execute('DROP TABLE journal_entries');
    await txn.execute('ALTER TABLE journal_entries_backup RENAME TO journal_entries');
    
    // Recreate v4 indexes
    await txn.execute('CREATE INDEX idx_journal_date ON journal_entries(date)');
    await txn.execute('CREATE INDEX idx_journal_moods ON journal_entries(moods)');
    await txn.execute('CREATE INDEX idx_journal_metadata ON journal_entries(metadata)');
    await txn.execute('CREATE INDEX idx_journal_analyzed ON journal_entries(isAnalyzed)');
    await txn.execute('CREATE INDEX idx_journal_ai_moods ON journal_entries(aiDetectedMoods)');
    await txn.execute('CREATE INDEX idx_journal_intensity ON journal_entries(emotionalIntensity)');
    await txn.execute('CREATE INDEX idx_journal_themes ON journal_entries(keyThemes)');
  }

  /// Utility method to get migration history
  Future<Map<String, dynamic>> getMigrationHistory() async {
    try {
      final currentVersion = await getCurrentVersion();
      final pendingMigrations = await getPendingMigrations();
      final hasPending = await hasPendingMigrations();
      
      return {
        'currentVersion': currentVersion,
        'targetVersion': _currentVersion,
        'pendingMigrations': pendingMigrations,
        'hasPendingMigrations': hasPending,
        'migrationHistory': {
          'v1_to_v2': 'Add metadata column to journal_entries',
          'v2_to_v3': 'Add AI analysis fields (aiAnalysis, isAnalyzed, draftContent)',
          'v3_to_v4': 'Add enhanced AI fields (aiDetectedMoods, emotionalIntensity, keyThemes, personalizedInsight)',
          'v4_to_v5': 'Add voice journal support (audioPath, transcriptionStatus, voiceAnalysisData)',
        },
      };
    } catch (e) {
      throw DatabaseMigrationException('Failed to get migration history: $e');
    }
  }

  /// Reset migration version (for testing purposes)
  Future<void> resetMigrationVersion([int version = 1]) async {
    try {
      await setCurrentVersion(version);
      debugPrint('Migration version reset to: $version');
    } catch (e) {
      throw DatabaseMigrationException('Failed to reset migration version: $e');
    }
  }
}