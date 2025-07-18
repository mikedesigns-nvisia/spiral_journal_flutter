import 'package:flutter/material.dart';

/// Comprehensive user preferences model for the Spiral Journal app.
/// 
/// This model encapsulates all user configuration options and preferences,
/// providing a centralized way to manage user settings throughout the application.
/// 
/// ## Key Features
/// - **Theme Management**: Light, dark, or system theme preferences
/// - **AI Analysis Control**: Toggle personalized insights on/off
/// - **Security Settings**: Biometric authentication preferences
/// - **Privacy Controls**: Analytics and data sharing preferences
/// - **JSON Serialization**: Support for persistence and data export
/// 
/// ## Usage Example
/// ```dart
/// final preferences = UserPreferences(
///   personalizedInsightsEnabled: true,
///   themeMode: ThemeMode.dark,
///   biometricAuthEnabled: true,
/// );
/// 
/// // Convert to JSON for storage
/// final json = preferences.toJson();
/// 
/// // Create from JSON
/// final restored = UserPreferences.fromJson(json);
/// ```
class UserPreferences {
  /// Whether personalized AI insights are enabled
  /// When true, AI analysis includes personal commentary and feedback
  /// When false, AI analysis only shows core updates without personal insights
  final bool personalizedInsightsEnabled;
  
  /// Current theme mode preference
  /// - system: Follow device system theme (default)
  /// - light: Always use light theme
  /// - dark: Always use dark theme
  final ThemeMode themeMode;
  
  /// Whether biometric authentication is enabled
  /// Requires device biometric capability (Face ID, Touch ID, Fingerprint)
  final bool biometricAuthEnabled;
  
  /// Whether basic usage analytics are enabled
  /// Used for app improvement and TestFlight feedback
  final bool analyticsEnabled;
  
  /// Whether daily reminder notifications are enabled
  final bool dailyRemindersEnabled;
  
  /// Time for daily reminder notifications (24-hour format)
  final String reminderTime;
  
  /// Whether splash screen is shown on app launch
  final bool splashScreenEnabled;
  
  /// Whether high contrast mode is enabled for better visibility
  final bool highContrastEnabled;
  
  /// Whether large text mode is enabled for better readability
  final bool largeTextEnabled;
  
  /// Whether reduced motion mode is enabled to minimize animations
  final bool reducedMotionEnabled;
  
  /// Whether screen reader support is enabled
  final bool screenReaderEnabled;

  const UserPreferences({
    this.personalizedInsightsEnabled = true,
    this.themeMode = ThemeMode.system,
    this.biometricAuthEnabled = false,
    this.analyticsEnabled = true,
    this.dailyRemindersEnabled = false,
    this.reminderTime = '20:00',
    this.splashScreenEnabled = true,
    this.highContrastEnabled = false,
    this.largeTextEnabled = false,
    this.reducedMotionEnabled = false,
    this.screenReaderEnabled = false,
  });

  /// Create UserPreferences with updated values
  UserPreferences copyWith({
    bool? personalizedInsightsEnabled,
    ThemeMode? themeMode,
    bool? biometricAuthEnabled,
    bool? analyticsEnabled,
    bool? dailyRemindersEnabled,
    String? reminderTime,
    bool? splashScreenEnabled,
    bool? highContrastEnabled,
    bool? largeTextEnabled,
    bool? reducedMotionEnabled,
    bool? screenReaderEnabled,
  }) {
    return UserPreferences(
      personalizedInsightsEnabled: personalizedInsightsEnabled ?? this.personalizedInsightsEnabled,
      themeMode: themeMode ?? this.themeMode,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      dailyRemindersEnabled: dailyRemindersEnabled ?? this.dailyRemindersEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      splashScreenEnabled: splashScreenEnabled ?? this.splashScreenEnabled,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      largeTextEnabled: largeTextEnabled ?? this.largeTextEnabled,
      reducedMotionEnabled: reducedMotionEnabled ?? this.reducedMotionEnabled,
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'personalizedInsightsEnabled': personalizedInsightsEnabled,
      'themeMode': _themeModeToString(themeMode),
      'biometricAuthEnabled': biometricAuthEnabled,
      'analyticsEnabled': analyticsEnabled,
      'dailyRemindersEnabled': dailyRemindersEnabled,
      'reminderTime': reminderTime,
      'splashScreenEnabled': splashScreenEnabled,
      'highContrastEnabled': highContrastEnabled,
      'largeTextEnabled': largeTextEnabled,
      'reducedMotionEnabled': reducedMotionEnabled,
      'screenReaderEnabled': screenReaderEnabled,
    };
  }

