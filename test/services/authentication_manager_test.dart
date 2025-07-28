import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/authentication_manager.dart';
import 'package:spiral_journal/core/app_constants.dart';

void main() {
  group('AuthenticationManager', () {
    late AuthenticationManager authManager;

    setUp(() {
      authManager = AuthenticationManager();
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = AuthenticationManager();
        final instance2 = AuthenticationManager();
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Public Interface', () {
      test('should have all required public methods', () {
        // Verify that the class has all the expected public methods
        expect(authManager.checkAuthenticationStatus, isA<Function>());
        expect(authManager.isFirstLaunch, isA<Function>());
        expect(authManager.isAuthSystemHealthy, isA<Function>());
        expect(authManager.markFirstLaunchComplete, isA<Function>());
        expect(authManager.performEmergencyReset, isA<Function>());
      });

      test('checkAuthenticationStatus should return Future<AuthenticationState>', () {
        final result = authManager.checkAuthenticationStatus();
        expect(result, isA<Future<AuthenticationState>>());
      });

      test('isFirstLaunch should return Future<bool>', () {
        final result = authManager.isFirstLaunch();
        expect(result, isA<Future<bool>>());
      });

      test('isAuthSystemHealthy should return Future<bool>', () {
        final result = authManager.isAuthSystemHealthy();
        expect(result, isA<Future<bool>>());
      });

      test('markFirstLaunchComplete should return Future<void>', () {
        final result = authManager.markFirstLaunchComplete();
        expect(result, isA<Future<void>>());
      });

      test('performEmergencyReset should return Future<bool>', () {
        final result = authManager.performEmergencyReset();
        expect(result, isA<Future<bool>>());
      });
    });

    group('Timeout Constants Integration', () {
      test('should use appropriate timeout constants', () {
        // Verify that the class references the correct timeout constants
        expect(AppConstants.authTimeout, isA<Duration>());
        expect(AppConstants.healthCheckTimeout, isA<Duration>());
        expect(AppConstants.firstLaunchTimeout, isA<Duration>());
        
        // Timeouts should be reasonable
        expect(AppConstants.authTimeout.inSeconds, greaterThan(0));
        expect(AppConstants.healthCheckTimeout.inSeconds, greaterThan(0));
        expect(AppConstants.firstLaunchTimeout.inSeconds, greaterThan(0));
      });
    });
  });

  group('AuthenticationState', () {
    test('should create valid state object', () {
      final state = AuthenticationState(
        isEnabled: true,
        isHealthy: true,
        requiresSetup: false,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: false,
      );

      expect(state.isEnabled, isTrue);
      expect(state.isHealthy, isTrue);
      expect(state.requiresSetup, isFalse);
      expect(state.isFirstLaunch, isFalse);
      expect(state.lastCheck, isA<DateTime>());
    });

    test('needsAuthentication should work correctly', () {
      // Case 1: Not enabled
      var state = AuthenticationState(
        isEnabled: false,
        isHealthy: true,
        requiresSetup: false,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: false,
      );
      expect(state.needsAuthentication, isTrue);

      // Case 2: First launch
      state = AuthenticationState(
        isEnabled: true,
        isHealthy: true,
        requiresSetup: false,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: true,
      );
      expect(state.needsAuthentication, isTrue);

      // Case 3: Not healthy
      state = AuthenticationState(
        isEnabled: true,
        isHealthy: false,
        requiresSetup: false,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: false,
      );
      expect(state.needsAuthentication, isTrue);

      // Case 4: All good
      state = AuthenticationState(
        isEnabled: true,
        isHealthy: true,
        requiresSetup: false,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: false,
      );
      expect(state.needsAuthentication, isFalse);
    });

    test('isReadyForOperation should work correctly', () {
      // Case 1: Ready for operation
      var state = AuthenticationState(
        isEnabled: true,
        isHealthy: true,
        requiresSetup: false,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: false,
      );
      expect(state.isReadyForOperation, isTrue);

      // Case 2: Requires setup
      state = AuthenticationState(
        isEnabled: true,
        isHealthy: true,
        requiresSetup: true,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: false,
      );
      expect(state.isReadyForOperation, isFalse);

      // Case 3: Not enabled
      state = AuthenticationState(
        isEnabled: false,
        isHealthy: true,
        requiresSetup: false,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: false,
      );
      expect(state.isReadyForOperation, isFalse);
    });

    test('toString should provide meaningful output', () {
      final state = AuthenticationState(
        isEnabled: true,
        isHealthy: true,
        requiresSetup: false,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: false,
      );

      final stringOutput = state.toString();
      expect(stringOutput, contains('AuthenticationState'));
      expect(stringOutput, contains('isEnabled: true'));
      expect(stringOutput, contains('isHealthy: true'));
      expect(stringOutput, contains('requiresSetup: false'));
      expect(stringOutput, contains('isFirstLaunch: false'));
    });
  });

  group('AuthenticationException', () {
    test('should create exception with message', () {
      const exception = AuthenticationException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.originalError, isNull);
    });

    test('should create exception with message and original error', () {
      final originalError = Exception('Original');
      final exception = AuthenticationException('Test error', originalError);
      expect(exception.message, equals('Test error'));
      expect(exception.originalError, equals(originalError));
    });

    test('toString should provide meaningful output', () {
      const exception = AuthenticationException('Test error');
      expect(exception.toString(), equals('AuthenticationException: Test error'));
    });
  });
}