import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/development_mode_detector.dart';

void main() {
  group('DevelopmentModeDetector', () {
    test('should detect development mode in test environment', () {
      expect(DevelopmentModeDetector.isDevelopmentMode, isTrue);
    });

    test('should provide development info', () {
      final info = DevelopmentModeDetector.getDevelopmentInfo();
      
      expect(info, isA<Map<String, dynamic>>());
      expect(info.containsKey('isDevelopmentMode'), isTrue);
      expect(info.containsKey('isFlutterRun'), isTrue);
      expect(info.containsKey('kDebugMode'), isTrue);
      expect(info.containsKey('platform'), isTrue);
    });

    test('should get mode description', () {
      final description = DevelopmentModeDetector.getModeDescription();
      expect(description, isA<String>());
      expect(description.isNotEmpty, isTrue);
    });

    test('should determine if fresh install should be enabled', () {
      final shouldEnable = DevelopmentModeDetector.shouldEnableFreshInstall();
      // In test environment, this should be true
      expect(shouldEnable, isTrue);
    });

    test('should not throw when logging development status', () {
      expect(() => DevelopmentModeDetector.logDevelopmentStatus(), returnsNormally);
    });
  });
}