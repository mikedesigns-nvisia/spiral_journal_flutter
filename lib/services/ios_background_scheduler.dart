import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'daily_journal_processor.dart';

/// iOS Background Task Scheduler
/// 
/// Manages background processing for iOS using BGTaskScheduler to process
/// journal entries at midnight. Handles iOS-specific background task lifecycle
/// and ensures compliance with iOS background execution limits.
class IOSBackgroundScheduler {
  static final IOSBackgroundScheduler _instance = IOSBackgroundScheduler._internal();
  factory IOSBackgroundScheduler() => _instance;
  IOSBackgroundScheduler._internal();

  static const MethodChannel _channel = MethodChannel('spiral_journal/background_tasks');
  static const String _taskIdentifier = 'com.spiraljournal.daily-processing';
  
  final DailyJournalProcessor _processor = DailyJournalProcessor();
  bool _isInitialized = false;

  /// Initialize the background scheduler
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up method call handler for iOS background tasks
      _channel.setMethodCallHandler(_handleMethodCall);

      // Register the background task with iOS
      await _registerBackgroundTask();
      
      // Schedule the next execution
      await scheduleNextDailyProcessing();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Failed to initialize: $e');
      }
      // Continue without background processing if initialization fails
    }
  }

  /// Handle method calls from iOS native code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'executeDailyProcessing':
        return await _executeDailyProcessing();
      case 'scheduleNext':
        return await scheduleNextDailyProcessing();
      default:
        throw PlatformException(
          code: 'unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Register background task with iOS BGTaskScheduler
  Future<bool> _registerBackgroundTask() async {
    try {
      final result = await _channel.invokeMethod<bool>('registerBackgroundTask', {
        'identifier': _taskIdentifier,
      });
      
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Background task registered: $result');
      }
      
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Failed to register background task: $e');
      }
      return false;
    }
  }

  /// Schedule the next daily processing task
  Future<bool> scheduleNextDailyProcessing() async {
    try {
      // Calculate next midnight
      final now = DateTime.now();
      var nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 5); // 12:05 AM
      
      // If it's already past midnight today, schedule for tomorrow
      if (now.isAfter(DateTime(now.year, now.month, now.day, 0, 5))) {
        nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 5);
      }

      final result = await _channel.invokeMethod<bool>('scheduleDailyProcessing', {
        'identifier': _taskIdentifier,
        'earliestBeginDate': nextMidnight.millisecondsSinceEpoch ~/ 1000, // Convert to seconds
        'requiresNetworkConnectivity': true,
        'requiresExternalPower': false,
      });

      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Scheduled next processing for $nextMidnight: $result');
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Failed to schedule daily processing: $e');
      }
      return false;
    }
  }

  /// Execute the daily processing task (called by iOS background task)
  Future<Map<String, dynamic>> _executeDailyProcessing() async {
    if (kDebugMode) {
      debugPrint('IOSBackgroundScheduler: Executing daily processing...');
    }

    try {
      // Initialize processor if needed
      await _processor.initialize();
      
      // Process all pending journal entries
      final result = await _processor.processAllPendingJournals();
      
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Processing completed: $result');
      }

      // Schedule the next execution
      await scheduleNextDailyProcessing();

      return {
        'success': true,
        'totalJournals': result.totalJournals,
        'processedJournals': result.processedJournals,
        'skippedJournals': result.skippedJournals,
        'failedJournals': result.failedJournals,
        'usageLimitReached': result.usageLimitReached,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Daily processing failed: $e');
      }

      // Still schedule next execution even if current one failed
      await scheduleNextDailyProcessing();

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Manually trigger daily processing (for testing)
  Future<Map<String, dynamic>> triggerDailyProcessing() async {
    if (kDebugMode) {
      debugPrint('IOSBackgroundScheduler: Manually triggering daily processing...');
    }
    
    return await _executeDailyProcessing();
  }

  /// Cancel all scheduled background tasks
  Future<bool> cancelScheduledTasks() async {
    try {
      final result = await _channel.invokeMethod<bool>('cancelBackgroundTasks', {
        'identifier': _taskIdentifier,
      });

      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Cancelled scheduled tasks: $result');
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Failed to cancel scheduled tasks: $e');
      }
      return false;
    }
  }

  /// Get the status of background task permissions
  Future<Map<String, dynamic>> getBackgroundTaskStatus() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBackgroundTaskStatus');
      
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Failed to get background task status: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Check if the app has background app refresh permission
  Future<bool> hasBackgroundRefreshPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasBackgroundRefreshPermission');
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IOSBackgroundScheduler: Failed to check background refresh permission: $e');
      }
      return false;
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await cancelScheduledTasks();
    _isInitialized = false;
    
    if (kDebugMode) {
      debugPrint('IOSBackgroundScheduler: Disposed');
    }
  }
}