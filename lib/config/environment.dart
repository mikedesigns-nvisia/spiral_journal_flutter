/// Environment Configuration
/// This file contains environment-specific settings for the application
class EnvironmentConfig {
  static const Environment current = Environment.development;
  
  // Application Configuration
  static const int monthlyAnalysisLimit = 30; // One per day for 30 days
  static const Duration autoSaveInterval = Duration(seconds: 3);
  static const Duration midnightProcessingWindow = Duration(minutes: 30);
  
  // Local-only Configuration
  static const bool useLocalStorage = true;
  
  // Debug Settings
  static const bool enableDebugLogging = current == Environment.development;
  static const bool enablePerformanceLogging = current == Environment.development;
  
  // Local Services Settings
  static const bool enableLocalAnalytics = current == Environment.development;
  static const bool enableLocalCrashReporting = true;
  
  // Cache Settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
  
  // Local Processing Configuration
  static const Duration localBatchProcessingSchedule = Duration(hours: 24); // Run at midnight
  static const int maxLocalBatchSize = 10;
  static const Duration localBatchTimeout = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  static const Duration retryBaseDelay = Duration(minutes: 5);
  
  // Local Analysis Settings
  static const bool enableLocalProcessing = true;
  static const int maxLocalCacheEntries = 1000;
  static const Duration localCacheCleanupInterval = Duration(hours: 6);

  // Feature flags
  static bool get enableDailyProcessing => true;
  static bool get enableUsageTracking => true;
  static bool get enableBackgroundProcessing => true;
  static bool get enableLocalAnalysis => true;
  
  // Midnight Processing Time Calculator
  static DateTime get nextMidnightProcessingTime {
    final now = DateTime.now();
    var nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    
    // Ensure we're scheduling for local time
    return nextMidnight;
  }
  
  // Local Processing Metrics
  static void recordLocalProcessing(int entriesProcessed) {
    // Local metrics tracking placeholder
  }

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