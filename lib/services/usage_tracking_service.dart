import 'dart:convert';
import '../database/database_helper.dart';
import '../config/environment.dart';
import '../utils/app_error_handler.dart';

/// Usage Tracking Service
/// 
/// Tracks API usage per month to enforce subscription limits and provide
/// analytics for the business model. Supports 30 journal analyses per month.
class UsageTrackingService {
  static final UsageTrackingService _instance = UsageTrackingService._internal();
  factory UsageTrackingService() => _instance;
  UsageTrackingService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  bool _isInitialized = false;

  /// Initialize the usage tracking service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _db.database; // Ensure database is initialized
    await _createUsageTrackingTables();
    _isInitialized = true;
  }

  /// Create usage tracking tables if they don't exist
  Future<void> _createUsageTrackingTables() async {
    final db = await _db.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monthly_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month_year TEXT NOT NULL,
        processed_journals INTEGER DEFAULT 0,
        api_calls INTEGER DEFAULT 0,
        tokens_used INTEGER DEFAULT 0,
        cost_estimate REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(month_year)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        journal_processed INTEGER DEFAULT 0,
        api_calls INTEGER DEFAULT 0,
        tokens_used INTEGER DEFAULT 0,
        processing_time_ms INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(date)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS usage_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        date TEXT NOT NULL,
        journal_id TEXT,
        tokens_input INTEGER DEFAULT 0,
        tokens_output INTEGER DEFAULT 0,
        processing_time_ms INTEGER DEFAULT 0,
        success INTEGER DEFAULT 1,
        error_message TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Get current month key (YYYY-MM format)
  String get _currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Get current date key (YYYY-MM-DD format)
  String get _currentDateKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if user can process another journal this month
  Future<bool> canProcessJournal() async {
    await initialize();
    
    try {
      final usage = await getCurrentMonthUsage();
      return usage.processedJournals < EnvironmentConfig.monthlyAnalysisLimit;
    } catch (e) {
      // If we can't check usage, allow processing (fail open)
      await AppErrorHandler().logError(
        'Failed to check usage limits',
        error: e,
        component: 'UsageTrackingService',
      );
      return true;
    }
  }

  /// Get remaining journal analyses for this month
  Future<int> getRemainingAnalyses() async {
    await initialize();
    
    try {
      final usage = await getCurrentMonthUsage();
      return (EnvironmentConfig.monthlyAnalysisLimit - usage.processedJournals).clamp(0, EnvironmentConfig.monthlyAnalysisLimit);
    } catch (e) {
      return EnvironmentConfig.monthlyAnalysisLimit; // Fail open
    }
  }

  /// Record a successful journal processing
  Future<void> recordJournalProcessing({
    required String journalId,
    required int tokensInput,
    required int tokensOutput,
    required int processingTimeMs,
    double? costEstimate,
  }) async {
    await initialize();
    
    return await AppErrorHandler().handleError(
      () async {
        final db = await _db.database;
        final now = DateTime.now();
        final monthKey = _currentMonthKey;
        final dateKey = _currentDateKey;

        await db.transaction((txn) async {
          // Update monthly usage
          await txn.execute('''
            INSERT OR REPLACE INTO monthly_usage (
              month_year, processed_journals, api_calls, tokens_used, cost_estimate, created_at, updated_at
            ) VALUES (
              ?, 
              COALESCE((SELECT processed_journals FROM monthly_usage WHERE month_year = ?), 0) + 1,
              COALESCE((SELECT api_calls FROM monthly_usage WHERE month_year = ?), 0) + 1,
              COALESCE((SELECT tokens_used FROM monthly_usage WHERE month_year = ?), 0) + ?,
              COALESCE((SELECT cost_estimate FROM monthly_usage WHERE month_year = ?), 0.0) + ?,
              COALESCE((SELECT created_at FROM monthly_usage WHERE month_year = ?), ?),
              ?
            )
          ''', [
            monthKey, monthKey, monthKey, monthKey, tokensInput + tokensOutput,
            monthKey, costEstimate ?? 0.0, monthKey, now.toIso8601String(), now.toIso8601String()
          ]);

          // Update daily usage
          await txn.execute('''
            INSERT OR REPLACE INTO daily_usage (
              date, journal_processed, api_calls, tokens_used, processing_time_ms, created_at, updated_at
            ) VALUES (
              ?,
              COALESCE((SELECT journal_processed FROM daily_usage WHERE date = ?), 0) + 1,
              COALESCE((SELECT api_calls FROM daily_usage WHERE date = ?), 0) + 1,
              COALESCE((SELECT tokens_used FROM daily_usage WHERE date = ?), 0) + ?,
              COALESCE((SELECT processing_time_ms FROM daily_usage WHERE date = ?), 0) + ?,
              COALESCE((SELECT created_at FROM daily_usage WHERE date = ?), ?),
              ?
            )
          ''', [
            dateKey, dateKey, dateKey, dateKey, tokensInput + tokensOutput,
            dateKey, processingTimeMs, dateKey, now.toIso8601String(), now.toIso8601String()
          ]);

          // Record usage event
          await txn.execute('''
            INSERT INTO usage_events (
              event_type, date, journal_id, tokens_input, tokens_output, 
              processing_time_ms, success, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, 1, ?)
          ''', [
            'journal_processing', dateKey, journalId, tokensInput, tokensOutput,
            processingTimeMs, now.toIso8601String()
          ]);
        });
      },
      operationName: 'recordJournalProcessing',
      component: 'UsageTrackingService',
      context: {
        'journalId': journalId,
        'tokensInput': tokensInput,
        'tokensOutput': tokensOutput,
      },
    );
  }

  /// Record a failed processing attempt
  Future<void> recordProcessingFailure({
    required String journalId,
    required String errorMessage,
    int processingTimeMs = 0,
  }) async {
    await initialize();
    
    return await AppErrorHandler().handleError(
      () async {
        final db = await _db.database;
        final now = DateTime.now();
        final dateKey = _currentDateKey;

        await db.execute('''
          INSERT INTO usage_events (
            event_type, date, journal_id, processing_time_ms, success, error_message, created_at
          ) VALUES (?, ?, ?, ?, 0, ?, ?)
        ''', [
          'journal_processing_failed', dateKey, journalId, processingTimeMs, errorMessage, now.toIso8601String()
        ]);
      },
      operationName: 'recordProcessingFailure',
      component: 'UsageTrackingService',
      context: {
        'journalId': journalId,
        'errorMessage': errorMessage,
      },
    );
  }

  /// Get current month's usage statistics
  Future<MonthlyUsage> getCurrentMonthUsage() async {
    await initialize();
    
    final db = await _db.database;
    final monthKey = _currentMonthKey;
    
    final result = await db.query(
      'monthly_usage',
      where: 'month_year = ?',
      whereArgs: [monthKey],
    );

    if (result.isEmpty) {
      return MonthlyUsage(
        monthYear: monthKey,
        processedJournals: 0,
        apiCalls: 0,
        tokensUsed: 0,
        costEstimate: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return MonthlyUsage.fromJson(result.first);
  }

  /// Get usage statistics for a specific month
  Future<MonthlyUsage?> getMonthUsage(String monthYear) async {
    await initialize();
    
    final db = await _db.database;
    final result = await db.query(
      'monthly_usage',
      where: 'month_year = ?',
      whereArgs: [monthYear],
    );

    if (result.isEmpty) return null;
    return MonthlyUsage.fromJson(result.first);
  }

  /// Get daily usage for today
  Future<DailyUsage> getTodayUsage() async {
    await initialize();
    
    final db = await _db.database;
    final dateKey = _currentDateKey;
    
    final result = await db.query(
      'daily_usage',
      where: 'date = ?',
      whereArgs: [dateKey],
    );

    if (result.isEmpty) {
      return DailyUsage(
        date: dateKey,
        journalProcessed: 0,
        apiCalls: 0,
        tokensUsed: 0,
        processingTimeMs: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return DailyUsage.fromJson(result.first);
  }

  /// Get usage history for the last N months
  Future<List<MonthlyUsage>> getUsageHistory({int months = 6}) async {
    await initialize();
    
    final db = await _db.database;
    final result = await db.query(
      'monthly_usage',
      orderBy: 'month_year DESC',
      limit: months,
    );

    return result.map((row) => MonthlyUsage.fromJson(row)).toList();
  }

  /// Get recent usage events
  Future<List<UsageEvent>> getRecentEvents({int limit = 50}) async {
    await initialize();
    
    final db = await _db.database;
    final result = await db.query(
      'usage_events',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return result.map((row) => UsageEvent.fromJson(row)).toList();
  }

  /// Reset monthly usage (for testing or manual reset)
  Future<void> resetMonthlyUsage([String? monthYear]) async {
    await initialize();
    
    final db = await _db.database;
    final targetMonth = monthYear ?? _currentMonthKey;
    
    await db.delete(
      'monthly_usage',
      where: 'month_year = ?',
      whereArgs: [targetMonth],
    );
  }

  /// Get usage analytics for business insights
  Future<UsageAnalytics> getUsageAnalytics() async {
    await initialize();
    
    final db = await _db.database;
    
    // Get total usage across all time
    final totalResult = await db.rawQuery('''
      SELECT 
        SUM(processed_journals) as total_processed,
        SUM(api_calls) as total_api_calls,
        SUM(tokens_used) as total_tokens,
        SUM(cost_estimate) as total_cost,
        COUNT(*) as active_months
      FROM monthly_usage
    ''');

    // Get current month usage
    final currentMonth = await getCurrentMonthUsage();
    
    // Get average daily processing
    final avgDailyResult = await db.rawQuery('''
      SELECT AVG(journal_processed) as avg_daily_processing
      FROM daily_usage
      WHERE journal_processed > 0
    ''');

    final totalRow = totalResult.first;
    final avgDaily = avgDailyResult.first['avg_daily_processing'] as double? ?? 0.0;

    return UsageAnalytics(
      totalProcessedJournals: totalRow['total_processed'] as int? ?? 0,
      totalApiCalls: totalRow['total_api_calls'] as int? ?? 0,
      totalTokensUsed: totalRow['total_tokens'] as int? ?? 0,
      totalCostEstimate: totalRow['total_cost'] as double? ?? 0.0,
      activeMonths: totalRow['active_months'] as int? ?? 0,
      currentMonthUsage: currentMonth,
      averageDailyProcessing: avgDaily,
    );
  }
}

/// Monthly usage statistics
class MonthlyUsage {
  final String monthYear;
  final int processedJournals;
  final int apiCalls;
  final int tokensUsed;
  final double costEstimate;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyUsage({
    required this.monthYear,
    required this.processedJournals,
    required this.apiCalls,
    required this.tokensUsed,
    required this.costEstimate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MonthlyUsage.fromJson(Map<String, dynamic> json) {
    return MonthlyUsage(
      monthYear: json['month_year'],
      processedJournals: json['processed_journals'] ?? 0,
      apiCalls: json['api_calls'] ?? 0,
      tokensUsed: json['tokens_used'] ?? 0,
      costEstimate: (json['cost_estimate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isAtLimit => processedJournals >= EnvironmentConfig.monthlyAnalysisLimit;
  int get remainingAnalyses => (EnvironmentConfig.monthlyAnalysisLimit - processedJournals).clamp(0, EnvironmentConfig.monthlyAnalysisLimit);
}

/// Daily usage statistics
class DailyUsage {
  final String date;
  final int journalProcessed;
  final int apiCalls;
  final int tokensUsed;
  final int processingTimeMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyUsage({
    required this.date,
    required this.journalProcessed,
    required this.apiCalls,
    required this.tokensUsed,
    required this.processingTimeMs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      date: json['date'],
      journalProcessed: json['journal_processed'] ?? 0,
      apiCalls: json['api_calls'] ?? 0,
      tokensUsed: json['tokens_used'] ?? 0,
      processingTimeMs: json['processing_time_ms'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Individual usage event
class UsageEvent {
  final String eventType;
  final String date;
  final String? journalId;
  final int tokensInput;
  final int tokensOutput;
  final int processingTimeMs;
  final bool success;
  final String? errorMessage;
  final DateTime createdAt;

  UsageEvent({
    required this.eventType,
    required this.date,
    this.journalId,
    required this.tokensInput,
    required this.tokensOutput,
    required this.processingTimeMs,
    required this.success,
    this.errorMessage,
    required this.createdAt,
  });

  factory UsageEvent.fromJson(Map<String, dynamic> json) {
    return UsageEvent(
      eventType: json['event_type'],
      date: json['date'],
      journalId: json['journal_id'],
      tokensInput: json['tokens_input'] ?? 0,
      tokensOutput: json['tokens_output'] ?? 0,
      processingTimeMs: json['processing_time_ms'] ?? 0,
      success: (json['success'] ?? 1) == 1,
      errorMessage: json['error_message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Overall usage analytics
class UsageAnalytics {
  final int totalProcessedJournals;
  final int totalApiCalls;
  final int totalTokensUsed;
  final double totalCostEstimate;
  final int activeMonths;
  final MonthlyUsage currentMonthUsage;
  final double averageDailyProcessing;

  UsageAnalytics({
    required this.totalProcessedJournals,
    required this.totalApiCalls,
    required this.totalTokensUsed,
    required this.totalCostEstimate,
    required this.activeMonths,
    required this.currentMonthUsage,
    required this.averageDailyProcessing,
  });
}
