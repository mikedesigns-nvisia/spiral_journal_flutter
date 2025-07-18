import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/utils/app_error_handler.dart';

/// Helper class for improved test diagnostics and error reporting
class TestDiagnosticsHelper {
  /// Provides detailed error messages for common test failures
  static String getDetailedErrorMessage({
    required String expectedBehavior,
    required String actualBehavior,
    String? widgetName,
    String? testContext,
    String? suggestion,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Test Failure:');
    buffer.writeln('- Expected: $expectedBehavior');
    buffer.writeln('- Actual: $actualBehavior');
    
    if (widgetName != null) {
      buffer.writeln('- Widget: $widgetName');
    }
    
    if (testContext != null) {
      buffer.writeln('- Context: $testContext');
    }
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }
    
    return buffer.toString();
  }

  /// Provides detailed error messages for widget finder failures
  static String getFinderErrorMessage({
    required Finder finder,
    required bool shouldExist,
    int? expectedCount,
    String? widgetDescription,
    String? suggestion,
  }) {
    final actualCount = finder.evaluate().length;
    final widgetType = widgetDescription ?? _getFinderDescription(finder);
    
    final buffer = StringBuffer();
    buffer.writeln('Widget Finder Failure:');
    
    if (shouldExist) {
      if (expectedCount != null) {
        buffer.writeln('- Expected: $expectedCount $widgetType widget(s)');
        buffer.writeln('- Found: $actualCount widget(s)');
      } else {
        buffer.writeln('- Expected: At least one $widgetType widget');
        buffer.writeln('- Found: $actualCount widget(s)');
      }
    } else {
      buffer.writeln('- Expected: No $widgetType widgets');
      buffer.writeln('- Found: $actualCount widget(s)');
    }
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }
    
