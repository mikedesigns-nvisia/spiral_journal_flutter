import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/pin_auth_service.dart';

void main() {
  group('PinAuthService', () {
    late PinAuthService pinAuthService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      pinAuthService = PinAuthService();
    });

    test('should initially have no PIN set', () async {
      final hasPinSet = await pinAuthService.hasPinSet();
      expect(hasPinSet, false);
    });

    test('should validate PIN format correctly', () async {
      // Test valid PINs
      final validResult = await pinAuthService.setPin('1234');
      expect(validResult.success, true);

      // Test invalid PINs
      final tooShortResult = await pinAuthService.setPin('123');
      expect(tooShortResult.success, false);
      expect(tooShortResult.message, contains('PIN must be 4-6 digits'));

      final tooLongResult = await pinAuthService.setPin('1234567');
      expect(tooLongResult.success, false);
      expect(tooLongResult.message, contains('PIN must be 4-6 digits'));

      final nonNumericResult = await pinAuthService.setPin('12ab');
      expect(nonNumericResult.success, false);
      expect(nonNumericResult.message, contains('PIN must be 4-6 digits'));
    });

    test('should set and validate PIN correctly', () async {
      const testPin = '1234';
      
      // Set PIN
      final setResult = await pinAuthService.setPin(testPin);
      expect(setResult.success, true);

      // Check PIN is set
      final hasPinSet = await pinAuthService.hasPinSet();
      expect(hasPinSet, true);

      // Validate correct PIN
      final validResult = await pinAuthService.validatePin(testPin);
      expect(validResult.success, true);

      // Validate incorrect PIN
      final invalidResult = await pinAuthService.validatePin('5678');
      expect(invalidResult.success, false);
      expect(invalidResult.message, contains('Incorrect PIN'));
    });

    test('should handle failed attempts correctly', () async {
      const testPin = '1234';
      await pinAuthService.setPin(testPin);

      // Make multiple failed attempts
      for (int i = 0; i < 3; i++) {
        final result = await pinAuthService.validatePin('9999');
        expect(result.success, false);
      }

      // Check status shows failed attempts
      final status = await pinAuthService.getAuthStatus();
      expect(status.failedAttempts, 3);
    });

    test('should reset PIN and clear data', () async {
      const testPin = '1234';
      await pinAuthService.setPin(testPin);
      
      // Verify PIN is set
      expect(await pinAuthService.hasPinSet(), true);

      // Reset PIN
      final resetResult = await pinAuthService.resetPin();
      expect(resetResult.success, true);

      // Verify PIN is no longer set
      expect(await pinAuthService.hasPinSet(), false);
    });

    test('should get authentication status correctly', () async {
      final status = await pinAuthService.getAuthStatus();
      
      expect(status.hasPinSet, false);
      expect(status.isFirstLaunch, true);
      expect(status.failedAttempts, 0);
      expect(status.isLockedOut, false);
    });
  });
}