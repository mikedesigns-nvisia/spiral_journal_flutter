import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:async';
import '../database/database_helper.dart';

/// Local analytics service for TestFlight feedback and crash reporting
/// All data is stored locally on device, no external services used
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  SharedPreferences? _prefs;
  Database? _analyticsDb;
  bool _isInitialized = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Initialize local analytics and crash reporting with SQLite database
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _initializeAnalyticsDatabase();
      _isInitialized = true;
      
      // Log app initialization locally
      await logEvent('app_initialized', {
        'platform': defaultTargetPlatform.name,
        'debug_mode': kDebugMode,
      });
    } catch (e) {
      // Gracefully handle initialization failures
      debugPrint('Analytics initialization failed: $e');
    }
  }

  /// Initialize dedicated analytics SQLite database
  Future<void> _initializeAnalyticsDatabase() async {
    try {
      final db = await _databaseHelper.database;
      _analyticsDb = db;
      
      // Create analytics tables if they don't exist
      await _createAnalyticsTables();
    } catch (e) {
      debugPrint('Failed to initialize analytics database: $e');
    }
  }

  /// Create analytics-specific tables in the existing database
  Future<void> _createAnalyticsTables() async {
    if (_analyticsDb == null) return;
    
    try {
      // Haiku API usage tracking table
      await _analyticsDb!.execute('''
        CREATE TABLE IF NOT EXISTS haiku_api_usage (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL DEFAULT 'local_user',
          model_name TEXT NOT NULL,
          input_tokens INTEGER NOT NULL,
          output_tokens INTEGER NOT NULL,
          estimated_cost REAL NOT NULL,
          request_type TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          success INTEGER NOT NULL DEFAULT 1,
          error_message TEXT,
          processing_time_ms INTEGER
        )
      ''');
      
      // UI interaction events table
      await _analyticsDb!.execute('''
        CREATE TABLE IF NOT EXISTS ui_interactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL DEFAULT 'local_user',
          component_type TEXT NOT NULL,
          component_id TEXT,
          action_type TEXT NOT NULL,
          interaction_data TEXT,
          timestamp TEXT NOT NULL,
          session_id TEXT,
          screen_name TEXT
        )
      ''');
      
      // Performance metrics table
      await _analyticsDb!.execute('''
        CREATE TABLE IF NOT EXISTS performance_metrics (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL DEFAULT 'local_user',
          metric_type TEXT NOT NULL,
          metric_name TEXT NOT NULL,
          value REAL NOT NULL,
          unit TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          context_data TEXT,
          session_id TEXT
        )
      ''');
      
      // Feature adoption tracking table
      await _analyticsDb!.execute('''
        CREATE TABLE IF NOT EXISTS feature_adoption (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL DEFAULT 'local_user',
          feature_name TEXT NOT NULL,
          first_used_at TEXT NOT NULL,
          last_used_at TEXT NOT NULL,
          usage_count INTEGER NOT NULL DEFAULT 1,
          adoption_stage TEXT NOT NULL,
          feature_version TEXT,
          context_data TEXT
        )
      ''');
      
      // Create indexes for better query performance
      await _analyticsDb!.execute('CREATE INDEX IF NOT EXISTS idx_haiku_timestamp ON haiku_api_usage(timestamp)');
      await _analyticsDb!.execute('CREATE INDEX IF NOT EXISTS idx_haiku_user ON haiku_api_usage(user_id)');
      await _analyticsDb!.execute('CREATE INDEX IF NOT EXISTS idx_ui_timestamp ON ui_interactions(timestamp)');
      await _analyticsDb!.execute('CREATE INDEX IF NOT EXISTS idx_ui_component ON ui_interactions(component_type)');
      await _analyticsDb!.execute('CREATE INDEX IF NOT EXISTS idx_performance_timestamp ON performance_metrics(timestamp)');
      await _analyticsDb!.execute('CREATE INDEX IF NOT EXISTS idx_performance_type ON performance_metrics(metric_type)');
      await _analyticsDb!.execute('CREATE INDEX IF NOT EXISTS idx_feature_name ON feature_adoption(feature_name)');
      await _analyticsDb!.execute('CREATE INDEX IF NOT EXISTS idx_feature_user ON feature_adoption(user_id)');
      
      debugPrint('📊 Analytics database tables initialized successfully');
    } catch (e) {
      debugPrint('Failed to create analytics tables: $e');
    }
  }

  /// Log custom events for TestFlight feedback (stored locally)
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    if (!_isInitialized || _prefs == null) return;
    
    try {
      final event = {
        'name': name,
        'parameters': parameters ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Store events locally in SharedPreferences
      final events = _prefs!.getStringList('analytics_events') ?? [];
      events.add(jsonEncode(event));
      
      // Keep only last 1000 events to prevent storage bloat
      if (events.length > 1000) {
        events.removeRange(0, events.length - 1000);
      }
      
      await _prefs!.setStringList('analytics_events', events);
    } catch (e) {
      debugPrint('Failed to log event $name: $e');
    }
  }

  /// Log journal-related events
  Future<void> logJournalEvent(String action, {Map<String, dynamic>? extra}) async {
    await logEvent('journal_$action', {
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log AI analysis events
  Future<void> logAIEvent(String action, {Map<String, dynamic>? extra}) async {
    await logEvent('ai_$action', {
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log authentication events
  Future<void> logAuthEvent(String action, {Map<String, dynamic>? extra}) async {
    await logEvent('auth_$action', {
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log theme events
  Future<void> logThemeEvent(String action, {Map<String, dynamic>? extra}) async {
    await logEvent('theme_$action', {
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log core library events
  Future<void> logCoreEvent(String action, {Map<String, dynamic>? extra}) async {
    await logEvent('core_$action', {
      'timestamp': DateTime.now().toIso8601String(),
      ...?extra,
    });
  }

  /// Log performance metrics
  Future<void> logPerformance(String operation, Duration duration) async {
    await logEvent('performance_$operation', {
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log errors for debugging (stored locally)
  Future<void> logError(String error, {String? context, StackTrace? stackTrace}) async {
    if (!_isInitialized || _prefs == null) return;
    
    try {
      // Store error logs locally
      final errorLog = {
        'error': error.toString(),
        'context': context ?? 'No context provided',
        'stack_trace': stackTrace?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final errorLogs = _prefs!.getStringList('error_logs') ?? [];
      errorLogs.add(jsonEncode(errorLog));
      
      // Keep only last 500 error logs
      if (errorLogs.length > 500) {
        errorLogs.removeRange(0, errorLogs.length - 500);
      }
      
      await _prefs!.setStringList('error_logs', errorLogs);
      
      await logEvent('error_logged', {
        'error_type': error.runtimeType.toString(),
        'context': context ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to log error: $e');
    }
  }

  /// Log fatal crashes (stored locally)
  Future<void> logFatalError(String error, StackTrace stackTrace, {String? context}) async {
    if (!_isInitialized || _prefs == null) return;
    
    try {
      // Store fatal error logs locally
      final fatalErrorLog = {
        'error': error.toString(),
        'context': context ?? 'Fatal error occurred',
        'stack_trace': stackTrace.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'fatal': true,
      };
      
      final errorLogs = _prefs!.getStringList('error_logs') ?? [];
      errorLogs.add(jsonEncode(fatalErrorLog));
      
      // Keep only last 500 error logs
      if (errorLogs.length > 500) {
        errorLogs.removeRange(0, errorLogs.length - 500);
      }
      
      await _prefs!.setStringList('error_logs', errorLogs);
    } catch (e) {
      debugPrint('Failed to log fatal error: $e');
    }
  }

  /// Set user properties for better crash analysis (stored locally)
  Future<void> setUserProperties({
    String? userId,
    bool? hasPin,
    String? themeMode,
    bool? personalizedInsights,
  }) async {
    if (!_isInitialized || _prefs == null) return;
    
    try {
      // Store user properties locally
      final userProperties = {
        'user_id': userId,
        'has_pin_auth': hasPin?.toString(),
        'theme_mode': themeMode,
        'personalized_insights': personalizedInsights?.toString(),
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      await _prefs!.setString('user_properties', jsonEncode(userProperties));
    } catch (e) {
      debugPrint('Failed to set user properties: $e');
    }
  }

  /// Log app launch time for performance monitoring
  Future<void> logAppLaunchTime(Duration launchTime) async {
    await logEvent('app_launch_time', {
      'launch_duration_ms': launchTime.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log TestFlight specific events with enhanced tracking
  Future<void> logTestFlightEvent(String action, {Map<String, dynamic>? extra}) async {
    await logEvent('testflight_$action', {
      'build_mode': 'testflight',
      'timestamp': DateTime.now().toIso8601String(),
      'device_model': defaultTargetPlatform.name,
      'app_version': '1.0.0',
      'build_number': '1',
      ...?extra,
    });
  }
  
  /// Log TestFlight user session data
  Future<void> logTestFlightSession({
    required String sessionId,
    required Duration sessionDuration,
    required int screensViewed,
    required List<String> featuresUsed,
  }) async {
    await logTestFlightEvent('session_completed', extra: {
      'session_id': sessionId,
      'session_duration_seconds': sessionDuration.inSeconds,
      'screens_viewed': screensViewed,
      'features_used': featuresUsed,
      'session_end': DateTime.now().toIso8601String(),
    });
  }
  
  /// Log TestFlight user journey milestone
  Future<void> logTestFlightMilestone(String milestone, {Map<String, dynamic>? context}) async {
    await logTestFlightEvent('milestone_reached', extra: {
      'milestone': milestone,
      'milestone_timestamp': DateTime.now().toIso8601String(),
      ...?context,
    });
  }

  // MARK: - Haiku API Usage and Cost Tracking

  /// Track Haiku API usage and costs per user
  Future<void> trackHaikuAPIUsage({
    required String modelName,
    required int inputTokens,
    required int outputTokens,
    required String requestType,
    required bool success,
    String? errorMessage,
    int? processingTimeMs,
    String? userId,
  }) async {
    if (!_isInitialized || _analyticsDb == null) return;
    
    try {
      final estimatedCost = _calculateHaikuCost(inputTokens, outputTokens);
      
      await _analyticsDb!.insert('haiku_api_usage', {
        'user_id': userId ?? 'local_user',
        'model_name': modelName,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'estimated_cost': estimatedCost,
        'request_type': requestType,
        'timestamp': DateTime.now().toIso8601String(),
        'success': success ? 1 : 0,
        'error_message': errorMessage,
        'processing_time_ms': processingTimeMs,
      });
      
      if (kDebugMode) {
        debugPrint('💰 Haiku API usage tracked: $modelName, tokens: $inputTokens/$outputTokens, cost: \$${estimatedCost.toStringAsFixed(4)}');
      }
    } catch (e) {
      debugPrint('Failed to track Haiku API usage: $e');
    }
  }

  /// Calculate estimated cost for Haiku API usage
  double _calculateHaikuCost(int inputTokens, int outputTokens) {
    // Haiku pricing: $0.25 per 1M input tokens, $1.25 per 1M output tokens
    const inputCostPer1M = 0.25;
    const outputCostPer1M = 1.25;
    
    final inputCost = (inputTokens / 1000000) * inputCostPer1M;
    final outputCost = (outputTokens / 1000000) * outputCostPer1M;
    
    return inputCost + outputCost;
  }

  /// Get Haiku API usage statistics
  Future<Map<String, dynamic>> getHaikuUsageStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized || _analyticsDb == null) {
      return {
        'totalRequests': 0,
        'totalCost': 0.0,
        'totalTokens': 0,
        'successRate': 0.0,
        'averageProcessingTime': 0.0,
      };
    }
    
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId ?? 'local_user'];
      
      if (startDate != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereClause += ' AND timestamp <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      final results = await _analyticsDb!.query(
        'haiku_api_usage',
        where: whereClause,
        whereArgs: whereArgs,
      );
      
      if (results.isEmpty) {
        return {
          'totalRequests': 0,
          'totalCost': 0.0,
          'totalTokens': 0,
          'successRate': 0.0,
          'averageProcessingTime': 0.0,
        };
      }
      
      final totalRequests = results.length;
      final totalCost = results.fold<double>(0.0, (sum, row) => sum + (row['estimated_cost'] as double? ?? 0.0));
      final totalInputTokens = results.fold<int>(0, (sum, row) => sum + (row['input_tokens'] as int? ?? 0));
      final totalOutputTokens = results.fold<int>(0, (sum, row) => sum + (row['output_tokens'] as int? ?? 0));
      final successfulRequests = results.where((row) => (row['success'] as int? ?? 0) == 1).length;
      final processingTimes = results.where((row) => row['processing_time_ms'] != null)
          .map((row) => row['processing_time_ms'] as int).toList();
      
      return {
        'totalRequests': totalRequests,
        'totalCost': totalCost,
        'totalInputTokens': totalInputTokens,
        'totalOutputTokens': totalOutputTokens,
        'totalTokens': totalInputTokens + totalOutputTokens,
        'successRate': totalRequests > 0 ? successfulRequests / totalRequests : 0.0,
        'averageProcessingTime': processingTimes.isNotEmpty 
            ? processingTimes.reduce((a, b) => a + b) / processingTimes.length 
            : 0.0,
        'costPerRequest': totalRequests > 0 ? totalCost / totalRequests : 0.0,
        'requestTypes': _getRequestTypeBreakdown(results),
        'dailyUsage': _getDailyUsageBreakdown(results),
      };
    } catch (e) {
      debugPrint('Failed to get Haiku usage stats: $e');
      return {
        'totalRequests': 0,
        'totalCost': 0.0,
        'totalTokens': 0,
        'successRate': 0.0,
        'averageProcessingTime': 0.0,
      };
    }
  }

  Map<String, int> _getRequestTypeBreakdown(List<Map<String, dynamic>> results) {
    final breakdown = <String, int>{};
    for (final row in results) {
      final requestType = row['request_type'] as String? ?? 'unknown';
      breakdown[requestType] = (breakdown[requestType] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, double> _getDailyUsageBreakdown(List<Map<String, dynamic>> results) {
    final breakdown = <String, double>{};
    for (final row in results) {
      final timestamp = row['timestamp'] as String?;
      if (timestamp != null) {
        final date = DateTime.parse(timestamp);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final cost = row['estimated_cost'] as double? ?? 0.0;
        breakdown[dateKey] = (breakdown[dateKey] ?? 0.0) + cost;
      }
    }
    return breakdown;
  }

  // MARK: - UI Interaction Tracking

  /// Track interaction events on new UI components
  Future<void> trackUIInteraction({
    required String componentType,
    required String actionType,
    String? componentId,
    Map<String, dynamic>? interactionData,
    String? sessionId,
    String? screenName,
    String? userId,
  }) async {
    if (!_isInitialized || _analyticsDb == null) return;
    
    try {
      await _analyticsDb!.insert('ui_interactions', {
        'user_id': userId ?? 'local_user',
        'component_type': componentType,
        'component_id': componentId,
        'action_type': actionType,
        'interaction_data': interactionData != null ? jsonEncode(interactionData) : null,
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': sessionId ?? _getCurrentSessionId(),
        'screen_name': screenName,
      });
      
      if (kDebugMode) {
        debugPrint('🖱️ UI interaction tracked: $componentType.$actionType on $screenName');
      }
    } catch (e) {
      debugPrint('Failed to track UI interaction: $e');
    }
  }

  /// Get UI interaction statistics
  Future<Map<String, dynamic>> getUIInteractionStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? componentType,
  }) async {
    if (!_isInitialized || _analyticsDb == null) {
      return {
        'totalInteractions': 0,
        'uniqueComponents': 0,
        'topComponents': <String, int>{},
        'topActions': <String, int>{},
        'screenBreakdown': <String, int>{},
      };
    }
    
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId ?? 'local_user'];
      
      if (startDate != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereClause += ' AND timestamp <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      if (componentType != null) {
        whereClause += ' AND component_type = ?';
        whereArgs.add(componentType);
      }
      
      final results = await _analyticsDb!.query(
        'ui_interactions',
        where: whereClause,
        whereArgs: whereArgs,
      );
      
      if (results.isEmpty) {
        return {
          'totalInteractions': 0,
          'uniqueComponents': 0,
          'topComponents': <String, int>{},
          'topActions': <String, int>{},
          'screenBreakdown': <String, int>{},
        };
      }
      
      final componentCounts = <String, int>{};
      final actionCounts = <String, int>{};
      final screenCounts = <String, int>{};
      final uniqueComponents = <String>{};
      
      for (final row in results) {
        final component = row['component_type'] as String? ?? 'unknown';
        final action = row['action_type'] as String? ?? 'unknown';
        final screen = row['screen_name'] as String? ?? 'unknown';
        
        componentCounts[component] = (componentCounts[component] ?? 0) + 1;
        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
        screenCounts[screen] = (screenCounts[screen] ?? 0) + 1;
        uniqueComponents.add(component);
      }
      
      return {
        'totalInteractions': results.length,
        'uniqueComponents': uniqueComponents.length,
        'topComponents': _sortMapByValue(componentCounts).take(10).toList(),
        'topActions': _sortMapByValue(actionCounts).take(10).toList(),
        'screenBreakdown': _sortMapByValue(screenCounts).take(10).toList(),
        'dailyInteractions': _getDailyInteractionBreakdown(results),
      };
    } catch (e) {
      debugPrint('Failed to get UI interaction stats: $e');
      return {
        'totalInteractions': 0,
        'uniqueComponents': 0,
        'topComponents': <String, int>{},
        'topActions': <String, int>{},
        'screenBreakdown': <String, int>{},
      };
    }
  }

  List<MapEntry<String, int>> _sortMapByValue(Map<String, int> map) {
    final entries = map.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Map<String, int> _getDailyInteractionBreakdown(List<Map<String, dynamic>> results) {
    final breakdown = <String, int>{};
    for (final row in results) {
      final timestamp = row['timestamp'] as String?;
      if (timestamp != null) {
        final date = DateTime.parse(timestamp);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        breakdown[dateKey] = (breakdown[dateKey] ?? 0) + 1;
      }
    }
    return breakdown;
  }

  // MARK: - Performance Metrics Tracking

  /// Track performance metrics (load times, frame rates)
  Future<void> trackPerformanceMetric({
    required String metricType,
    required String metricName,
    required double value,
    required String unit,
    Map<String, dynamic>? contextData,
    String? sessionId,
    String? userId,
  }) async {
    if (!_isInitialized || _analyticsDb == null) return;
    
    try {
      await _analyticsDb!.insert('performance_metrics', {
        'user_id': userId ?? 'local_user',
        'metric_type': metricType,
        'metric_name': metricName,
        'value': value,
        'unit': unit,
        'timestamp': DateTime.now().toIso8601String(),
        'context_data': contextData != null ? jsonEncode(contextData) : null,
        'session_id': sessionId ?? _getCurrentSessionId(),
      });
      
      if (kDebugMode) {
        debugPrint('⚡ Performance metric tracked: $metricType.$metricName = $value $unit');
      }
    } catch (e) {
      debugPrint('Failed to track performance metric: $e');
    }
  }

  /// Track app load time
  Future<void> trackLoadTime({
    required String loadType,
    required Duration loadTime,
    Map<String, dynamic>? contextData,
  }) async {
    await trackPerformanceMetric(
      metricType: 'load_time',
      metricName: loadType,
      value: loadTime.inMilliseconds.toDouble(),
      unit: 'milliseconds',
      contextData: contextData,
    );
  }

  /// Track frame rate performance
  Future<void> trackFrameRate({
    required String screenName,
    required double fps,
    Map<String, dynamic>? contextData,
  }) async {
    await trackPerformanceMetric(
      metricType: 'frame_rate',
      metricName: screenName,
      value: fps,
      unit: 'fps',
      contextData: contextData,
    );
  }

  /// Get performance metrics statistics
  Future<Map<String, dynamic>> getPerformanceStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? metricType,
  }) async {
    if (!_isInitialized || _analyticsDb == null) {
      return {
        'totalMetrics': 0,
        'averageValues': <String, double>{},
        'metricTypes': <String, int>{},
        'performanceTrends': <String, List<double>>{},
      };
    }
    
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId ?? 'local_user'];
      
      if (startDate != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereClause += ' AND timestamp <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      if (metricType != null) {
        whereClause += ' AND metric_type = ?';
        whereArgs.add(metricType);
      }
      
      final results = await _analyticsDb!.query(
        'performance_metrics',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'timestamp ASC',
      );
      
      if (results.isEmpty) {
        return {
          'totalMetrics': 0,
          'averageValues': <String, double>{},
          'metricTypes': <String, int>{},
          'performanceTrends': <String, List<double>>{},
        };
      }
      
      final metricTypeCounts = <String, int>{};
      final metricValues = <String, List<double>>{};
      
      for (final row in results) {
        final type = row['metric_type'] as String? ?? 'unknown';
        final name = row['metric_name'] as String? ?? 'unknown';
        final value = row['value'] as double? ?? 0.0;
        
        metricTypeCounts[type] = (metricTypeCounts[type] ?? 0) + 1;
        
        final key = '$type.$name';
        if (!metricValues.containsKey(key)) {
          metricValues[key] = [];
        }
        metricValues[key]!.add(value);
      }
      
      final averageValues = <String, double>{};
      for (final entry in metricValues.entries) {
        final values = entry.value;
        averageValues[entry.key] = values.reduce((a, b) => a + b) / values.length;
      }
      
      return {
        'totalMetrics': results.length,
        'averageValues': averageValues,
        'metricTypes': metricTypeCounts,
        'performanceTrends': metricValues,
        'dailyAverages': _getDailyPerformanceAverages(results),
      };
    } catch (e) {
      debugPrint('Failed to get performance stats: $e');
      return {
        'totalMetrics': 0,
        'averageValues': <String, double>{},
        'metricTypes': <String, int>{},
        'performanceTrends': <String, List<double>>{},
      };
    }
  }

  Map<String, Map<String, double>> _getDailyPerformanceAverages(List<Map<String, dynamic>> results) {
    final dailyValues = <String, Map<String, List<double>>>{};
    
    for (final row in results) {
      final timestamp = row['timestamp'] as String?;
      if (timestamp != null) {
        final date = DateTime.parse(timestamp);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final metricKey = '${row['metric_type']}.${row['metric_name']}';
        final value = row['value'] as double? ?? 0.0;
        
        if (!dailyValues.containsKey(dateKey)) {
          dailyValues[dateKey] = {};
        }
        if (!dailyValues[dateKey]!.containsKey(metricKey)) {
          dailyValues[dateKey]![metricKey] = [];
        }
        dailyValues[dateKey]![metricKey]!.add(value);
      }
    }
    
    final dailyAverages = <String, Map<String, double>>{};
    for (final dateEntry in dailyValues.entries) {
      dailyAverages[dateEntry.key] = {};
      for (final metricEntry in dateEntry.value.entries) {
        final values = metricEntry.value;
        dailyAverages[dateEntry.key]![metricEntry.key] = 
            values.reduce((a, b) => a + b) / values.length;
      }
    }
    
    return dailyAverages;
  }

  // MARK: - Feature Adoption Rate Tracking

  /// Track feature adoption rates
  Future<void> trackFeatureUsage({
    required String featureName,
    String? featureVersion,
    Map<String, dynamic>? contextData,
    String? userId,
  }) async {
    if (!_isInitialized || _analyticsDb == null) return;
    
    try {
      final existingFeature = await _analyticsDb!.query(
        'feature_adoption',
        where: 'user_id = ? AND feature_name = ?',
        whereArgs: [userId ?? 'local_user', featureName],
        limit: 1,
      );
      
      final now = DateTime.now().toIso8601String();
      
      if (existingFeature.isEmpty) {
        // First time using this feature
        await _analyticsDb!.insert('feature_adoption', {
          'user_id': userId ?? 'local_user',
          'feature_name': featureName,
          'first_used_at': now,
          'last_used_at': now,
          'usage_count': 1,
          'adoption_stage': 'discovery',
          'feature_version': featureVersion,
          'context_data': contextData != null ? jsonEncode(contextData) : null,
        });
        
        if (kDebugMode) {
          debugPrint('🆕 Feature discovered: $featureName');
        }
      } else {
        // Update existing feature usage
        final existing = existingFeature.first;
        final currentUsageCount = existing['usage_count'] as int? ?? 0;
        final newUsageCount = currentUsageCount + 1;
        final adoptionStage = _determineAdoptionStage(newUsageCount);
        
        await _analyticsDb!.update(
          'feature_adoption',
          {
            'last_used_at': now,
            'usage_count': newUsageCount,
            'adoption_stage': adoptionStage,
            'feature_version': featureVersion,
            'context_data': contextData != null ? jsonEncode(contextData) : null,
          },
          where: 'user_id = ? AND feature_name = ?',
          whereArgs: [userId ?? 'local_user', featureName],
        );
        
        if (kDebugMode) {
          debugPrint('📈 Feature usage updated: $featureName (usage: $newUsageCount, stage: $adoptionStage)');
        }
      }
    } catch (e) {
      debugPrint('Failed to track feature usage: $e');
    }
  }

  String _determineAdoptionStage(int usageCount) {
    if (usageCount == 1) return 'discovery';
    if (usageCount <= 3) return 'trial';
    if (usageCount <= 10) return 'adoption';
    if (usageCount <= 30) return 'regular_use';
    return 'expert_use';
  }

  /// Get feature adoption statistics
  Future<Map<String, dynamic>> getFeatureAdoptionStats({
    String? userId,
    String? featureName,
  }) async {
    if (!_isInitialized || _analyticsDb == null) {
      return {
        'totalFeatures': 0,
        'adoptionStages': <String, int>{},
        'topFeatures': <String, int>{},
        'adoptionTimeline': <String, List<String>>{},
      };
    }
    
    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId ?? 'local_user'];
      
      if (featureName != null) {
        whereClause += ' AND feature_name = ?';
        whereArgs.add(featureName);
      }
      
      final results = await _analyticsDb!.query(
        'feature_adoption',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'first_used_at ASC',
      );
      
      if (results.isEmpty) {
        return {
          'totalFeatures': 0,
          'adoptionStages': <String, int>{},
          'topFeatures': <String, int>{},
          'adoptionTimeline': <String, List<String>>{},
        };
      }
      
      final stageCounts = <String, int>{};
      final featureUsageCounts = <String, int>{};
      final adoptionTimeline = <String, List<String>>{};
      
      for (final row in results) {
        final stage = row['adoption_stage'] as String? ?? 'discovery';
        final feature = row['feature_name'] as String? ?? 'unknown';
        final usageCount = row['usage_count'] as int? ?? 0;
        final firstUsed = row['first_used_at'] as String?;
        
        stageCounts[stage] = (stageCounts[stage] ?? 0) + 1;
        featureUsageCounts[feature] = usageCount;
        
        if (firstUsed != null) {
          final date = DateTime.parse(firstUsed);
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          
          if (!adoptionTimeline.containsKey(dateKey)) {
            adoptionTimeline[dateKey] = [];
          }
          adoptionTimeline[dateKey]!.add(feature);
        }
      }
      
      final sortedFeatures = featureUsageCounts.entries.toList();
      sortedFeatures.sort((a, b) => b.value.compareTo(a.value));
      
      return {
        'totalFeatures': results.length,
        'adoptionStages': stageCounts,
        'topFeatures': Map.fromEntries(sortedFeatures.take(10)),
        'adoptionTimeline': adoptionTimeline,
        'featureDetails': results.map((row) => {
          'name': row['feature_name'],
          'usageCount': row['usage_count'],
          'stage': row['adoption_stage'],
          'firstUsed': row['first_used_at'],
          'lastUsed': row['last_used_at'],
        }).toList(),
      };
    } catch (e) {
      debugPrint('Failed to get feature adoption stats: $e');
      return {
        'totalFeatures': 0,
        'adoptionStages': <String, int>{},
        'topFeatures': <String, int>{},
        'adoptionTimeline': <String, List<String>>{},
      };
    }
  }

  // MARK: - Helper Methods

  String _getCurrentSessionId() {
    // Simple session ID based on app start time
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get comprehensive analytics report
  Future<Map<String, dynamic>> getAnalyticsReport({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final haikuStats = await getHaikuUsageStats(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    
    final uiStats = await getUIInteractionStats(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    
    final performanceStats = await getPerformanceStats(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    
    final featureStats = await getFeatureAdoptionStats(userId: userId);
    
    return {
      'reportGeneratedAt': DateTime.now().toIso8601String(),
      'reportPeriod': {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      },
      'haikuUsage': haikuStats,
      'uiInteractions': uiStats,
      'performance': performanceStats,
      'featureAdoption': featureStats,
      'summary': {
        'totalApiCost': haikuStats['totalCost'],
        'totalInteractions': uiStats['totalInteractions'],
        'totalFeatures': featureStats['totalFeatures'],
        'averageLoadTime': performanceStats['averageValues']['load_time.app_start'] ?? 0.0,
      },
    };
  }

  /// Export analytics data for privacy compliance
  Future<Map<String, dynamic>> exportAnalyticsData({String? userId}) async {
    if (!_isInitialized || _analyticsDb == null) return {};
    
    try {
      final userIdToExport = userId ?? 'local_user';
      
      final haikuData = await _analyticsDb!.query(
        'haiku_api_usage',
        where: 'user_id = ?',
        whereArgs: [userIdToExport],
      );
      
      final uiData = await _analyticsDb!.query(
        'ui_interactions',
        where: 'user_id = ?',
        whereArgs: [userIdToExport],
      );
      
      final performanceData = await _analyticsDb!.query(
        'performance_metrics',
        where: 'user_id = ?',
        whereArgs: [userIdToExport],
      );
      
      final featureData = await _analyticsDb!.query(
        'feature_adoption',
        where: 'user_id = ?',
        whereArgs: [userIdToExport],
      );
      
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': userIdToExport,
        'haikuApiUsage': haikuData,
        'uiInteractions': uiData,
        'performanceMetrics': performanceData,
        'featureAdoption': featureData,
      };
    } catch (e) {
      debugPrint('Failed to export analytics data: $e');
      return {};
    }
  }

  /// Clear analytics data for privacy compliance
  Future<void> clearAnalyticsData({String? userId}) async {
    if (!_isInitialized || _analyticsDb == null) return;
    
    try {
      final userIdToClear = userId ?? 'local_user';
      
      await _analyticsDb!.delete(
        'haiku_api_usage',
        where: 'user_id = ?',
        whereArgs: [userIdToClear],
      );
      
      await _analyticsDb!.delete(
        'ui_interactions',
        where: 'user_id = ?',
        whereArgs: [userIdToClear],
      );
      
      await _analyticsDb!.delete(
        'performance_metrics',
        where: 'user_id = ?',
        whereArgs: [userIdToClear],
      );
      
      await _analyticsDb!.delete(
        'feature_adoption',
        where: 'user_id = ?',
        whereArgs: [userIdToClear],
      );
      
      debugPrint('🗑️ Analytics data cleared for user: $userIdToClear');
    } catch (e) {
      debugPrint('Failed to clear analytics data: $e');
    }
  }
}
