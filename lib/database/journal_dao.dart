import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../constants/validation_constants.dart';
import '../models/journal_entry.dart';
import '../utils/database_exceptions.dart';
import 'database_helper.dart';

/// Data Access Object for journal entry database operations.
/// 
/// This class provides comprehensive database operations for journal entries with
/// transaction safety, data validation, and atomic operations. It implements
/// sophisticated error handling and supports both individual and batch operations.
/// 
/// ## Key Features
/// - **Transaction Safety**: All operations use database transactions for consistency
/// - **Data Validation**: Comprehensive validation using centralized constants
/// - **Atomic Operations**: Combined journal entry and core update operations
/// - **Batch Operations**: Efficient multi-record operations with rollback support
/// - **Error Recovery**: Detailed error handling with context-specific exceptions
/// 
/// ## Usage Example
/// ```dart
/// final journalDao = JournalDao();
/// 
/// // Create entry with atomic core updates
/// final entryId = await journalDao.insertJournalEntryWithCoreUpdates(
///   entry,
///   {'core-id-1': 75.5, 'core-id-2': 82.0}
/// );
/// 
/// // Search and filter entries
/// final entries = await journalDao.searchJournalEntries("grateful");
/// final monthlyEntries = await journalDao.getJournalEntriesByMonth(2024, 12);
/// 
/// // Batch operations
/// final entryIds = await journalDao.insertMultipleJournalEntries(entries);
/// ```
/// 
/// ## Transaction Architecture
/// All database operations are wrapped in transactions using `_executeInTransaction`:
/// - Automatic rollback on any operation failure
/// - Comprehensive error logging and context preservation
/// - Type-safe transaction handling with generic return types
/// - Validation before database operations to prevent invalid states
/// 
/// ## Data Validation Strategy
/// - Content length validation using `AppConstants.maxContentLength`
/// - Mood validation using `ValidationConstants.validMoods`
/// - Core percentage validation (0-100 range)
/// - Required field validation (content, userId, moods)
/// - Database constraint validation before operations
class JournalDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  // Create a new journal entry with transaction safety
  Future<String> insertJournalEntry(JournalEntry entry) async {
    return await _executeInTransaction<String>((txn) async {
      return await _insertJournalEntryInTransaction(txn, entry);
    });
  }

  // Internal method for inserting journal entry within a transaction
  Future<String> _insertJournalEntryInTransaction(Transaction txn, JournalEntry entry) async {
    // Validate entry data before insertion
    _validateJournalEntry(entry);
    
    final entryWithId = entry.copyWith(
      id: entry.id.isEmpty ? _uuid.v4() : entry.id,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now(),
    );

    await txn.insert(
      'journal_entries',
      {
        'id': entryWithId.id,
        'userId': entryWithId.userId,
        'date': entryWithId.date.toIso8601String(),
        'content': entryWithId.content,
        'moods': entryWithId.moods.join(','),
        'dayOfWeek': entryWithId.dayOfWeek,
        'createdAt': entryWithId.createdAt.toIso8601String(),
        'updatedAt': entryWithId.updatedAt.toIso8601String(),
        'isSynced': entryWithId.isSynced ? 1 : 0,
        'metadata': entryWithId.metadata.isNotEmpty ? 
                   jsonEncode(entryWithId.metadata) : '{}',
        'aiAnalysis': entryWithId.aiAnalysis != null ? 
                     jsonEncode(entryWithId.aiAnalysis!.toJson()) : null,
        'isAnalyzed': entryWithId.isAnalyzed ? 1 : 0,
        'draftContent': entryWithId.draftContent,
        'aiDetectedMoods': jsonEncode(entryWithId.aiDetectedMoods),
        'emotionalIntensity': entryWithId.emotionalIntensity,
        'keyThemes': jsonEncode(entryWithId.keyThemes),
        'personalizedInsight': entryWithId.personalizedInsight,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return entryWithId.id;
  }

  // Get all journal entries
  Future<List<JournalEntry>> getAllJournalEntries() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        orderBy: 'date DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.getAllJournalEntries failed: $e');
      rethrow;
    }
  }

  // Get journal entries by date range
  Future<List<JournalEntry>> getJournalEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.getJournalEntriesByDateRange failed: $e');
      rethrow;
    }
  }

  // Get journal entries by year
  Future<List<JournalEntry>> getJournalEntriesByYear(int year) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);
    return getJournalEntriesByDateRange(startDate, endDate);
  }

  // Get journal entries by month
  Future<List<JournalEntry>> getJournalEntriesByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return getJournalEntriesByDateRange(startDate, endDate);
  }

  // Search journal entries by content
  Future<List<JournalEntry>> searchJournalEntries(String query) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'content LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.searchJournalEntries failed: $e');
      rethrow;
    }
  }

  // Search journal entries by mood
  Future<List<JournalEntry>> getJournalEntriesByMood(String mood) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'moods LIKE ?',
        whereArgs: ['%$mood%'],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.getJournalEntriesByMood failed: $e');
      rethrow;
    }
  }

  // Get a single journal entry by ID
  Future<JournalEntry?> getJournalEntryById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _mapToJournalEntry(maps.first);
    } catch (e) {
      debugPrint('JournalDao.getJournalEntryById failed: $e');
      rethrow;
    }
  }

  // Update a journal entry with transaction safety
  Future<void> updateJournalEntry(JournalEntry entry) async {
    await _executeInTransaction<void>((txn) async {
      await _updateJournalEntryInTransaction(txn, entry);
    });
  }

  // Internal method for updating journal entry within a transaction
  Future<void> _updateJournalEntryInTransaction(Transaction txn, JournalEntry entry) async {
    // Validate entry data before update
    _validateJournalEntry(entry);
    
    final updatedEntry = entry.copyWith(updatedAt: DateTime.now());

    final result = await txn.update(
      'journal_entries',
      {
        'userId': updatedEntry.userId,
        'date': updatedEntry.date.toIso8601String(),
        'content': updatedEntry.content,
        'moods': updatedEntry.moods.join(','),
        'dayOfWeek': updatedEntry.dayOfWeek,
        'updatedAt': updatedEntry.updatedAt.toIso8601String(),
        'isSynced': updatedEntry.isSynced ? 1 : 0,
        'metadata': updatedEntry.metadata.isNotEmpty ? 
                   jsonEncode(updatedEntry.metadata) : '{}',
        'aiAnalysis': updatedEntry.aiAnalysis != null ? 
                     jsonEncode(updatedEntry.aiAnalysis!.toJson()) : null,
        'isAnalyzed': updatedEntry.isAnalyzed ? 1 : 0,
        'draftContent': updatedEntry.draftContent,
        'aiDetectedMoods': jsonEncode(updatedEntry.aiDetectedMoods),
        'emotionalIntensity': updatedEntry.emotionalIntensity,
        'keyThemes': jsonEncode(updatedEntry.keyThemes),
        'personalizedInsight': updatedEntry.personalizedInsight,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );

    if (result == 0) {
      throw DatabaseTransactionException('Failed to update journal entry: entry not found');
    }
  }

  // Delete a journal entry with transaction safety
  Future<void> deleteJournalEntry(String id) async {
    await _executeInTransaction<void>((txn) async {
      await _deleteJournalEntryInTransaction(txn, id);
    });
  }

  // Internal method for deleting journal entry within a transaction
  Future<void> _deleteJournalEntryInTransaction(Transaction txn, String id) async {
    // Validate input
    if (id.trim().isEmpty) {
      throw ArgumentError('Journal entry ID cannot be empty');
    }

    // Check if entry exists before deletion
    final existingEntry = await txn.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (existingEntry.isEmpty) {
      throw DatabaseTransactionException('Cannot delete journal entry: entry with ID $id not found');
    }

    final result = await txn.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result == 0) {
      throw DatabaseTransactionException('Failed to delete journal entry: no rows affected');
    }
  }

  // Get entry count by month for statistics
  Future<Map<String, int>> getMonthlyEntryCounts(int year) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT strftime('%m', date) as month, COUNT(*) as count
        FROM journal_entries
        WHERE strftime('%Y', date) = ?
        GROUP BY strftime('%m', date)
        ORDER BY month
      ''', [year.toString()]);

      final Map<String, int> counts = {};
      for (final map in maps) {
        final month = map['month'] as String;
        final count = map['count'] as int;
        counts[month] = count;
      }

      return counts;
    } catch (e) {
      debugPrint('JournalDao.getMonthlyEntryCounts failed: $e');
      rethrow;
    }
  }

  // Get most common moods
  Future<Map<String, int>> getMoodFrequency() async {
    final entries = await getAllJournalEntries();
    final Map<String, int> moodCounts = {};

    for (final entry in entries) {
      for (final mood in entry.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    return moodCounts;
  }

  // Enhanced search functionality for full-text search
  Future<List<JournalEntry>> searchJournalEntriesFullText(String query) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'content LIKE ? OR personalizedInsight LIKE ? OR keyThemes LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.searchJournalEntriesFullText failed: $e');
      rethrow;
    }
  }

  // Get entries by AI detected moods
  Future<List<JournalEntry>> getJournalEntriesByAIMood(String mood) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'aiDetectedMoods LIKE ?',
        whereArgs: ['%"$mood"%'],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.getJournalEntriesByAIMood failed: $e');
      rethrow;
    }
  }

  // Get entries by emotional intensity range
  Future<List<JournalEntry>> getJournalEntriesByIntensityRange(
    double minIntensity,
    double maxIntensity,
  ) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'emotionalIntensity BETWEEN ? AND ?',
        whereArgs: [minIntensity, maxIntensity],
        orderBy: 'emotionalIntensity DESC, date DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.getJournalEntriesByIntensityRange failed: $e');
      rethrow;
    }
  }

  // Get entries by key themes
  Future<List<JournalEntry>> getJournalEntriesByTheme(String theme) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'keyThemes LIKE ?',
        whereArgs: ['%"$theme"%'],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.getJournalEntriesByTheme failed: $e');
      rethrow;
    }
  }

  // Get analyzed vs unanalyzed entries
  Future<List<JournalEntry>> getAnalyzedEntries({bool analyzed = true}) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'isAnalyzed = ?',
        whereArgs: [analyzed ? 1 : 0],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.getAnalyzedEntries failed: $e');
      rethrow;
    }
  }

  // Get entries with draft content (for crash recovery)
  Future<List<JournalEntry>> getEntriesWithDrafts() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: 'draftContent IS NOT NULL AND draftContent != ""',
        orderBy: 'updatedAt DESC',
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.getEntriesWithDrafts failed: $e');
      rethrow;
    }
  }

  // Combined search with multiple filters
  Future<List<JournalEntry>> searchJournalEntriesAdvanced({
    String? textQuery,
    List<String>? moods,
    List<String>? aiMoods,
    DateTime? startDate,
    DateTime? endDate,
    double? minIntensity,
    double? maxIntensity,
    bool? isAnalyzed,
    List<String>? themes,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];
      
      // Text search
      if (textQuery != null && textQuery.isNotEmpty) {
        whereConditions.add('(content LIKE ? OR personalizedInsight LIKE ? OR keyThemes LIKE ?)');
        whereArgs.addAll(['%$textQuery%', '%$textQuery%', '%$textQuery%']);
      }
      
      // Manual moods filter
      if (moods != null && moods.isNotEmpty) {
        final moodConditions = moods.map((_) => 'moods LIKE ?').join(' OR ');
        whereConditions.add('($moodConditions)');
        whereArgs.addAll(moods.map((mood) => '%$mood%'));
      }
      
      // AI detected moods filter
      if (aiMoods != null && aiMoods.isNotEmpty) {
        final aiMoodConditions = aiMoods.map((_) => 'aiDetectedMoods LIKE ?').join(' OR ');
        whereConditions.add('($aiMoodConditions)');
        whereArgs.addAll(aiMoods.map((mood) => '%"$mood"%'));
      }
      
      // Date range filter
      if (startDate != null && endDate != null) {
        whereConditions.add('date BETWEEN ? AND ?');
        whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
      } else if (startDate != null) {
        whereConditions.add('date >= ?');
        whereArgs.add(startDate.toIso8601String());
      } else if (endDate != null) {
        whereConditions.add('date <= ?');
        whereArgs.add(endDate.toIso8601String());
      }
      
      // Emotional intensity filter
      if (minIntensity != null && maxIntensity != null) {
        whereConditions.add('emotionalIntensity BETWEEN ? AND ?');
        whereArgs.addAll([minIntensity, maxIntensity]);
      } else if (minIntensity != null) {
        whereConditions.add('emotionalIntensity >= ?');
        whereArgs.add(minIntensity);
      } else if (maxIntensity != null) {
        whereConditions.add('emotionalIntensity <= ?');
        whereArgs.add(maxIntensity);
      }
      
      // Analysis status filter
      if (isAnalyzed != null) {
        whereConditions.add('isAnalyzed = ?');
        whereArgs.add(isAnalyzed ? 1 : 0);
      }
      
      // Themes filter
      if (themes != null && themes.isNotEmpty) {
        final themeConditions = themes.map((_) => 'keyThemes LIKE ?').join(' OR ');
        whereConditions.add('($themeConditions)');
        whereArgs.addAll(themes.map((theme) => '%"$theme"%'));
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        'journal_entries',
        where: whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => _mapToJournalEntry(map)).toList();
    } catch (e) {
      debugPrint('JournalDao.searchJournalEntriesAdvanced failed: $e');
      rethrow;
    }
  }

  // Transaction wrapper for atomic operations with comprehensive error handling
  Future<T> _executeInTransaction<T>(Future<T> Function(Transaction txn) operation) async {
    final db = await _dbHelper.database;
    
    try {
      return await db.transaction<T>((txn) async {
        try {
          return await operation(txn);
        } catch (e) {
          // Transaction will automatically rollback on exception
          // Log the specific operation error for debugging
          debugPrint('Journal transaction operation failed: ${e.toString()}');
          rethrow; // Let the transaction handle the rollback
        }
      });
    } on DatabaseException catch (e) {
      // Database-specific errors
      throw DatabaseTransactionException('Journal database transaction failed: ${e.toString()}');
    } on ArgumentError catch (e) {
      // Validation errors
      throw DatabaseValidationException('Journal transaction validation failed: ${e.message}');
    } catch (e) {
      // Generic errors
      throw DatabaseTransactionException('Journal transaction failed with unexpected error: ${e.toString()}');
    }
  }

  // Data validation before database operations
  void _validateJournalEntry(JournalEntry entry) {
    if (entry.content.trim().isEmpty) {
      throw ArgumentError('Journal entry content cannot be empty');
    }
    
    if (entry.userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    
    if (entry.moods.isEmpty) {
      throw ArgumentError('At least one mood must be selected');
    }
    
    // Validate mood values using centralized constants
    for (final mood in entry.moods) {
      if (!ValidationConstants.isValidMood(mood)) {
        throw ArgumentError('Invalid mood: $mood');
      }
    }
    
    // Validate content length using centralized constants
    if (entry.content.length > AppConstants.maxContentLength) {
      throw ArgumentError('Journal entry content is too long (max ${AppConstants.maxContentLength} characters)');
    }
  }

  // Atomic journal entry creation with core updates (for use by services)
  Future<String> insertJournalEntryWithCoreUpdates(
    JournalEntry entry,
    Map<String, double> coreUpdates,
  ) async {
    return await _executeInTransaction<String>((txn) async {
      // Insert the journal entry
      final entryId = await _insertJournalEntryInTransaction(txn, entry);
      
      // Validate and update emotional cores atomically
      await _updateCoresInTransaction(txn, coreUpdates);
      
      return entryId;
    });
  }

  // Atomic journal entry update with core updates (for use by services)
  Future<void> updateJournalEntryWithCoreUpdates(
    JournalEntry entry,
    Map<String, double> coreUpdates,
  ) async {
    await _executeInTransaction<void>((txn) async {
      // Update the journal entry
      await _updateJournalEntryInTransaction(txn, entry);
      
      // Validate and update emotional cores atomically
      await _updateCoresInTransaction(txn, coreUpdates);
    });
  }

  // Internal method for updating cores within a transaction with validation
  Future<void> _updateCoresInTransaction(Transaction txn, Map<String, double> coreUpdates) async {
    final now = DateTime.now().toIso8601String();
    
    for (final update in coreUpdates.entries) {
      final coreId = update.key;
      final newPercentage = update.value;
      
      // Validate core update data
      if (coreId.trim().isEmpty) {
        throw ArgumentError('Core ID cannot be empty');
      }
      
      if (newPercentage < 0.0 || newPercentage > 100.0) {
        throw ArgumentError('Core percentage must be between 0 and 100, got: $newPercentage');
      }
      
      // Check if core exists before updating
      final existingCore = await txn.query(
        'emotional_cores',
        where: 'id = ?',
        whereArgs: [coreId],
        limit: 1,
      );
      
      if (existingCore.isEmpty) {
        throw DatabaseTransactionException('Cannot update core: core with ID $coreId not found');
      }
      
      // Determine trend based on current vs new percentage
      final currentPercentage = existingCore.first['percentage'] as double;
      final trend = _determineTrend(currentPercentage, newPercentage);
      
      final result = await txn.update(
        'emotional_cores',
        {
          'percentage': newPercentage,
          'trend': trend,
          'updatedAt': now,
        },
        where: 'id = ?',
        whereArgs: [coreId],
      );
      
      if (result == 0) {
        throw DatabaseTransactionException('Failed to update core: no rows affected for core $coreId');
      }
    }
  }

  // Batch operations with transaction safety
  Future<List<String>> insertMultipleJournalEntries(List<JournalEntry> entries) async {
    return await _executeInTransaction<List<String>>((txn) async {
      final entryIds = <String>[];
      
      for (final entry in entries) {
        final entryId = await _insertJournalEntryInTransaction(txn, entry);
        entryIds.add(entryId);
      }
      
      return entryIds;
    });
  }

  Future<void> updateMultipleJournalEntries(List<JournalEntry> entries) async {
    await _executeInTransaction<void>((txn) async {
      for (final entry in entries) {
        await _updateJournalEntryInTransaction(txn, entry);
      }
    });
  }

  Future<void> deleteMultipleJournalEntries(List<String> ids) async {
    await _executeInTransaction<void>((txn) async {
      for (final id in ids) {
        await _deleteJournalEntryInTransaction(txn, id);
      }
    });
  }

  // Helper method to determine trend based on percentage change
  String _determineTrend(double oldPercentage, double newPercentage) {
    final difference = newPercentage - oldPercentage;
    if (difference > 0.1) return 'rising';
    if (difference < -0.1) return 'declining';
    return 'stable';
  }

  // Helper method to convert database map to JournalEntry
  JournalEntry _mapToJournalEntry(Map<String, dynamic> map) {
    // Parse metadata safely
    Map<String, dynamic> metadata = {};
    try {
      final metadataStr = map['metadata']?.toString() ?? '{}';
      if (metadataStr != '{}') {
        metadata = jsonDecode(metadataStr);
      }
    } catch (e) {
      metadata = {};
    }

    // Parse AI analysis safely
    EmotionalAnalysis? aiAnalysis;
    try {
      final aiAnalysisStr = map['aiAnalysis']?.toString();
      if (aiAnalysisStr != null && aiAnalysisStr.isNotEmpty) {
        aiAnalysis = EmotionalAnalysis.fromJson(jsonDecode(aiAnalysisStr));
      }
    } catch (e) {
      aiAnalysis = null;
    }

    // Parse AI detected moods safely
    List<String> aiDetectedMoods = [];
    try {
      final aiMoodsStr = map['aiDetectedMoods']?.toString() ?? '[]';
      aiDetectedMoods = List<String>.from(jsonDecode(aiMoodsStr));
    } catch (e) {
      aiDetectedMoods = [];
    }

    // Parse key themes safely
    List<String> keyThemes = [];
    try {
      final keyThemesStr = map['keyThemes']?.toString() ?? '[]';
      keyThemes = List<String>.from(jsonDecode(keyThemesStr));
    } catch (e) {
      keyThemes = [];
    }

    return JournalEntry(
      id: map['id'],
      userId: map['userId'] ?? 'local_user',
      date: DateTime.parse(map['date']),
      content: map['content'],
      moods: map['moods'].toString().split(',').where((m) => m.isNotEmpty).toList(),
      dayOfWeek: map['dayOfWeek'],
      createdAt: DateTime.parse(map['createdAt'] ?? map['date']),
      updatedAt: DateTime.parse(map['updatedAt'] ?? map['date']),
      isSynced: (map['isSynced'] ?? 1) == 1,
      metadata: metadata,
      aiAnalysis: aiAnalysis,
      isAnalyzed: (map['isAnalyzed'] ?? 0) == 1,
      draftContent: map['draftContent'],
      aiDetectedMoods: aiDetectedMoods,
      emotionalIntensity: map['emotionalIntensity']?.toDouble(),
      keyThemes: keyThemes,
      personalizedInsight: map['personalizedInsight'],
    );
  }
}