  /// Create from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      personalizedInsightsEnabled: json['personalizedInsightsEnabled'] as bool? ?? true,
      themeMode: _themeModeFromString(json['themeMode'] as String?),
      biometricAuthEnabled: json['biometricAuthEnabled'] as bool? ?? false,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
      dailyRemindersEnabled: json['dailyRemindersEnabled'] as bool? ?? false,
      reminderTime: json['reminderTime'] as String? ?? '20:00',
      splashScreenEnabled: json['splashScreenEnabled'] as bool? ?? true,
      highContrastEnabled: json['highContrastEnabled'] as bool? ?? false,
      largeTextEnabled: json['largeTextEnabled'] as bool? ?? false,
      reducedMotionEnabled: json['reducedMotionEnabled'] as bool? ?? false,
      screenReaderEnabled: json['screenReaderEnabled'] as bool? ?? false,
    );
  }

  /// Default preferences instance
  static const UserPreferences defaults = UserPreferences();

  /// Convert ThemeMode to string for JSON serialization
  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert string to ThemeMode for JSON deserialization
  static ThemeMode _themeModeFromString(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Get display name for theme mode
  String get themeModeDisplayName {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  /// Check if using system theme
  bool get isSystemTheme => themeMode == ThemeMode.system;

  /// Check if using light theme
  bool get isLightTheme => themeMode == ThemeMode.light;

  /// Check if using dark theme
  bool get isDarkTheme => themeMode == ThemeMode.dark;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserPreferences &&
        other.personalizedInsightsEnabled == personalizedInsightsEnabled &&
        other.themeMode == themeMode &&
        other.biometricAuthEnabled == biometricAuthEnabled &&
        other.analyticsEnabled == analyticsEnabled &&
        other.dailyRemindersEnabled == dailyRemindersEnabled &&
        other.reminderTime == reminderTime &&
        other.splashScreenEnabled == splashScreenEnabled &&
        other.highContrastEnabled == highContrastEnabled &&
        other.largeTextEnabled == largeTextEnabled &&
        other.reducedMotionEnabled == reducedMotionEnabled &&
        other.screenReaderEnabled == screenReaderEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      personalizedInsightsEnabled,
      themeMode,
      biometricAuthEnabled,
      analyticsEnabled,
      dailyRemindersEnabled,
      reminderTime,
      splashScreenEnabled,
      highContrastEnabled,
      largeTextEnabled,
      reducedMotionEnabled,
      screenReaderEnabled,
    );
  }

  @override
  String toString() {
    return 'UserPreferences('
        'personalizedInsightsEnabled: $personalizedInsightsEnabled, '
        'themeMode: $themeMode, '
        'biometricAuthEnabled: $biometricAuthEnabled, '
        'analyticsEnabled: $analyticsEnabled, '
        'dailyRemindersEnabled: $dailyRemindersEnabled, '
        'reminderTime: $reminderTime, '
        'splashScreenEnabled: $splashScreenEnabled, '
        'highContrastEnabled: $highContrastEnabled, '
        'largeTextEnabled: $largeTextEnabled, '
        'reducedMotionEnabled: $reducedMotionEnabled, '
        'screenReaderEnabled: $screenReaderEnabled'
        ')';
  }
}