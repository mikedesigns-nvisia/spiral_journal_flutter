import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/authentication_manager.dart';
import 'package:spiral_journal/services/app_initializer.dart';
import 'package:spiral_journal/controllers/splash_screen_controller.dart';
import 'package:spiral_journal/services/pin_auth_service.dart';
import 'package:spiral_journal/screens/pin_setup_screen.dart';
import 'package:spiral_journal/screens/pin_entry_screen.dart';
import 'package:spiral_journal/main.dart';
import 'package:spiral_journal/constants/app_constants.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Authentication Flow Integration Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });
    late AuthenticationManager authManager;
    late AppInitializer appInitializer;
    late SplashScreenController splashController;

    setUp(() {
      authManager = AuthenticationManager();
      appInitializer = AppInitializer();
      splashController = SplashScreenController();
    });

    group('Component Integration', () {
      test('should have consistent singleton instances across components', () {
        // Verify singleton pattern consistency
        final authManager1 = AuthenticationManager();
        final authManager2 = AuthenticationManager();
        final appInitializer1 = AppInitializer();
        final appInitializer2 = AppInitializer();
        final splashController1 = SplashScreenController();
        final splashController2 = SplashScreenController();

        expect(identical(authManager1, authManager2), isTrue);
        expect(identical(appInitializer1, appInitializer2), isTrue);
        expect(identical(splashController1, splashController2), isTrue);
      });

      test('should use consistent timeout constants', () {
        // Verify all components reference the same timeout constants
        expect(AppConstants.authTimeout, isA<Duration>());
        expect(AppConstants.healthCheckTimeout, isA<Duration>());
        expect(AppConstants.firstLaunchTimeout, isA<Duration>());
        expect(AppConstants.initializationTimeout, isA<Duration>());

        // Verify timeout hierarchy makes sense
        expect(AppConstants.initializationTimeout.inSeconds, 
               greaterThanOrEqualTo(AppConstants.authTimeout.inSeconds));
        expect(AppConstants.initializationTimeout.inSeconds,
               greaterThanOrEqualTo(AppConstants.healthCheckTimeout.inSeconds));
      });

      test('should have proper method signatures for integration', () {
        // Verify AuthenticationManager interface
        expect(authManager.checkAuthenticationStatus, isA<Function>());
        expect(authManager.isFirstLaunch, isA<Function>());
        expect(authManager.isAuthSystemHealthy, isA<Function>());
        expect(authManager.markFirstLaunchComplete, isA<Function>());
        expect(authManager.performEmergencyReset, isA<Function>());

        // Verify AppInitializer interface
        expect(appInitializer.initialize, isA<Function>());
        expect(appInitializer.verifySystemHealth, isA<Function>());
        expect(appInitializer.handleInitializationError, isA<Function>());
        expect(appInitializer.reset, isA<Function>());

        // Verify SplashScreenController interface
        expect(splashController.shouldShowSplash, isA<Function>());
        expect(splashController.onSplashComplete, isA<Function>());
        expect(splashController.getSplashConfiguration, isA<Function>());
        expect(splashController.setSplashEnabled, isA<Function>());
        expect(splashController.clearConfigurationCache, isA<Function>());
        expect(splashController.getCacheStatus, isA<Function>());
      });
    });

    group('Error Handling Integration', () {
      test('should handle initialization errors gracefully', () {
        // Test that error handling doesn't throw exceptions
        expect(() => appInitializer.handleInitializationError('Test error'), returnsNormally);
        expect(() => appInitializer.handleInitializationError(Exception('Test exception')), returnsNormally);
        expect(() => appInitializer.handleInitializationError(null), returnsNormally);
      });

      test('should handle splash completion errors gracefully', () {
        // Test that splash completion doesn't throw exceptions
        expect(() => splashController.onSplashComplete(), returnsNormally);
      });

      test('should handle cache operations safely', () {
        // Test cache operations don't throw exceptions
        expect(() => splashController.clearConfigurationCache(), returnsNormally);
        
        final cacheStatus = splashController.getCacheStatus();
        expect(cacheStatus, isA<Map<String, dynamic>>());
        expect(cacheStatus.containsKey('hasCachedConfiguration'), isTrue);
        expect(cacheStatus.containsKey('cacheTime'), isTrue);
        expect(cacheStatus.containsKey('cacheAge'), isTrue);
        expect(cacheStatus.containsKey('cacheValid'), isTrue);
      });

      test('should handle reset operations safely', () {
        // Test that reset operations don't throw exceptions
        expect(() => appInitializer.reset(), returnsNormally);
      });
    });

    group('Data Structure Integration', () {
      test('should create valid AuthenticationState objects', () {
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
        expect(state.needsAuthentication, isFalse);
        expect(state.isReadyForOperation, isTrue);
      });

      test('should create valid InitializationResult objects', () {
        final result = InitializationResult(
          success: true,
          errorMessage: null,
          systemStatus: {'test': 'status'},
          initializationTime: const Duration(seconds: 1),
          timestamp: DateTime.now(),
        );

        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
        expect(result.isReadyForOperation, isTrue);
        expect(result.timedOut, isFalse);
      });

      test('should create valid SystemHealthResult objects', () {
        final result = SystemHealthResult(
          isHealthy: true,
          componentStatus: {'auth': true, 'settings': true},
          details: {'auth': {'status': 'ok'}},
          checkTime: DateTime.now(),
        );

        expect(result.isHealthy, isTrue);
        expect(result.healthyComponents.length, equals(2));
        expect(result.unhealthyComponents.length, equals(0));
      });

      test('should create valid SplashConfiguration objects', () {
        final config = SplashConfiguration(
          enabled: true,
          displayDuration: const Duration(seconds: 2),
          lastUpdated: DateTime.now(),
        );

        expect(config.enabled, isTrue);
        expect(config.displayDuration, equals(const Duration(seconds: 2)));
        
        // Test copyWith functionality
        final modifiedConfig = config.copyWith(enabled: false);
        expect(modifiedConfig.enabled, isFalse);
        expect(modifiedConfig.displayDuration, equals(config.displayDuration));
      });
    });

    group('Exception Handling Integration', () {
      test('should create and handle AuthenticationException properly', () {
        const exception = AuthenticationException('Test error');
        expect(exception.message, equals('Test error'));
        expect(exception.originalError, isNull);
        expect(exception.toString(), contains('AuthenticationException'));
      });

      test('should create and handle SplashConfigurationException properly', () {
        const exception = SplashConfigurationException('Test error');
        expect(exception.message, equals('Test error'));
        expect(exception.originalError, isNull);
        expect(exception.toString(), contains('SplashConfigurationException'));
      });

      test('should handle exceptions with original errors', () {
        final originalError = Exception('Original');
        final authException = AuthenticationException('Test error', originalError);
        final splashException = SplashConfigurationException('Test error', originalError);

        expect(authException.originalError, equals(originalError));
        expect(splashException.originalError, equals(originalError));
      });
    });

    group('Timeout and Recovery Integration', () {
      test('should have reasonable timeout values for integration', () {
        // Verify timeouts are reasonable for integration scenarios
        expect(AppConstants.initializationTimeout.inSeconds, lessThan(60));
        expect(AppConstants.authTimeout.inSeconds, lessThan(30));
        expect(AppConstants.healthCheckTimeout.inSeconds, lessThan(10));
        expect(AppConstants.firstLaunchTimeout.inSeconds, lessThan(10));

        // Verify timeout relationships
        expect(AppConstants.initializationTimeout.inSeconds,
               greaterThanOrEqualTo(AppConstants.authTimeout.inSeconds));
      });

      test('should handle timeout scenarios in data structures', () {
        // Test timeout-related data structures
        final timedOutResult = InitializationResult(
          success: false,
          errorMessage: 'Timeout occurred',
          systemStatus: {'timeout': true},
          initializationTime: AppConstants.initializationTimeout,
          timestamp: DateTime.now(),
        );

        expect(timedOutResult.timedOut, isTrue);
        expect(timedOutResult.isReadyForOperation, isFalse);
      });
    });

    group('State Consistency Integration', () {
      test('should maintain consistent state across authentication scenarios', () {
        // Test various authentication state combinations
        final scenarios = [
          // Scenario 1: First launch
          AuthenticationState(
            isEnabled: false,
            isHealthy: true,
            requiresSetup: true,
            lastCheck: DateTime.now(),
            authStatus: null,
            isFirstLaunch: true,
          ),
          // Scenario 2: System unhealthy
          AuthenticationState(
            isEnabled: true,
            isHealthy: false,
            requiresSetup: false,
            lastCheck: DateTime.now(),
            authStatus: null,
            isFirstLaunch: false,
          ),
          // Scenario 3: Ready for operation
          AuthenticationState(
            isEnabled: true,
            isHealthy: true,
            requiresSetup: false,
            lastCheck: DateTime.now(),
            authStatus: null,
            isFirstLaunch: false,
          ),
        ];

        // Verify state logic consistency
        expect(scenarios[0].needsAuthentication, isTrue);
        expect(scenarios[0].isReadyForOperation, isFalse);
        
        expect(scenarios[1].needsAuthentication, isTrue);
        expect(scenarios[1].isReadyForOperation, isFalse);
        
        expect(scenarios[2].needsAuthentication, isFalse);
        expect(scenarios[2].isReadyForOperation, isTrue);
      });

      test('should maintain consistent health reporting', () {
        // Test health result consistency
        final healthyResult = SystemHealthResult(
          isHealthy: true,
          componentStatus: {'auth': true, 'settings': true, 'system': true},
          details: {},
          checkTime: DateTime.now(),
        );

        final unhealthyResult = SystemHealthResult(
          isHealthy: false,
          componentStatus: {'auth': false, 'settings': true, 'system': true},
          details: {},
          checkTime: DateTime.now(),
        );

        expect(healthyResult.healthyComponents.length, equals(3));
        expect(healthyResult.unhealthyComponents.length, equals(0));
        
        expect(unhealthyResult.healthyComponents.length, equals(2));
        expect(unhealthyResult.unhealthyComponents.length, equals(1));
        expect(unhealthyResult.unhealthyComponents, contains('auth'));
      });
    });

    group('Widget-based Authentication Flow Tests', () {
      testWidgets('should complete PIN setup flow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PinSetupScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show PIN setup screen
        expect(find.text('Secure Your Journal'), findsOneWidget);

        // Enter PIN
        await tester.enterText(find.byType(TextField), '1234');
        await tester.pump();

        // Continue to confirmation
        final continueButton = find.text('Continue');
        if (continueButton.evaluate().isNotEmpty) {
          await tester.tap(continueButton);
          await tester.pumpAndSettle();

          // Confirm PIN
          await tester.enterText(find.byType(TextField), '1234');
          await tester.pump();

          final confirmButton = find.text('Confirm');
          if (confirmButton.evaluate().isNotEmpty) {
            await tester.tap(confirmButton);
            await tester.pumpAndSettle();

            // Should complete setup
            expect(find.byType(CircularProgressIndicator), findsNothing);
          }
        }
      });

      testWidgets('should handle PIN entry flow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PinEntryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show PIN entry screen
        expect(find.text('Enter Your PIN'), findsOneWidget);

        // Enter PIN
        await tester.enterText(find.byType(TextField), '1234');
        await tester.pump();

        // Submit PIN
        final submitButton = find.text('Submit');
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('should handle authentication in main app flow', (WidgetTester tester) async {
        await tester.pumpWidget(const SpiralJournalApp());
        await tester.pumpAndSettle();

        // App should load and show main interface or authentication
        expect(find.byType(MaterialApp), findsOneWidget);
        
        // Should show either main navigation or authentication screen
        final hasNavigation = find.byType(BottomNavigationBar).evaluate().isNotEmpty;
        final hasAuth = find.textContaining('PIN').evaluate().isNotEmpty;
        
        expect(hasNavigation || hasAuth, isTrue);
      });

      testWidgets('should handle biometric authentication when available', (WidgetTester tester) async {
        final pinAuthService = PinAuthService();
        final biometricAvailable = await pinAuthService.isBiometricAvailable();

        if (biometricAvailable) {
          await tester.pumpWidget(
            const MaterialApp(
              home: PinEntryScreen(),
            ),
          );

          await tester.pumpAndSettle();

          // Look for biometric option
          final biometricButton = find.textContaining('biometric');
          if (biometricButton.evaluate().isNotEmpty) {
            await tester.tap(biometricButton);
            await tester.pump();
            
            // Should trigger biometric authentication
            expect(find.byType(PinEntryScreen), findsOneWidget);
          }
        }
      });

      testWidgets('should handle PIN reset flow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PinEntryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Look for reset option
        final resetButton = find.text('Reset PIN');
        if (resetButton.evaluate().isNotEmpty) {
          await tester.tap(resetButton);
          await tester.pumpAndSettle();

          // Should show confirmation dialog
          expect(find.textContaining('reset'), findsOneWidget);
          
          // Confirm reset
          final confirmReset = find.text('Confirm');
          if (confirmReset.evaluate().isNotEmpty) {
            await tester.tap(confirmReset);
            await tester.pumpAndSettle();
          }
        }
      });

      testWidgets('should handle authentication errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PinEntryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Enter wrong PIN
        await tester.enterText(find.byType(TextField), '0000');
        await tester.pump();

        final submitButton = find.text('Submit');
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton);
          await tester.pump();

          // Should show error message
          expect(find.textContaining('incorrect'), findsOneWidget);
        }
      });
    });
  });
}