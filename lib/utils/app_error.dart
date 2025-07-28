import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Standardized error types for the Spiral Journal application
/// 
/// This enum provides a consistent categorization of errors that can occur
/// throughout the application, enabling better error handling and user feedback.
enum AppErrorType {
  // Network and API errors
  networkError,
  apiError,
  authenticationError,
  
  // Database errors
  databaseError,
  dataCorruption,
  
  // File system errors
  fileSystemError,
  permissionError,
  
  // Validation errors
  validationError,
  invalidInput,
  
  // Service errors
  serviceUnavailable,
  rateLimitExceeded,
  
  // Platform errors
  platformError,
  
  // Unknown errors
  unknown,
}

/// Standardized error severity levels
enum AppErrorSeverity {
  low,    // Minor issues that don't affect core functionality
  medium, // Issues that affect some functionality but have workarounds
  high,   // Issues that significantly impact functionality
  critical, // Issues that make the app unusable
}

/// Standardized application error class
/// 
/// This class provides a consistent structure for all errors in the application,
/// including proper categorization, context information, and recovery suggestions.
class AppError implements Exception {
  final AppErrorType type;
  final AppErrorSeverity severity;
  final String message;
  final String? userMessage;
  final String? component;
  final String? operation;
  final Map<String, dynamic>? context;
  final Object? originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  
  const AppError({
    required this.type,
    required this.severity,
    required this.message,
    this.userMessage,
    this.component,
    this.operation,
    this.context,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const DateTime.now();
  
  /// Create an AppError from an existing exception
  factory AppError.from(
    Object error, {
    String? component,
    String? operation,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    final errorInfo = _categorizeError(error);
    
    return AppError(
      type: errorInfo['type'] as AppErrorType,
      severity: errorInfo['severity'] as AppErrorSeverity,
      message: errorInfo['message'] as String,
      userMessage: errorInfo['userMessage'] as String?,
      component: component,
      operation: operation,
      context: context,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Create a network error
  factory AppError.network(
    String message, {
    String? component,
    String? operation,
    Map<String, dynamic>? context,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: AppErrorType.networkError,
      severity: AppErrorSeverity.medium,
      message: message,
      userMessage: 'Network connection issue. Please check your internet connection.',
      component: component,
      operation: operation,
      context: context,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
  
  /// Create a database error
  factory AppError.database(
    String message, {
    String? component,
    String? operation,
    Map<String, dynamic>? context,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: AppErrorType.databaseError,
      severity: AppErrorSeverity.high,
      message: message,
      userMessage: 'A data storage issue occurred. Your data is safe.',
      component: component,
      operation: operation,
      context: context,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
  
  /// Create a validation error
  factory AppError.validation(
    String message, {
    String? userMessage,
    String? component,
    String? operation,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      type: AppErrorType.validationError,
      severity: AppErrorSeverity.low,
      message: message,
      userMessage: userMessage ?? message,
      component: component,
      operation: operation,
      context: context,
    );
  }
  
  /// Create an authentication error
  factory AppError.authentication(
    String message, {
    String? component,
    String? operation,
    Map<String, dynamic>? context,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: AppErrorType.authenticationError,
      severity: AppErrorSeverity.high,
      message: message,
      userMessage: 'Authentication required. Please verify your credentials.',
      component: component,
      operation: operation,
      context: context,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
  
  /// Create a file system error
  factory AppError.fileSystem(
    String message, {
    String? component,
    String? operation,
    Map<String, dynamic>? context,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: AppErrorType.fileSystemError,
      severity: AppErrorSeverity.medium,
      message: message,
      userMessage: 'File access issue. Please check storage permissions.',
      component: component,
      operation: operation,
      context: context,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
  
  /// Get a user-friendly error message
  String get displayMessage => userMessage ?? message;
  
  /// Check if error is recoverable
  bool get isRecoverable {
    switch (type) {
      case AppErrorType.networkError:
      case AppErrorType.serviceUnavailable:
      case AppErrorType.rateLimitExceeded:
        return true;
      case AppErrorType.dataCorruption:
      case AppErrorType.permissionError:
        return false;
      default:
        return severity != AppErrorSeverity.critical;
    }
  }
  
  /// Get recovery suggestions
  List<String> get recoverySuggestions {
    switch (type) {
      case AppErrorType.networkError:
        return [
          'Check your internet connection',
          'Try again in a moment',
          'Restart the app if the problem persists',
        ];
      case AppErrorType.databaseError:
        return [
          'Restart the app',
          'Contact support if the problem persists',
        ];
      case AppErrorType.fileSystemError:
        return [
          'Check available storage space',
          'Verify app permissions',
          'Restart the app',
        ];
      case AppErrorType.validationError:
        return [
          'Check your input and try again',
        ];
      case AppErrorType.authenticationError:
        return [
          'Check your credentials',
          'Try logging in again',
        ];
      default:
        return [
          'Try again',
          'Restart the app if the problem persists',
        ];
    }
  }
  
  /// Convert error to a loggable map
  Map<String, dynamic> toLogMap() {
    return {
      'type': type.toString(),
      'severity': severity.toString(),
      'message': message,
      'userMessage': userMessage,
      'component': component,
      'operation': operation,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'originalError': originalError?.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('AppError(');
    buffer.write('type: $type, ');
    buffer.write('severity: $severity, ');
    buffer.write('message: $message');
    if (component != null) buffer.write(', component: $component');
    if (operation != null) buffer.write(', operation: $operation');
    buffer.write(')');
    return buffer.toString();
  }
  
  /// Categorize an unknown error into appropriate AppError type and severity
  static Map<String, dynamic> _categorizeError(Object error) {
    // Network and HTTP errors
    if (error is SocketException) {
      return {
        'type': AppErrorType.networkError,
        'severity': AppErrorSeverity.medium,
        'message': 'Network connection failed: ${error.message}',
        'userMessage': 'Network connection issue. Please check your internet connection.',
      };
    }
    
    if (error is HttpException) {
      return {
        'type': AppErrorType.apiError,
        'severity': AppErrorSeverity.medium,
        'message': 'HTTP error: ${error.message}',
        'userMessage': 'Server communication issue. Please try again.',
      };
    }
    
    if (error is TimeoutException) {
      return {
        'type': AppErrorType.networkError,
        'severity': AppErrorSeverity.medium,
        'message': 'Operation timed out: ${error.message}',
        'userMessage': 'Request timed out. Please try again.',
      };
    }
    
    // Database errors
    if (error is DatabaseException) {
      return {
        'type': AppErrorType.databaseError,
        'severity': AppErrorSeverity.high,
        'message': 'Database error: ${error.toString()}',
        'userMessage': 'A data storage issue occurred. Your data is safe.',
      };
    }
    
    // File system errors
    if (error is FileSystemException) {
      return {
        'type': AppErrorType.fileSystemError,
        'severity': AppErrorSeverity.medium,
        'message': 'File system error: ${error.message}',
        'userMessage': 'File access issue. Please check storage permissions.',
      };
    }
    
    // Argument errors (validation)
    if (error is ArgumentError) {
      return {
        'type': AppErrorType.validationError,
        'severity': AppErrorSeverity.low,
        'message': 'Invalid argument: ${error.message}',
        'userMessage': 'Invalid input. Please check your data and try again.',
      };
    }
    
    // Format errors (validation)
    if (error is FormatException) {
      return {
        'type': AppErrorType.validationError,
        'severity': AppErrorSeverity.low,
        'message': 'Format error: ${error.message}',
        'userMessage': 'Data format issue. Please check your input.',
      };
    }
    
    // State errors (programming errors)
    if (error is StateError) {
      return {
        'type': AppErrorType.platformError,
        'severity': AppErrorSeverity.high,
        'message': 'State error: ${error.message}',
        'userMessage': 'An unexpected issue occurred. Please restart the app.',
      };
    }
    
    // Default for unknown errors
    return {
      'type': AppErrorType.unknown,
      'severity': AppErrorSeverity.medium,
      'message': 'Unknown error: ${error.toString()}',
      'userMessage': 'An unexpected issue occurred. Please try again.',
    };
  }
}

/// Result wrapper for operations that may fail
class AppResult<T> {
  final T? data;
  final AppError? error;
  final bool isSuccess;
  
  const AppResult.success(this.data) : error = null, isSuccess = true;
  const AppResult.failure(this.error) : data = null, isSuccess = false;
  
  /// Get data or throw error
  T get value {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ?? AppError(
      type: AppErrorType.unknown,
      severity: AppErrorSeverity.high,
      message: 'No data available in result',
    );
  }
  
  /// Get data or return default value
  T? getOrDefault(T? defaultValue) {
    return isSuccess ? data : defaultValue;
  }
  
  /// Map the data if successful
  AppResult<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return AppResult.success(mapper(data!));
      } catch (e, stackTrace) {
        return AppResult.failure(AppError.from(e, stackTrace: stackTrace));
      }
    }
    return AppResult.failure(error!);
  }
  
  /// Handle both success and failure cases
  R fold<R>(
    R Function(AppError error) onFailure,
    R Function(T data) onSuccess,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    }
    return onFailure(error!);
  }
}