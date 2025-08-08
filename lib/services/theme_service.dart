import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'accessibility_service.dart';

/// Comprehensive theme management service for the Spiral Journal app.
/// 
/// This service handles theme persistence, automatic system theme detection,
/// and manual theme overrides. It provides a centralized way to manage
/// light and dark theme switching throughout the application.
/// 
/// ## Key Features
/// - **Theme Persistence**: Saves user theme preferences locally
/// - **System Theme Detection**: Automatically detects and follows system theme
/// - **Manual Override**: Allows users to override system theme preferences
/// - **Real-time Updates**: Notifies listeners when theme changes occur
/// 
/// ## Usage Example
/// ```dart
/// final themeService = ThemeService();
/// 
/// // Get current theme mode
/// final currentMode = await themeService.getThemeMode();
/// 
/// // Set manual theme override
/// await themeService.setThemeMode(ThemeMode.dark);
/// 
/// // Check if following system theme
/// final isSystemTheme = await themeService.isSystemTheme();
/// 
/// // Listen to theme changes
/// themeService.addListener(() {
///   // Handle theme change
/// });
/// ```
/// 
/// ## Theme Modes
/// - **System**: Follows device system theme (default)
/// - **Light**: Always uses light theme
/// - **Dark**: Always uses dark theme
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  SharedPreferences? _prefs;
  ThemeMode _currentThemeMode = ThemeMode.system;
  bool _isInitialized = false;
  final AccessibilityService _accessibilityService = AccessibilityService();

  // Settings keys
  static const String _themeModeKey = 'theme_mode';
  static const String _isSystemThemeKey = 'is_system_theme';

  /// Initialize the theme service
  /// Must be called before using other methods
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadThemePreferences();
      await _accessibilityService.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('ThemeService initialization error: $e');
      // Set safe defaults
      _currentThemeMode = ThemeMode.system;
      _isInitialized = true;
    }
  }

  /// Load theme preferences from storage
  Future<void> _loadThemePreferences() async {
    try {
      // Handle both int and string values for backward compatibility
      final themeValue = _prefs?.get(_themeModeKey);
      
      if (themeValue is int) {
        // New format: integer index
        if (themeValue >= 0 && themeValue < ThemeMode.values.length) {
          _currentThemeMode = ThemeMode.values[themeValue];
        } else {
          _currentThemeMode = ThemeMode.system;
        }
      } else if (themeValue is String) {
        // Legacy format: string value - convert to new format
        _currentThemeMode = themeModeFromString(themeValue);
        // Save in new format
        await _prefs?.setInt(_themeModeKey, _currentThemeMode.index);
      } else {
        // No preference set
        _currentThemeMode = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('ThemeService _loadThemePreferences error: $e');
      _currentThemeMode = ThemeMode.system;
    }
  }

  /// Get current theme mode
  Future<ThemeMode> getThemeMode() async {
    await _ensureInitialized();
    return _currentThemeMode;
  }

  /// Set theme mode and persist the preference
  Future<void> setThemeMode(ThemeMode mode) async {
    await _ensureInitialized();
    
    if (_currentThemeMode == mode) return;
    
    try {
      _currentThemeMode = mode;
      await _prefs?.setInt(_themeModeKey, mode.index);
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeService setThemeMode error: $e');
      rethrow;
    }
  }

  /// Check if currently using system theme
  bool get isSystemTheme => _currentThemeMode == ThemeMode.system;

  /// Check if currently using light theme
  bool get isLightTheme => _currentThemeMode == ThemeMode.light;

  /// Check if currently using dark theme
  bool get isDarkTheme => _currentThemeMode == ThemeMode.dark;

  /// Get the effective theme mode based on system brightness
  ThemeMode getEffectiveThemeMode(BuildContext context) {
    if (_currentThemeMode == ThemeMode.system) {
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }
    return _currentThemeMode;
  }

  /// Check if the effective theme is dark
  bool isEffectiveDark(BuildContext context) {
    return getEffectiveThemeMode(context) == ThemeMode.dark;
  }

  /// Check if the effective theme is light
  bool isEffectiveLight(BuildContext context) {
    return getEffectiveThemeMode(context) == ThemeMode.light;
  }

  /// Toggle between light and dark theme (skips system)
  Future<void> toggleTheme() async {
    await _ensureInitialized();
    
    switch (_currentThemeMode) {
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

  /// Clear all theme preferences (for app reset)
  Future<void> clearThemePreferences() async {
    await _ensureInitialized();
    
    try {
      await _prefs?.remove(_themeModeKey);
      await _prefs?.remove(_isSystemThemeKey);
      _currentThemeMode = ThemeMode.system;
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeService clearThemePreferences error: $e');
      rethrow;
    }
  }

  /// Get theme mode display name
  String getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  /// Get current theme mode display name
  String get currentThemeModeDisplayName => getThemeModeDisplayName(_currentThemeMode);

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get theme mode from string (for serialization)
  static ThemeMode themeModeFromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Convert theme mode to string (for serialization)
  static String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Get accessibility-optimized colors for current theme
  AccessibleColors getAccessibleColors(BuildContext context) {
    return _accessibilityService.getAccessibleColors(context);
  }

  /// Get accessibility-optimized text styles for current theme
  AccessibleTextStyles getAccessibleTextStyles(BuildContext context) {
    return _accessibilityService.getAccessibleTextStyles(context);
  }

  /// Check if high contrast mode is enabled
  bool get isHighContrastMode => _accessibilityService.highContrastMode;

  /// Enable or disable high contrast mode
  Future<void> setHighContrastMode(bool enabled) async {
    await _accessibilityService.setHighContrastMode(enabled);
    notifyListeners();
  }

  /// Check if large text mode is enabled
  bool get isLargeTextMode => _accessibilityService.largeTextMode;

  /// Enable or disable large text mode
  Future<void> setLargeTextMode(bool enabled) async {
    await _accessibilityService.setLargeTextMode(enabled);
    notifyListeners();
  }

  /// Check if reduced motion mode is enabled
  bool get isReducedMotionMode => _accessibilityService.reducedMotionMode;

  /// Enable or disable reduced motion mode
  Future<void> setReducedMotionMode(bool enabled) async {
    await _accessibilityService.setReducedMotionMode(enabled);
    notifyListeners();
  }

  /// Get animation duration based on accessibility settings
  Duration getAnimationDuration(Duration defaultDuration) {
    return _accessibilityService.getAnimationDuration(defaultDuration);
  }

  /// Get animation curve based on accessibility settings
  Curve getAnimationCurve(Curve defaultCurve) {
    return _accessibilityService.getAnimationCurve(defaultCurve);
  }

  /// Check if device has system accessibility features enabled
  bool hasSystemAccessibilityEnabled(BuildContext context) {
    return _accessibilityService.hasSystemAccessibilityEnabled(context);
  }
}