    return buffer.toString();
  }

  /// Provides detailed error messages for callback failures
  static String getCallbackErrorMessage({
    required String callbackName,
    required String expectedBehavior,
    required String actualBehavior,
    String? widgetName,
    String? suggestion,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Callback Failure:');
    buffer.writeln('- Callback: $callbackName');
    buffer.writeln('- Expected: $expectedBehavior');
    buffer.writeln('- Actual: $actualBehavior');
    
    if (widgetName != null) {
      buffer.writeln('- Widget: $widgetName');
    }
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }
    
    return buffer.toString();
  }

  /// Provides detailed error messages for state verification failures
  static String getStateVerificationErrorMessage({
    required String stateName,
    required String expectedState,
    required String actualState,
    String? widgetName,
    String? suggestion,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('State Verification Failure:');
    buffer.writeln('- State: $stateName');
    buffer.writeln('- Expected: $expectedState');
    buffer.writeln('- Actual: $actualState');
    
    if (widgetName != null) {
      buffer.writeln('- Widget: $widgetName');
    }
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }
    
    return buffer.toString();
  }

  /// Provides detailed error messages for theme verification failures
  static String getThemeVerificationErrorMessage({
    required ThemeMode expectedThemeMode,
    required Brightness actualBrightness,
    String? widgetName,
    String? suggestion,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Theme Verification Failure:');
    buffer.writeln('- Expected theme mode: ${expectedThemeMode.name}');
    buffer.writeln('- Actual brightness: ${actualBrightness.name}');
    
    if (widgetName != null) {
      buffer.writeln('- Widget: $widgetName');
    }
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }
    
    return buffer.toString();
  }

  /// Provides detailed error messages for chart data validation failures
  static String getChartDataValidationErrorMessage({
    required String dataType,
    required String issue,
    int? invalidPointCount,
    List<String>? specificIssues,
    String? suggestion,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Chart Data Validation Failure:');
    buffer.writeln('- Data type: $dataType');
    buffer.writeln('- Issue: $issue');
    
    if (invalidPointCount != null) {
      buffer.writeln('- Invalid points: $invalidPointCount');
    }
    
    if (specificIssues != null && specificIssues.isNotEmpty) {
      buffer.writeln('\nSpecific issues:');
      for (final specificIssue in specificIssues) {
        buffer.writeln('  - $specificIssue');
      }
    }
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }
    
    return buffer.toString();
  }

  /// Provides detailed error messages for timeout failures
  static String getTimeoutErrorMessage({
    required String operation,
    required Duration timeout,
    String? widgetName,
    String? suggestion,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Timeout Failure:');
    buffer.writeln('- Operation: $operation');
    buffer.writeln('- Timeout: ${timeout.inMilliseconds}ms');
    
    if (widgetName != null) {
      buffer.writeln('- Widget: $widgetName');
    }
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }
    
    return buffer.toString();
  }

  /// Provides detailed error messages for platform service failures
  static String getPlatformServiceErrorMessage({
    required String serviceName,
    required String expectedBehavior,
    required String actualBehavior,
    String? suggestion,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Platform Service Failure:');
    buffer.writeln('- Service: $serviceName');
    buffer.writeln('- Expected: $expectedBehavior');
    buffer.writeln('- Actual: $actualBehavior');
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }
    
    return buffer.toString();
  }

  /// Provides detailed error messages for binding initialization failures
  static String getBindingErrorMessage({
    required String expectedBehavior,
    required String actualBehavior,
    String? suggestion,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Flutter Binding Failure:');
    buffer.writeln('- Expected: $expectedBehavior');
    buffer.writeln('- Actual: $actualBehavior');
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    } else {
      buffer.writeln('\nSuggestion: Ensure TestWidgetsFlutterBinding.ensureInitialized() is called before the test.');
    }
    
    return buffer.toString();
  }

  /// Provides detailed error messages for app error handling failures
  static String getAppErrorHandlingMessage({
    required AppError error,
    required String expectedBehavior,
    required String actualBehavior,
    String? suggestion,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Error Handling Failure:');
    buffer.writeln('- Error type: ${error.type.name}');
    buffer.writeln('- Error category: ${error.category.name}');
    buffer.writeln('- Expected: $expectedBehavior');
    buffer.writeln('- Actual: $actualBehavior');
    
    if (error.operationName != null) {
      buffer.writeln('- Operation: ${error.operationName}');
    }
    
    if (error.component != null) {
      buffer.writeln('- Component: ${error.component}');
    }
    
    if (suggestion != null) {
      buffer.writeln('\nSuggestion: $suggestion');
    }
    
    return buffer.toString();
  }

  /// Gets a descriptive name for a finder for error messages
  static String _getFinderDescription(Finder finder) {
    final description = finder.description;
    if (description.contains('type ')) {
      return description.replaceAll('"', '');
    }
    if (description.contains('text ')) {
      return description;
    }
    if (description.contains('key ')) {
      return description;
    }
    return description;
  }

  /// Prints the widget tree for debugging
  static void printWidgetTree(WidgetTester tester, {String? message}) {
    if (message != null) {
      debugPrint('\n=== $message ===');
    } else {
      debugPrint('\n=== Widget Tree ===');
    }
    
    debugPrint(tester.allWidgets.map((widget) => widget.toString()).join('\n'));
    debugPrint('===================\n');
  }

  /// Prints the element tree for more detailed debugging
  static void printElementTree(WidgetTester tester, {String? message}) {
    if (message != null) {
      debugPrint('\n=== $message ===');
    } else {
      debugPrint('\n=== Element Tree ===');
    }
    
    debugDumpRenderTree();
    debugPrint('===================\n');
  }

  /// Creates a diagnostic context for test failures
  static Map<String, dynamic> createDiagnosticContext({
    required String testName,
    required String failureReason,
    Map<String, dynamic>? additionalContext,
  }) {
    final context = <String, dynamic>{
      'testName': testName,
      'failureReason': failureReason,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (additionalContext != null) {
      context.addAll(additionalContext);
    }
    
    return context;
  }

  /// Runs a test with diagnostic context
  static Future<T> runWithDiagnostics<T>(
    Future<T> Function() testFunction, {
    required String testName,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      return await testFunction();
    } catch (error, stackTrace) {
      final context = createDiagnosticContext(
        testName: testName,
        failureReason: error.toString(),
        additionalContext: additionalContext,
      );
      
      debugPrint('\n=== Test Failure Diagnostics ===');
      debugPrint('Test: $testName');
      debugPrint('Error: $error');
      debugPrint('Context: $context');
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('===============================\n');
      
      rethrow;
    }
  }

  /// Verifies a condition with a detailed error message
  static void verifyCondition(
    bool condition, {
    required String message,
    String? suggestion,
  }) {
    if (!condition) {
      final errorMessage = suggestion != null
          ? '$message\n\nSuggestion: $suggestion'
          : message;
      
      fail(errorMessage);
    }
  }

  /// Verifies equality with a detailed error message
  static void verifyEquals<T>(
    T actual,
    T expected, {
    required String message,
    String? suggestion,
  }) {
    if (actual != expected) {
      final errorMessage = StringBuffer();
      errorMessage.writeln(message);
      errorMessage.writeln('- Expected: $expected');
      errorMessage.writeln('- Actual: $actual');
      
      if (suggestion != null) {
        errorMessage.writeln('\nSuggestion: $suggestion');
      }
      
      fail(errorMessage.toString());
    }
  }

  /// Verifies that a widget exists with a detailed error message
  static void verifyWidgetExists(
    Finder finder, {
    required String widgetDescription,
    String? suggestion,
  }) {
    final count = finder.evaluate().length;
    if (count == 0) {
      final errorMessage = getFinderErrorMessage(
        finder: finder,
        shouldExist: true,
        widgetDescription: widgetDescription,
        suggestion: suggestion,
      );
      
      fail(errorMessage);
    }
  }

  /// Verifies that a widget does not exist with a detailed error message
  static void verifyWidgetDoesNotExist(
    Finder finder, {
    required String widgetDescription,
    String? suggestion,
  }) {
    final count = finder.evaluate().length;
    if (count > 0) {
      final errorMessage = getFinderErrorMessage(
        finder: finder,
        shouldExist: false,
        widgetDescription: widgetDescription,
        suggestion: suggestion,
      );
      
      fail(errorMessage);
    }
  }

  /// Verifies that a widget count matches expected count with a detailed error message
  static void verifyWidgetCount(
    Finder finder,
    int expectedCount, {
    required String widgetDescription,
    String? suggestion,
  }) {
    final actualCount = finder.evaluate().length;
    if (actualCount != expectedCount) {
      final errorMessage = getFinderErrorMessage(
        finder: finder,
        shouldExist: true,
        expectedCount: expectedCount,
        widgetDescription: widgetDescription,
        suggestion: suggestion,
      );
      
      fail(errorMessage);
    }
  }
}

/// Extension on WidgetTester to provide diagnostic helpers
extension DiagnosticWidgetTester on WidgetTester {
  /// Prints the current widget tree for debugging
  void printCurrentWidgetTree({String? message}) {
    TestDiagnosticsHelper.printWidgetTree(this, message: message);
  }
  
  /// Prints the current element tree for more detailed debugging
  void printCurrentElementTree({String? message}) {
    TestDiagnosticsHelper.printElementTree(this, message: message);
  }
  
  /// Taps a widget with diagnostic error handling
  Future<void> tapWithDiagnostics(
    Finder finder, {
    required String widgetDescription,
    String? suggestion,
  }) async {
    TestDiagnosticsHelper.verifyWidgetExists(
      finder,
      widgetDescription: widgetDescription,
      suggestion: suggestion ?? 'Make sure the widget is visible and enabled before tapping',
    );
    
    await tap(finder);
    await pumpAndSettle();
  }
  
  /// Enters text with diagnostic error handling
  Future<void> enterTextWithDiagnostics(
    Finder finder,
    String text, {
    required String widgetDescription,
    String? suggestion,
  }) async {
    TestDiagnosticsHelper.verifyWidgetExists(
      finder,
      widgetDescription: widgetDescription,
      suggestion: suggestion ?? 'Make sure the text field is visible and enabled before entering text',
    );
    
    await enterText(finder, text);
    await pumpAndSettle();
  }
  
  /// Scrolls until a widget is visible with diagnostic error handling
  Future<void> scrollUntilVisibleWithDiagnostics(
    Finder finder, {
    required String widgetDescription,
    double delta = 100.0,
    Finder? scrollable,
    Duration timeout = const Duration(seconds: 10),
    String? suggestion,
  }) async {
    final scrollableFinder = scrollable ?? find.byType(Scrollable);
    TestDiagnosticsHelper.verifyWidgetExists(
      scrollableFinder,
      widgetDescription: 'Scrollable widget',
      suggestion: 'Make sure there is a scrollable widget in the widget tree',
    );
    
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
      final errorMessage = TestDiagnosticsHelper.getTimeoutErrorMessage(
        operation: 'Scrolling to find $widgetDescription',
        timeout: timeout,
        suggestion: suggestion ?? 'The widget may not exist in the scrollable area',
      );
      
      fail(errorMessage);
    }
  }
}