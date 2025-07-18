import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:spiral_journal/services/settings_service.dart';

/// Controls splash screen behavior and lifecycle management.
/// 
/// This class manages splash screen display logic, configuration,
/// and completion handling that was previously embedded in AuthWrapper.
/// 
/// ## Usage Example
/// ```dart
/// final splashController = SplashScreenController();
/// 
/// // Check if splash should be shown
/// if (await splashController.shouldShowSplash()) {
///   // Display splash screen
///   await Future.delayed(Duration(seconds: 2));
///   splashController.onSplashComplete();
/// }
/// 
/// // Update splash settings
/// await splashController.setSplashEnabled(false);
/// ```
/// 
/// ## Integration Pattern
/// This class is designed to be used by:
/// - AuthWrapper for splash screen flow control
/// - Settings screens for splash configuration
/// - App initialization for startup coordination
/// 
/// The class uses caching to optimize performance and reduce
/// repeated settings service calls during app startup.
class SplashScreenController {
  static final SplashScreenController _instance = SplashScreenController._internal();
  factory SplashScreenController() => _instance;
  SplashScreenController._internal();

  final SettingsService _settingsService = SettingsService();

  SplashConfiguration? _cachedConfiguration;
  DateTime? _configurationCacheTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Determines if the splash screen should be shown.
  /// 
  /// Returns true if splash screen is enabled in settings and should be displayed,
  /// false otherwise. Uses cached configuration when available and valid.
  /// 
  /// In case of errors, defaults to showing splash screen for safety.
  Future<bool> shouldShowSplash() async {
    try {
      final config = await getSplashConfiguration();
      return config.enabled;
    } catch (e) {
      // Default to showing splash if we can't determine the setting
      debugPrint('Error getting splash configuration: $e');
      return true;
    }
  }

  /// Called when the splash screen completes its display cycle.
  /// 
  /// This method handles any cleanup or state updates needed after
  /// the splash screen finishes. Currently, it primarily serves as
  /// a hook for future functionality and logging.
  void onSplashComplete() {
    try {
      // Log splash completion for debugging
      debugPrint('Splash screen completed successfully');
      
      // Future: Could add analytics tracking here
      // Future: Could trigger post-splash initialization tasks
      
    } catch (e) {
      debugPrint('Error in splash completion: $e');
      // Don't rethrow - splash completion should not block app flow
    }
  }

  /// Gets the current splash screen configuration.
  /// 
  /// Returns a [SplashConfiguration] object containing all splash screen
  /// settings. Uses caching to avoid repeated settings service calls.
  /// 
  /// Throws [SplashConfigurationException] if configuration cannot be loaded.
  Future<SplashConfiguration> getSplashConfiguration() async {
    try {
      // Check if we have a valid cached configuration
      if (_cachedConfiguration != null && 
          _configurationCacheTime != null &&
          DateTime.now().difference(_configurationCacheTime!) < _cacheValidityDuration) {
        return _cachedConfiguration!;
      }

      // Load fresh configuration from settings
      final enabled = await _settingsService.isSplashScreenEnabled();
      
      final configuration = SplashConfiguration(
        enabled: enabled,
        displayDuration: const Duration(seconds: 2), // Standard splash duration
        lastUpdated: DateTime.now(),
      );

      // Cache the configuration
      _cachedConfiguration = configuration;
      _configurationCacheTime = DateTime.now();

      return configuration;
    } catch (e) {
      debugPrint('Error getting splash configuration: $e');
      
      // Return safe defaults if configuration loading fails
      return SplashConfiguration(
        enabled: true, // Default to showing splash
        displayDuration: const Duration(seconds: 2),
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Updates the splash screen enabled setting.
  /// 
  /// This method updates both the persistent setting and clears the cache
  /// to ensure the new setting takes effect immediately.
  Future<void> setSplashEnabled(bool enabled) async {
    try {
      await _settingsService.setSplashScreenEnabled(enabled);
      
      // Clear cache to force reload of configuration
      _cachedConfiguration = null;
      _configurationCacheTime = null;
      
    } catch (e) {
      debugPrint('Error setting splash enabled: $e');
      rethrow; // This is a user-initiated action, so we should propagate errors
    }
  }

  /// Clears the configuration cache.
  /// 
  /// This forces the next configuration request to reload from settings.
  /// Useful for testing or when settings might have been changed externally.
  void clearConfigurationCache() {
    _cachedConfiguration = null;
    _configurationCacheTime = null;
  }

  /// Gets the current cache status for debugging purposes.
  /// 
  /// Returns information about whether configuration is cached and when
  /// it was last updated.
  Map<String, dynamic> getCacheStatus() {
    return {
      'hasCachedConfiguration': _cachedConfiguration != null,
      'cacheTime': _configurationCacheTime?.toIso8601String(),
      'cacheAge': _configurationCacheTime != null 
          ? DateTime.now().difference(_configurationCacheTime!).inSeconds
          : null,
      'cacheValid': _cachedConfiguration != null && 
          _configurationCacheTime != null &&
          DateTime.now().difference(_configurationCacheTime!) < _cacheValidityDuration,
    };
  }
}

/// Configuration object for splash screen behavior.
class SplashConfiguration {
  /// Whether the splash screen is enabled
  final bool enabled;
  
  /// How long the splash screen should be displayed
  final Duration displayDuration;
  
  /// When this configuration was last updated
  final DateTime lastUpdated;

  const SplashConfiguration({
    required this.enabled,
    required this.displayDuration,
    required this.lastUpdated,
  });

  @override
  String toString() {
    return 'SplashConfiguration('
        'enabled: $enabled, '
        'displayDuration: ${displayDuration.inSeconds}s, '
        'lastUpdated: $lastUpdated'
        ')';
  }

  /// Creates a copy of this configuration with updated values
  SplashConfiguration copyWith({
    bool? enabled,
    Duration? displayDuration,
    DateTime? lastUpdated,
  }) {
    return SplashConfiguration(
      enabled: enabled ?? this.enabled,
      displayDuration: displayDuration ?? this.displayDuration,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Exception thrown when splash configuration operations fail.
class SplashConfigurationException implements Exception {
  final String message;
  final dynamic originalError;

  const SplashConfigurationException(this.message, [this.originalError]);

  @override
  String toString() => 'SplashConfigurationException: $message';
}