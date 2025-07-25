import 'package:flutter/foundation.dart';

/// Enumeration of different types of core-related errors
enum CoreErrorType {
  /// Error loading core data from storage or service
  dataLoadFailure,
  
  /// Error synchronizing core data across components
  syncFailure,
  
  /// Error during navigation between core screens
  navigationError,
  
  /// Error during AI analysis of cores
  analysisError,
  
  /// Error persisting core data to storage
  persistenceError,
  
  /// Network connectivity issues
  networkError,
  
  /// Cache-related errors
  cacheError,
  
  /// Memory or performance related errors
  performanceError,
  
  /// Unknown or unexpected errors
  unknown,
}

/// Comprehensive error model for core-related operations
class CoreError {
  /// The type of error that occurred
  final CoreErrorType type;
  
  /// Human-readable error message
  final String message;
  
  /// Optional core ID associated with the error
  final String? coreId;
  
  /// The original exception that caused this error (for debugging)
  final dynamic originalError;
  
  /// Whether this error can be recovered from automatically
  final bool isRecoverable;
  
  /// Timestamp when the error occurred
  final DateTime timestamp;
  
  /// Additional context data for debugging
  final Map<String, dynamic>? context;
  
  /// Stack trace for debugging (only in debug mode)
  final StackTrace? stackTrace;

