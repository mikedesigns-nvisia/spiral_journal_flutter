import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Comprehensive network error handler for iOS Anthropic API connectivity
/// 
/// Handles DNS resolution failures (errno 8), network timeouts, and provides
/// exponential backoff retry logic with iOS-specific error detection
class NetworkErrorHandler {
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _defaultTimeout = Duration(seconds: 30);
  
  /// Handle network errors with iOS-specific DNS failure detection
  static Future<T> handleNetworkRequest<T>(
    Future<T> Function() request, {
    int maxRetries = _maxRetries,
    Duration baseDelay = _baseRetryDelay,
    Duration timeout = _defaultTimeout,
    String operation = 'network_request',
  }) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🌐 NetworkErrorHandler: Attempting $operation (${attempt}/$maxRetries)');
        
        return await request().timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'Request timed out after ${timeout.inSeconds}s', 
            timeout,
          ),
        );
      } on SocketException catch (e) {
        lastException = await _handleSocketException(e, attempt, maxRetries, operation);
        if (attempt < maxRetries && _isRetryableSocketError(e)) {
          await _waitForRetry(attempt, baseDelay);
        } else {
          break;
        }
      } on TimeoutException catch (e) {
        lastException = NetworkException(
          'Connection timed out after ${timeout.inSeconds} seconds',
          type: NetworkErrorType.timeout,
          isRetryable: true,
          originalError: e,
          errno: null,
        );
        if (attempt < maxRetries) {
          await _waitForRetry(attempt, baseDelay);
        }
      } on HttpException catch (e) {
        lastException = await _handleHttpException(e, attempt, maxRetries, operation);
        if (attempt < maxRetries && _isRetryableHttpError(e)) {
          await _waitForRetry(attempt, baseDelay);
        } else {
          break;
        }
      } catch (e) {
        lastException = NetworkException(
          'Unexpected network error: ${e.toString()}',
          type: NetworkErrorType.unknown,
          isRetryable: attempt < maxRetries,
          originalError: e,
          errno: null,
        );
        if (attempt < maxRetries) {
          await _waitForRetry(attempt, baseDelay);
        }
      }
    }
    
    throw lastException ?? NetworkException(
      'Network request failed after $maxRetries attempts',
      type: NetworkErrorType.unknown,
      isRetryable: false,
      originalError: null,
      errno: null,
    );
  }
  
  /// Handle SocketException with iOS DNS errno 8 detection
  static Future<NetworkException> _handleSocketException(
    SocketException e, 
    int attempt, 
    int maxRetries,
    String operation,
  ) async {
    final errno = e.osError?.errorCode;
    final message = e.osError?.message ?? e.message;
    
    // iOS-specific DNS resolution failure (errno 8)
    if (errno == 8) {
      debugPrint('🔴 NetworkErrorHandler: DNS resolution failure detected (errno 8)');
      debugPrint('   Address: ${e.address?.host}');
      debugPrint('   Port: ${e.port}');
      debugPrint('   Message: $message');
      
      return NetworkException(
        'DNS resolution failed. Please check your internet connection.',
        type: NetworkErrorType.dnsFailure,
        isRetryable: true,
        originalError: e,
        errno: errno,
        userMessage: 'Unable to connect. Please check your internet connection and try again.',
      );
    }
    
    // Network unreachable (errno 51)
    if (errno == 51) {
      return NetworkException(
        'Network is unreachable',
        type: NetworkErrorType.networkUnreachable,
        isRetryable: true,
        originalError: e,
        errno: errno,
        userMessage: 'Network is currently unavailable. Please try again later.',
      );
    }
    
    // Connection refused (errno 61)
    if (errno == 61) {
      return NetworkException(
        'Connection refused by server',
        type: NetworkErrorType.connectionRefused,
        isRetryable: false,
        originalError: e,
        errno: errno,
        userMessage: 'Unable to connect to the service. Please try again later.',
      );
    }
    
    // Host not found (errno 8 variant)
    if (message.toLowerCase().contains('nodename nor servname provided')) {
      return NetworkException(
        'Host not found during DNS lookup',
        type: NetworkErrorType.dnsFailure,
        isRetryable: true,
        originalError: e,
        errno: errno,
        userMessage: 'Connection failed. Please check your internet connection.',
      );
    }
    
    // Generic socket error
    return NetworkException(
      'Network connection failed: $message',
      type: NetworkErrorType.socketError,
      isRetryable: _isRetryableErrno(errno),
      originalError: e,
      errno: errno,
      userMessage: 'Connection problem. Please check your internet connection.',
    );
  }
  
  /// Handle HTTP exceptions
  static Future<NetworkException> _handleHttpException(
    HttpException e,
    int attempt,
    int maxRetries,
    String operation,
  ) async {
    final statusCode = _extractStatusCode(e.message);
    
    if (statusCode == 401) {
      return NetworkException(
        'Authentication failed - invalid API key',
        type: NetworkErrorType.authentication,
        isRetryable: false,
        originalError: e,
        errno: null,
        userMessage: 'Authentication error. Please check your API key configuration.',
      );
    }
    
    if (statusCode == 429) {
      return NetworkException(
        'Rate limit exceeded',
        type: NetworkErrorType.rateLimit,
        isRetryable: true,
        originalError: e,
        errno: null,
        userMessage: 'Service is busy. Please wait a moment and try again.',
      );
    }
    
    if (statusCode != null && statusCode >= 500) {
      return NetworkException(
        'Server error: HTTP $statusCode',
        type: NetworkErrorType.serverError,
        isRetryable: true,
        originalError: e,
        errno: null,
        userMessage: 'Service temporarily unavailable. Please try again.',
      );
    }
    
    return NetworkException(
      'HTTP error: ${e.message}',
      type: NetworkErrorType.httpError,
      isRetryable: false,
      originalError: e,
      errno: null,
      userMessage: 'Connection error. Please try again.',
    );
  }
  
  /// Check if socket error is retryable based on errno
  static bool _isRetryableSocketError(SocketException e) {
    final errno = e.osError?.errorCode;
    return _isRetryableErrno(errno);
  }
  
  /// Check if HTTP error is retryable
  static bool _isRetryableHttpError(HttpException e) {
    final statusCode = _extractStatusCode(e.message);
    if (statusCode == null) return true;
    
    // Retry on server errors and rate limits, not on client errors
    return statusCode >= 500 || statusCode == 429;
  }
  
  /// Check if errno indicates a retryable error
  static bool _isRetryableErrno(int? errno) {
    if (errno == null) return true;
    
    const retryableErrCodes = {
      8,   // DNS resolution failure - retry
      51,  // Network unreachable - retry
      60,  // Operation timed out - retry  
      65,  // No route to host - retry
      54,  // Connection reset by peer - retry
    };
    
    const nonRetryableErrCodes = {
      61,  // Connection refused - don't retry immediately
      13,  // Permission denied - don't retry
      2,   // No such file or directory - don't retry
    };
    
    if (nonRetryableErrCodes.contains(errno)) return false;
    if (retryableErrCodes.contains(errno)) return true;
    
    // Default to retryable for unknown errno
    return true;
  }
  
  /// Extract HTTP status code from exception message
  static int? _extractStatusCode(String message) {
    final regex = RegExp(r'(\d{3})');
    final match = regex.firstMatch(message);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
  
  /// Wait with exponential backoff
  static Future<void> _waitForRetry(int attempt, Duration baseDelay) async {
    final delayMs = baseDelay.inMilliseconds * pow(2, attempt - 1);
    final jitter = Random().nextInt(1000); // Add jitter to prevent thundering herd
    final totalDelay = Duration(milliseconds: delayMs.toInt() + jitter);
    
    debugPrint('⏳ NetworkErrorHandler: Waiting ${totalDelay.inMilliseconds}ms before retry...');
    await Future.delayed(totalDelay);
  }
  
  /// Get user-friendly error message for UI display
  static String getUserFriendlyMessage(NetworkException error) {
    if (error.userMessage != null) {
      return error.userMessage!;
    }
    
    switch (error.type) {
      case NetworkErrorType.dnsFailure:
        return 'Unable to connect. Please check your internet connection.';
      case NetworkErrorType.timeout:
        return 'Connection timed out. Tap to retry.';
      case NetworkErrorType.networkUnreachable:
        return 'Network is unavailable. Please check your connection.';
      case NetworkErrorType.rateLimit:
        return 'Service is busy. Please wait a moment and try again.';
      case NetworkErrorType.authentication:
        return 'Authentication error. Please check your settings.';
      case NetworkErrorType.serverError:
        return 'Service temporarily unavailable. Please try again.';
      default:
        return 'Connection problem. Please try again.';
    }
  }
}

/// Network error types for categorization
enum NetworkErrorType {
  dnsFailure,
  timeout,
  networkUnreachable,
  connectionRefused,
  socketError,
  httpError,
  authentication,
  rateLimit,
  serverError,
  unknown,
}

/// Custom network exception with iOS-specific error information
class NetworkException implements Exception {
  final String message;
  final NetworkErrorType type;
  final bool isRetryable;
  final dynamic originalError;
  final int? errno;
  final String? userMessage;
  
  NetworkException(
    this.message, {
    required this.type,
    required this.isRetryable,
    required this.originalError,
    required this.errno,
    this.userMessage,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('NetworkException: $message');
    if (errno != null) {
      buffer.write(' (errno: $errno)');
    }
    buffer.write(' [${type.name}]');
    if (isRetryable) {
      buffer.write(' [retryable]');
    }
    return buffer.toString();
  }
  
  /// Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'type': type.name,
      'isRetryable': isRetryable,
      'errno': errno,
      'userMessage': userMessage,
      'originalError': originalError?.toString(),
    };
  }
}