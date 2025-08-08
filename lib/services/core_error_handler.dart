import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/core_error.dart';

/// Centralized error handling service for core-related operations
class CoreErrorHandler {
  static final CoreErrorHandler _instance = CoreErrorHandler._internal();
  factory CoreErrorHandler() => _instance;
  CoreErrorHandler._internal();

  /// Stream controller for broadcasting error events
  final StreamController<CoreError> _errorController = 
      StreamController<CoreError>.broadcast();

  /// Stream of error events for UI components to listen to
  Stream<CoreError> get errorStream => _errorController.stream;

  /// Map to track error frequency for intelligent handling
  final Map<String, int> _errorFrequency = {};
  
  /// Map to track last occurrence of each error type
  final Map<String, DateTime> _lastErrorTime = {};
  
  /// List of recent errors for debugging
  final List<CoreError> _recentErrors = [];
  
  /// Maximum number of recent errors to keep
  static const int _maxRecentErrors = 50;
  
  /// Minimum time between similar errors to avoid spam
  static const Duration _errorThrottleInterval = Duration(seconds: 5);

  /// Handle a core error with automatic recovery attempts
  Future<bool> handleError(CoreError error) async {
    // Log the error if needed
    if (error.shouldLog) {
      _logError(error);
    }

    // Add to recent errors list
    _addToRecentErrors(error);

    // Update error frequency tracking
    _updateErrorFrequency(error);

    // Check if we should throttle this error
    if (_shouldThrottleError(error)) {
      return false;
    }

    // Broadcast error event
    _errorController.add(error);

    // Attempt automatic recovery if possible
    if (error.isRecoverable) {
      return await _attemptAutoRecovery(error);
    }

    return false;
  }

  /// Attempt automatic recovery for recoverable errors
  Future<bool> _attemptAutoRecovery(CoreError error) async {
    try {
      switch (error.type) {
        case CoreErrorType.cacheError:
          return await _recoverFromCacheError(error);
        case CoreErrorType.networkError:
          return await _recoverFromNetworkError(error);
        case CoreErrorType.syncFailure:
          return await _recoverFromSyncFailure(error);
        case CoreErrorType.performanceError:
          return await _recoverFromPerformanceError(error);
        default:
          return false;
      }
    } catch (e) {
      // Recovery attempt failed
      _logError(CoreError.fromException(
        Exception('Recovery failed for ${error.type}: $e'),
        type: CoreErrorType.unknown,
        context: {'originalError': error.toJson()},
      ));
      return false;
    }
  }

