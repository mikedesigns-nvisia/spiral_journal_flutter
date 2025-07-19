import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class for detecting development mode and flutter run execution
class DevelopmentModeDetector {
  static const String _logName = 'DevModeDetector';
  
  /// Check if the app is running in development mode
  static bool get isDevelopmentMode {
    // Primary check: Flutter's debug mode
    if (kDebugMode) return true;
    
    // Secondary check: Profile mode (also considered development)
    if (kProfileMode) return true;
    
    // Additional checks for development environment
    return _hasDebugEnvironmentIndicators();
  }
  
  /// Check if the app was launched via flutter run
  static bool get isFlutterRun {
    try {
      // Check for flutter run specific environment variables
      final flutterEngine = Platform.environment['FLUTTER_ENGINE'];
      final flutterRoot = Platform.environment['FLUTTER_ROOT'];
      
      // These environment variables are typically set during flutter run
      if (flutterEngine != null || flutterRoot != null) {
        return true;
      }
      
      // Check for debug mode as a fallback
      return kDebugMode;
    } catch (e) {
      // If we can't determine, assume not flutter run
      return false;
    }
  }
  
  /// Check for various development environment indicators
  static bool _hasDebugEnvironmentIndicators() {
    try {
      final env = Platform.environment;
      
      // Check for common development environment variables
      final devIndicators = [
        'FLUTTER_ROOT',
        'FLUTTER_ENGINE',
        'DART_VM_SERVICE_URL',
        'OBSERVATORY_URI',
      ];
      
      return devIndicators.any((indicator) => env.containsKey(indicator));
    } catch (e) {
      return false;
    }
  }
  
  /// Get development mode information for logging
  static Map<String, dynamic> getDevelopmentInfo() {
    return {
      'isDevelopmentMode': isDevelopmentMode,
      'isFlutterRun': isFlutterRun,
      'kDebugMode': kDebugMode,
      'kProfileMode': kProfileMode,
      'kReleaseMode': kReleaseMode,
      'platform': Platform.operatingSystem,
      'environmentVariables': _getRelevantEnvironmentVariables(),
    };
  }
  
  /// Get relevant environment variables for debugging
  static Map<String, String> _getRelevantEnvironmentVariables() {
    try {
      final env = Platform.environment;
      final relevantKeys = [
        'FLUTTER_ROOT',
        'FLUTTER_ENGINE',
        'DART_VM_SERVICE_URL',
        'OBSERVATORY_URI',
      ];
      
      final relevantEnv = <String, String>{};
      for (final key in relevantKeys) {
        if (env.containsKey(key)) {
          relevantEnv[key] = env[key] ?? '';
        }
      }
      
      return relevantEnv;
    } catch (e) {
      return {};
    }
  }
  
  /// Log current development mode status
  static void logDevelopmentStatus() {
    if (kDebugMode) {
      final info = getDevelopmentInfo();
      developer.log(
        'Development Mode Status: ${info.toString()}',
        name: _logName,
      );
    }
  }
  
  /// Check if fresh install mode should be enabled based on environment
  static bool shouldEnableFreshInstall() {
    // Enable fresh install in development mode
    if (isDevelopmentMode) return true;
    
    // Check for explicit environment variable override
    try {
      final forceEnabled = Platform.environment['FORCE_FRESH_INSTALL'];
      if (forceEnabled?.toLowerCase() == 'true') return true;
    } catch (e) {
      // Ignore environment variable errors
    }
    
    return false;
  }
  
  /// Get a human-readable description of the current mode
  static String getModeDescription() {
    if (kReleaseMode) return 'Release Mode';
    if (kProfileMode) return 'Profile Mode';
    if (kDebugMode) return 'Debug Mode';
    return 'Unknown Mode';
  }
}