import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/utils/app_error_handler.dart';
import 'test_diagnostics_helper.dart';

/// Handler for test exceptions with improved error context and fallback behavior
class TestExceptionHandler {
  /// Runs a test function with proper exception handling and diagnostics
  static Future<T> runWithExceptionHandling<T>(
    Future<T> Function() testFunction, {
    required String testName,
    Map<String, dynamic>? context,
    T? fallbackValue,
    bool rethrowException = true,
  }) async {
    try {
      return await testFunction();
    } catch (error, stackTrace) {
      final errorContext = TestDiagnosticsHelper.createDiagnosticContext(
        testName: testName,
        failureReason: error.toString(),
        additionalContext: context,
      );
      
      _logTestException(error, stackTrace, errorContext);
      
      if (fallbackValue != null) {
        debugPrint('Returning fallback value for test: $testName');
        return fallbackValue;
      }
      
      if (rethrowException) {
        rethrow;
      }
      
      throw TestFailure('Test failed: $testName - $error');
    }
  }

  /// Runs a widget test with proper exception handling and diagnostics
  static Future<void> runWidgetTest(
    WidgetTester tester,
    Future<void> Function(WidgetTester) testFunction, {
    required String testName,
    Map<String, dynamic>? context,
    bool printWidgetTree = true,
  }) async {
    try {
      await testFunction(tester);
    } catch (error, stackTrace) {
      final errorContext = TestDiagnosticsHelper.createDiagnosticContext(
        testName: testName,
        failureReason: error.toString(),
        additionalContext: context,
      );
      
      if (printWidgetTree) {
        try {
          TestDiagnosticsHelper.printWidgetTree(tester, message: 'Widget tree at failure');
        } catch (e) {
          debugPrint('Could not print widget tree: $e');
        }
      }
      
      _logTestException(error, stackTrace, errorContext);
      rethrow;
    }
  }