  /// Recover from cache-related errors
  Future<bool> _recoverFromCacheError(CoreError error) async {
    try {
      // Clear cache and force refresh
      // This would integrate with the cache manager
      debugPrint('CoreErrorHandler: Attempting cache recovery for ${error.coreId}');
      
      // Simulate cache clearing
      await Future.delayed(const Duration(milliseconds: 100));
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Recover from network-related errors
  Future<bool> _recoverFromNetworkError(CoreError error) async {
    try {
      // Implement exponential backoff retry
      final retryCount = _getErrorFrequency(error);
      final backoffDelay = Duration(seconds: (2 * retryCount).clamp(1, 30));
      
      debugPrint('CoreErrorHandler: Network recovery attempt $retryCount, '
                'waiting ${backoffDelay.inSeconds}s');
      
      await Future.delayed(backoffDelay);
      
      // This would attempt to reconnect or retry the operation
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Recover from synchronization failures
  Future<bool> _recoverFromSyncFailure(CoreError error) async {
    try {
      // Queue the failed operation for retry
      debugPrint('CoreErrorHandler: Queuing sync operation for retry');
      
      // This would integrate with the background sync service
      await Future.delayed(const Duration(milliseconds: 50));
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Recover from performance-related errors
  Future<bool> _recoverFromPerformanceError(CoreError error) async {
    try {
      // Trigger memory optimization
      debugPrint('CoreErrorHandler: Triggering memory optimization');
      
      // This would integrate with the memory optimizer
      await Future.delayed(const Duration(milliseconds: 200));
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Execute a recovery action manually
  Future<bool> executeRecoveryAction(
    CoreError error, 
    CoreErrorRecoveryAction action,
  ) async {
    try {
      switch (action) {
        case CoreErrorRecoveryAction.retry:
          return await _retryOperation(error);
        case CoreErrorRecoveryAction.refreshData:
          return await _refreshData(error);
        case CoreErrorRecoveryAction.clearCache:
          return await _clearCache(error);
        case CoreErrorRecoveryAction.forceSync:
          return await _forceSync(error);
        case CoreErrorRecoveryAction.optimizeMemory:
          return await _optimizeMemory(error);
        case CoreErrorRecoveryAction.workOffline:
          return await _enableOfflineMode(error);
        case CoreErrorRecoveryAction.reportIssue:
          return await _reportIssue(error);
        default:
          return false;
      }
    } catch (e) {
      _logError(CoreError.fromException(
        Exception('Recovery action failed: $e'),
        type: CoreErrorType.unknown,
        context: {
          'originalError': error.toJson(),
          'recoveryAction': action.name,
        },
      ));
      return false;
    }
  }

  /// Retry the failed operation
  Future<bool> _retryOperation(CoreError error) async {
    debugPrint('CoreErrorHandler: Retrying operation for ${error.type}');
    
    // This would depend on the specific operation that failed
    // For now, simulate a retry
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Refresh data from the server
  Future<bool> _refreshData(CoreError error) async {
    debugPrint('CoreErrorHandler: Refreshing data for ${error.coreId}');
    
    // This would trigger a data refresh in the CoreProvider
    await Future.delayed(const Duration(milliseconds: 1000));
    return true;
  }

  /// Clear application cache
  Future<bool> _clearCache(CoreError error) async {
    debugPrint('CoreErrorHandler: Clearing cache');
    
    // This would integrate with the cache manager
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  /// Force synchronization
  Future<bool> _forceSync(CoreError error) async {
    debugPrint('CoreErrorHandler: Forcing synchronization');
    
    // This would trigger a force sync in the background sync service
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }

  /// Optimize memory usage
  Future<bool> _optimizeMemory(CoreError error) async {
    debugPrint('CoreErrorHandler: Optimizing memory');
    
    // This would trigger memory optimization
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  /// Enable offline mode
  Future<bool> _enableOfflineMode(CoreError error) async {
    debugPrint('CoreErrorHandler: Enabling offline mode');
    
    // This would switch the app to offline mode
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  /// Report issue to developers
  Future<bool> _reportIssue(CoreError error) async {
    try {
      debugPrint('CoreErrorHandler: Reporting issue');
      
      // In a real implementation, this would send error data to a crash reporting service
      final errorReport = {
        'error': error.toJson(),
        'deviceInfo': await _getDeviceInfo(),
        'appVersion': await _getAppVersion(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Simulate sending report
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('Error report: $errorReport');
      return true;
    } catch (e) {
      debugPrint('Failed to report issue: $e');
      return false;
    }
  }

  /// Get device information for error reporting
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // This would collect device information for debugging
    return {
      'platform': defaultTargetPlatform.name,
      'isDebugMode': kDebugMode,
      'isProfileMode': kProfileMode,
      'isReleaseMode': kReleaseMode,
    };
  }

  /// Get app version for error reporting
  Future<String> _getAppVersion() async {
    // This would get the actual app version
    return '1.0.0';
  }

  /// Log error with appropriate level
  void _logError(CoreError error) {
    final logMessage = 'CoreError: ${error.type.name} - ${error.message}';
    
    switch (error.severity) {
      case CoreErrorSeverity.low:
        debugPrint(logMessage);
        break;
      case CoreErrorSeverity.medium:
        debugPrint('⚠️ $logMessage');
        if (kDebugMode) {
          developer.log(
            logMessage,
            name: 'CoreErrorHandler',
            level: 900, // Warning level
            error: error.originalError,
            stackTrace: error.stackTrace,
          );
        }
        break;
      case CoreErrorSeverity.high:
      case CoreErrorSeverity.critical:
        debugPrint('🚨 $logMessage');
        if (kDebugMode) {
          developer.log(
            logMessage,
            name: 'CoreErrorHandler',
            level: 1000, // Error level
            error: error.originalError,
            stackTrace: error.stackTrace,
          );
        }
        break;
    }
  }

  /// Add error to recent errors list
  void _addToRecentErrors(CoreError error) {
    _recentErrors.add(error);
    
    // Keep only the most recent errors
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }
  }

  /// Update error frequency tracking
  void _updateErrorFrequency(CoreError error) {
    final errorKey = '${error.type.name}_${error.coreId ?? 'global'}';
    _errorFrequency[errorKey] = (_errorFrequency[errorKey] ?? 0) + 1;
    _lastErrorTime[errorKey] = DateTime.now();
  }

  /// Get error frequency for a specific error
  int _getErrorFrequency(CoreError error) {
    final errorKey = '${error.type.name}_${error.coreId ?? 'global'}';
    return _errorFrequency[errorKey] ?? 0;
  }

  /// Check if error should be throttled to avoid spam
  bool _shouldThrottleError(CoreError error) {
    final errorKey = '${error.type.name}_${error.coreId ?? 'global'}';
    final lastTime = _lastErrorTime[errorKey];
    
    if (lastTime == null) return false;
    
    final timeSinceLastError = DateTime.now().difference(lastTime);
    return timeSinceLastError < _errorThrottleInterval;
  }

  /// Get recent errors for debugging
  List<CoreError> getRecentErrors({int? limit}) {
    if (limit == null) return List.from(_recentErrors);
    
    final startIndex = (_recentErrors.length - limit).clamp(0, _recentErrors.length);
    return _recentErrors.sublist(startIndex);
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    final stats = <String, dynamic>{
      'totalErrors': _recentErrors.length,
      'errorsByType': <String, int>{},
      'errorsBySeverity': <String, int>{},
      'mostFrequentErrors': <String, int>{},
    };

    // Count errors by type
    for (final error in _recentErrors) {
      final typeName = error.type.name;
      stats['errorsByType'][typeName] = (stats['errorsByType'][typeName] ?? 0) + 1;
      
      final severityName = error.severity.name;
      stats['errorsBySeverity'][severityName] = (stats['errorsBySeverity'][severityName] ?? 0) + 1;
    }

    // Get most frequent errors
    final sortedFrequency = _errorFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedFrequency.take(5)) {
      stats['mostFrequentErrors'][entry.key] = entry.value;
    }

    return stats;
  }

  /// Clear error history and statistics
  void clearErrorHistory() {
    _recentErrors.clear();
    _errorFrequency.clear();
    _lastErrorTime.clear();
  }

  /// Check if there are any critical errors
  bool get hasCriticalErrors {
    return _recentErrors.any((error) => error.severity == CoreErrorSeverity.critical);
  }

  /// Get the most recent error
  CoreError? get lastError {
    return _recentErrors.isNotEmpty ? _recentErrors.last : null;
  }

  /// Dispose of resources
  void dispose() {
    _errorController.close();
    clearErrorHistory();
  }
}

/// Extension to provide convenient error handling methods
extension CoreErrorHandling<T> on Future<T> {
  /// Handle errors automatically with the CoreErrorHandler
  Future<T?> handleCoreErrors({
    CoreErrorType? defaultErrorType,
    String? coreId,
    Map<String, dynamic>? context,
  }) async {
    try {
      return await this;
    } catch (e) {
      final error = e is CoreError 
          ? e 
          : CoreError.fromException(
              e is Exception ? e : Exception(e.toString()),
              type: defaultErrorType ?? CoreErrorType.unknown,
              coreId: coreId,
              context: context,
            );
      
      await CoreErrorHandler().handleError(error);
      return null;
    }
  }
}