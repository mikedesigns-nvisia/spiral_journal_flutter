import 'package:flutter/foundation.dart';

/// Comprehensive error tracking for AI service operations
class AIServiceErrorTracker {
  static final List<AIServiceError> _errors = [];
  static final List<FallbackEvent> _fallbackEvents = [];
  
  /// Log an AI service error with detailed context
  static void logError(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? provider,
  }) {
    final aiError = AIServiceError(
      operation: operation,
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      context: context ?? {},
      provider: provider,
    );
    
    _errors.add(aiError);
    
    // Also log to console for immediate debugging
    debugPrint('❌ AI Service Error in $operation: $error');
    if (provider != null) {
      debugPrint('   Provider: $provider');
    }
    if (context != null && context.isNotEmpty) {
      debugPrint('   Context: $context');
    }
    if (stackTrace != null) {
      debugPrint('   Stack trace: $stackTrace');
    }
    
    // Keep only the last 100 errors to prevent memory issues
    if (_errors.length > 100) {
      _errors.removeAt(0);
    }
  }
  
  /// Log when the app falls back to FallbackProvider
  static void logFallback(
    String reason,
    String originalProvider, {
    Map<String, dynamic>? context,
  }) {
    final fallbackEvent = FallbackEvent(
      reason: reason,
      originalProvider: originalProvider,
      timestamp: DateTime.now(),
      context: context ?? {},
    );
    
    _fallbackEvents.add(fallbackEvent);
    
    debugPrint('⚠️  AI Service Fallback: $reason');
    debugPrint('   Original Provider: $originalProvider');
    debugPrint('   Falling back to: FallbackProvider');
    if (context != null && context.isNotEmpty) {
      debugPrint('   Context: $context');
    }
    
    // Keep only the last 50 fallback events
    if (_fallbackEvents.length > 50) {
      _fallbackEvents.removeAt(0);
    }
  }
  
  /// Get recent errors with optional filtering
  static List<AIServiceError> getRecentErrors({
    int limit = 10,
    String? operation,
    String? provider,
  }) {
    var filteredErrors = _errors.reversed.toList();
    
    if (operation != null) {
      filteredErrors = filteredErrors
          .where((error) => error.operation.contains(operation))
          .toList();
    }
    
    if (provider != null) {
      filteredErrors = filteredErrors
          .where((error) => error.provider == provider)
          .toList();
    }
    
    return filteredErrors.take(limit).toList();
  }
  
  /// Get recent fallback events
  static List<FallbackEvent> getRecentFallbacks({int limit = 10}) {
    return _fallbackEvents.reversed.take(limit).toList();
  }
  
  /// Get error statistics
  static ErrorStatistics getErrorStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));
    
    final errors24h = _errors.where((e) => e.timestamp.isAfter(last24Hours)).length;
    final errors7d = _errors.where((e) => e.timestamp.isAfter(last7Days)).length;
    final fallbacks24h = _fallbackEvents.where((e) => e.timestamp.isAfter(last24Hours)).length;
    
    // Count errors by operation
    final errorsByOperation = <String, int>{};
    for (final error in _errors) {
      errorsByOperation[error.operation] = (errorsByOperation[error.operation] ?? 0) + 1;
    }
    
    // Count fallbacks by reason
    final fallbacksByReason = <String, int>{};
    for (final fallback in _fallbackEvents) {
      fallbacksByReason[fallback.reason] = (fallbacksByReason[fallback.reason] ?? 0) + 1;
    }
    
    return ErrorStatistics(
      totalErrors: _errors.length,
      errors24Hours: errors24h,
      errors7Days: errors7d,
      totalFallbacks: _fallbackEvents.length,
      fallbacks24Hours: fallbacks24h,
      errorsByOperation: errorsByOperation,
      fallbacksByReason: fallbacksByReason,
      lastError: _errors.isNotEmpty ? _errors.last : null,
      lastFallback: _fallbackEvents.isNotEmpty ? _fallbackEvents.last : null,
    );
  }
  
  /// Clear all stored errors and fallback events
  static void clearAll() {
    _errors.clear();
    _fallbackEvents.clear();
    debugPrint('🧹 AI Service Error Tracker: All errors and fallbacks cleared');
  }
  
  /// Clear only errors older than specified duration
  static void clearOldErrors({Duration? olderThan}) {
    final cutoff = DateTime.now().subtract(olderThan ?? const Duration(days: 7));
    
    _errors.removeWhere((error) => error.timestamp.isBefore(cutoff));
    _fallbackEvents.removeWhere((event) => event.timestamp.isBefore(cutoff));
    
    debugPrint('🧹 AI Service Error Tracker: Cleared errors older than ${olderThan ?? const Duration(days: 7)}');
  }
  
  /// Generate a comprehensive error report
  static String generateErrorReport() {
    final stats = getErrorStatistics();
    final buffer = StringBuffer();
    
    buffer.writeln('🔍 AI Service Error Report');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    
    // Summary statistics
    buffer.writeln('📊 Summary:');
    buffer.writeln('  Total Errors: ${stats.totalErrors}');
    buffer.writeln('  Errors (24h): ${stats.errors24Hours}');
    buffer.writeln('  Errors (7d): ${stats.errors7Days}');
    buffer.writeln('  Total Fallbacks: ${stats.totalFallbacks}');
    buffer.writeln('  Fallbacks (24h): ${stats.fallbacks24Hours}');
    buffer.writeln('');
    
    // Errors by operation
    if (stats.errorsByOperation.isNotEmpty) {
      buffer.writeln('🔧 Errors by Operation:');
      final sortedOperations = stats.errorsByOperation.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedOperations) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln('');
    }
    
    // Fallbacks by reason
    if (stats.fallbacksByReason.isNotEmpty) {
      buffer.writeln('⚠️  Fallbacks by Reason:');
      final sortedReasons = stats.fallbacksByReason.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedReasons) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln('');
    }
    
    // Recent errors
    final recentErrors = getRecentErrors(limit: 5);
    if (recentErrors.isNotEmpty) {
      buffer.writeln('🚨 Recent Errors:');
      for (final error in recentErrors) {
        buffer.writeln('  [${error.timestamp.toIso8601String()}] ${error.operation}');
        buffer.writeln('    Error: ${error.error}');
        if (error.provider != null) {
          buffer.writeln('    Provider: ${error.provider}');
        }
        if (error.context.isNotEmpty) {
          buffer.writeln('    Context: ${error.context}');
        }
        buffer.writeln('');
      }
    }
    
    // Recent fallbacks
    final recentFallbacks = getRecentFallbacks(limit: 3);
    if (recentFallbacks.isNotEmpty) {
      buffer.writeln('🔄 Recent Fallbacks:');
      for (final fallback in recentFallbacks) {
        buffer.writeln('  [${fallback.timestamp.toIso8601String()}] ${fallback.reason}');
        buffer.writeln('    From: ${fallback.originalProvider}');
        if (fallback.context.isNotEmpty) {
          buffer.writeln('    Context: ${fallback.context}');
        }
        buffer.writeln('');
      }
    }
    
    return buffer.toString();
  }
}

