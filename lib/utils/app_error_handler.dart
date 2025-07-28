import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'database_exceptions.dart';
import 'package:spiral_journal/services/analytics_service.dart';

/// Centralized error handling system for the Spiral Journal app.
/// 
/// This class provides comprehensive error handling with user-friendly messages,
/// automatic retry mechanisms, graceful degradation, and crash recovery.
class AppErrorHandler {
  static final AppErrorHandler _instance = AppErrorHandler._internal();
  factory AppErrorHandler() => _instance;
  AppErrorHandler._internal();

  // Error tracking
  final List<AppError> _errorHistory = [];
  final Map<String, int> _retryAttempts = {};
  final Map<String, DateTime> _lastErrorTimes = {};

  // Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration errorCooldown = Duration(minutes: 5);

  /// Initialize error handling system
  static void initialize() {
    // Set up global error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      _instance._handleFlutterError(details);
    };

    // Handle errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _instance._handlePlatformError(error, stack);
      return true;
    };
  }

  /// Handle an error with automatic retry and user feedback
  Future<T?> handleError<T>(
    Future<T> Function() operation, {
    required String operationName,
    String? component,
    Map<String, dynamic>? context,
    bool allowRetry = true,
    bool showUserMessage = true,
    T? fallbackValue,
  }) async {
    final errorKey = '$component:$operationName';
    
    try {
      final result = await operation();
      // Reset retry count on success
      _retryAttempts.remove(errorKey);
      return result;
    } catch (error, stackTrace) {
      final appError = _createAppError(
        error,
        stackTrace,
        operationName: operationName,
        component: component,
        context: context,
      );

      // Log the error
      _logError(appError);

      // Check if we should retry
      if (allowRetry && _shouldRetry(errorKey, appError)) {
        return await _retryOperation(
          operation,
          errorKey,
          operationName,
          component,
          context,
          fallbackValue,
        );
      }

      // Show user message if requested
      if (showUserMessage) {
        _showUserError(appError);
      }

      // Return fallback value or rethrow
      if (fallbackValue != null) {
        return fallbackValue;
      }

      rethrow;
    }
  }

  /// Handle errors with graceful degradation
  Future<T> handleWithFallback<T>(
    Future<T> Function() primaryOperation,
    Future<T> Function() fallbackOperation, {
    required String operationName,
    String? component,
    Map<String, dynamic>? context,
  }) async {
    try {
      return await primaryOperation();
    } catch (error, stackTrace) {
      final appError = _createAppError(
        error,
        stackTrace,
        operationName: operationName,
        component: component,
        context: context,
      );

      _logError(appError);

      try {
        return await fallbackOperation();
      } catch (fallbackError, fallbackStackTrace) {
        final fallbackAppError = _createAppError(
          fallbackError,
          fallbackStackTrace,
          operationName: '$operationName (fallback)',
          component: component,
          context: context,
        );

        _logError(fallbackAppError);
        _showUserError(fallbackAppError);
        rethrow;
      }
    }
  }

  /// Save draft content for crash recovery
  Future<void> saveDraft(String content, String entryId) async {
    try {
      // This would integrate with your storage system
      // For now, we'll use a simple in-memory approach
      _draftStorage[entryId] = DraftData(
        content: content,
        timestamp: DateTime.now(),
      );
    } catch (error) {
      // Don't let draft saving errors affect the main operation
      debugPrint('Failed to save draft: $error');
    }
  }

  /// Recover draft content after crash
  Future<String?> recoverDraft(String entryId) async {
    try {
      final draft = _draftStorage[entryId];
      if (draft != null && 
          DateTime.now().difference(draft.timestamp) < const Duration(hours: 24)) {
        return draft.content;
      }
      return null;
    } catch (error) {
      debugPrint('Failed to recover draft: $error');
      return null;
    }
  }

  /// Clear draft after successful save
  Future<void> clearDraft(String entryId) async {
    try {
      _draftStorage.remove(entryId);
    } catch (error) {
      debugPrint('Failed to clear draft: $error');
    }
  }

  /// Get error statistics for debugging
  Map<String, dynamic> getErrorStats() {
    final errorCounts = <String, int>{};
    for (final error in _errorHistory) {
      final key = '${error.type.name}:${error.category}';
      errorCounts[key] = (errorCounts[key] ?? 0) + 1;
    }

    return {
      'totalErrors': _errorHistory.length,
      'errorsByType': errorCounts,
      'recentErrors': _errorHistory
          .where((e) => DateTime.now().difference(e.timestamp) < const Duration(hours: 1))
          .length,
    };
  }

  // Private methods

  AppError _createAppError(
    dynamic error,
    StackTrace stackTrace, {
    String? operationName,
    String? component,
    Map<String, dynamic>? context,
  }) {
    ErrorType type;
    ErrorCategory category;
    String userMessage;
    bool isRecoverable;

    // Determine error type and category
    if (error is DatabaseException || error is DatabaseTransactionException) {
      type = ErrorType.database;
      category = ErrorCategory.storage;
      userMessage = 'Unable to save your data. Please try again.';
      isRecoverable = true;
    } else if (error is SocketException || error is TimeoutException) {
      type = ErrorType.network;
      category = ErrorCategory.connectivity;
      userMessage = 'Network connection issue. Please check your internet connection.';
      isRecoverable = true;
    } else if (error is PlatformException) {
      type = ErrorType.platform;
      category = ErrorCategory.system;
      userMessage = 'A system error occurred. Please try again.';
      isRecoverable = true;
    } else if (error is FormatException || error is TypeError) {
      type = ErrorType.parsing;
      category = ErrorCategory.data;
      userMessage = 'Data processing error. Please try again.';
      isRecoverable = false;
    } else {
      type = ErrorType.unknown;
      category = ErrorCategory.general;
      userMessage = 'An unexpected error occurred. Please try again.';
      isRecoverable = true;
    }

    return AppError(
      type: type,
      category: category,
      message: error.toString(),
      userMessage: userMessage,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      operationName: operationName,
      component: component,
      context: context,
      isRecoverable: isRecoverable,
    );
  }

  void _logError(AppError error) {
    _errorHistory.add(error);
    
    // Keep only recent errors to prevent memory issues
    if (_errorHistory.length > 100) {
      _errorHistory.removeRange(0, _errorHistory.length - 100);
    }

    // Log to analytics service for crash reporting
    try {
      AnalyticsService().logError(
        error.message,
        context: '${error.component}:${error.operationName}',
        stackTrace: error.stackTrace,
      );
    } catch (e) {
      // Don't let analytics errors affect error handling
      debugPrint('Failed to log error to analytics: $e');
    }

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('ERROR [${error.type.name}] ${error.component ?? 'Unknown'}:${error.operationName ?? 'Unknown'}');
      debugPrint('Message: ${error.message}');
      debugPrint('User Message: ${error.userMessage}');
      if (error.context != null) {
        debugPrint('Context: ${error.context}');
      }
      debugPrint('Stack Trace: ${error.stackTrace}');
    }
  }

  bool _shouldRetry(String errorKey, AppError error) {
    if (!error.isRecoverable) return false;

    final attempts = _retryAttempts[errorKey] ?? 0;
    if (attempts >= maxRetryAttempts) return false;

    final lastError = _lastErrorTimes[errorKey];
    if (lastError != null && 
        DateTime.now().difference(lastError) < errorCooldown) {
      return false;
    }

    return true;
  }

  Future<T?> _retryOperation<T>(
    Future<T> Function() operation,
    String errorKey,
    String operationName,
    String? component,
    Map<String, dynamic>? context,
    T? fallbackValue,
  ) async {
    final attempts = _retryAttempts[errorKey] ?? 0;
    _retryAttempts[errorKey] = attempts + 1;
    _lastErrorTimes[errorKey] = DateTime.now();

    // Wait before retry
    await Future.delayed(retryDelay);

    try {
      final result = await operation();
      _retryAttempts.remove(errorKey);
      return result;
    } catch (error, stackTrace) {
      final appError = _createAppError(
        error,
        stackTrace,
        operationName: '$operationName (retry ${attempts + 1})',
        component: component,
        context: context,
      );

      _logError(appError);

      if (fallbackValue != null) {
        return fallbackValue;
      }

      rethrow;
    }
  }

  void _showUserError(AppError error) {
    // This would integrate with your UI system to show user-friendly errors
    // For now, we'll use a simple debug print
    debugPrint('USER ERROR: ${error.userMessage}');
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    final appError = _createAppError(
      details.exception,
      details.stack ?? StackTrace.current,
      operationName: 'Flutter Framework',
      component: details.library,
      context: {
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
    );

    _logError(appError);
  }

  bool _handlePlatformError(Object error, StackTrace stack) {
    final appError = _createAppError(
      error,
      stack,
      operationName: 'Platform',
      component: 'System',
    );

    _logError(appError);
    return true;
  }

  // Draft storage for crash recovery
  final Map<String, DraftData> _draftStorage = {};
}

/// Represents an application error with context and user-friendly information
class AppError {
  final ErrorType type;
  final ErrorCategory category;
  final String message;
  final String userMessage;
  final StackTrace stackTrace;
  final DateTime timestamp;
  final String? operationName;
  final String? component;
  final Map<String, dynamic>? context;
  final bool isRecoverable;

  AppError({
    required this.type,
    required this.category,
    required this.message,
    required this.userMessage,
    required this.stackTrace,
    required this.timestamp,
    this.operationName,
    this.component,
    this.context,
    required this.isRecoverable,
  });
}

/// Types of errors that can occur in the application
enum ErrorType {
  database,
  network,
  platform,
  parsing,
  authentication,
  validation,
  unknown,
}

/// Categories of errors for grouping and handling
enum ErrorCategory {
  storage,
  connectivity,
  system,
  data,
  security,
  user,
  general,
}

/// Draft data for crash recovery
class DraftData {
  final String content;
  final DateTime timestamp;

  DraftData({
    required this.content,
    required this.timestamp,
  });
}