  CoreError({
    required this.type,
    required this.message,
    this.coreId,
    this.originalError,
    this.isRecoverable = true,
    DateTime? timestamp,
    this.context,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a CoreError from an Exception
  factory CoreError.fromException(
    Exception exception, {
    required CoreErrorType type,
    String? coreId,
    String? customMessage,
    bool isRecoverable = true,
    Map<String, dynamic>? context,
  }) {
    final message = customMessage ?? _getMessageFromException(exception, type);
    
    return CoreError(
      type: type,
      message: message,
      coreId: coreId,
      originalError: exception,
      isRecoverable: isRecoverable,
      timestamp: DateTime.now(),
      context: context,
      stackTrace: kDebugMode ? StackTrace.current : null,
    );
  }

  /// Create a network-related error
  factory CoreError.network({
    required String message,
    String? coreId,
    dynamic originalError,
    Map<String, dynamic>? context,
  }) {
    return CoreError(
      type: CoreErrorType.networkError,
      message: message,
      coreId: coreId,
      originalError: originalError,
      isRecoverable: true,
      timestamp: DateTime.now(),
      context: context,
      stackTrace: kDebugMode ? StackTrace.current : null,
    );
  }

  /// Create a cache-related error
  factory CoreError.cache({
    required String message,
    String? coreId,
    dynamic originalError,
    bool isRecoverable = true,
    Map<String, dynamic>? context,
  }) {
    return CoreError(
      type: CoreErrorType.cacheError,
      message: message,
      coreId: coreId,
      originalError: originalError,
      isRecoverable: isRecoverable,
      timestamp: DateTime.now(),
      context: context,
      stackTrace: kDebugMode ? StackTrace.current : null,
    );
  }

  /// Create a performance-related error
  factory CoreError.performance({
    required String message,
    String? coreId,
    dynamic originalError,
    Map<String, dynamic>? context,
  }) {
    return CoreError(
      type: CoreErrorType.performanceError,
      message: message,
      coreId: coreId,
      originalError: originalError,
      isRecoverable: true,
      timestamp: DateTime.now(),
      context: context,
      stackTrace: kDebugMode ? StackTrace.current : null,
    );
  }

  /// Get user-friendly error message with recovery suggestions
  String get userFriendlyMessage {
    switch (type) {
      case CoreErrorType.dataLoadFailure:
        return 'Unable to load your core data. Please check your connection and try again.';
      case CoreErrorType.syncFailure:
        return 'Your cores couldn\'t sync properly. Changes will be saved when connection is restored.';
      case CoreErrorType.navigationError:
        return 'Navigation error occurred. Please try again or restart the app.';
      case CoreErrorType.analysisError:
        return 'AI analysis is temporarily unavailable. Your journal entry has been saved.';
      case CoreErrorType.persistenceError:
        return 'Unable to save changes. Please try again or check available storage.';
      case CoreErrorType.networkError:
        return 'Network connection issue. Please check your internet connection.';
      case CoreErrorType.cacheError:
        return 'Data cache issue. The app will refresh your data automatically.';
      case CoreErrorType.performanceError:
        return 'Performance issue detected. The app is optimizing for better experience.';
      case CoreErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get recovery action suggestions for the user
  List<CoreErrorRecoveryAction> get recoveryActions {
    switch (type) {
      case CoreErrorType.dataLoadFailure:
        return [
          CoreErrorRecoveryAction.retry,
          CoreErrorRecoveryAction.refreshData,
          CoreErrorRecoveryAction.checkConnection,
        ];
      case CoreErrorType.syncFailure:
        return [
          CoreErrorRecoveryAction.retry,
          CoreErrorRecoveryAction.checkConnection,
          CoreErrorRecoveryAction.forceSync,
        ];
      case CoreErrorType.navigationError:
        return [
          CoreErrorRecoveryAction.retry,
          CoreErrorRecoveryAction.goBack,
          CoreErrorRecoveryAction.restartApp,
        ];
      case CoreErrorType.analysisError:
        return [
          CoreErrorRecoveryAction.retry,
          CoreErrorRecoveryAction.skipAnalysis,
          CoreErrorRecoveryAction.checkConnection,
        ];
      case CoreErrorType.persistenceError:
        return [
          CoreErrorRecoveryAction.retry,
          CoreErrorRecoveryAction.checkStorage,
          CoreErrorRecoveryAction.clearCache,
        ];
      case CoreErrorType.networkError:
        return [
          CoreErrorRecoveryAction.retry,
          CoreErrorRecoveryAction.checkConnection,
          CoreErrorRecoveryAction.workOffline,
        ];
      case CoreErrorType.cacheError:
        return [
          CoreErrorRecoveryAction.clearCache,
          CoreErrorRecoveryAction.refreshData,
          CoreErrorRecoveryAction.retry,
        ];
      case CoreErrorType.performanceError:
        return [
          CoreErrorRecoveryAction.optimizeMemory,
          CoreErrorRecoveryAction.clearCache,
          CoreErrorRecoveryAction.restartApp,
        ];
      case CoreErrorType.unknown:
        return [
          CoreErrorRecoveryAction.retry,
          CoreErrorRecoveryAction.restartApp,
          CoreErrorRecoveryAction.reportIssue,
        ];
    }
  }

  /// Check if this error should be logged for debugging
  bool get shouldLog {
    // Always log non-recoverable errors and analysis errors
    if (!isRecoverable || type == CoreErrorType.analysisError) {
      return true;
    }
    
    // Log network errors only in debug mode
    if (type == CoreErrorType.networkError) {
      return kDebugMode;
    }
    
    // Log cache errors only if they're persistent
    if (type == CoreErrorType.cacheError) {
      return context?['isPersistent'] == true;
    }
    
    return true;
  }

  /// Get severity level for logging and monitoring
  CoreErrorSeverity get severity {
    switch (type) {
      case CoreErrorType.dataLoadFailure:
      case CoreErrorType.persistenceError:
        return CoreErrorSeverity.high;
      case CoreErrorType.syncFailure:
      case CoreErrorType.analysisError:
        return CoreErrorSeverity.medium;
      case CoreErrorType.navigationError:
      case CoreErrorType.networkError:
      case CoreErrorType.cacheError:
        return CoreErrorSeverity.low;
      case CoreErrorType.performanceError:
        return CoreErrorSeverity.medium;
      case CoreErrorType.unknown:
        return CoreErrorSeverity.high;
    }
  }

  /// Convert to JSON for logging and debugging
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'userFriendlyMessage': userFriendlyMessage,
      'coreId': coreId,
      'isRecoverable': isRecoverable,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'context': context,
      'originalError': originalError?.toString(),
      'stackTrace': kDebugMode ? stackTrace?.toString() : null,
    };
  }

  /// Create a copy with updated properties
  CoreError copyWith({
    CoreErrorType? type,
    String? message,
    String? coreId,
    dynamic originalError,
    bool? isRecoverable,
    DateTime? timestamp,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    return CoreError(
      type: type ?? this.type,
      message: message ?? this.message,
      coreId: coreId ?? this.coreId,
      originalError: originalError ?? this.originalError,
      isRecoverable: isRecoverable ?? this.isRecoverable,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  String toString() {
    return 'CoreError(type: $type, message: $message, coreId: $coreId, '
           'isRecoverable: $isRecoverable, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreError &&
        other.type == type &&
        other.message == message &&
        other.coreId == coreId &&
        other.isRecoverable == isRecoverable;
  }

  @override
  int get hashCode {
    return Object.hash(type, message, coreId, isRecoverable);
  }

  /// Helper method to extract meaningful message from exceptions
  static String _getMessageFromException(Exception exception, CoreErrorType type) {
    final exceptionString = exception.toString();
    
    // Remove common exception prefixes for cleaner messages
    String cleanMessage = exceptionString
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('ArgumentError: ', '');
    
    // Provide context-specific messages based on error type
    switch (type) {
      case CoreErrorType.dataLoadFailure:
        return 'Failed to load core data: $cleanMessage';
      case CoreErrorType.syncFailure:
        return 'Synchronization failed: $cleanMessage';
      case CoreErrorType.navigationError:
        return 'Navigation error: $cleanMessage';
      case CoreErrorType.analysisError:
        return 'Analysis error: $cleanMessage';
      case CoreErrorType.persistenceError:
        return 'Failed to save data: $cleanMessage';
      case CoreErrorType.networkError:
        return 'Network error: $cleanMessage';
      case CoreErrorType.cacheError:
        return 'Cache error: $cleanMessage';
      case CoreErrorType.performanceError:
        return 'Performance issue: $cleanMessage';
      case CoreErrorType.unknown:
        return 'Unexpected error: $cleanMessage';
    }
  }
}

/// Available recovery actions for core errors
enum CoreErrorRecoveryAction {
  retry,
  refreshData,
  checkConnection,
  forceSync,
  goBack,
  restartApp,
  skipAnalysis,
  checkStorage,
  clearCache,
  workOffline,
  optimizeMemory,
  reportIssue,
}

/// Severity levels for core errors
enum CoreErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Extension to get user-friendly labels for recovery actions
extension CoreErrorRecoveryActionExtension on CoreErrorRecoveryAction {
  String get label {
    switch (this) {
      case CoreErrorRecoveryAction.retry:
        return 'Try Again';
      case CoreErrorRecoveryAction.refreshData:
        return 'Refresh Data';
      case CoreErrorRecoveryAction.checkConnection:
        return 'Check Connection';
      case CoreErrorRecoveryAction.forceSync:
        return 'Force Sync';
      case CoreErrorRecoveryAction.goBack:
        return 'Go Back';
      case CoreErrorRecoveryAction.restartApp:
        return 'Restart App';
      case CoreErrorRecoveryAction.skipAnalysis:
        return 'Skip Analysis';
      case CoreErrorRecoveryAction.checkStorage:
        return 'Check Storage';
      case CoreErrorRecoveryAction.clearCache:
        return 'Clear Cache';
      case CoreErrorRecoveryAction.workOffline:
        return 'Work Offline';
      case CoreErrorRecoveryAction.optimizeMemory:
        return 'Optimize Memory';
      case CoreErrorRecoveryAction.reportIssue:
        return 'Report Issue';
    }
  }

  String get description {
    switch (this) {
      case CoreErrorRecoveryAction.retry:
        return 'Attempt the operation again';
      case CoreErrorRecoveryAction.refreshData:
        return 'Reload data from the server';
      case CoreErrorRecoveryAction.checkConnection:
        return 'Verify your internet connection';
      case CoreErrorRecoveryAction.forceSync:
        return 'Force synchronization of data';
      case CoreErrorRecoveryAction.goBack:
        return 'Return to the previous screen';
      case CoreErrorRecoveryAction.restartApp:
        return 'Close and reopen the app';
      case CoreErrorRecoveryAction.skipAnalysis:
        return 'Continue without AI analysis';
      case CoreErrorRecoveryAction.checkStorage:
        return 'Check available device storage';
      case CoreErrorRecoveryAction.clearCache:
        return 'Clear app cache and temporary data';
      case CoreErrorRecoveryAction.workOffline:
        return 'Continue with cached data';
      case CoreErrorRecoveryAction.optimizeMemory:
        return 'Free up memory resources';
      case CoreErrorRecoveryAction.reportIssue:
        return 'Send error report to developers';
    }
  }
}