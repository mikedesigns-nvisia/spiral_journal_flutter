import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/daily_journal.dart';
import '../config/environment.dart';
import '../utils/app_error_handler.dart';

/// Daily Journal Service
/// 
/// Manages daily journal entries with continuous auto-saving functionality.
/// Handles one journal per day that can be updated throughout the day.
class DailyJournalService {
  static final DailyJournalService _instance = DailyJournalService._internal();
  factory DailyJournalService() => _instance;
  DailyJournalService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  bool _isInitialized = false;
  Timer? _autoSaveTimer;
  DailyJournal? _currentJournal;
  String _pendingContent = '';
  List<String> _pendingMoods = [];
  bool _hasPendingChanges = false;

  /// Initialize the daily journal service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _db.database; // Ensure database is initialized
    await _createDailyJournalTable();
    await _loadTodaysJournal();
    _startAutoSaveTimer();
    _isInitialized = true;
  }

  /// Create daily journal table if it doesn't exist
  Future<void> _createDailyJournalTable() async {
    final db = await _db.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_journals (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        content TEXT DEFAULT '',
        moods TEXT DEFAULT '[]',
        is_processed INTEGER DEFAULT 0,
        processed_at TEXT,
        ai_analysis TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(date)
      )
    ''');

    // Create index for faster date queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_daily_journals_date ON daily_journals(date)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_daily_journals_processed ON daily_journals(is_processed)
    ''');
  }

  /// Load today's journal from database or create new one
  Future<void> _loadTodaysJournal() async {
    final today = DateTime.now();
    final todayKey = DailyJournal.forToday().dateKey;
    
    final db = await _db.database;
    final result = await db.query(
      'daily_journals',
      where: 'date = ?',
      whereArgs: [todayKey],
    );

    if (result.isNotEmpty) {
      _currentJournal = DailyJournal.fromJson(result.first);
      _pendingContent = _currentJournal!.content;
      _pendingMoods = List.from(_currentJournal!.moods);
    } else {
      _currentJournal = DailyJournal.forToday();
      _pendingContent = '';
      _pendingMoods = [];
    }
    
    _hasPendingChanges = false;
  }

  /// Start the auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(EnvironmentConfig.autoSaveInterval, (_) {
      if (_hasPendingChanges) {
        _saveCurrentJournal();
      }
    });
  }

  /// Stop the auto-save timer
  void _stopAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Get today's journal
  Future<DailyJournal> getTodaysJournal() async {
    await initialize();
    
    // Check if we need to create a new journal for today
    if (_currentJournal == null || !_currentJournal!.isToday) {
      await _loadTodaysJournal();
    }
    
    // Return journal with pending changes applied
    return _currentJournal!.copyWith(
      content: _pendingContent,
      moods: _pendingMoods,
    );
  }

  /// Update journal content (triggers auto-save)
  Future<void> updateContent(String content) async {
    await initialize();
    
    if (_pendingContent != content) {
      _pendingContent = content;
      _hasPendingChanges = true;
    }
  }

  /// Update journal moods (triggers auto-save)
  Future<void> updateMoods(List<String> moods) async {
    await initialize();
    
    if (!_listsEqual(_pendingMoods, moods)) {
      _pendingMoods = List.from(moods);
      _hasPendingChanges = true;
    }
  }

  /// Add a mood to the current journal
  Future<void> addMood(String mood) async {
    await initialize();
    
    if (!_pendingMoods.contains(mood)) {
      _pendingMoods.add(mood);
      _hasPendingChanges = true;
    }
  }

  /// Remove a mood from the current journal
  Future<void> removeMood(String mood) async {
    await initialize();
    
    if (_pendingMoods.remove(mood)) {
      _hasPendingChanges = true;
    }
  }

  /// Force save current journal immediately
  Future<void> saveNow() async {
    await initialize();
    await _saveCurrentJournal();
  }

  /// Save current journal to database
  Future<void> _saveCurrentJournal() async {
    if (_currentJournal == null) return;
    
    return await AppErrorHandler().handleError(
      () async {
        final updatedJournal = _currentJournal!.copyWith(
          content: _pendingContent,
          moods: _pendingMoods,
        );

        final db = await _db.database;
        await db.insert(
          'daily_journals',
          updatedJournal.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        _currentJournal = updatedJournal;
        _hasPendingChanges = false;
      },
      operationName: 'saveCurrentJournal',
      component: 'DailyJournalService',
      context: {
        'journalId': _currentJournal!.id,
        'contentLength': _pendingContent.length,
        'moodCount': _pendingMoods.length,
      },
    );
  }

  /// Get journal for a specific date
  Future<DailyJournal?> getJournalForDate(DateTime date) async {
    await initialize();
    
    final dateKey = DailyJournal.forDate(date).dateKey;
    final db = await _db.database;
    
    final result = await db.query(
      'daily_journals',
      where: 'date = ?',
      whereArgs: [dateKey],
    );

    if (result.isEmpty) return null;
    return DailyJournal.fromJson(result.first);
  }

  /// Get journals for a date range
  Future<List<DailyJournal>> getJournalsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await initialize();
    
    final startKey = DailyJournal.forDate(startDate).dateKey;
    final endKey = DailyJournal.forDate(endDate).dateKey;
    
    final db = await _db.database;
    final result = await db.query(
      'daily_journals',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'date DESC',
    );

    return result.map((row) => DailyJournal.fromJson(row)).toList();
  }

  /// Get recent journals (last N days)
  Future<List<DailyJournal>> getRecentJournals({int days = 30}) async {
    await initialize();
    
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    return await getJournalsInRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get journals that need processing (unprocessed and not today)
  Future<List<DailyJournal>> getJournalsNeedingProcessing() async {
    await initialize();
    
    final db = await _db.database;
    final today = DailyJournal.forToday().dateKey;
    
    final result = await db.query(
      'daily_journals',
      where: 'is_processed = 0 AND date < ? AND (content != "" OR moods != "[]")',
      whereArgs: [today],
      orderBy: 'date ASC',
    );

    return result.map((row) => DailyJournal.fromJson(row)).toList();
  }

  /// Mark a journal as processed with AI analysis
  Future<void> markJournalAsProcessed({
    required String journalId,
    required Map<String, dynamic> aiAnalysis,
  }) async {
    await initialize();
    
    return await AppErrorHandler().handleError(
      () async {
        final db = await _db.database;
        final now = DateTime.now();
        
        await db.update(
          'daily_journals',
          {
            'is_processed': 1,
            'processed_at': now.toIso8601String(),
            'ai_analysis': jsonEncode(aiAnalysis),
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [journalId],
        );
      },
      operationName: 'markJournalAsProcessed',
      component: 'DailyJournalService',
      context: {
        'journalId': journalId,
        'analysisKeys': aiAnalysis.keys.toList(),
      },
    );
  }

  /// Get journal statistics
  Future<JournalStatistics> getStatistics() async {
    await initialize();
    
    final db = await _db.database;
    
    // Get total counts
    final totalResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_journals,
        COUNT(CASE WHEN content != "" OR moods != "[]" THEN 1 END) as journals_with_content,
        COUNT(CASE WHEN is_processed = 1 THEN 1 END) as processed_journals,
        SUM(LENGTH(content)) as total_characters,
        AVG(LENGTH(content)) as avg_characters
      FROM daily_journals
    ''');

    // Get current streak
    final streakResult = await db.rawQuery('''
      SELECT COUNT(*) as current_streak
      FROM daily_journals 
      WHERE date >= date('now', '-' || (
        SELECT COUNT(*) 
        FROM daily_journals d2 
        WHERE d2.date > daily_journals.date 
        AND (d2.content = "" AND d2.moods = "[]")
      ) || ' days')
      AND (content != "" OR moods != "[]")
      ORDER BY date DESC
    ''');

    final totalRow = totalResult.first;
    final currentStreak = streakResult.first['current_streak'] as int? ?? 0;

    return JournalStatistics(
      totalJournals: totalRow['total_journals'] as int? ?? 0,
      journalsWithContent: totalRow['journals_with_content'] as int? ?? 0,
      processedJournals: totalRow['processed_journals'] as int? ?? 0,
      totalCharacters: totalRow['total_characters'] as int? ?? 0,
      averageCharacters: (totalRow['avg_characters'] as double?)?.round() ?? 0,
      currentStreak: currentStreak,
    );
  }

  /// Search journals by content
  Future<List<DailyJournal>> searchJournals(String query) async {
    await initialize();
    
    if (query.trim().isEmpty) return [];
    
    final db = await _db.database;
    final result = await db.query(
      'daily_journals',
      where: 'content LIKE ? OR moods LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
      limit: 50,
    );

    return result.map((row) => DailyJournal.fromJson(row)).toList();
  }

  /// Delete a journal
  Future<void> deleteJournal(String journalId) async {
    await initialize();
    
    return await AppErrorHandler().handleError(
      () async {
        final db = await _db.database;
        await db.delete(
          'daily_journals',
          where: 'id = ?',
          whereArgs: [journalId],
        );

        // If this was today's journal, reset current state
        if (_currentJournal?.id == journalId) {
          _currentJournal = DailyJournal.forToday();
          _pendingContent = '';
          _pendingMoods = [];
          _hasPendingChanges = false;
        }
      },
      operationName: 'deleteJournal',
      component: 'DailyJournalService',
      context: {'journalId': journalId},
    );
  }

  /// Export all journals
  Future<List<DailyJournal>> exportAllJournals() async {
    await initialize();
    
    final db = await _db.database;
    final result = await db.query(
      'daily_journals',
      orderBy: 'date ASC',
    );

    return result.map((row) => DailyJournal.fromJson(row)).toList();
  }

  /// Clear all journals (for data deletion)
  Future<void> clearAllJournals() async {
    await initialize();
    
    return await AppErrorHandler().handleError(
      () async {
        final db = await _db.database;
        await db.delete('daily_journals');
        
        // Reset current state
        _currentJournal = DailyJournal.forToday();
        _pendingContent = '';
        _pendingMoods = [];
        _hasPendingChanges = false;
      },
      operationName: 'clearAllJournals',
      component: 'DailyJournalService',
    );
  }

  /// Dispose of the service
  void dispose() {
    _stopAutoSaveTimer();
    if (_hasPendingChanges) {
      _saveCurrentJournal(); // Fire and forget final save
    }
  }

  /// Helper method to compare lists
  bool _listsEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Journal statistics
class JournalStatistics {
  final int totalJournals;
  final int journalsWithContent;
  final int processedJournals;
  final int totalCharacters;
  final int averageCharacters;
  final int currentStreak;

  JournalStatistics({
    required this.totalJournals,
    required this.journalsWithContent,
    required this.processedJournals,
    required this.totalCharacters,
    required this.averageCharacters,
    required this.currentStreak,
  });

  double get completionRate {
    if (totalJournals == 0) return 0.0;
    return journalsWithContent / totalJournals;
  }

  double get processingRate {
    if (journalsWithContent == 0) return 0.0;
    return processedJournals / journalsWithContent;
  }
}
