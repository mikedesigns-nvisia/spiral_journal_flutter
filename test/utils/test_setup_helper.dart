import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_diagnostics_helper.dart';
import 'test_exception_handler.dart';

/// Helper class for consistent test setup and teardown across the test suite
class TestSetupHelper {
  static bool _bindingInitialized = false;
  static final Map<String, dynamic> _testConfiguration = {};

  /// Ensures Flutter binding is initialized for tests that require platform services
  static void ensureFlutterBinding() {
    if (!_bindingInitialized) {
      TestWidgetsFlutterBinding.ensureInitialized();
      _bindingInitialized = true;
    }
  }

  /// Sets up test configuration with consistent settings
  static void setupTestConfiguration({
    bool enablePlatformChannels = true,
    bool enableMockServices = true,
    Duration testTimeout = const Duration(seconds: 30),
  }) {
    _testConfiguration.clear();
    _testConfiguration['enablePlatformChannels'] = enablePlatformChannels;
    _testConfiguration['enableMockServices'] = enableMockServices;
    _testConfiguration['testTimeout'] = testTimeout;
    
    if (enablePlatformChannels) {
      setupPlatformChannelMocks();
    }
  }

  /// Gets test configuration value
  static T getTestConfig<T>(String key, T defaultValue) {
    return _testConfiguration[key] as T? ?? defaultValue;
  }

  /// Cleans up test configuration
  static void teardownTestConfiguration() {
    clearPlatformChannelMocks();
    _testConfiguration.clear();
  }

  /// Complete test setup including binding and configuration
  static void setupTest({
    bool enablePlatformChannels = true,
    Duration testTimeout = const Duration(seconds: 30),
  }) {
    ensureFlutterBinding();
    setupTestConfiguration(
      enablePlatformChannels: enablePlatformChannels,
      testTimeout: testTimeout,
    );
  }

  /// Complete test teardown
  static void teardownTest() {
    teardownTestConfiguration();
  }

  /// Sets up platform channel mocks for common platform services
  static void setupPlatformChannelMocks() {
    // Use the newer API for setting up method channel mocks
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'isDeviceSupported':
            return true;
          case 'getAvailableBiometrics':
            return ['fingerprint'];
          case 'authenticate':
            return true;
          default:
            return null;
        }
      },
    );

    // Mock secure storage channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'read':
            return null;
          case 'write':
            return null;
          case 'delete':
            return null;
          default:
            return null;
        }
      },
    );
  }

  /// Clears platform channel mocks
  static void clearPlatformChannelMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  }

  /// Creates a test-friendly environment with proper error handling
  static Future<T> runWithTestEnvironment<T>(
    Future<T> Function() testFunction, {
    Duration? timeout,
    String? testName,
    Map<String, dynamic>? context,
    T? fallbackValue,
    bool rethrowException = true,
  }) async {
    setupTest();
    try {
      return await TestExceptionHandler.handleTimeoutException(
        testFunction,
        operationName: testName ?? 'test operation',
        timeout: timeout ?? getTestConfig('testTimeout', const Duration(seconds: 30)),
        fallbackValue: fallbackValue,
        rethrowException: rethrowException,
      );
    } catch (error, stackTrace) {
      final errorMessage = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Test should complete successfully',
        actualBehavior: 'Test failed with error: $error',
        testContext: testName,
        suggestion: 'Check test setup and error handling',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      if (fallbackValue != null && !rethrowException) {
        return fallbackValue;
      }
      
      rethrow;
    } finally {
      teardownTest();
    }
  }
  
  /// Ensures Flutter binding is initialized with proper error handling
  static void ensureFlutterBindingWithDiagnostics() {
    try {
      ensureFlutterBinding();
    } catch (error, stackTrace) {
      final errorMessage = TestDiagnosticsHelper.getBindingErrorMessage(
        expectedBehavior: 'Flutter binding should initialize successfully',
        actualBehavior: 'Flutter binding initialization failed: $error',
        suggestion: 'Check if there are conflicting bindings or platform issues',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      rethrow;
    }
  }
  
  /// Sets up platform channel mocks with proper error handling
  static void setupPlatformChannelMocksWithDiagnostics() {
    try {
      setupPlatformChannelMocks();
    } catch (error, stackTrace) {
      final errorMessage = TestDiagnosticsHelper.getPlatformServiceErrorMessage(
        serviceName: 'PlatformChannelMocks',
        expectedBehavior: 'Platform channel mocks should be set up successfully',
        actualBehavior: 'Platform channel mock setup failed: $error',
        suggestion: 'Check if the platform channels are properly configured',
      );
      
      debugPrint(errorMessage);
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      
      rethrow;
    }
  }
  
  /// Runs a widget test with proper setup and error handling
  static Future<void> runWidgetTestWithEnvironment(
    WidgetTester tester,
    Future<void> Function(WidgetTester) testFunction, {
    required String testName,
    bool enablePlatformChannels = true,
    Duration? timeout,
    Map<String, dynamic>? context,
    bool printWidgetTree = true,
  }) async {
    setupTest(enablePlatformChannels: enablePlatformChannels);
    
    try {
      await TestExceptionHandler.runWidgetTest(
        tester,
        testFunction,
        testName: testName,
        context: context,
        printWidgetTree: printWidgetTree,
      );
    } finally {
      teardownTest();
    }
  }
}