  /// Handles platform service exceptions with fallback behavior
  static Future<T> handlePlatformServiceException<T>(
    Future<T> Function() serviceCall, {
    required String serviceName,
    required String methodName,
    T? fallbackValue,
    bool rethrowException = true,
  }) async {
    try {
      return await serviceCall();
    } on PlatformException catch (error, stackTrace) {
      final errorMessage = TestDiagnosticsHelper.getPlatformServiceErrorMessage(
        serviceName: serviceName,
        expectedBehavior: 'Platform service call to $methodName should succeed',
        actualBehavior: 'Platform service call failed: ${error.message}',
        suggestion: 'Mock the platform channel response for $serviceName.$methodName',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      if (fallbackValue != null) {
        debugPrint('Returning fallback value for platform service call: $serviceName.$methodName');
        return fallbackValue;
      }
      
      if (rethrowException) {
        rethrow;
      }
      
      throw TestFailure('Platform service call failed: $serviceName.$methodName - ${error.message}');
    } catch (error, stackTrace) {
      final errorMessage = TestDiagnosticsHelper.getPlatformServiceErrorMessage(
        serviceName: serviceName,
        expectedBehavior: 'Platform service call to $methodName should succeed',
        actualBehavior: 'Unexpected error: $error',
        suggestion: 'Check if the platform service is properly mocked',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      if (fallbackValue != null) {
        debugPrint('Returning fallback value for platform service call: $serviceName.$methodName');
        return fallbackValue;
      }
      
      if (rethrowException) {
        rethrow;
      }
      
      throw TestFailure('Platform service call failed: $serviceName.$methodName - $error');
    }
  }

  /// Handles timeout exceptions with detailed error messages
  static Future<T> handleTimeoutException<T>(
    Future<T> Function() operation, {
    required String operationName,
    required Duration timeout,
    T? fallbackValue,
    bool rethrowException = true,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException catch (error, stackTrace) {
      final errorMessage = TestDiagnosticsHelper.getTimeoutErrorMessage(
        operation: operationName,
        timeout: timeout,
        suggestion: 'Check if the operation is taking too long or stuck in an infinite loop',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      if (fallbackValue != null) {
        debugPrint('Returning fallback value for timed out operation: $operationName');
        return fallbackValue;
      }
      
      if (rethrowException) {
        rethrow;
      }
      
      throw TestFailure('Operation timed out: $operationName - ${error.message}');
    }
  }

  /// Handles app errors with detailed error messages
  static Future<T> handleAppError<T>(
    Future<T> Function() operation, {
    required String operationName,
    T? fallbackValue,
    bool rethrowException = true,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      AppError appError;
      
      if (error is AppError) {
        appError = error;
      } else {
        appError = AppError(
          type: ErrorType.unknown,
          category: ErrorCategory.general,
          message: error.toString(),
          userMessage: 'An unexpected error occurred during testing',
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
          operationName: operationName,
          isRecoverable: false,
        );
      }
      
      final errorMessage = TestDiagnosticsHelper.getAppErrorHandlingMessage(
        error: appError,
        expectedBehavior: 'Operation $operationName should succeed',
        actualBehavior: 'Operation failed with error: ${appError.message}',
        suggestion: 'Check error handling for ${appError.type.name} errors',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      if (fallbackValue != null) {
        debugPrint('Returning fallback value for failed operation: $operationName');
        return fallbackValue;
      }
      
      if (rethrowException) {
        rethrow;
      }
      
      throw TestFailure('Operation failed: $operationName - ${appError.message}');
    }
  }

  /// Wraps a finder with exception handling and better error messages
  static Finder findWithErrorHandling(
    Finder Function() finderFunction, {
    required String widgetDescription,
    String? suggestion,
  }) {
    try {
      return finderFunction();
    } catch (error) {
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to find $widgetDescription',
        actualBehavior: 'Failed to create finder: $error',
        suggestion: suggestion ?? 'Check if the widget exists in the widget tree',
      );
      
      throw TestFailure(errorMessage);
    }
  }

  /// Verifies a condition with exception handling and better error messages
  static void verifyWithErrorHandling(
    bool Function() condition, {
    required String expectedBehavior,
    required String failureMessage,
    String? suggestion,
  }) {
    try {
      final result = condition();
      if (!result) {
        final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
          expectedBehavior: expectedBehavior,
          actualBehavior: failureMessage,
          suggestion: suggestion,
        );
        
        throw TestFailure(errorMessage);
      }
    } catch (error) {
      if (error is TestFailure) {
        rethrow;
      }
      
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: expectedBehavior,
        actualBehavior: 'Exception during verification: $error',
        suggestion: suggestion,
      );
      
      throw TestFailure(errorMessage);
    }
  }

  /// Creates a fallback for platform service calls
  static T createPlatformServiceFallback<T>({
    required String serviceName,
    required String methodName,
    required T fallbackValue,
  }) {
    debugPrint('Using fallback value for platform service: $serviceName.$methodName');
    return fallbackValue;
  }

  /// Logs test exceptions with detailed context
  static void _logTestException(
    Object error,
    StackTrace stackTrace,
    Map<String, dynamic> context,
  ) {
    debugPrint('\n=== Test Exception ===');
    debugPrint('Error: $error');
    debugPrint('Context: $context');
    debugPrint('Stack trace:');
    debugPrint(stackTrace.toString());
    debugPrint('======================\n');
  }
}

/// Extension on WidgetTester for exception handling
extension ExceptionHandlingWidgetTester on WidgetTester {
  /// Taps a widget with exception handling
  Future<void> tapWithExceptionHandling(
    Finder finder, {
    required String widgetDescription,
    String? suggestion,
  }) async {
    try {
      await tap(finder);
      await pumpAndSettle();
    } catch (error) {
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to tap $widgetDescription',
        actualBehavior: 'Failed to tap widget: $error',
        widgetName: widgetDescription,
        suggestion: suggestion ?? 'Check if the widget is visible and enabled',
      );
      
      throw TestFailure(errorMessage);
    }
  }

  /// Enters text with exception handling
  Future<void> enterTextWithExceptionHandling(
    Finder finder,
    String text, {
    required String widgetDescription,
    String? suggestion,
  }) async {
    try {
      await enterText(finder, text);
      await pumpAndSettle();
    } catch (error) {
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to enter text in $widgetDescription',
        actualBehavior: 'Failed to enter text: $error',
        widgetName: widgetDescription,
        suggestion: suggestion ?? 'Check if the text field is visible and enabled',
      );
      
      throw TestFailure(errorMessage);
    }
  }

