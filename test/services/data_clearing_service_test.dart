import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spiral_journal/services/data_clearing_service.dart';

void main() {
  group('DataClearingService Tests', () {
    setUpAll(() {
      // Initialize test environment
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize FFI for database tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    group('SharedPreferences clearing', () {
      test('should clear SharedPreferences and restore defaults', () async {
        // Set up initial preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', 'Test User');
        await prefs.setInt('user_age', 25);
        await prefs.setBool('notifications_enabled', true);
        await prefs.setStringList('favorite_moods', ['happy', 'excited']);

        // Verify initial state
        expect(prefs.getKeys().length, equals(4));
        expect(prefs.getString('user_name'), equals('Test User'));

        // Clear preferences
        final result = await DataClearingService.clearSharedPreferences();

        // Verify clearing result
        expect(result.success, isTrue);
        expect(result.clearOperationSuccess, isTrue);
        expect(result.initialKeyCount, equals(4));
        expect(result.clearedKeys.length, equals(4));
        expect(result.clearedKeys, contains('user_name'));
        expect(result.clearedKeys, contains('user_age'));
        expect(result.clearedKeys, contains('notifications_enabled'));
        expect(result.clearedKeys, contains('favorite_moods'));

        // Verify defaults were restored
        expect(result.restoredKeys.length, greaterThan(0));
        expect(result.restoredKeys, contains('first_launch'));
        expect(result.restoredKeys, contains('onboarding_completed'));
        expect(result.restoredKeys, contains('profile_setup_completed'));

        // Verify actual preferences state
        final finalPrefs = await SharedPreferences.getInstance();
        expect(finalPrefs.getBool('first_launch'), isTrue);
        expect(finalPrefs.getBool('onboarding_completed'), isFalse);
        expect(finalPrefs.getBool('profile_setup_completed'), isFalse);
        expect(finalPrefs.getBool('fresh_install_mode'), isTrue);
        expect(finalPrefs.getString('theme_mode'), equals('system'));
        expect(finalPrefs.getBool('ai_analysis_enabled'), isTrue);

        // Verify old data is gone
        expect(finalPrefs.getString('user_name'), isNull);
        expect(finalPrefs.getInt('user_age'), isNull);
      });

      test('should handle empty SharedPreferences gracefully', () async {
        // Clear preferences when already empty
        final result = await DataClearingService.clearSharedPreferences();

        // Verify result
        expect(result.success, isTrue);
        expect(result.initialKeyCount, equals(0));
        expect(result.clearedKeys.length, equals(0));
        expect(result.restoredKeys.length, greaterThan(0));

        // Verify defaults were still restored
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('first_launch'), isTrue);
        expect(prefs.getBool('onboarding_completed'), isFalse);
      });

      test('should provide detailed summary of preferences clearing', () async {
        // Set up initial preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('test_key', 'test_value');

        // Clear preferences
        final result = await DataClearingService.clearSharedPreferences();

        // Verify summary
        expect(result.summary, contains('successfully'));
        expect(result.summary, contains('Removed 1 keys'));
        expect(result.summary, contains('restored'));
      });
    });

    group('Secure Storage clearing', () {
      test('should handle secure storage clearing in test environment', () async {
        // Clear secure storage (will be mocked in test environment)
        final result = await DataClearingService.clearSecureStorage();

        // In test environment, should be considered successful
        expect(result.success, isTrue);
        expect(result.testEnvironment, isTrue);
        expect(result.error, isNull);

        // Verify summary
        expect(result.summary, contains('test environment'));
      });

      test('should provide detailed summary of secure storage clearing', () async {
        final result = await DataClearingService.clearSecureStorage();

        // Verify summary is informative
        expect(result.summary, isNotEmpty);
        expect(result.summary, anyOf([
          contains('successfully'),
          contains('test environment')
        ]));
      });
    });

    group('Cache clearing', () {
      test('should handle cache clearing in test environment', () async {
        // Clear caches (should work in test environment with mocked SharedPreferences)
        final result = await DataClearingService.clearCaches();

        // Should handle test environment gracefully
        expect(result.success, isTrue);
        expect(result.aiCacheCleared, isTrue);
        expect(result.hasErrors, isFalse);

        // Verify summary
        expect(result.summary, contains('successfully'));
      });

      test('should provide detailed summary of cache clearing', () async {
        final result = await DataClearingService.clearCaches();

        // Verify summary is informative
        expect(result.summary, isNotEmpty);
        expect(result.summary, contains('successfully'));
      });
    });

    group('Comprehensive data clearing', () {
      test('should clear all data types comprehensively', () async {
        // Set up initial data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('test_data', 'should_be_cleared');
        await prefs.setBool('test_flag', true);

        // Clear all data
        final result = await DataClearingService.clearAllData();

        // Verify comprehensive clearing
        expect(result.success, isTrue);
        expect(result.databaseResult.success, isTrue);
        expect(result.preferencesResult.success, isTrue);
        expect(result.secureStorageResult.success, isTrue);
        expect(result.cacheResult.success, isTrue);
        expect(result.hasErrors, isFalse);

        // Verify preferences were cleared and defaults restored
        final finalPrefs = await SharedPreferences.getInstance();
        expect(finalPrefs.getString('test_data'), isNull);
        expect(finalPrefs.getBool('test_flag'), isNull);
        expect(finalPrefs.getBool('first_launch'), isTrue);
        expect(finalPrefs.getBool('fresh_install_mode'), isTrue);

        // Verify summary is comprehensive
        expect(result.summary, contains('successfully'));
        expect(result.summary, contains('Database:'));
        expect(result.summary, contains('Preferences:'));
        expect(result.summary, contains('Secure Storage:'));
        expect(result.summary, contains('Caches:'));
      });

      test('should provide detailed error reporting', () async {
        // Clear all data
        final result = await DataClearingService.clearAllData();

        // Even if some operations have test environment limitations,
        // should provide detailed reporting
        expect(result.summary, isNotEmpty);
        
        if (result.hasErrors) {
          // If there are errors, they should be properly categorized
          expect(result.databaseResult.hasErrors || 
                 result.preferencesResult.error != null ||
                 result.secureStorageResult.error != null ||
                 result.cacheResult.hasErrors, isTrue);
        }
      });

      test('should handle selective storage clearing', () async {
        // Test clearing specific storage types
        final dbResult = await DataClearingService.clearDatabase();
        expect(dbResult, isNotNull);
        expect(dbResult.success, isTrue);

        final prefsResult = await DataClearingService.clearSharedPreferences();
        expect(prefsResult.success, isTrue);

        final secureResult = await DataClearingService.clearSecureStorage();
        expect(secureResult.success, isTrue);

        final cacheResult = await DataClearingService.clearCaches();
        expect(cacheResult.success, isTrue);
      });
    });

    group('Default preferences restoration', () {
      test('should restore all essential default preferences', () async {
        // Clear preferences to trigger default restoration
        final result = await DataClearingService.clearSharedPreferences();
        expect(result.success, isTrue);

        // Verify all essential defaults are restored
        final prefs = await SharedPreferences.getInstance();
        
        // Fresh install flags
        expect(prefs.getBool('first_launch'), isTrue);
        expect(prefs.getBool('onboarding_completed'), isFalse);
        expect(prefs.getBool('profile_setup_completed'), isFalse);
        expect(prefs.getBool('pin_setup_completed'), isFalse);
        expect(prefs.getBool('fresh_install_mode'), isTrue);
        
        // Security defaults
        expect(prefs.getBool('biometric_auth_enabled'), isFalse);
        
        // Theme defaults
        expect(prefs.getString('theme_mode'), equals('system'));
        expect(prefs.getBool('dark_mode_enabled'), isFalse);
        
        // Privacy defaults
        expect(prefs.getBool('analytics_enabled'), isFalse);
        expect(prefs.getBool('crash_reporting_enabled'), isFalse);
        
        // AI defaults
        expect(prefs.getBool('ai_analysis_enabled'), isTrue);
        expect(prefs.getString('ai_provider'), equals('claude'));
      });

      test('should maintain fresh install state after clearing', () async {
        // Clear preferences multiple times
        await DataClearingService.clearSharedPreferences();
        await DataClearingService.clearSharedPreferences();
        
        // Should still maintain fresh install state
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('fresh_install_mode'), isTrue);
        expect(prefs.getBool('first_launch'), isTrue);
        expect(prefs.getBool('onboarding_completed'), isFalse);
      });
    });

    group('Error handling', () {
      test('should handle storage clearing errors gracefully', () async {
        // This test verifies that errors don't crash the clearing process
        final result = await DataClearingService.clearAllData();
        
        // Should complete without throwing exceptions
        expect(result, isNotNull);
        expect(result.summary, isNotEmpty);
      });

      test('should provide meaningful error messages', () async {
        final result = await DataClearingService.clearAllData();
        
        if (result.hasErrors) {
          // Error messages should be informative
          if (result.preferencesResult.error != null) {
            expect(result.preferencesResult.error, isNotEmpty);
          }
          if (result.secureStorageResult.error != null) {
            expect(result.secureStorageResult.error, isNotEmpty);
          }
          if (result.cacheResult.hasErrors) {
            expect(result.cacheResult.errors, isNotEmpty);
          }
        }
      });
    });
  });
}