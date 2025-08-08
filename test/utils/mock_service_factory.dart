import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/utils/app_error_handler.dart';
import 'test_diagnostics_helper.dart';
import 'test_exception_handler.dart';

/// Factory class for creating consistent test data and configurations across tests
class MockServiceFactory {
  static final Map<String, dynamic> _testData = {};
  static final Map<String, Function()> _dataGenerators = {};

  /// Initialize the factory with data generators
  static void initialize() {
    _dataGenerators.clear();
    _testData.clear();

    // Register data generators
    _dataGenerators['journal_entries'] = _createTestJournalEntries;
    _dataGenerators['auth_config'] = _createAuthConfig;
    _dataGenerators['theme_config'] = _createThemeConfig;
    _dataGenerators['settings_config'] = _createSettingsConfig;
  }

  /// Gets test data by key with error handling
  static T getTestData<T>(String key, {T? fallbackValue}) {
    try {
      if (!_testData.containsKey(key)) {
        final generator = _dataGenerators[key];
        if (generator != null) {
          _testData[key] = generator();
        } else {
          final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
            expectedBehavior: 'Data generator should exist for key "$key"',
            actualBehavior: 'No data generator registered for key "$key"',
            suggestion: 'Register a data generator for this key using MockServiceFactory.initialize()',
          );
          
          if (fallbackValue != null) {
            debugPrint(errorMessage);
            return fallbackValue;
          }
          
          throw ArgumentError(errorMessage);
        }
      }
      
      final data = _testData[key];
      if (data is! T) {
        final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
          expectedBehavior: 'Test data for key "$key" should be of type $T',
          actualBehavior: 'Test data is of type ${data.runtimeType}',
          suggestion: 'Check that the data generator returns the correct type',
        );
        
        if (fallbackValue != null) {
          debugPrint(errorMessage);
          return fallbackValue;
        }
        
        throw TypeError();
      }
      
