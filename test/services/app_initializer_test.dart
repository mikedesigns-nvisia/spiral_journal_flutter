import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/app_initializer.dart';
import 'package:spiral_journal/constants/app_constants.dart';

void main() {
  group('AppInitializer', () {
    late AppInitializer appInitializer;

    setUp(() {
      appInitializer = AppInitializer();
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = AppInitializer();
        final instance2 = AppInitializer();
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Public Interface', () {
      test('should have all required public methods', () {
        // Verify that the class has all the expected public methods
        expect(appInitializer.initialize, isA<Function>());
        expect(appInitializer.verifySystemHealth, isA<Function>());
        expect(appInitializer.handleInitializationError, isA<Function>());
        expect(appInitializer.reset, isA<Function>());
      });

      test('initialize should return Future<InitializationResult>', () {
        final result = appInitializer.initialize();
        expect(result, isA<Future<InitializationResult>>());
        // Note: We don't await the result to avoid Flutter binding issues in tests
      });

      test('verifySystemHealth should return Future<SystemHealthResult>', () {
        final result = appInitializer.verifySystemHealth();
        expect(result, isA<Future<SystemHealthResult>>());
        // Note: We don't await the result to avoid Flutter binding issues in tests
      });

      test('handleInitializationError should handle errors without throwing', () {
        expect(() => appInitializer.handleInitializationError('Test error'), returnsNormally);
        expect(() => appInitializer.handleInitializationError(Exception('Test exception')), returnsNormally);
        expect(() => appInitializer.handleInitializationError(null), returnsNormally);
      });

      test('reset should complete without throwing', () {
        expect(() => appInitializer.reset(), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle various error types', () {
        // String error
        expect(() => appInitializer.handleInitializationError('String error'), returnsNormally);
        
        // Exception error
        expect(() => appInitializer.handleInitializationError(Exception('Exception error')), returnsNormally);
        
        // Custom error object
        expect(() => appInitializer.handleInitializationError({'error': 'Custom error'}), returnsNormally);
      });
    });

    group('Timeout Integration', () {
      test('should use appropriate timeout constants', () {
        // Verify that the class references the correct timeout constants
        expect(AppConstants.initializationTimeout, isA<Duration>());
        expect(AppConstants.healthCheckTimeout, isA<Duration>());
        
        // Timeouts should be reasonable
        expect(AppConstants.initializationTimeout.inSeconds, greaterThan(0));
        expect(AppConstants.healthCheckTimeout.inSeconds, greaterThan(0));
        
        // Initialization timeout should be longer than health check timeout
        expect(AppConstants.initializationTimeout.inSeconds, 
               greaterThanOrEqualTo(AppConstants.healthCheckTimeout.inSeconds));
      });
    });
  });

  group('InitializationResult', () {
    test('should create valid result object', () {
      final result = InitializationResult(
        success: true,
        errorMessage: null,
        systemStatus: {'test': 'status'},
        initializationTime: const Duration(seconds: 1),
        timestamp: DateTime.now(),
      );

      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.systemStatus, equals({'test': 'status'}));
      expect(result.initializationTime, equals(const Duration(seconds: 1)));
      expect(result.timestamp, isA<DateTime>());
    });

    test('isReadyForOperation should work correctly', () {
      // Success case
      var result = InitializationResult(
        success: true,
        errorMessage: null,
        systemStatus: {},
        initializationTime: const Duration(seconds: 1),
        timestamp: DateTime.now(),
      );
      expect(result.isReadyForOperation, isTrue);

      // Failure case
      result = InitializationResult(
        success: false,
        errorMessage: 'Error occurred',
        systemStatus: {},
        initializationTime: const Duration(seconds: 1),
        timestamp: DateTime.now(),
      );
      expect(result.isReadyForOperation, isFalse);

      // Success but with error message
      result = InitializationResult(
        success: true,
        errorMessage: 'Warning message',
        systemStatus: {},
        initializationTime: const Duration(seconds: 1),
        timestamp: DateTime.now(),
      );
      expect(result.isReadyForOperation, isFalse);
    });

    test('timedOut should work correctly', () {
      // Timeout case
      var result = InitializationResult(
        success: false,
        errorMessage: 'Timeout',
        systemStatus: {'timeout': true},
        initializationTime: const Duration(seconds: 15),
        timestamp: DateTime.now(),
      );
      expect(result.timedOut, isTrue);

      // Non-timeout case
      result = InitializationResult(
        success: true,
        errorMessage: null,
        systemStatus: {'timeout': false},
        initializationTime: const Duration(seconds: 1),
        timestamp: DateTime.now(),
      );
      expect(result.timedOut, isFalse);

      // No timeout info
      result = InitializationResult(
        success: true,
        errorMessage: null,
        systemStatus: {},
        initializationTime: const Duration(seconds: 1),
        timestamp: DateTime.now(),
      );
      expect(result.timedOut, isFalse);
    });

    test('toString should provide meaningful output', () {
      final result = InitializationResult(
        success: true,
        errorMessage: null,
        systemStatus: {},
        initializationTime: const Duration(milliseconds: 1500),
        timestamp: DateTime.now(),
      );

      final stringOutput = result.toString();
      expect(stringOutput, contains('InitializationResult'));
      expect(stringOutput, contains('success: true'));
      expect(stringOutput, contains('1500ms'));
    });
  });

  group('SystemHealthResult', () {
    test('should create valid health result object', () {
      final result = SystemHealthResult(
        isHealthy: true,
        componentStatus: {'auth': true, 'settings': true},
        details: {'auth': {'status': 'ok'}, 'settings': {'status': 'ok'}},
        checkTime: DateTime.now(),
      );

      expect(result.isHealthy, isTrue);
      expect(result.componentStatus, equals({'auth': true, 'settings': true}));
      expect(result.details, isA<Map<String, dynamic>>());
      expect(result.checkTime, isA<DateTime>());
    });

    test('unhealthyComponents should work correctly', () {
      final result = SystemHealthResult(
        isHealthy: false,
        componentStatus: {'auth': true, 'settings': false, 'database': false},
        details: {},
        checkTime: DateTime.now(),
      );

      final unhealthy = result.unhealthyComponents;
      expect(unhealthy, contains('settings'));
      expect(unhealthy, contains('database'));
      expect(unhealthy, isNot(contains('auth')));
      expect(unhealthy.length, equals(2));
    });

    test('healthyComponents should work correctly', () {
      final result = SystemHealthResult(
        isHealthy: false,
        componentStatus: {'auth': true, 'settings': false, 'database': true},
        details: {},
        checkTime: DateTime.now(),
      );

      final healthy = result.healthyComponents;
      expect(healthy, contains('auth'));
      expect(healthy, contains('database'));
      expect(healthy, isNot(contains('settings')));
      expect(healthy.length, equals(2));
    });

    test('toString should provide meaningful output', () {
      final result = SystemHealthResult(
        isHealthy: true,
        componentStatus: {'auth': true, 'settings': true},
        details: {},
        checkTime: DateTime.now(),
      );

      final stringOutput = result.toString();
      expect(stringOutput, contains('SystemHealthResult'));
      expect(stringOutput, contains('isHealthy: true'));
      expect(stringOutput, contains('healthyComponents: 2'));
      expect(stringOutput, contains('unhealthyComponents: 0'));
    });
  });
}