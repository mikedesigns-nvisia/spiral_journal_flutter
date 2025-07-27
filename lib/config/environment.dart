/// Environment Configuration
/// This file contains environment-specific settings for the application
class EnvironmentConfig {
  static const Environment current = Environment.development;
  
  // Claude API Configuration (injected at build time via --dart-define)
  static const String claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');
  
  // Daily Journal & Usage Limits
  static const int monthlyAnalysisLimit = 30; // One per day for 30 days
  static const Duration autoSaveInterval = Duration(seconds: 3);
  static const Duration midnightProcessingWindow = Duration(minutes: 30);
  
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
  
  // Feature flags
  static bool get hasBuiltInApiKey => claudeApiKey.isNotEmpty;
  static bool get enableDailyProcessing => true;
  static bool get enableUsageTracking => true;
  static bool get enableBackgroundProcessing => true;
  
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
