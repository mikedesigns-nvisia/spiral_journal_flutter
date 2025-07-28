import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/accessibility_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AccessibilityService', () {
    late AccessibilityService accessibilityService;

    setUp(() {
      accessibilityService = AccessibilityService();
    });

    test('should initialize with default values', () {
      expect(accessibilityService.highContrastMode, false);
      expect(accessibilityService.largeTextMode, false);
      expect(accessibilityService.reducedMotionMode, false);
      expect(accessibilityService.screenReaderEnabled, false);
    });

    test('should generate core semantic labels correctly', () {
      final label = accessibilityService.getCoreCardSemanticLabel(
        'Optimism',
        0.75,
        0.70,
        'rising',
        true,
      );
      
      expect(label, contains('Optimism core at 75 percent'));
      expect(label, contains('trending upward'));
      expect(label, contains('increased by 5 percent'));
      expect(label, contains('recently updated'));
    });

    test('should generate core impact semantic labels correctly', () {
      final label = accessibilityService.getCoreImpactSemanticLabel(
        'Resilience',
        0.3,
        'recent journal entry',
      );
      
      expect(label, contains('Resilience core'));
      expect(label, contains('strong growth'));
      expect(label, contains('increased by 30 percent'));
      expect(label, contains('from recent journal entry'));
    });

    test('should provide appropriate animation durations for reduced motion', () async {
      await accessibilityService.setReducedMotionMode(true);
      
      final duration = accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 1000),
      );
      
      expect(duration.inMilliseconds, lessThanOrEqualTo(300));
    });

    test('should get minimum touch target size', () {
      final size = accessibilityService.getMinimumTouchTargetSize();
      expect(size, equals(48.0));
    });
  });
}