import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Local analytics service for TestFlight feedback and crash reporting
/// All data is stored locally on device, no external services used
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialize local analytics and crash reporting
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
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
}
