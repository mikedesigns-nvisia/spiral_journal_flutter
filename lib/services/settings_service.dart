import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';
import 'theme_service.dart';

/// Comprehensive settings management service for application preferences.
/// 
/// This service provides centralized management of all user preferences and settings,
/// integrating with the theme service and providing immediate effect for setting changes.
/// All settings are persisted locally using SharedPreferences for non-sensitive data.
/// 
/// ## Key Features
/// - **Unified Preferences**: Single source of truth for all user settings
/// - **Immediate Effect**: Setting changes take effect immediately
/// - **Theme Integration**: Seamless integration with ThemeService
/// - **Error Resilience**: Graceful handling of storage errors with fallback to defaults
/// - **JSON Persistence**: Efficient storage using JSON serialization
/// 
/// ## Usage Example
/// ```dart
/// final settingsService = SettingsService();
/// await settingsService.initialize();
/// 
/// // Get current preferences
/// final preferences = await settingsService.getPreferences();
/// 
/// // Update specific setting with immediate effect
/// await settingsService.setPersonalizedInsightsEnabled(false);
/// 
/// // Update theme with immediate effect
/// await settingsService.setThemeMode(ThemeMode.dark);
/// ```
/// 
/// ## Integration Points
/// - **ThemeService**: Automatic theme updates when theme preferences change
/// - **AI Analysis**: Personalized insights toggle affects AI analysis behavior
/// - **Authentication**: Biometric settings integration with auth system
/// 
/// ## Default Values
/// All defaults are defined in UserPreferences.defaults
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;
  UserPreferences _currentPreferences = UserPreferences.defaults;
  bool _isInitialized = false;
  
  final ThemeService _themeService = ThemeService();

  // Settings keys
  static const String _userPreferencesKey = 'user_preferences';

  /// Initialize the settings service
  /// Must be called before using other methods
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _themeService.initialize();
      await _loadPreferences();
      _isInitialized = true;
    } catch (e) {
      debugPrint('SettingsService initialization error: $e');
      // Set safe defaults
      _currentPreferences = UserPreferences.defaults;
      _isInitialized = true;
    }
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefsJson = _prefs?.getString(_userPreferencesKey);
      if (prefsJson != null) {
        final prefsMap = jsonDecode(prefsJson) as Map<String, dynamic>;
        _currentPreferences = UserPreferences.fromJson(prefsMap);
      } else {
        _currentPreferences = UserPreferences.defaults;
      }
    } catch (e) {
      debugPrint('SettingsService _loadPreferences error: $e');
      _currentPreferences = UserPreferences.defaults;
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefsJson = jsonEncode(_currentPreferences.toJson());
      await _prefs?.setString(_userPreferencesKey, prefsJson);
    } catch (e) {
      debugPrint('SettingsService _savePreferences error: $e');
      rethrow;
    }
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get current user preferences
  Future<UserPreferences> getPreferences() async {
    await _ensureInitialized();
    return _currentPreferences;
  }

  /// Update preferences with new values
  Future<void> updatePreferences(UserPreferences preferences) async {
    await _ensureInitialized();
    
    if (_currentPreferences == preferences) return;
    
    try {
      final oldPreferences = _currentPreferences;
      _currentPreferences = preferences;
      
      // Update theme service if theme changed
      if (oldPreferences.themeMode != preferences.themeMode) {
        await _themeService.setThemeMode(preferences.themeMode);
      }
      
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService updatePreferences error: $e');
      rethrow;
    }
  }

  /// Get personalized insights enabled status
  Future<bool> getPersonalizedInsightsEnabled() async {
    await _ensureInitialized();
    return _currentPreferences.personalizedInsightsEnabled;
  }

  /// Set personalized insights enabled/disabled with immediate effect
  Future<void> setPersonalizedInsightsEnabled(bool enabled) async {
    await _ensureInitialized();
    
    if (_currentPreferences.personalizedInsightsEnabled == enabled) return;
    
    try {
      _currentPreferences = _currentPreferences.copyWith(
        personalizedInsightsEnabled: enabled,
      );
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService setPersonalizedInsightsEnabled error: $e');
      rethrow;
    }
  }

  /// Get current theme mode
  Future<ThemeMode> getThemeMode() async {
    await _ensureInitialized();
    return _currentPreferences.themeMode;
  }

  /// Set theme mode with immediate effect
  Future<void> setThemeMode(ThemeMode mode) async {
    await _ensureInitialized();
    
    if (_currentPreferences.themeMode == mode) return;
    
    try {
      _currentPreferences = _currentPreferences.copyWith(themeMode: mode);
      await _themeService.setThemeMode(mode);
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService setThemeMode error: $e');
      rethrow;
    }
  }

  /// Get biometric authentication enabled status
  Future<bool> getBiometricAuthEnabled() async {
    await _ensureInitialized();
    return _currentPreferences.biometricAuthEnabled;
  }

  /// Set biometric authentication enabled/disabled
  Future<void> setBiometricAuthEnabled(bool enabled) async {
    await _ensureInitialized();
    
    if (_currentPreferences.biometricAuthEnabled == enabled) return;
    
    try {
      _currentPreferences = _currentPreferences.copyWith(
        biometricAuthEnabled: enabled,
      );
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService setBiometricAuthEnabled error: $e');
      rethrow;
    }
  }

  /// Get analytics enabled status
  Future<bool> getAnalyticsEnabled() async {
    await _ensureInitialized();
    return _currentPreferences.analyticsEnabled;
  }

  /// Set analytics enabled/disabled
  Future<void> setAnalyticsEnabled(bool enabled) async {
    await _ensureInitialized();
    
    if (_currentPreferences.analyticsEnabled == enabled) return;
    
    try {
      _currentPreferences = _currentPreferences.copyWith(
        analyticsEnabled: enabled,
      );
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService setAnalyticsEnabled error: $e');
      rethrow;
    }
  }

  /// Get daily reminders enabled status
  Future<bool> getDailyRemindersEnabled() async {
    await _ensureInitialized();
    return _currentPreferences.dailyRemindersEnabled;
  }

  /// Set daily reminders enabled/disabled
  Future<void> setDailyRemindersEnabled(bool enabled) async {
    await _ensureInitialized();
    
    if (_currentPreferences.dailyRemindersEnabled == enabled) return;
    
    try {
      _currentPreferences = _currentPreferences.copyWith(
        dailyRemindersEnabled: enabled,
      );
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService setDailyRemindersEnabled error: $e');
      rethrow;
    }
  }

  /// Get reminder time
  Future<String> getReminderTime() async {
    await _ensureInitialized();
    return _currentPreferences.reminderTime;
  }

  /// Set reminder time
  Future<void> setReminderTime(String time) async {
    await _ensureInitialized();
    
    if (_currentPreferences.reminderTime == time) return;
    
    try {
      _currentPreferences = _currentPreferences.copyWith(reminderTime: time);
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService setReminderTime error: $e');
      rethrow;
    }
  }

  /// Get splash screen enabled status
  Future<bool> getSplashScreenEnabled() async {
    await _ensureInitialized();
    return _currentPreferences.splashScreenEnabled;
  }

  /// Set splash screen enabled/disabled
  Future<void> setSplashScreenEnabled(bool enabled) async {
    await _ensureInitialized();
    
    if (_currentPreferences.splashScreenEnabled == enabled) return;
    
    try {
      _currentPreferences = _currentPreferences.copyWith(
        splashScreenEnabled: enabled,
      );
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService setSplashScreenEnabled error: $e');
      rethrow;
    }
  }

  /// Toggle theme between light and dark (skips system)
  Future<void> toggleTheme() async {
    await _ensureInitialized();
    
    switch (_currentPreferences.themeMode) {
      case ThemeMode.system:
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
    }
  }

  /// Reset to system theme
  Future<void> resetToSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Clear all settings (for app reset)
  Future<void> clearAllSettings() async {
    await _ensureInitialized();
    
    try {
      await _prefs?.remove(_userPreferencesKey);
      await _themeService.clearThemePreferences();
      _currentPreferences = UserPreferences.defaults;
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService clearAllSettings error: $e');
      rethrow;
    }
  }

  /// Get theme service instance for direct access
  ThemeService get themeService => _themeService;

  /// Check if using system theme
  bool get isSystemTheme => _currentPreferences.isSystemTheme;

  /// Check if using light theme
  bool get isLightTheme => _currentPreferences.isLightTheme;

  /// Check if using dark theme
  bool get isDarkTheme => _currentPreferences.isDarkTheme;

  /// Get current theme mode display name
  String get currentThemeModeDisplayName => _currentPreferences.themeModeDisplayName;

  /// Set text scale factor for accessibility
  Future<void> setTextScaleFactor(double scaleFactor) async {
    await _ensureInitialized();
    
    try {
      // Store the text scale factor in preferences
      // Note: This would need to be added to UserPreferences model
      // For now, we'll store it separately
      await _prefs?.setDouble('text_scale_factor', scaleFactor);
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService setTextScaleFactor error: $e');
      rethrow;
    }
  }

  /// Get text scale factor
  Future<double> getTextScaleFactor() async {
    await _ensureInitialized();
    return _prefs?.getDouble('text_scale_factor') ?? 1.0;
  }

  /// Set notifications enabled/disabled (alias for daily reminders)
  Future<void> setNotificationsEnabled(bool enabled) async {
    await setDailyRemindersEnabled(enabled);
  }

  /// Get notifications enabled status (alias for daily reminders)
  Future<bool> getNotificationsEnabled() async {
    return await getDailyRemindersEnabled();
  }

  /// Set PIN setup requested flag
  Future<void> setPinSetupRequested(bool requested) async {
    await _ensureInitialized();
    
    try {
      await _prefs?.setBool('pin_setup_requested', requested);
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService setPinSetupRequested error: $e');
      rethrow;
    }
  }

  /// Get PIN setup requested status
  Future<bool> getPinSetupRequested() async {
    await _ensureInitialized();
    return _prefs?.getBool('pin_setup_requested') ?? false;
  }

  // Legacy compatibility methods (deprecated - use new methods instead)
  @deprecated
  Future<bool> isSplashScreenEnabled() => getSplashScreenEnabled();
  
  @deprecated
  Future<bool> isDailyRemindersEnabled() => getDailyRemindersEnabled();
  
  @deprecated
  Future<bool> isPersonalizedInsightsEnabled() => getPersonalizedInsightsEnabled();
  
  @deprecated
  Future<bool> isBiometricAuthEnabled() => getBiometricAuthEnabled();
}
