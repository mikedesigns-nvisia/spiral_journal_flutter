import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exception handler for test operations with timeout and error management
class TestExceptionHandler {
  
  /// Handle timeout exceptions with fallback values
  static Future<T> handleTimeoutException<T>(
    Future<T> Function() operation, {
    required String operationName,
    Duration timeout = const Duration(seconds: 30),
    T? fallbackValue,
    bool rethrowException = true,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException catch (e) {
      final errorMessage = 'Operation "$operationName" timed out after ${timeout.inSeconds}s: $e';
      debugPrint('⏰ $errorMessage');
      
      if (fallbackValue != null && !rethrowException) {
        debugPrint('🔄 Using fallback value for timed out operation');
        return fallbackValue;
      }
      
      if (rethrowException) {
        throw TimeoutException(errorMessage, timeout);
      } else {
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      final errorMessage = 'Operation "$operationName" failed: $e';
      debugPrint('❌ $errorMessage');
      debugPrint('Stack trace: $stackTrace');
      
      if (fallbackValue != null && !rethrowException) {
        debugPrint('🔄 Using fallback value for failed operation');
        return fallbackValue;
      }
      
      rethrow;
    }
  }
  
  /// Handle widget test exceptions with proper error reporting
  static Future<void> runWidgetTest(
    WidgetTester tester,
    Future<void> Function(WidgetTester) testFunction, {
    required String testName,
    Map<String, dynamic>? context,
    bool printWidgetTree = false,
  }) async {
    try {
      debugPrint('🧪 Starting widget test: $testName');
      
      await testFunction(tester);
      
      debugPrint('✅ Widget test completed: $testName');
    } catch (e, stackTrace) {
      debugPrint('❌ Widget test failed: $testName');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (printWidgetTree) {
        try {
          debugPrint('🌳 Widget tree at failure:');
          debugPrint(tester.binding.renderViewElement?.toStringDeep() ?? 'No widget tree available');
        } catch (treeError) {
          debugPrint('Failed to print widget tree: $treeError');
        }
      }
      
      if (context != null) {
        debugPrint('📋 Test context:');
        for (final entry in context.entries) {
          debugPrint('  ${entry.key}: ${entry.value}');
        }
      }
      
      rethrow;
    }
  }
  
  /// Handle async operations with retry logic
  static Future<T> handleWithRetry<T>(
    Future<T> Function() operation, {
    required String operationName,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    dynamic lastError;
    
    while (attempts < maxRetries) {
      attempts++;
      
      try {
        debugPrint('🔄 Attempt $attempts/$maxRetries for operation: $operationName');
        return await operation();
      } catch (e, stackTrace) {
        lastError = e;
        debugPrint('❌ Attempt $attempts failed for operation "$operationName": $e');
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          debugPrint('🚫 Error is not retryable, stopping attempts');
          rethrow;
        }
        
        // If this was the last attempt, rethrow
        if (attempts >= maxRetries) {
          debugPrint('🚫 Max retries reached for operation "$operationName"');
          rethrow;
        }
        
        // Wait before retrying
        debugPrint('⏳ Waiting ${retryDelay.inMilliseconds}ms before retry...');
        await Future.delayed(retryDelay);
      }
    }
    
    // This should never be reached, but just in case
    throw Exception('Operation "$operationName" failed after $maxRetries attempts. Last error: $lastError');
  }
  
  /// Handle network-related exceptions specifically
  static Future<T> handleNetworkException<T>(
    Future<T> Function() operation, {
    required String operationName,
    T? fallbackValue,
    bool useOfflineMode = false,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      
      // Check if this is a network-related error
      if (errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('timeout') ||
          errorString.contains('socket') ||
          errorString.contains('dns')) {
        
        debugPrint('🌐 Network error detected in operation "$operationName": $e');
        
        if (useOfflineMode && fallbackValue != null) {
          debugPrint('📱 Using offline mode with fallback value');
          return fallbackValue;
        }
        
        throw NetworkException('Network error in operation "$operationName": $e');
      }
      
      // Not a network error, rethrow as-is
      rethrow;
    }
  }
  
  /// Handle API-specific exceptions
  static Future<T> handleApiException<T>(
    Future<T> Function() operation, {
    required String operationName,
    T? fallbackValue,
    bool useFallbackOnError = false,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      
      // Check for API-specific errors
      if (errorString.contains('api') ||
          errorString.contains('401') ||
          errorString.contains('403') ||
          errorString.contains('rate limit') ||
          errorString.contains('quota')) {
        
        debugPrint('🔑 API error detected in operation "$operationName": $e');
        
        if (useFallbackOnError && fallbackValue != null) {
          debugPrint('🔄 Using fallback value for API error');
          return fallbackValue;
        }
        
        throw ApiException('API error in operation "$operationName": $e');
      }
      
      // Not an API error, rethrow as-is
      rethrow;
    }
  }
  
  /// Comprehensive error handler that combines multiple strategies
  static Future<T> handleComprehensive<T>(
    Future<T> Function() operation, {
    required String operationName,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
    T? fallbackValue,
    bool useFallbackOnTimeout = false,
    bool useFallbackOnNetworkError = false,
    bool useFallbackOnApiError = false,
    Map<String, dynamic>? context,
  }) async {
    return await handleTimeoutException(
      () => handleWithRetry(
        () => handleNetworkException(
          () => handleApiException(
            operation,
            operationName: operationName,
            fallbackValue: useFallbackOnApiError ? fallbackValue : null,
            useFallbackOnError: useFallbackOnApiError,
          ),
          operationName: operationName,
          fallbackValue: useFallbackOnNetworkError ? fallbackValue : null,
          useOfflineMode: useFallbackOnNetworkError,
        ),
        operationName: operationName,
        maxRetries: maxRetries,
        retryDelay: retryDelay,
        shouldRetry: (error) {
          // Retry on network errors but not on API auth errors
          final errorString = error.toString().toLowerCase();
          return errorString.contains('network') ||
                 errorString.contains('connection') ||
                 errorString.contains('timeout') ||
                 !errorString.contains('401') &&
                 !errorString.contains('403');
        },
      ),
      operationName: operationName,
      timeout: timeout,
      fallbackValue: useFallbackOnTimeout ? fallbackValue : null,
      rethrowException: !useFallbackOnTimeout,
    );
  }
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Custom exception for API-related errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

/// Custom exception for timeout errors
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: ${timeout.inSeconds}s)';
}