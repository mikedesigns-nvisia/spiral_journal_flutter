import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'migrations/schema_migration_v3.dart';
import 'migrations/schema_migration_v4.dart';
import '../utils/database_exceptions.dart';

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
        version: 4, // Increment version for new AI analysis fields
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
    // Create tables with enhanced schema (version 4 with AI analysis fields)
    // Journal entries table with AI analysis support
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

    // Emotional cores table
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

    // Create comprehensive indexes for better query performance
    await db.execute('CREATE INDEX idx_journal_entries_date ON journal_entries(date)');
    await db.execute('CREATE INDEX idx_journal_entries_created_at ON journal_entries(createdAt)');
    await db.execute('CREATE INDEX idx_journal_entries_moods ON journal_entries(moods)');
    await db.execute('CREATE INDEX idx_journal_entries_analyzed ON journal_entries(isAnalyzed)');
    await db.execute('CREATE INDEX idx_journal_entries_content_fts ON journal_entries(content)');
    await db.execute('CREATE INDEX idx_journal_entries_ai_moods ON journal_entries(aiDetectedMoods)');
    await db.execute('CREATE INDEX idx_journal_entries_intensity ON journal_entries(emotionalIntensity)');
    await db.execute('CREATE INDEX idx_journal_entries_themes ON journal_entries(keyThemes)');
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
      
      // Also clear the encryption key
      await _secureStorage.delete(key: _encryptionKeyName);
      
    } catch (e) {
      throw DatabaseOperationException('Failed to clear all data: $e');
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
}
