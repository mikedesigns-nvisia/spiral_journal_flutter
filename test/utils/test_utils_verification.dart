import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/utils/app_error_handler.dart';
import 'test_diagnostics_helper.dart';
import 'test_exception_handler.dart';

/// Utility class for verifying test utilities and error handling
class TestUtilsVerification {
  /// Verifies that the test diagnostics helper is working correctly
  static void verifyTestDiagnosticsHelper() {
    final detailedMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
      expectedBehavior: 'Button should be enabled',
      actualBehavior: 'Button is disabled',
      widgetName: 'SubmitButton',
      testContext: 'Form submission test',
      suggestion: 'Check if form validation is preventing button activation',
    );
    
    if (!detailedMessage.contains('Expected: Button should be enabled') ||
        !detailedMessage.contains('Actual: Button is disabled') ||
        !detailedMessage.contains('Widget: SubmitButton') ||
        !detailedMessage.contains('Context: Form submission test') ||
        !detailedMessage.contains('Suggestion: Check if form validation is preventing button activation')) {
      throw TestFailure('TestDiagnosticsHelper.getDetailedErrorMessage is not formatting messages correctly');
    }
  }

  /// Verifies that the test exception handler is working correctly
  static Future<void> verifyTestExceptionHandler() async {
    bool exceptionCaught = false;
    
    try {
      await TestExceptionHandler.runWithExceptionHandling<void>(
        () async {
          throw Exception('Test exception');
        },
        testName: 'Test Exception Handler Verification',
        rethrowException: false,
        fallbackValue: null,
      );
    } catch (e) {
      exceptionCaught = true;
    }
    
    if (!exceptionCaught) {
      throw TestFailure('TestExceptionHandler.runWithExceptionHandling did not handle the exception correctly');
    }
    
    // Test with fallback value
    final result = await TestExceptionHandler.runWithExceptionHandling<String>(
      () async {
        throw Exception('Test exception');
      },
      testName: 'Test Exception Handler Verification',
      rethrowException: false,
      fallbackValue: 'Fallback',
    );
    
    if (result != 'Fallback') {
      throw TestFailure('TestExceptionHandler.runWithExceptionHandling did not return the fallback value');
    }
  }

  /// Verifies that platform service exception handling is working correctly
  static Future<void> verifyPlatformServiceExceptionHandling() async {
    final result = await TestExceptionHandler.handlePlatformServiceException<String>(
      () async {
        throw PlatformException(code: 'TEST_ERROR', message: 'Test platform exception');
      },
      serviceName: 'TestService',
      methodName: 'testMethod',
      fallbackValue: 'Fallback',
      rethrowException: false,
    );
    
    if (result != 'Fallback') {
      throw TestFailure('TestExceptionHandler.handlePlatformServiceException did not return the fallback value');
    }
  }

  /// Verifies that timeout exception handling is working correctly
  static Future<void> verifyTimeoutExceptionHandling() async {
    final result = await TestExceptionHandler.handleTimeoutException<String>(
      () async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 'Result';
      },
      operationName: 'Test Operation',
      timeout: const Duration(milliseconds: 50),
      fallbackValue: 'Fallback',
      rethrowException: false,
    );
    
    if (result != 'Fallback') {
      throw TestFailure('TestExceptionHandler.handleTimeoutException did not return the fallback value');
    }
  }

  /// Verifies that app error handling is working correctly
  static Future<void> verifyAppErrorHandling() async {
    final appError = AppError(
      type: ErrorType.network,
      category: ErrorCategory.connectivity,
      message: 'Test error',
      userMessage: 'Test user message',
      stackTrace: StackTrace.current,
      timestamp: DateTime.now(),
      isRecoverable: true,
    );
    
    final result = await TestExceptionHandler.handleAppError<String>(
      () async {
        throw appError;
      },
      operationName: 'Test Operation',
      fallbackValue: 'Fallback',
      rethrowException: false,
    );
    
    if (result != 'Fallback') {
      throw TestFailure('TestExceptionHandler.handleAppError did not return the fallback value');
    }
  }

  /// Verifies that finder exception handling is working correctly
  static void verifyFinderExceptionHandling() {
    try {
      TestExceptionHandler.findWithErrorHandling(
        () {
          throw Exception('Test exception');
        },
        widgetDescription: 'Test Widget',
        suggestion: 'Check widget existence',
      );
      throw TestFailure('TestExceptionHandler.findWithErrorHandling did not throw an exception');
    } catch (e) {
      if (e is! TestFailure || !e.toString().contains('Test Widget')) {
        throw TestFailure('TestExceptionHandler.findWithErrorHandling did not format the error message correctly');
      }
    }
  }

  /// Verifies that condition verification with error handling is working correctly
  static void verifyConditionVerification() {
    try {
      TestExceptionHandler.verifyWithErrorHandling(
        () => false,
        expectedBehavior: 'Condition should be true',
        failureMessage: 'Condition is false',
        suggestion: 'Check condition logic',
      );
      throw TestFailure('TestExceptionHandler.verifyWithErrorHandling did not throw an exception');
    } catch (e) {
      if (e is! TestFailure || !e.toString().contains('Condition should be true')) {
        throw TestFailure('TestExceptionHandler.verifyWithErrorHandling did not format the error message correctly');
      }
    }
  }

  /// Runs all verification tests
  static Future<void> runAllVerifications() async {
    verifyTestDiagnosticsHelper();
    await verifyTestExceptionHandler();
    await verifyPlatformServiceExceptionHandling();
    await verifyTimeoutExceptionHandling();
    await verifyAppErrorHandling();
    verifyFinderExceptionHandling();
    verifyConditionVerification();
  }
}
