import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/controllers/splash_screen_controller.dart';

void main() {
  group('SplashScreenController', () {
    late SplashScreenController splashController;

    setUp(() {
      splashController = SplashScreenController();
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = SplashScreenController();
        final instance2 = SplashScreenController();
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Public Interface', () {
      test('should have all required public methods', () {
        // Verify that the class has all the expected public methods
        expect(splashController.shouldShowSplash, isA<Function>());
        expect(splashController.onSplashComplete, isA<Function>());
        expect(splashController.getSplashConfiguration, isA<Function>());
        expect(splashController.setSplashEnabled, isA<Function>());
        expect(splashController.clearConfigurationCache, isA<Function>());
        expect(splashController.getCacheStatus, isA<Function>());
      });

      test('shouldShowSplash should return Future<bool>', () {
        final result = splashController.shouldShowSplash();
        expect(result, isA<Future<bool>>());
        // Note: We don't await the result to avoid Flutter binding issues in tests
      });

      test('onSplashComplete should complete without throwing', () {
        expect(() => splashController.onSplashComplete(), returnsNormally);
      });

      test('getSplashConfiguration should return Future<SplashConfiguration>', () {
        final result = splashController.getSplashConfiguration();
        expect(result, isA<Future<SplashConfiguration>>());
      });

      test('setSplashEnabled should return Future<void>', () {
        final result = splashController.setSplashEnabled(true);
        expect(result, isA<Future<void>>());
        // Note: We don't await the result to avoid Flutter binding issues in tests
      });

      test('clearConfigurationCache should complete without throwing', () {
        expect(() => splashController.clearConfigurationCache(), returnsNormally);
      });

      test('getCacheStatus should return Map<String, dynamic>', () {
        final status = splashController.getCacheStatus();
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('hasCachedConfiguration'), isTrue);
        expect(status.containsKey('cacheTime'), isTrue);
        expect(status.containsKey('cacheAge'), isTrue);
        expect(status.containsKey('cacheValid'), isTrue);
      });
    });

    group('Cache Management', () {
      test('should handle cache status correctly', () {
        final status = splashController.getCacheStatus();
        expect(status, isA<Map<String, dynamic>>());
        
        // Initially should not have cached configuration
        expect(status['hasCachedConfiguration'], isFalse);
      });

      test('clearConfigurationCache should work without errors', () {
        // Should not throw even if there's no cache to clear
        expect(() => splashController.clearConfigurationCache(), returnsNormally);
        
        final status = splashController.getCacheStatus();
        expect(status['hasCachedConfiguration'], isFalse);
      });
    });
  });

  group('SplashConfiguration', () {
    test('should create valid configuration object', () {
      final config = SplashConfiguration(
        enabled: true,
        displayDuration: const Duration(seconds: 2),
        lastUpdated: DateTime.now(),
      );

      expect(config.enabled, isTrue);
      expect(config.displayDuration, equals(const Duration(seconds: 2)));
      expect(config.lastUpdated, isA<DateTime>());
    });

    test('toString should provide meaningful output', () {
      final config = SplashConfiguration(
        enabled: true,
        displayDuration: const Duration(seconds: 2),
        lastUpdated: DateTime.now(),
      );

      final stringOutput = config.toString();
      expect(stringOutput, contains('SplashConfiguration'));
      expect(stringOutput, contains('enabled: true'));
      expect(stringOutput, contains('displayDuration: 2s'));
    });

    test('copyWith should create modified copy', () {
      final original = SplashConfiguration(
        enabled: true,
        displayDuration: const Duration(seconds: 2),
        lastUpdated: DateTime.now(),
      );

      final modified = original.copyWith(enabled: false);
      
      expect(modified.enabled, isFalse);
      expect(modified.displayDuration, equals(original.displayDuration));
      expect(modified.lastUpdated, equals(original.lastUpdated));
    });

    test('copyWith should handle partial updates', () {
      final original = SplashConfiguration(
        enabled: true,
        displayDuration: const Duration(seconds: 2),
        lastUpdated: DateTime.now(),
      );

      // Update only duration
      final modified1 = original.copyWith(displayDuration: const Duration(seconds: 3));
      expect(modified1.enabled, equals(original.enabled));
      expect(modified1.displayDuration, equals(const Duration(seconds: 3)));
      expect(modified1.lastUpdated, equals(original.lastUpdated));

      // Update only timestamp
      final newTime = DateTime.now().add(const Duration(hours: 1));
      final modified2 = original.copyWith(lastUpdated: newTime);
      expect(modified2.enabled, equals(original.enabled));
      expect(modified2.displayDuration, equals(original.displayDuration));
      expect(modified2.lastUpdated, equals(newTime));
    });

    test('copyWith with no parameters should return identical copy', () {
      final original = SplashConfiguration(
        enabled: true,
        displayDuration: const Duration(seconds: 2),
        lastUpdated: DateTime.now(),
      );

      final copy = original.copyWith();
      
      expect(copy.enabled, equals(original.enabled));
      expect(copy.displayDuration, equals(original.displayDuration));
      expect(copy.lastUpdated, equals(original.lastUpdated));
    });
  });

  group('SplashConfigurationException', () {
    test('should create exception with message', () {
      const exception = SplashConfigurationException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.originalError, isNull);
    });

    test('should create exception with message and original error', () {
      final originalError = Exception('Original');
      final exception = SplashConfigurationException('Test error', originalError);
      expect(exception.message, equals('Test error'));
      expect(exception.originalError, equals(originalError));
    });

    test('toString should provide meaningful output', () {
      const exception = SplashConfigurationException('Test error');
      expect(exception.toString(), equals('SplashConfigurationException: Test error'));
    });
  });
}