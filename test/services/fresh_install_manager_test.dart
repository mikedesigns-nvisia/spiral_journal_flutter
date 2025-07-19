import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/fresh_install_manager.dart';
import 'package:spiral_journal/services/development_mode_detector.dart';

void main() {
  group('FreshInstallManager', () {
    setUp(() {
      // Reset the manager before each test
      FreshInstallManager.reset();
    });

    test('should initialize with default configuration', () async {
      await FreshInstallManager.initialize();
      
      expect(FreshInstallManager.isInitialized, isTrue);
      expect(FreshInstallManager.config, isNotNull);
    });

    test('should detect fresh install mode correctly', () {
      // In test environment, development mode should be detected
      expect(DevelopmentModeDetector.isDevelopmentMode, isTrue);
      expect(FreshInstallManager.isFreshInstallMode, isTrue);
    });

    test('should allow configuration updates', () {
      const testConfig = FreshInstallConfig(
        enabled: false,
        showIndicator: false,
        enableLogging: false,
      );
      
      FreshInstallManager.initialize(config: testConfig);
      
      expect(FreshInstallManager.config.enabled, isFalse);
      expect(FreshInstallManager.config.showIndicator, isFalse);
      expect(FreshInstallManager.config.enableLogging, isFalse);
    });

    test('should toggle fresh install mode', () {
      FreshInstallManager.setFreshInstallMode(false);
      expect(FreshInstallManager.config.enabled, isFalse);
      
      FreshInstallManager.setFreshInstallMode(true);
      expect(FreshInstallManager.config.enabled, isTrue);
    });

    test('should reset properly', () {
      FreshInstallManager.initialize();
      expect(FreshInstallManager.isInitialized, isTrue);
      
      FreshInstallManager.reset();
      expect(FreshInstallManager.isInitialized, isFalse);
    });
  });

  group('FreshInstallConfig', () {
    test('should create from environment with debug defaults', () {
      final config = FreshInstallConfig.fromEnvironment();
      
      // In test environment, these should be true
      expect(config.enabled, isTrue);
      expect(config.showIndicator, isTrue);
      expect(config.enableLogging, isTrue);
      expect(config.splashDuration, equals(const Duration(seconds: 2)));
    });

    test('should create with custom values', () {
      const config = FreshInstallConfig(
        enabled: false,
        showIndicator: false,
        enableLogging: false,
        splashDuration: Duration(seconds: 5),
      );
      
      expect(config.enabled, isFalse);
      expect(config.showIndicator, isFalse);
      expect(config.enableLogging, isFalse);
      expect(config.splashDuration, equals(const Duration(seconds: 5)));
    });
  });
}