import 'package:flutter/foundation.dart';
/// Standardized error handling patterns for consistent error management across the application.
/// 
/// This utility class provides standardized patterns for error handling, logging,
/// and context preservation throughout the application. It ensures consistent
/// error management approaches and simplifies debugging by providing structured
/// error information with appropriate context.
/// 
/// ## Key Features
/// - **Standardized Error Handling**: Consistent try-catch patterns across the application
/// - **Contextual Logging**: Error logging with component, operation, and parameter context
/// - **Severity Classification**: Error severity levels for appropriate response handling
/// - **Stack Trace Preservation**: Full stack trace logging for debugging
/// - **Flexible Integration**: Easy integration with existing code patterns
/// 
/// ## Usage Examples
/// ```dart
/// // Basic error handling with context
/// final result = await ErrorHandlingPatterns.executeWithStandardErrorHandling(
///   () => someAsyncOperation(),
///   component: 'JournalService',
///   operationName: 'createEntry',
///   parameters: {'userId': userId, 'contentLength': content.length},
///   severity: ErrorSeverity.medium,
/// );
/// 
/// // Direct error logging
/// try {
///   await riskyOperation();
/// } catch (error, stackTrace) {
///   ErrorHandlingPatterns.logError(
///     error,
///     stackTrace,
///     component: 'DatabaseLayer',
///     operation: 'transaction',
///     severity: ErrorSeverity.high,
///   );
///   rethrow;
/// }
/// ```
/// 
/// ## Error Severity Levels
/// - **Low**: Minor issues that don't affect core functionality
/// - **Medium**: Issues that may impact user experience but have fallbacks
/// - **High**: Significant issues that affect core functionality
/// - **Critical**: System-level failures that require immediate attention
/// 
/// ## Integration Pattern
/// This class is designed to be used throughout the application:
/// - Service layer operations for business logic error handling
/// - Database operations for transaction and data integrity errors
/// - UI operations for user-facing error scenarios
/// - Background operations for system-level error management
/// 
/// ## Logging Strategy
/// - Console logging for development and debugging
/// - Structured error information with context preservation
/// - Stack trace inclusion for detailed debugging information
/// - Extensible design for future logging enhancements (analytics, crash reporting)
class ErrorHandlingPatterns {
  /// Execute an operation with basic error handling
  static Future<T> executeWithStandardErrorHandling<T>(
    Future<T> Function() operation, {
    String? component,
    String? operationName,
    Map<String, dynamic>? parameters,
    ErrorSeverity? severity,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      // Simple logging - in production this could be enhanced
      logError(
        error, 
        stackTrace, 
        component: component, 
        operation: operationName,
        parameters: parameters,
        severity: severity,
      );
      rethrow;
    }
  }

  /// Log an error with context
  static void logError(
    dynamic error,
    StackTrace stackTrace, {
    String? component,
    String? operation,
    Map<String, dynamic>? parameters,
    ErrorSeverity? severity,
  }) {
    // Simple console logging - in production this could be enhanced
    final context = component != null ? '[$component]' : '';
    final op = operation != null ? ' $operation:' : '';
    final sev = severity != null ? ' [${severity.name.toUpperCase()}]' : '';
    final params = parameters != null ? ' params: $parameters' : '';
    debugPrint('ERROR$sev$context$op $error$params');
    debugPrint('Stack trace: $stackTrace');
  }
}

/// Error severity levels for logging
enum ErrorSeverity {
  low,
  medium,
  high,
  critical
}