      return data;
    } catch (error, stackTrace) {
      if (error is ArgumentError || error is TypeError) {
        rethrow;
      }
      
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to get test data for key "$key"',
        actualBehavior: 'Failed to get test data: $error',
        suggestion: 'Check that the data generator is properly implemented',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      if (fallbackValue != null) {
        return fallbackValue;
      }
      
      throw TestFailure(errorMessage);
    }
  }

  /// Creates fresh test data (not cached) with error handling
  static T createFreshTestData<T>(String key, {T? fallbackValue}) {
    try {
      final generator = _dataGenerators[key];
      if (generator == null) {
        final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
          expectedBehavior: 'Data generator should exist for key "$key"',
          actualBehavior: 'No data generator registered for key "$key"',
          suggestion: 'Register a data generator for this key using MockServiceFactory.initialize()',
        );
        
        if (fallbackValue != null) {
          debugPrint(errorMessage);
          return fallbackValue;
        }
        
        throw ArgumentError(errorMessage);
      }
      
      final data = generator();
      if (data is! T) {
        final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
          expectedBehavior: 'Test data for key "$key" should be of type $T',
          actualBehavior: 'Test data is of type ${data.runtimeType}',
          suggestion: 'Check that the data generator returns the correct type',
        );
        
        if (fallbackValue != null) {
          debugPrint(errorMessage);
          return fallbackValue;
        }
        
        throw TypeError();
      }
      
      return data;
    } catch (error, stackTrace) {
      if (error is ArgumentError || error is TypeError) {
        rethrow;
      }
      
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to create fresh test data for key "$key"',
        actualBehavior: 'Failed to create test data: $error',
        suggestion: 'Check that the data generator is properly implemented',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      if (fallbackValue != null) {
        return fallbackValue;
      }
      
      throw TestFailure(errorMessage);
    }
  }

  /// Clears all cached test data
  static void clearAllTestData() {
    _testData.clear();
  }

  /// Creates authentication test configuration
  static Map<String, dynamic> _createAuthConfig() {
    return {
      'isDeviceSupported': true,
      'authenticationSucceeds': true,
      'isPinSet': false,
      'pinVerificationSucceeds': true,
      'availableBiometrics': ['fingerprint'],
    };
  }

  /// Creates theme test configuration
  static Map<String, dynamic> _createThemeConfig() {
    return {
      'currentTheme': 'light',
      'availableThemes': ['light', 'dark', 'system'],
      'settingSucceeds': true,
    };
  }

  /// Creates settings test configuration
  static Map<String, dynamic> _createSettingsConfig() {
    return {
      'themeMode': 'system',
      'analyticsEnabled': true,
      'biometricAuthEnabled': true,
      'dailyRemindersEnabled': false,
    };
  }

  /// Sets up test scenario configurations with error handling
  static void setupTestScenario(String scenarioName, Map<String, dynamic> config) {
    try {
      if (scenarioName.isEmpty) {
        final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
          expectedBehavior: 'Scenario name should not be empty',
          actualBehavior: 'Empty scenario name provided',
          suggestion: 'Provide a meaningful scenario name',
        );
        throw ArgumentError(errorMessage);
      }
      
      if (config.isEmpty) {
        final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
          expectedBehavior: 'Scenario config should not be empty',
          actualBehavior: 'Empty config provided',
          suggestion: 'Provide configuration values for the scenario',
        );
        throw ArgumentError(errorMessage);
      }
      
      _testData[scenarioName] = config;
    } catch (error, stackTrace) {
      if (error is ArgumentError) {
        rethrow;
      }
      
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to set up test scenario "$scenarioName"',
        actualBehavior: 'Failed to set up test scenario: $error',
        suggestion: 'Check that the scenario configuration is valid',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      throw TestFailure(errorMessage);
    }
  }

  /// Gets test scenario configuration with error handling
  static Map<String, dynamic> getTestScenario(String scenarioName, {Map<String, dynamic>? fallbackConfig}) {
    try {
      final scenario = _testData[scenarioName];
      if (scenario == null) {
        final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
          expectedBehavior: 'Test scenario "$scenarioName" should exist',
          actualBehavior: 'Scenario not found',
          suggestion: 'Set up the scenario first using setupTestScenario()',
        );
        
        if (fallbackConfig != null) {
          debugPrint(errorMessage);
          return fallbackConfig;
        }
        
        // Return empty map as default behavior
        return {};
      }
      
      if (scenario is! Map<String, dynamic>) {
        final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
          expectedBehavior: 'Test scenario should be a Map<String, dynamic>',
          actualBehavior: 'Scenario is of type ${scenario.runtimeType}',
          suggestion: 'Check that the scenario is set up correctly',
        );
        
        if (fallbackConfig != null) {
          debugPrint(errorMessage);
          return fallbackConfig;
        }
        
        // Return empty map as default behavior
        return {};
      }
      
      return scenario;
    } catch (error, stackTrace) {
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to get test scenario "$scenarioName"',
        actualBehavior: 'Failed to get test scenario: $error',
        suggestion: 'Check that the scenario is set up correctly',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      if (fallbackConfig != null) {
        return fallbackConfig;
      }
      
      // Return empty map as default behavior
      return {};
    }
  }

  /// Creates test journal entries for mock scenarios
  static List<JournalEntry> _createTestJournalEntries() {
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return [
      JournalEntry(
        id: '1',
        userId: 'test_user',
        date: now.subtract(const Duration(days: 1)),
        content: 'Test entry 1',
        moods: ['happy', 'excited'],
        dayOfWeek: dayNames[(now.subtract(const Duration(days: 1))).weekday - 1],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        isAnalyzed: true,
      ),
      JournalEntry(
        id: '2',
        userId: 'test_user',
        date: now.subtract(const Duration(days: 2)),
        content: 'Test entry 2',
        moods: ['calm', 'peaceful'],
        dayOfWeek: dayNames[(now.subtract(const Duration(days: 2))).weekday - 1],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        isAnalyzed: false,
      ),
    ];
  }

  /// Creates test configuration for performance testing
  static Map<String, dynamic> createPerformanceTestConfig({
    Duration delay = const Duration(milliseconds: 100),
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return {
      'delay': delay,
      'maxRetries': maxRetries,
      'timeout': timeout,
      'enablePerformanceLogging': true,
    };
  }

  /// Creates test configuration for error scenarios
  static Map<String, dynamic> createErrorTestConfig({
    String errorMessage = 'Test error',
    bool shouldRetry = false,
    int maxRetries = 0,
  }) {
    return {
      'errorMessage': errorMessage,
      'shouldRetry': shouldRetry,
      'maxRetries': maxRetries,
      'errorType': 'generic',
    };
  }

  /// Validates test data integrity with error handling
  static bool validateTestData(String key, dynamic data, {bool throwOnInvalid = false}) {
    try {
      bool isValid = false;
      String errorReason = '';
      
      switch (key) {
        case 'journal_entries':
          isValid = data is List<JournalEntry> && data.isNotEmpty;
          if (!isValid) {
            errorReason = data is! List<JournalEntry> 
                ? 'Data is not a List<JournalEntry>' 
                : 'Journal entries list is empty';
          }
          break;
        case 'auth_config':
        case 'theme_config':
        case 'settings_config':
          isValid = data is Map<String, dynamic> && data.isNotEmpty;
          if (!isValid) {
            errorReason = data is! Map<String, dynamic> 
                ? 'Data is not a Map<String, dynamic>' 
                : 'Configuration map is empty';
          }
          break;
        default:
          isValid = data != null;
          if (!isValid) {
            errorReason = 'Data is null';
          }
      }
      
      if (!isValid && throwOnInvalid) {
        final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
          expectedBehavior: 'Test data for key "$key" should be valid',
          actualBehavior: 'Invalid test data: $errorReason',
          suggestion: 'Check that the data generator returns valid data',
        );
        throw TestFailure(errorMessage);
      }
      
      return isValid;
    } catch (error, stackTrace) {
      if (error is TestFailure) {
        rethrow;
      }
      
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Should be able to validate test data for key "$key"',
        actualBehavior: 'Validation failed with error: $error',
        suggestion: 'Check that the validation logic is correct',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      if (throwOnInvalid) {
        throw TestFailure(errorMessage);
      }
      
      return false;
    }
  }
  
  /// Creates a fallback for platform service failures
  static T createPlatformServiceFallback<T>(String serviceName, String methodName, T fallbackValue) {
    debugPrint('Using fallback value for platform service: $serviceName.$methodName');
    return fallbackValue;
  }
  
  /// Creates a mock AppError for testing error handling
  static AppError createMockAppError({
    ErrorType type = ErrorType.unknown,
    ErrorCategory category = ErrorCategory.general,
    String message = 'Mock error',
    String userMessage = 'A test error occurred',
    bool isRecoverable = true,
    String? operationName,
    String? component,
  }) {
    return AppError(
      type: type,
      category: category,
      message: message,
      userMessage: userMessage,
      stackTrace: StackTrace.current,
      timestamp: DateTime.now(),
      operationName: operationName,
      component: component,
      isRecoverable: isRecoverable,
    );
  }
  
  /// Simulates a platform service failure for testing error handling
  static Future<T> simulatePlatformServiceFailure<T>({
    required String serviceName,
    required String methodName,
    String errorCode = 'ERROR',
    String errorMessage = 'Platform service error',
    T? fallbackValue,
    bool useErrorHandler = true,
  }) async {
    if (useErrorHandler) {
      return TestExceptionHandler.handlePlatformServiceException<T>(
        () => throw PlatformException(code: errorCode, message: errorMessage),
        serviceName: serviceName,
        methodName: methodName,
        fallbackValue: fallbackValue,
        rethrowException: fallbackValue == null,
      );
    } else {
      throw PlatformException(code: errorCode, message: errorMessage);
    }
  }
  
  /// Simulates a timeout for testing error handling
  static Future<T> simulateTimeout<T>({
    required String operationName,
    Duration timeout = const Duration(milliseconds: 50),
    T? fallbackValue,
    bool useErrorHandler = true,
  }) async {
    if (useErrorHandler) {
      return TestExceptionHandler.handleTimeoutException<T>(
        () async {
          await Future.delayed(timeout * 2);
          throw TimeoutException('Operation timed out', timeout);
        },
        operationName: operationName,
        timeout: timeout,
        fallbackValue: fallbackValue,
        rethrowException: fallbackValue == null,
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 10));
      throw TimeoutException('Operation timed out', timeout);
    }
  }
  
  /// Simulates an app error for testing error handling
  static Future<T> simulateAppError<T>({
    required String operationName,
    ErrorType type = ErrorType.unknown,
    ErrorCategory category = ErrorCategory.general,
    String message = 'Mock error',
    String userMessage = 'A test error occurred',
    bool isRecoverable = true,
    T? fallbackValue,
    bool useErrorHandler = true,
  }) async {
    final appError = createMockAppError(
      type: type,
      category: category,
      message: message,
      userMessage: userMessage,
      isRecoverable: isRecoverable,
      operationName: operationName,
    );
    
    if (useErrorHandler) {
      return TestExceptionHandler.handleAppError<T>(
        () => throw appError,
        operationName: operationName,
        fallbackValue: fallbackValue,
        rethrowException: fallbackValue == null,
      );
    } else {
      throw appError;
    }
  }
}