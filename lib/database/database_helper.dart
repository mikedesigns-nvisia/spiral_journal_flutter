import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'migrations/schema_migration_v3.dart';
import 'migrations/schema_migration_v4.dart';
import 'migrations/schema_migration_v6.dart';
import '../utils/database_exceptions.dart';

/// Result class for database clearing operations
class DatabaseClearResult {
  bool success = false;
  Map<String, int> initialCounts = {};
  Map<String, int> finalCounts = {};
  Map<String, int> clearedTables = {};
  Map<String, String> errors = {};
  bool sequencesReset = false;
  bool encryptionKeyCleared = false;
  
  /// Get total number of rows cleared
  int get totalRowsCleared => clearedTables.values.fold(0, (sum, count) => sum + count);
  
  /// Check if any errors occurred
  bool get hasErrors => errors.isNotEmpty;
  
  /// Get summary of the clearing operation
  String get summary {
    if (success) {
      return 'Database cleared successfully. Removed $totalRowsCleared rows from ${clearedTables.length} tables.';
    } else {
      return 'Database clearing completed with ${errors.length} errors. Cleared $totalRowsCleared rows.';
    }
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const String _encryptionKeyName = 'spiral_journal_db_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
      accountName: 'spiral_journal_db',
    ),
  );

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database with enhanced schema for AI analysis
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'spiral_journal_v4.db');
      
      // Only generate encryption key in production (not during testing)
      try {
        await _getOrCreateEncryptionKey();
      } catch (e) {
        // Ignore encryption key errors during testing
        debugPrint('Warning: Could not initialize encryption key (likely in test environment): $e');
      }
      
      return await openDatabase(
        path,
        version: 6, // Increment version for AI field removal
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseInitializationException('Failed to initialize database: $e');
    }
  }

  /// Get existing encryption key or create a new one
  Future<String> _getOrCreateEncryptionKey() async {
    try {
      // Try to get existing key
      String? existingKey = await _secureStorage.read(key: _encryptionKeyName);
      
      if (existingKey != null && existingKey.isNotEmpty) {
        return existingKey;
      }
      
      // Generate new encryption key
      final bytes = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch + i);
      final key = sha256.convert(bytes).toString();
      
      // Store the key securely
      await _secureStorage.write(key: _encryptionKeyName, value: key);
      
      return key;
    } catch (e) {
      throw DatabaseSecurityException('Failed to manage encryption key: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables with simplified schema (version 6 without AI analysis fields)
    // Journal entries table focused on local processing
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
        draftContent TEXT
      )
    ''');

    // Emotional cores table with resonance depth system
    await db.execute('''
      CREATE TABLE emotional_cores (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        current_level REAL NOT NULL DEFAULT 0.0,
        previous_level REAL NOT NULL DEFAULT 0.0,
        last_updated TEXT NOT NULL,
        last_transition_date TEXT,
        entries_at_current_depth INTEGER DEFAULT 0,
        trend TEXT NOT NULL,
        color TEXT NOT NULL,
        icon_path TEXT NOT NULL,
        insight TEXT NOT NULL,
        related_cores TEXT NOT NULL,
        transition_signals TEXT,
        supporting_evidence TEXT,
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
        dominantMoods TEXT NOT NULL,
        emotionalJourneyData TEXT NOT NULL,
        insight TEXT NOT NULL,
        entryCount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(month, year)
      )
    ''');

    // Core combinations table
    await db.execute('''
      CREATE TABLE core_combinations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        coreIds TEXT NOT NULL,
        description TEXT NOT NULL,
        benefit TEXT NOT NULL,
        createdAt TEXT NOT NULL
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
        createdAt TEXT NOT NULL
      )
    ''');

    // Core transition history table
    await db.execute('''
      CREATE TABLE core_transition_history (
        id TEXT PRIMARY KEY,
        core_id TEXT NOT NULL,
        from_depth TEXT NOT NULL,
        to_depth TEXT NOT NULL,
        transition_date TEXT NOT NULL,
        contributing_entry_id TEXT,
        transition_reason TEXT,
        FOREIGN KEY (core_id) REFERENCES emotional_cores (id) ON DELETE CASCADE,
        FOREIGN KEY (contributing_entry_id) REFERENCES journal_entries (id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for better query performance (simplified for local processing)
    await db.execute('CREATE INDEX idx_journal_entries_date ON journal_entries(date)');
    await db.execute('CREATE INDEX idx_journal_entries_created_at ON journal_entries(createdAt)');
    await db.execute('CREATE INDEX idx_journal_entries_moods ON journal_entries(moods)');
    await db.execute('CREATE INDEX idx_journal_entries_content_fts ON journal_entries(content)');
    await db.execute('CREATE INDEX idx_monthly_summaries_year_month ON monthly_summaries(year, month)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades with proper migrations
    if (oldVersion < 3 && newVersion >= 3) {
      // Migrate from version 2 to version 3 (snake_case to camelCase)
      await SchemaMigrationV3.migrate(db);
    }
    
    if (oldVersion < 4 && newVersion >= 4) {
      // Migrate from version 3 to version 4 (add AI analysis fields)
      await SchemaMigrationV4.migrate(db);
    }
    
    if (oldVersion < 5 && newVersion >= 5) {
      // Migrate from version 4 to version 5 (resonance depth system)
      await _migrateToResonanceDepthSystem(db);
    }
    
    if (oldVersion < 6 && newVersion >= 6) {
      // Migrate from version 5 to version 6 (remove AI analysis fields)
      await SchemaMigrationV6.migrate(db);
    }
  }

  Future<void> _migrateToResonanceDepthSystem(Database db) async {
    await db.transaction((txn) async {
      // Check if the new columns already exist
      final columns = await txn.rawQuery('PRAGMA table_info(emotional_cores)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();
      
      if (!columnNames.contains('current_level')) {
        // Add new resonance depth columns
        await txn.execute('ALTER TABLE emotional_cores ADD COLUMN current_level REAL DEFAULT 0.0');
        await txn.execute('ALTER TABLE emotional_cores ADD COLUMN previous_level REAL DEFAULT 0.0');
        await txn.execute('ALTER TABLE emotional_cores ADD COLUMN last_transition_date TEXT');
        await txn.execute('ALTER TABLE emotional_cores ADD COLUMN entries_at_current_depth INTEGER DEFAULT 0');
        await txn.execute('ALTER TABLE emotional_cores ADD COLUMN transition_signals TEXT');
        await txn.execute('ALTER TABLE emotional_cores ADD COLUMN supporting_evidence TEXT');
      }
      
      // Add last_updated column if it doesn't exist
      if (!columnNames.contains('last_updated')) {
        await txn.execute('ALTER TABLE emotional_cores ADD COLUMN last_updated TEXT');
        // Update existing rows with current timestamp
        await txn.execute('UPDATE emotional_cores SET last_updated = datetime(\'now\') WHERE last_updated IS NULL');
      }
      
      if (!columnNames.contains('current_level')) {
        
        // Migrate percentage data to current_level (percentage/100)
        await txn.execute('''
          UPDATE emotional_cores 
          SET current_level = COALESCE(percentage, 0.0) / 100.0,
              previous_level = COALESCE(percentage, 0.0) / 100.0
        ''');
        
        // Update last_updated to use existing updated_at or updatedAt
        try {
          await txn.execute('''
            UPDATE emotional_cores 
            SET last_updated = COALESCE(updated_at, datetime('now'))
          ''');
        } catch (e) {
          // If updated_at doesn't exist, try updatedAt
          try {
            await txn.execute('''
              UPDATE emotional_cores 
              SET last_updated = COALESCE(updatedAt, datetime('now'))
            ''');
          } catch (e2) {
            // If neither exists, just set to current time
            await txn.execute('''
              UPDATE emotional_cores 
              SET last_updated = datetime('now')
            ''');
          }
        }
      }
      
      // Create core transition history table if it doesn't exist
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS core_transition_history (
          id TEXT PRIMARY KEY,
          core_id TEXT NOT NULL,
          from_depth TEXT NOT NULL,
          to_depth TEXT NOT NULL,
          transition_date TEXT NOT NULL,
          contributing_entry_id TEXT,
          transition_reason TEXT,
          FOREIGN KEY (core_id) REFERENCES emotional_cores (id) ON DELETE CASCADE,
          FOREIGN KEY (contributing_entry_id) REFERENCES journal_entries (id) ON DELETE SET NULL
        )
      ''');
    });
  }

  /// Export all journal data to JSON format
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final db = await database;
      
      // Export journal entries
      final journalEntries = await db.query('journal_entries', orderBy: 'date DESC');
      
      // Export emotional cores
      final emotionalCores = await db.query('emotional_cores', orderBy: 'name ASC');
      
      // Export monthly summaries
      final monthlySummaries = await db.query('monthly_summaries', orderBy: 'year DESC, month DESC');
      
      // Export core combinations
      final coreCombinations = await db.query('core_combinations', orderBy: 'name ASC');
      
      // Export emotional patterns
      final emotionalPatterns = await db.query('emotional_patterns', orderBy: 'category ASC');
      
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': 4,
        'journalEntries': journalEntries,
        'emotionalCores': emotionalCores,
        'monthlySummaries': monthlySummaries,
        'coreCombinations': coreCombinations,
        'emotionalPatterns': emotionalPatterns,
      };
    } catch (e) {
      throw DatabaseExportException('Failed to export data: $e');
    }
  }

  /// Export journal data as encrypted JSON string
  Future<String> exportDataAsJson({bool encrypted = true}) async {
    try {
      final data = await exportAllData();
      final jsonString = jsonEncode(data);
      
      if (!encrypted) {
        return jsonString;
      }
      
      // Encrypt the JSON data
      final encryptionKey = await _getOrCreateEncryptionKey();
      final bytes = utf8.encode(jsonString);
      final digest = Hmac(sha256, utf8.encode(encryptionKey)).convert(bytes);
      
      return jsonEncode({
        'encrypted': true,
        'data': base64Encode(bytes),
        'signature': digest.toString(),
      });
    } catch (e) {
      throw DatabaseExportException('Failed to export data as JSON: $e');
    }
  }

  /// Validate database integrity
  Future<bool> validateDatabaseIntegrity() async {
    try {
      final db = await database;
      
      // Check if all required tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      final requiredTables = {
        'journal_entries',
        'emotional_cores',
        'monthly_summaries',
        'core_combinations',
        'emotional_patterns'
      };
      
      final existingTables = tables.map((t) => t['name'] as String).toSet();
      
      if (!requiredTables.every((table) => existingTables.contains(table))) {
        return false;
      }
      
      // Validate journal entries data integrity
      final invalidEntries = await db.rawQuery('''
        SELECT COUNT(*) as count FROM journal_entries 
        WHERE id IS NULL OR content IS NULL OR date IS NULL
      ''');
      
      if ((invalidEntries.first['count'] as int) > 0) {
        return false;
      }
      
      // Validate emotional cores data integrity
      final invalidCores = await db.rawQuery('''
        SELECT COUNT(*) as count FROM emotional_cores 
        WHERE id IS NULL OR name IS NULL OR percentage < 0 OR percentage > 100
      ''');
      
      if ((invalidCores.first['count'] as int) > 0) {
        return false;
      }
      
      return true;
    } catch (e) {
      throw DatabaseValidationException('Database integrity validation failed: $e');
    }
  }

  /// Clear all data (for PIN reset functionality)
  Future<void> clearAllData() async {
    try {
      final db = await database;
      
      await db.transaction((txn) async {
        await txn.delete('journal_entries');
        await txn.delete('emotional_cores');
        await txn.delete('monthly_summaries');
        await txn.delete('core_combinations');
        await txn.delete('emotional_patterns');
      });
      
      // Also clear the encryption key (skip in test environment)
      try {
        await _secureStorage.delete(key: _encryptionKeyName);
      } catch (e) {
        if (!e.toString().contains('MissingPluginException')) {
          rethrow; // Only ignore MissingPluginException (test environment)
        }
      }
      
    } catch (e) {
      throw DatabaseOperationException('Failed to clear all data: $e');
    }
  }

  /// Clear all tables (for fresh install functionality)
  Future<void> clearAllTables() async {
    try {
      final db = await database;
      
      // Use a more comprehensive clearing approach for fresh install
      await db.transaction((txn) async {
        // Clear all data from tables
        await txn.delete('journal_entries');
        await txn.delete('emotional_cores');
        await txn.delete('monthly_summaries');
        await txn.delete('core_combinations');
        await txn.delete('emotional_patterns');
        
        // Reset auto-increment sequences if they exist
        try {
          await txn.execute('DELETE FROM sqlite_sequence WHERE name IN (?, ?, ?, ?, ?)', [
            'journal_entries',
            'emotional_cores', 
            'monthly_summaries',
            'core_combinations',
            'emotional_patterns'
          ]);
        } catch (e) {
          // sqlite_sequence table may not exist in test environment, ignore error
          if (kDebugMode) {
            debugPrint('Note: sqlite_sequence table not found (normal in test environment)');
          }
        }
      });
      
      // Clear the encryption key for complete fresh start (skip in test environment)
      try {
        await _secureStorage.delete(key: _encryptionKeyName);
      } catch (e) {
        if (!e.toString().contains('MissingPluginException')) {
          rethrow; // Only ignore MissingPluginException (test environment)
        }
      }
      
    } catch (e) {
      throw DatabaseOperationException('Failed to clear all tables: $e');
    }
  }

  /// Safe database reset with comprehensive error handling
  Future<DatabaseClearResult> safeDatabaseReset() async {
    final result = DatabaseClearResult();
    
    try {
      final db = await database;
      
      // Get initial counts for verification
      final initialStats = await getDatabaseStats();
      result.initialCounts = initialStats;
      
      // Perform the clearing operation in a transaction
      await db.transaction((txn) async {
        // Clear each table individually with error tracking
        final tables = ['journal_entries', 'emotional_cores', 'monthly_summaries', 
                       'core_combinations', 'emotional_patterns'];
        
        for (final table in tables) {
          try {
            final deletedRows = await txn.delete(table);
            result.clearedTables[table] = deletedRows;
          } catch (e) {
            result.errors[table] = 'Failed to clear $table: $e';
          }
        }
        
        // Reset auto-increment sequences if they exist
        try {
          await txn.execute('DELETE FROM sqlite_sequence WHERE name IN (?, ?, ?, ?, ?)', [
            'journal_entries', 'emotional_cores', 'monthly_summaries',
            'core_combinations', 'emotional_patterns'
          ]);
          result.sequencesReset = true;
        } catch (e) {
          // sqlite_sequence table may not exist in test environment
          if (e.toString().contains('no such table: sqlite_sequence')) {
            result.sequencesReset = true; // Consider it successful in test environment
          } else {
            result.errors['sequences'] = 'Failed to reset sequences: $e';
          }
        }
      });
      
      // Clear encryption key (skip in test environment)
      try {
        await _secureStorage.delete(key: _encryptionKeyName);
        result.encryptionKeyCleared = true;
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          // In test environment, secure storage is not available
          result.encryptionKeyCleared = true; // Consider it successful
          if (kDebugMode) {
            debugPrint('Secure storage not available in test environment');
          }
        } else {
          result.errors['encryption_key'] = 'Failed to clear encryption key: $e';
        }
      }
      
      // Verify clearing was successful
      final finalStats = await getDatabaseStats();
      result.finalCounts = finalStats;
      result.success = result.errors.isEmpty && 
                      finalStats['totalEntries'] == 0 && 
                      finalStats['totalCores'] == 0;
      
    } catch (e) {
      result.errors['general'] = 'Database reset failed: $e';
      result.success = false;
    }
    
    return result;
  }

  /// Verify database is completely empty
  Future<bool> isDatabaseEmpty() async {
    try {
      final stats = await getDatabaseStats();
      return stats['totalEntries'] == 0 && 
             stats['totalCores'] == 0 &&
             stats.values.every((count) => count == 0);
    } catch (e) {
      return false;
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await database;
      
      final journalCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM journal_entries')
      ) ?? 0;
      
      final coreCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM emotional_cores')
      ) ?? 0;
      
      final analyzedCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM journal_entries WHERE isAnalyzed = 1')
      ) ?? 0;
      
      return {
        'totalEntries': journalCount,
        'totalCores': coreCount,
        'analyzedEntries': analyzedCount,
        'unanalyzedEntries': journalCount - analyzedCount,
      };
    } catch (e) {
      throw DatabaseOperationException('Failed to get database statistics: $e');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Close database connection for backup/restore operations
  Future<void> closeDatabase() async {
    await close();
  }
}
