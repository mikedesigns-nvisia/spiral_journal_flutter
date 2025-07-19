import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'data_clearing_service.dart';
import 'development_mode_detector.dart';

/// Configuration model for fresh install behavior
class FreshInstallConfig {
  final bool enabled;
  final bool showIndicator;
  final bool enableLogging;
  final Duration splashDuration;
  
  const FreshInstallConfig({
    this.enabled = true,
    this.showIndicator = true,
    this.enableLogging = true,
    this.splashDuration = const Duration(seconds: 2),
  });
  
  factory FreshInstallConfig.fromEnvironment() {
    return const FreshInstallConfig(
      enabled: kDebugMode, // Only enable in debug mode by default
      showIndicator: kDebugMode,
      enableLogging: kDebugMode,
    );
  }
}

/// Central service responsible for managing fresh install behavior
class FreshInstallManager {
  static FreshInstallConfig _config = FreshInstallConfig.fromEnvironment();
  static bool _isInitialized = false;
  
  /// Initialize the fresh install manager with configuration
  static Future<void> initialize({FreshInstallConfig? config}) async {
    if (_isInitialized) return;
    
    _config = config ?? FreshInstallConfig.fromEnvironment();
    
    if (_config.enableLogging) {
      developer.log(
        'FreshInstallManager initialized - Mode: ${_config.enabled ? "ENABLED" : "DISABLED"}',
        name: 'FreshInstall',
      );
    }
    
    _isInitialized = true;
    
    // Perform fresh install if enabled and in development mode
    if (_config.enabled && DevelopmentModeDetector.isDevelopmentMode) {
      await performFreshInstall();
    }
  }
  
  /// Check if fresh install mode is currently active
  static bool get isFreshInstallMode => 
      _config.enabled && DevelopmentModeDetector.isDevelopmentMode;
  
  /// Get current configuration
  static FreshInstallConfig get config => _config;
  
  /// Update fresh install mode configuration
  static void setFreshInstallMode(bool enabled) {
    _config = FreshInstallConfig(
      enabled: enabled,
      showIndicator: _config.showIndicator,
      enableLogging: _config.enableLogging,
      splashDuration: _config.splashDuration,
    );
    
    if (_config.enableLogging) {
      developer.log(
        'Fresh install mode ${enabled ? "ENABLED" : "DISABLED"}',
        name: 'FreshInstall',
      );
    }
  }
  
  /// Perform the complete fresh install process
  static Future<void> performFreshInstall() async {
    if (!isFreshInstallMode) return;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      if (_config.enableLogging) {
        developer.log('Starting fresh install process...', name: 'FreshInstall');
      }
      
      // Clear all user data
      await DataClearingService.clearAllData();
      
      stopwatch.stop();
      
      if (_config.enableLogging) {
        developer.log(
          'Fresh install completed in ${stopwatch.elapsedMilliseconds}ms',
          name: 'FreshInstall',
        );
      }
    } catch (error, stackTrace) {
      stopwatch.stop();
      
      if (_config.enableLogging) {
        developer.log(
          'Fresh install failed after ${stopwatch.elapsedMilliseconds}ms: $error',
          name: 'FreshInstall',
          error: error,
          stackTrace: stackTrace,
        );
      }
      
      // Continue with app launch even if fresh install fails
      // This ensures the app doesn't crash due to data clearing issues
    }
  }
  
  /// Check if the manager has been initialized
  static bool get isInitialized => _isInitialized;
  
  /// Reset the manager (primarily for testing)
  static void reset() {
    _isInitialized = false;
    _config = FreshInstallConfig.fromEnvironment();
  }
}