  /// Scrolls until a widget is visible with exception handling
  Future<void> scrollUntilVisibleWithExceptionHandling(
    Finder finder, {
    required String widgetDescription,
    double delta = 100.0,
    Finder? scrollable,
    Duration timeout = const Duration(seconds: 10),
    String? suggestion,
  }) async {
    final scrollableFinder = scrollable ?? find.byType(Scrollable);
    
    try {
      if (scrollableFinder.evaluate().isEmpty) {
        throw TestFailure('No scrollable widget found');
      }
      
      final stopwatch = Stopwatch()..start();
      bool isVisible = false;
      
      while (!isVisible && stopwatch.elapsed < timeout) {
        if (finder.evaluate().isNotEmpty) {
          isVisible = true;
          break;
        }
        
        await scrollUntilVisible(
          finder,
          delta,
          scrollable: scrollableFinder,
        );
        
        await pump(const Duration(milliseconds: 100));
      }
      
      if (!isVisible) {
        throw TimeoutException('Widget not found within timeout', timeout);
      }
    } catch (error) {
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to scroll to $widgetDescription',
        actualBehavior: 'Failed to scroll to widget: $error',
        widgetName: widgetDescription,
        suggestion: suggestion ?? 'Check if the widget exists in the scrollable area',
      );
      
      throw TestFailure(errorMessage);
    }
  }

  /// Pumps a widget with exception handling
  Future<void> pumpWidgetWithExceptionHandling(
    Widget widget, {
    Duration? duration,
    String? widgetDescription,
    String? suggestion,
  }) async {
    try {
      await pumpWidget(widget);
    } catch (error) {
      final description = widgetDescription ?? widget.runtimeType.toString();
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to pump $description widget',
        actualBehavior: 'Failed to pump widget: $error',
        widgetName: description,
        suggestion: suggestion ?? 'Check if the widget can be built without errors',
      );
      
      throw TestFailure(errorMessage);
    }
  }

  /// Pumps and settles with exception handling and timeout
  Future<void> pumpAndSettleWithExceptionHandling({
    Duration timeout = const Duration(seconds: 10),
    String? operationDescription,
    String? suggestion,
  }) async {
    try {
      await pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, timeout);
    } catch (error) {
      final description = operationDescription ?? 'widget animations';
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to pump and settle $description',
        actualBehavior: 'Failed to pump and settle: $error',
        suggestion: suggestion ?? 'Check if there are infinite animations or rebuilds',
      );
      
      throw TestFailure(errorMessage);
    }
  }
}

/// Extension on Finder for exception handling
extension ExceptionHandlingFinder on Finder {
  /// Evaluates a finder with exception handling
  List<Element> evaluateWithExceptionHandling({
    required String widgetDescription,
    String? suggestion,
  }) {
    try {
      return evaluate().toList();
    } catch (error) {
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to evaluate finder for $widgetDescription',
        actualBehavior: 'Failed to evaluate finder: $error',
        widgetName: widgetDescription,
        suggestion: suggestion ?? 'Check if the widget exists in the widget tree',
      );
      
      throw TestFailure(errorMessage);
    }
  }

  /// Gets the first widget with exception handling
  T getWidgetWithExceptionHandling<T extends Widget>({
    required String widgetDescription,
    String? suggestion,
  }) {
    try {
      final elements = evaluate();
      if (elements.isEmpty) {
        throw TestFailure('No widgets found matching finder');
      }
      
      final widget = elements.first.widget;
      if (widget is! T) {
        throw TestFailure('Widget is not of type $T, found ${widget.runtimeType} instead');
      }
      
      return widget;
    } catch (error) {
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to get $T widget for $widgetDescription',
        actualBehavior: 'Failed to get widget: $error',
        widgetName: widgetDescription,
        suggestion: suggestion ?? 'Check if the widget exists and is of the correct type',
      );
      
      throw TestFailure(errorMessage);
    }
  }
}