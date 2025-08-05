import 'package:flutter/foundation.dart';

/// Helper class for generating detailed diagnostic messages in tests
class TestDiagnosticsHelper {
  
  /// Generate detailed error message for test failures
  static String getDetailedErrorMessage({
    required String expectedBehavior,
    required String actualBehavior,
    String? testContext,
    String? suggestion,
    Map<String, dynamic>? additionalData,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('🔍 Test Diagnostic Information');
    buffer.writeln('=' * 50);
    
    if (testContext != null) {
      buffer.writeln('📋 Test Context: $testContext');
    }
    
    buffer.writeln('✅ Expected: $expectedBehavior');
    buffer.writeln('❌ Actual: $actualBehavior');
    
    if (suggestion != null) {
      buffer.writeln('💡 Suggestion: $suggestion');
    }
    
    if (additionalData != null && additionalData.isNotEmpty) {
      buffer.writeln('📊 Additional Data:');
      for (final entry in additionalData.entries) {
        buffer.writeln('  • ${entry.key}: ${entry.value}');
      }
    }
    
    buffer.writeln('=' * 50);
    
    return buffer.toString();
  }
  
  /// Generate binding error message
  static String getBindingErrorMessage({
    required String expectedBehavior,
    required String actualBehavior,
    String? suggestion,
  }) {
    return getDetailedErrorMessage(
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      testContext: 'Flutter Binding Initialization',
      suggestion: suggestion ?? 'Ensure TestWidgetsFlutterBinding.ensureInitialized() is called',
    );
  }
  
  /// Generate platform service error message
  static String getPlatformServiceErrorMessage({
    required String serviceName,
    required String expectedBehavior,
    required String actualBehavior,
    String? suggestion,
  }) {
    return getDetailedErrorMessage(
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      testContext: 'Platform Service: $serviceName',
      suggestion: suggestion ?? 'Check platform channel configuration and mock setup',
    );
  }
  
  /// Generate AI service error message
  static String getAIServiceErrorMessage({
    required String operation,
    required String expectedBehavior,
    required String actualBehavior,
    String? apiKeyStatus,
    String? providerType,
    String? suggestion,
  }) {
    final additionalData = <String, dynamic>{};
    
    if (apiKeyStatus != null) {
      additionalData['API Key Status'] = apiKeyStatus;
    }
    
    if (providerType != null) {
      additionalData['Provider Type'] = providerType;
    }
    
    return getDetailedErrorMessage(
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      testContext: 'AI Service Operation: $operation',
      suggestion: suggestion ?? 'Check AI service configuration and API key validity',
      additionalData: additionalData,
    );
  }
  
  /// Generate network error message
  static String getNetworkErrorMessage({
    required String operation,
    required String expectedBehavior,
    required String actualBehavior,
    String? endpoint,
    int? statusCode,
    String? suggestion,
  }) {
    final additionalData = <String, dynamic>{};
    
    if (endpoint != null) {
      additionalData['Endpoint'] = endpoint;
    }
    
    if (statusCode != null) {
      additionalData['Status Code'] = statusCode;
    }
    
    return getDetailedErrorMessage(
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      testContext: 'Network Operation: $operation',
      suggestion: suggestion ?? 'Check network connectivity and endpoint availability',
      additionalData: additionalData,
    );
  }
  
  /// Generate database error message
  static String getDatabaseErrorMessage({
    required String operation,
    required String expectedBehavior,
    required String actualBehavior,
    String? tableName,
    String? suggestion,
  }) {
    final additionalData = <String, dynamic>{};
    
    if (tableName != null) {
      additionalData['Table'] = tableName;
    }
    
    return getDetailedErrorMessage(
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      testContext: 'Database Operation: $operation',
      suggestion: suggestion ?? 'Check database schema and connection',
      additionalData: additionalData,
    );
  }
  
  /// Generate widget test error message
  static String getWidgetTestErrorMessage({
    required String widgetType,
    required String expectedBehavior,
    required String actualBehavior,
    String? widgetKey,
    String? suggestion,
  }) {
    final additionalData = <String, dynamic>{};
    
    if (widgetKey != null) {
      additionalData['Widget Key'] = widgetKey;
    }
    
    return getDetailedErrorMessage(
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      testContext: 'Widget Test: $widgetType',
      suggestion: suggestion ?? 'Check widget state and test setup',
      additionalData: additionalData,
    );
  }
  
  /// Generate integration test error message
  static String getIntegrationTestErrorMessage({
    required String testFlow,
    required String expectedBehavior,
    required String actualBehavior,
    String? failurePoint,
    List<String>? completedSteps,
    String? suggestion,
  }) {
    final additionalData = <String, dynamic>{};
    
    if (failurePoint != null) {
      additionalData['Failure Point'] = failurePoint;
    }
    
    if (completedSteps != null && completedSteps.isNotEmpty) {
      additionalData['Completed Steps'] = completedSteps.join(', ');
    }
    
    return getDetailedErrorMessage(
      expectedBehavior: expectedBehavior,
      actualBehavior: actualBehavior,
      testContext: 'Integration Test: $testFlow',
      suggestion: suggestion ?? 'Check service integration and data flow',
      additionalData: additionalData,
    );
  }
  
  /// Generate performance test error message
  static String getPerformanceTestErrorMessage({
    required String operation,
    required Duration expectedDuration,
    required Duration actualDuration,
    String? suggestion,
  }) {
    final additionalData = <String, dynamic>{
      'Expected Duration': '${expectedDuration.inMilliseconds}ms',
      'Actual Duration': '${actualDuration.inMilliseconds}ms',
      'Performance Ratio': '${(actualDuration.inMilliseconds / expectedDuration.inMilliseconds).toStringAsFixed(2)}x',
    };
    
    return getDetailedErrorMessage(
      expectedBehavior: 'Operation should complete within ${expectedDuration.inMilliseconds}ms',
      actualBehavior: 'Operation took ${actualDuration.inMilliseconds}ms',
      testContext: 'Performance Test: $operation',
      suggestion: suggestion ?? 'Check for performance bottlenecks and optimize critical paths',
      additionalData: additionalData,
    );
  }
  
  /// Generate memory test error message
  static String getMemoryTestErrorMessage({
    required String operation,
    required int expectedMemoryUsage,
    required int actualMemoryUsage,
    String? suggestion,
  }) {
    final additionalData = <String, dynamic>{
      'Expected Memory': '${(expectedMemoryUsage / 1024 / 1024).toStringAsFixed(2)} MB',
      'Actual Memory': '${(actualMemoryUsage / 1024 / 1024).toStringAsFixed(2)} MB',
      'Memory Ratio': '${(actualMemoryUsage / expectedMemoryUsage).toStringAsFixed(2)}x',
    };
    
    return getDetailedErrorMessage(
      expectedBehavior: 'Memory usage should be under ${(expectedMemoryUsage / 1024 / 1024).toStringAsFixed(2)} MB',
      actualBehavior: 'Memory usage was ${(actualMemoryUsage / 1024 / 1024).toStringAsFixed(2)} MB',
      testContext: 'Memory Test: $operation',
      suggestion: suggestion ?? 'Check for memory leaks and optimize resource usage',
      additionalData: additionalData,
    );
  }
  
  /// Generate test summary report
  static String generateTestSummaryReport({
    required String testSuite,
    required int totalTests,
    required int passedTests,
    required int failedTests,
    required Duration totalDuration,
    List<String>? failedTestNames,
    Map<String, dynamic>? metrics,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 Test Summary Report: $testSuite');
    buffer.writeln('=' * 60);
    buffer.writeln('📈 Results:');
    buffer.writeln('  • Total Tests: $totalTests');
    buffer.writeln('  • Passed: $passedTests (${((passedTests / totalTests) * 100).toStringAsFixed(1)}%)');
    buffer.writeln('  • Failed: $failedTests (${((failedTests / totalTests) * 100).toStringAsFixed(1)}%)');
    buffer.writeln('  • Duration: ${totalDuration.inMilliseconds}ms');
    
    if (failedTestNames != null && failedTestNames.isNotEmpty) {
      buffer.writeln('❌ Failed Tests:');
      for (final testName in failedTestNames) {
        buffer.writeln('  • $testName');
      }
    }
    
    if (metrics != null && metrics.isNotEmpty) {
      buffer.writeln('📊 Metrics:');
      for (final entry in metrics.entries) {
        buffer.writeln('  • ${entry.key}: ${entry.value}');
      }
    }
    
    buffer.writeln('=' * 60);
    
    return buffer.toString();
  }
  
  /// Print diagnostic information to console
  static void printDiagnostic(String message) {
    debugPrint('🔍 DIAGNOSTIC: $message');
  }
  
  /// Print warning information to console
  static void printWarning(String message) {
    debugPrint('⚠️  WARNING: $message');
  }
  
  /// Print success information to console
  static void printSuccess(String message) {
    debugPrint('✅ SUCCESS: $message');
  }
  
  /// Print error information to console
  static void printError(String message) {
    debugPrint('❌ ERROR: $message');
  }
  
  /// Print info information to console
  static void printInfo(String message) {
    debugPrint('ℹ️  INFO: $message');
  }
}