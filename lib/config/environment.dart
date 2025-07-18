/// Environment Configuration
/// This file contains environment-specific settings for the application
class EnvironmentConfig {
  static const Environment current = Environment.development;
  
  // Claude API Configuration
  static const String claudeApiKey = 'YOUR_CLAUDE_API_KEY_HERE';
  
  // Local-only Configuration (Firebase removed)
  static const bool useLocalStorage = true;
  
  // Debug Settings
  static const bool enableDebugLogging = current == Environment.development;
  static const bool enablePerformanceLogging = current == Environment.development;
  
  // Local Services Settings
  static const bool enableLocalAnalytics = current == Environment.development;
  static const bool enableLocalCrashReporting = true;
  
  // API Settings
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Cache Settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
  
  // Convenience getters
  static bool get isDevelopment => current == Environment.development;
  static bool get isProduction => current == Environment.production;
  static bool get isStaging => current == Environment.staging;
}

enum Environment {
  development,
  staging,
  production,
}