/// Represents an AI service error with full context
class AIServiceError {
  final String operation;
  final String error;
  final String? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final String? provider;
  
  AIServiceError({
    required this.operation,
    required this.error,
    this.stackTrace,
    required this.timestamp,
    required this.context,
    this.provider,
  });
  
  Map<String, dynamic> toJson() => {
    'operation': operation,
    'error': error,
    'stackTrace': stackTrace,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
    'provider': provider,
  };
  
  @override
  String toString() {
    return 'AIServiceError(operation: $operation, error: $error, provider: $provider, timestamp: $timestamp)';
  }
}

/// Represents a fallback event when switching to FallbackProvider
class FallbackEvent {
  final String reason;
  final String originalProvider;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  
  FallbackEvent({
    required this.reason,
    required this.originalProvider,
    required this.timestamp,
    required this.context,
  });
  
  Map<String, dynamic> toJson() => {
    'reason': reason,
    'originalProvider': originalProvider,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
  };
  
  @override
  String toString() {
    return 'FallbackEvent(reason: $reason, originalProvider: $originalProvider, timestamp: $timestamp)';
  }
}

/// Statistics about AI service errors and fallbacks
class ErrorStatistics {
  final int totalErrors;
  final int errors24Hours;
  final int errors7Days;
  final int totalFallbacks;
  final int fallbacks24Hours;
  final Map<String, int> errorsByOperation;
  final Map<String, int> fallbacksByReason;
  final AIServiceError? lastError;
  final FallbackEvent? lastFallback;
  
  ErrorStatistics({
    required this.totalErrors,
    required this.errors24Hours,
    required this.errors7Days,
    required this.totalFallbacks,
    required this.fallbacks24Hours,
    required this.errorsByOperation,
    required this.fallbacksByReason,
    this.lastError,
    this.lastFallback,
  });
  
  /// Check if the service appears to be healthy
  bool get isHealthy {
    // Consider unhealthy if more than 5 errors in the last hour
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final recentErrors = AIServiceErrorTracker._errors
        .where((e) => e.timestamp.isAfter(oneHourAgo))
        .length;
    
    return recentErrors <= 5 && fallbacks24Hours <= 3;
  }
  
  Map<String, dynamic> toJson() => {
    'totalErrors': totalErrors,
    'errors24Hours': errors24Hours,
    'errors7Days': errors7Days,
    'totalFallbacks': totalFallbacks,
    'fallbacks24Hours': fallbacks24Hours,
    'errorsByOperation': errorsByOperation,
    'fallbacksByReason': fallbacksByReason,
    'lastError': lastError?.toJson(),
    'lastFallback': lastFallback?.toJson(),
    'isHealthy': isHealthy,
  };
}