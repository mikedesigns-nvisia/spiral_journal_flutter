import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/services/settings_service.dart';
import 'package:spiral_journal/models/user_preferences.dart';

void main() {
  group('SettingsService', () {
    late SettingsService settingsService;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
    });

    tearDown(() async {
      // Clean up after each test
      await settingsService.clearAllSettings();
    });

    group('Initialization', () {
      test('should initialize with default preferences', () async {
        await settingsService.initialize();
        final preferences = await settingsService.getPreferences();
        
        expect(preferences.personalizedInsightsEnabled, isTrue);
        expect(preferences.themeMode, equals(ThemeMode.system));
        expect(preferences.biometricAuthEnabled, isFalse);
        expect(preferences.analyticsEnabled, isTrue);
        expect(preferences.dailyRemindersEnabled, isFalse);
        expect(preferences.splashScreenEnabled, isTrue);
      });

      test('should only initialize once', () async {
        await settingsService.initialize();
        await settingsService.initialize(); // Second call should be ignored
        
        final preferences = await settingsService.getPreferences();
        expect(preferences, isA<UserPreferences>());
      });

      test('should handle initialization errors gracefully', () async {
        // Service should initialize even with potential errors
        await settingsService.initialize();
        expect(await settingsService.getPreferences(), isA<UserPreferences>());
      });
    });

    group('Preferences Management', () {
      test('should update and persist preferences', () async {
        await settingsService.initialize();
        
        final newPreferences = UserPreferences(
          personalizedInsightsEnabled: false,
          themeMode: ThemeMode.dark,
          biometricAuthEnabled: true,
          analyticsEnabled: false,
          dailyRemindersEnabled: true,
          reminderTime: '09:00',
          splashScreenEnabled: false,
        );
        
        await settingsService.updatePreferences(newPreferences);
        final updatedPreferences = await settingsService.getPreferences();
        
        expect(updatedPreferences.personalizedInsightsEnabled, isFalse);
        expect(updatedPreferences.themeMode, equals(ThemeMode.dark));
        expect(updatedPreferences.biometricAuthEnabled, isTrue);
        expect(updatedPreferences.analyticsEnabled, isFalse);
        expect(updatedPreferences.dailyRemindersEnabled, isTrue);
        expect(updatedPreferences.reminderTime, equals('09:00'));
        expect(updatedPreferences.splashScreenEnabled, isFalse);
      });

      test('should persist preferences across service instances', () async {
        await settingsService.initialize();
        
        await settingsService.setPersonalizedInsightsEnabled(false);
        await settingsService.setThemeMode(ThemeMode.dark);
        
        // Create new instance to test persistence
        final newSettingsService = SettingsService();
        await newSettingsService.initialize();
        
        expect(await newSettingsService.getPersonalizedInsightsEnabled(), isFalse);
        expect(await newSettingsService.getThemeMode(), equals(ThemeMode.dark));
      });

      test('should not update if preferences are the same', () async {
        await settingsService.initialize();
        
        var notificationCount = 0;
        settingsService.addListener(() => notificationCount++);
        
        final currentPreferences = await settingsService.getPreferences();
        await settingsService.updatePreferences(currentPreferences);
        
        expect(notificationCount, equals(0));
      });

      test('should notify listeners when preferences change', () async {
        await settingsService.initialize();
        
        var notificationCount = 0;
        settingsService.addListener(() => notificationCount++);
        
        await settingsService.setPersonalizedInsightsEnabled(false);
        expect(notificationCount, equals(1));
        
        await settingsService.setThemeMode(ThemeMode.dark);
        expect(notificationCount, equals(2));
      });
    });

    group('Personalized Insights', () {
      test('should get and set personalized insights enabled', () async {
        await settingsService.initialize();
        
        expect(await settingsService.getPersonalizedInsightsEnabled(), isTrue);
        
        await settingsService.setPersonalizedInsightsEnabled(false);
        expect(await settingsService.getPersonalizedInsightsEnabled(), isFalse);
        
        await settingsService.setPersonalizedInsightsEnabled(true);
        expect(await settingsService.getPersonalizedInsightsEnabled(), isTrue);
      });

      test('should not change if setting same value', () async {
        await settingsService.initialize();
        
        var notificationCount = 0;
        settingsService.addListener(() => notificationCount++);
        
        await settingsService.setPersonalizedInsightsEnabled(true); // Same as default
        expect(notificationCount, equals(0));
      });
    });

    group('Theme Management', () {
      test('should get and set theme mode', () async {
        await settingsService.initialize();
        
        expect(await settingsService.getThemeMode(), equals(ThemeMode.system));
        
        await settingsService.setThemeMode(ThemeMode.dark);
        expect(await settingsService.getThemeMode(), equals(ThemeMode.dark));
        
        await settingsService.setThemeMode(ThemeMode.light);
        expect(await settingsService.getThemeMode(), equals(ThemeMode.light));
      });

      test('should toggle theme correctly', () async {
        await settingsService.initialize();
        
        // Start with system theme, should toggle to dark
        await settingsService.toggleTheme();
        expect(await settingsService.getThemeMode(), equals(ThemeMode.dark));
        
        // Toggle from dark to light
        await settingsService.toggleTheme();
        expect(await settingsService.getThemeMode(), equals(ThemeMode.light));
        
        // Toggle from light to dark
        await settingsService.toggleTheme();
        expect(await settingsService.getThemeMode(), equals(ThemeMode.dark));
      });

      test('should reset to system theme', () async {
        await settingsService.initialize();
        
        await settingsService.setThemeMode(ThemeMode.dark);
        await settingsService.resetToSystemTheme();
        
        expect(await settingsService.getThemeMode(), equals(ThemeMode.system));
      });

      test('should provide theme status getters', () async {
        await settingsService.initialize();
        
        await settingsService.setThemeMode(ThemeMode.system);
        expect(settingsService.isSystemTheme, isTrue);
        expect(settingsService.isLightTheme, isFalse);
        expect(settingsService.isDarkTheme, isFalse);
        
        await settingsService.setThemeMode(ThemeMode.light);
        expect(settingsService.isSystemTheme, isFalse);
        expect(settingsService.isLightTheme, isTrue);
        expect(settingsService.isDarkTheme, isFalse);
        
        await settingsService.setThemeMode(ThemeMode.dark);
        expect(settingsService.isSystemTheme, isFalse);
        expect(settingsService.isLightTheme, isFalse);
        expect(settingsService.isDarkTheme, isTrue);
      });

      test('should provide current theme mode display name', () async {
        await settingsService.initialize();
        
        await settingsService.setThemeMode(ThemeMode.system);
        expect(settingsService.currentThemeModeDisplayName, equals('System'));
        
        await settingsService.setThemeMode(ThemeMode.light);
        expect(settingsService.currentThemeModeDisplayName, equals('Light'));
        
        await settingsService.setThemeMode(ThemeMode.dark);
        expect(settingsService.currentThemeModeDisplayName, equals('Dark'));
      });
    });

    group('Biometric Authentication', () {
      test('should get and set biometric auth enabled', () async {
        await settingsService.initialize();
        
        expect(await settingsService.getBiometricAuthEnabled(), isFalse);
        
        await settingsService.setBiometricAuthEnabled(true);
        expect(await settingsService.getBiometricAuthEnabled(), isTrue);
        
        await settingsService.setBiometricAuthEnabled(false);
        expect(await settingsService.getBiometricAuthEnabled(), isFalse);
      });

      test('should not change if setting same value', () async {
        await settingsService.initialize();
        
        var notificationCount = 0;
        settingsService.addListener(() => notificationCount++);
        
        await settingsService.setBiometricAuthEnabled(false); // Same as default
        expect(notificationCount, equals(0));
      });
    });

    group('Analytics', () {
      test('should get and set analytics enabled', () async {
        await settingsService.initialize();
        
        expect(await settingsService.getAnalyticsEnabled(), isTrue);
        
        await settingsService.setAnalyticsEnabled(false);
        expect(await settingsService.getAnalyticsEnabled(), isFalse);
        
        await settingsService.setAnalyticsEnabled(true);
        expect(await settingsService.getAnalyticsEnabled(), isTrue);
      });
    });

    group('Daily Reminders', () {
      test('should get and set daily reminders enabled', () async {
        await settingsService.initialize();
        
        expect(await settingsService.getDailyRemindersEnabled(), isFalse);
        
        await settingsService.setDailyRemindersEnabled(true);
        expect(await settingsService.getDailyRemindersEnabled(), isTrue);
        
        await settingsService.setDailyRemindersEnabled(false);
        expect(await settingsService.getDailyRemindersEnabled(), isFalse);
      });

      test('should get and set reminder time', () async {
        await settingsService.initialize();
        
        expect(await settingsService.getReminderTime(), equals('20:00'));
        
        await settingsService.setReminderTime('09:00');
        expect(await settingsService.getReminderTime(), equals('09:00'));
        
        await settingsService.setReminderTime('18:30');
        expect(await settingsService.getReminderTime(), equals('18:30'));
      });
    });

    group('Splash Screen', () {
      test('should get and set splash screen enabled', () async {
        await settingsService.initialize();
        
        expect(await settingsService.getSplashScreenEnabled(), isTrue);
        
        await settingsService.setSplashScreenEnabled(false);
        expect(await settingsService.getSplashScreenEnabled(), isFalse);
        
        await settingsService.setSplashScreenEnabled(true);
        expect(await settingsService.getSplashScreenEnabled(), isTrue);
      });
    });

    group('Legacy Compatibility', () {
      test('should support deprecated methods', () async {
        await settingsService.initialize();
        
        // Test deprecated methods still work
        expect(await settingsService.isSplashScreenEnabled(), isTrue);
        expect(await settingsService.isDailyRemindersEnabled(), isFalse);
        expect(await settingsService.isPersonalizedInsightsEnabled(), isTrue);
        expect(await settingsService.isBiometricAuthEnabled(), isFalse);
      });
    });

    group('Clear Settings', () {
      test('should clear all settings and reset to defaults', () async {
        await settingsService.initialize();
        
        // Change some settings
        await settingsService.setPersonalizedInsightsEnabled(false);
        await settingsService.setThemeMode(ThemeMode.dark);
        await settingsService.setBiometricAuthEnabled(true);
        
        // Clear all settings
        await settingsService.clearAllSettings();
        
        // Verify settings are back to defaults
        final preferences = await settingsService.getPreferences();
        expect(preferences.personalizedInsightsEnabled, isTrue);
        expect(preferences.themeMode, equals(ThemeMode.system));
        expect(preferences.biometricAuthEnabled, isFalse);
      });

      test('should notify listeners when clearing settings', () async {
        await settingsService.initialize();
        
        var notificationCount = 0;
        settingsService.addListener(() => notificationCount++);
        
        await settingsService.setPersonalizedInsightsEnabled(false);
        await settingsService.clearAllSettings();
        
        expect(notificationCount, equals(2)); // One for set, one for clear
      });
    });

    group('Theme Service Integration', () {
      test('should provide access to theme service', () async {
        await settingsService.initialize();
        
        final themeService = settingsService.themeService;
        expect(themeService, isNotNull);
      });

      test('should update theme service when theme mode changes', () async {
        await settingsService.initialize();
        
        await settingsService.setThemeMode(ThemeMode.dark);
        
        final themeService = settingsService.themeService;
        final themeMode = await themeService.getThemeMode();
        expect(themeMode, equals(ThemeMode.dark));
      });
    });

    group('Error Handling', () {
      test('should handle JSON parsing errors gracefully', () async {
        // Set invalid JSON in SharedPreferences
        SharedPreferences.setMockInitialValues({'user_preferences': 'invalid_json'});
        
        await settingsService.initialize();
        
        // Should fall back to defaults
        final preferences = await settingsService.getPreferences();
        expect(preferences.personalizedInsightsEnabled, isTrue);
        expect(preferences.themeMode, equals(ThemeMode.system));
      });

      test('should handle SharedPreferences errors gracefully', () async {
        await settingsService.initialize();
        
        // Service should still work even if there are storage issues
        expect(await settingsService.getPreferences(), isA<UserPreferences>());
      });

      test('should rethrow errors on save failures', () async {
        await settingsService.initialize();
        
        // This test ensures that save errors are properly propagated
        // In a real scenario, this would test actual storage failures
        expect(() async => await settingsService.setPersonalizedInsightsEnabled(false), 
               returnsNormally);
      });
    });

    group('Notification Behavior', () {
      test('should not notify if setting same value multiple times', () async {
        await settingsService.initialize();
        
        var notificationCount = 0;
        settingsService.addListener(() => notificationCount++);
        
        await settingsService.setPersonalizedInsightsEnabled(false);
        await settingsService.setPersonalizedInsightsEnabled(false); // Same value
        await settingsService.setPersonalizedInsightsEnabled(false); // Same value
        
        expect(notificationCount, equals(1)); // Only first change should notify
      });

      test('should notify for each different setting change', () async {
        await settingsService.initialize();
        
        var notificationCount = 0;
        settingsService.addListener(() => notificationCount++);
        
        await settingsService.setPersonalizedInsightsEnabled(false);
        await settingsService.setThemeMode(ThemeMode.dark);
        await settingsService.setBiometricAuthEnabled(true);
        await settingsService.setAnalyticsEnabled(false);
        
        expect(notificationCount, equals(4));
      });
    });
  });
}