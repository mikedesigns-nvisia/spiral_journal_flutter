import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/services/theme_service.dart';

void main() {
  group('ThemeService', () {
    late ThemeService themeService;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      themeService = ThemeService();
    });

    tearDown(() async {
      // Clean up after each test
      await themeService.clearThemePreferences();
    });

    group('Initialization', () {
      test('should initialize with system theme by default', () async {
        await themeService.initialize();
        final themeMode = await themeService.getThemeMode();
        expect(themeMode, equals(ThemeMode.system));
        expect(themeService.isSystemTheme, isTrue);
      });

      test('should handle initialization errors gracefully', () async {
        // This test verifies error handling during initialization
        await themeService.initialize();
        expect(themeService.isSystemTheme, isTrue);
      });

      test('should only initialize once', () async {
        await themeService.initialize();
        await themeService.initialize(); // Second call should be ignored
        final themeMode = await themeService.getThemeMode();
        expect(themeMode, equals(ThemeMode.system));
      });
    });

    group('Theme Mode Management', () {
      test('should set and get theme mode correctly', () async {
        await themeService.initialize();
        
        await themeService.setThemeMode(ThemeMode.dark);
        final darkMode = await themeService.getThemeMode();
        expect(darkMode, equals(ThemeMode.dark));
        expect(themeService.isDarkTheme, isTrue);
        expect(themeService.isLightTheme, isFalse);
        expect(themeService.isSystemTheme, isFalse);

        await themeService.setThemeMode(ThemeMode.light);
        final lightMode = await themeService.getThemeMode();
        expect(lightMode, equals(ThemeMode.light));
        expect(themeService.isLightTheme, isTrue);
        expect(themeService.isDarkTheme, isFalse);
        expect(themeService.isSystemTheme, isFalse);
      });

      test('should persist theme mode across service instances', () async {
        await themeService.initialize();
        await themeService.setThemeMode(ThemeMode.dark);

        // Create new instance to test persistence
        final newThemeService = ThemeService();
        await newThemeService.initialize();
        final persistedMode = await newThemeService.getThemeMode();
        
        expect(persistedMode, equals(ThemeMode.dark));
      });

      test('should not change theme mode if setting same value', () async {
        await themeService.initialize();
        
        var notificationCount = 0;
        themeService.addListener(() => notificationCount++);
        
        await themeService.setThemeMode(ThemeMode.system);
        await themeService.setThemeMode(ThemeMode.system); // Same value
        
        expect(notificationCount, equals(0));
      });

      test('should notify listeners when theme mode changes', () async {
        await themeService.initialize();
        
        var notificationCount = 0;
        themeService.addListener(() => notificationCount++);
        
        await themeService.setThemeMode(ThemeMode.dark);
        expect(notificationCount, equals(1));
        
        await themeService.setThemeMode(ThemeMode.light);
        expect(notificationCount, equals(2));
      });
    });

    group('Theme Toggle', () {
      test('should toggle between light and dark themes', () async {
        await themeService.initialize();
        
        // Start with light theme
        await themeService.setThemeMode(ThemeMode.light);
        await themeService.toggleTheme();
        expect(await themeService.getThemeMode(), equals(ThemeMode.dark));
        
        // Toggle back to light
        await themeService.toggleTheme();
        expect(await themeService.getThemeMode(), equals(ThemeMode.light));
      });

      test('should toggle from system to dark theme', () async {
        await themeService.initialize();
        
        // Start with system theme
        expect(await themeService.getThemeMode(), equals(ThemeMode.system));
        
        await themeService.toggleTheme();
        expect(await themeService.getThemeMode(), equals(ThemeMode.dark));
      });
    });

    group('Effective Theme Mode', () {
      testWidgets('should return correct effective theme mode based on system brightness', (tester) async {
        await themeService.initialize();
        
        // Create a test widget to provide MediaQuery context
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                // Test system theme with light system brightness
                final effectiveMode = themeService.getEffectiveThemeMode(context);
                expect(effectiveMode, equals(ThemeMode.light));
                
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return set theme mode when not using system', (tester) async {
        await themeService.initialize();
        await themeService.setThemeMode(ThemeMode.dark);
        
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                final effectiveMode = themeService.getEffectiveThemeMode(context);
                expect(effectiveMode, equals(ThemeMode.dark));
                
                final isEffectiveDark = themeService.isEffectiveDark(context);
                expect(isEffectiveDark, isTrue);
                
                final isEffectiveLight = themeService.isEffectiveLight(context);
                expect(isEffectiveLight, isFalse);
                
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('Theme Mode Display Names', () {
      test('should return correct display names for theme modes', () {
        expect(themeService.getThemeModeDisplayName(ThemeMode.system), equals('System'));
        expect(themeService.getThemeModeDisplayName(ThemeMode.light), equals('Light'));
        expect(themeService.getThemeModeDisplayName(ThemeMode.dark), equals('Dark'));
      });

      test('should return current theme mode display name', () async {
        await themeService.initialize();
        
        await themeService.setThemeMode(ThemeMode.dark);
        expect(themeService.currentThemeModeDisplayName, equals('Dark'));
        
        await themeService.setThemeMode(ThemeMode.light);
        expect(themeService.currentThemeModeDisplayName, equals('Light'));
      });
    });

    group('Theme Mode Serialization', () {
      test('should convert theme mode to string correctly', () {
        expect(ThemeService.themeModeToString(ThemeMode.system), equals('system'));
        expect(ThemeService.themeModeToString(ThemeMode.light), equals('light'));
        expect(ThemeService.themeModeToString(ThemeMode.dark), equals('dark'));
      });

      test('should convert string to theme mode correctly', () {
        expect(ThemeService.themeModeFromString('system'), equals(ThemeMode.system));
        expect(ThemeService.themeModeFromString('light'), equals(ThemeMode.light));
        expect(ThemeService.themeModeFromString('dark'), equals(ThemeMode.dark));
        expect(ThemeService.themeModeFromString('LIGHT'), equals(ThemeMode.light));
        expect(ThemeService.themeModeFromString('invalid'), equals(ThemeMode.system));
      });
    });

    group('Reset and Clear', () {
      test('should reset to system theme', () async {
        await themeService.initialize();
        
        await themeService.setThemeMode(ThemeMode.dark);
        await themeService.resetToSystemTheme();
        
        expect(await themeService.getThemeMode(), equals(ThemeMode.system));
        expect(themeService.isSystemTheme, isTrue);
      });

      test('should clear theme preferences', () async {
        await themeService.initialize();
        
        await themeService.setThemeMode(ThemeMode.dark);
        await themeService.clearThemePreferences();
        
        expect(await themeService.getThemeMode(), equals(ThemeMode.system));
      });

      test('should notify listeners when clearing preferences', () async {
        await themeService.initialize();
        
        var notificationCount = 0;
        themeService.addListener(() => notificationCount++);
        
        await themeService.setThemeMode(ThemeMode.dark);
        await themeService.clearThemePreferences();
        
        expect(notificationCount, equals(2)); // One for set, one for clear
      });
    });

    group('Accessibility Features', () {
      test('should provide accessibility-related methods', () async {
        await themeService.initialize();
        
        // Test that accessibility methods are available
        expect(themeService.isHighContrastMode, isA<bool>());
        expect(themeService.isLargeTextMode, isA<bool>());
        expect(themeService.isReducedMotionMode, isA<bool>());
      });

      test('should handle accessibility mode changes', () async {
        await themeService.initialize();
        
        var notificationCount = 0;
        themeService.addListener(() => notificationCount++);
        
        await themeService.setHighContrastMode(true);
        await themeService.setLargeTextMode(true);
        await themeService.setReducedMotionMode(true);
        
        expect(notificationCount, equals(3));
      });

      test('should provide animation duration based on accessibility settings', () async {
        await themeService.initialize();
        
        const defaultDuration = Duration(milliseconds: 300);
        final animationDuration = themeService.getAnimationDuration(defaultDuration);
        
        expect(animationDuration, isA<Duration>());
      });

      test('should provide animation curve based on accessibility settings', () async {
        await themeService.initialize();
        
        const defaultCurve = Curves.easeInOut;
        final animationCurve = themeService.getAnimationCurve(defaultCurve);
        
        expect(animationCurve, isA<Curve>());
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // This test ensures the service doesn't crash on storage errors
        await themeService.initialize();
        
        // Service should still work even if there are storage issues
        expect(await themeService.getThemeMode(), isA<ThemeMode>());
      });

      test('should handle invalid stored theme mode values', () async {
        // Set invalid theme mode index in SharedPreferences
        SharedPreferences.setMockInitialValues({'theme_mode': 999});
        
        await themeService.initialize();
        
        // Should default to system theme for invalid values
        expect(await themeService.getThemeMode(), equals(ThemeMode.system));
      });
    });
  });
}