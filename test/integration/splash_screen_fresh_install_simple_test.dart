import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/controllers/splash_screen_controller.dart';
import 'package:spiral_journal/services/fresh_install_manager.dart';

void main() {
  group('Splash Screen Fresh Install Simple Tests', () {
    late SplashScreenController splashController;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      splashController = SplashScreenController();
      FreshInstallManager.reset();
    });

    tearDown(() async {
      splashController.clearConfigurationCache();
      FreshInstallManager.reset();
    });

    test('splash screen controller detects fresh install mode', () async {
      // Initialize fresh install manager in enabled mode
      await FreshInstallManager.initialize(
        config: const FreshInstallConfig(
          enabled: true,
          showIndicator: true,
          enableLogging: false,
        ),
      );
      
      // Check if splash should be shown
      final shouldShow = await splashController.shouldShowSplash();
      
      // Verify splash is forced in fresh install mode
      expect(shouldShow, isTrue);
      expect(FreshInstallManager.isFreshInstallMode, isTrue);
    });

    test('splash screen controller returns correct configuration in fresh install mode', () async {
      // Initialize fresh install manager
      await FreshInstallManager.initialize(
        config: const FreshInstallConfig(
          enabled: true,
          showIndicator: true,
          enableLogging: false,
          splashDuration: Duration(seconds: 3),
        ),
      );
      
      // Get splash configuration
      final config = await splashController.getSplashConfiguration();
      
      // Verify configuration reflects fresh install mode
      expect(config.enabled, isTrue);
      expect(config.isFreshInstallMode, isTrue);
      expect(config.showFreshInstallIndicator, isTrue);
      expect(config.displayDuration, equals(const Duration(seconds: 3)));
    });

    test('splash screen controller returns normal configuration when fresh install disabled', () async {
      // Initialize fresh install manager in disabled mode
      await FreshInstallManager.initialize(
        config: const FreshInstallConfig(
          enabled: false,
          enableLogging: false,
        ),
      );
      
      // Get splash configuration
      final config = await splashController.getSplashConfiguration();
      
      // Verify configuration reflects normal mode
      expect(config.isFreshInstallMode, isFalse);
      expect(config.showFreshInstallIndicator, isFalse);
      expect(config.displayDuration, equals(const Duration(seconds: 2)));
    });

    test('splash screen controller handles completion callback', () async {
      // Initialize fresh install manager
      await FreshInstallManager.initialize(
        config: const FreshInstallConfig(
          enabled: true,
          enableLogging: false,
        ),
      );
      
      // Call onSplashComplete - should not throw
      expect(() => splashController.onSplashComplete(), returnsNormally);
    });
  });
}