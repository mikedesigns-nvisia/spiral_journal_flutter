/// Environment Configuration
/// This file contains environment-specific settings for the application
class EnvironmentConfig {
  static const Environment current = Environment.development;
  
  // Claude API Configuration - loaded from .env file or dart-define
  static String get claudeApiKey {
    // First try to get from ProductionEnvironmentLoader (loaded from .env file)
    try {
      final envKey = _getFromProductionLoader();
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (e) {
      // If ProductionEnvironmentLoader fails, continue to dart-define fallback
    }
    
    // Fallback to dart-define (build-time injection)
    return const String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');
  }
  
  // Helper method to get API key from ProductionEnvironmentLoader
  static String? _getFromProductionLoader() {
    try {
      // Import ProductionEnvironmentLoader dynamically to avoid circular dependencies
      // This will be resolved by ensuring ProductionEnvironmentLoader is loaded first
      return _productionEnvironmentLoaderApiKey;
    } catch (e) {
      return null;
    }
  }
  
  // Static field to hold the API key from ProductionEnvironmentLoader
  static String? _productionEnvironmentLoaderApiKey;
  
  // Method to set the API key from ProductionEnvironmentLoader
  static void setClaudeApiKeyFromLoader(String? apiKey) {
    _productionEnvironmentLoaderApiKey = apiKey;
  }
  
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
  
  // Haiku Production Configuration
  static const Duration haikuBatchProcessingSchedule = Duration(hours: 24); // Run at midnight
  static const int haikuRateLimit = 100; // requests per hour
  static const int haikuTokenLimit = 500; // output tokens per request
  static const Duration haikuResponseCacheTTL = Duration(days: 7); // 7-day cache
  static const bool haikuEnableCostTracking = true;
  
  // Haiku Batch Processing Settings
  static const int haikuMaxBatchSize = 10;
  static const Duration haikuBatchTimeout = Duration(minutes: 5);
  static const int haikuMaxRetryAttempts = 3;
  static const Duration haikuRetryBaseDelay = Duration(minutes: 5);
  
  // Haiku Cost Management
  static const double haikuMaxDailyCostPerUser = 0.50; // $0.50 per user per day
  static const double haikuMaxMonthlyCostPerUser = 10.0; // $10.00 per user per month
  static const bool haikuEnableUsageAlerts = true;
  
  // Haiku Response Caching
  static const bool haikuEnableResponseCaching = true;
  static const int haikuMaxCacheEntries = 1000;
  static const Duration haikuCacheCleanupInterval = Duration(hours: 6);

  // Feature flags
  static bool get hasBuiltInApiKey => claudeApiKey.isNotEmpty;
  static bool get enableDailyProcessing => true;
  static bool get enableUsageTracking => true;
  static bool get enableBackgroundProcessing => true;
  
  // Haiku Midnight Processing Time Calculator
  static DateTime get nextMidnightProcessingTime {
    final now = DateTime.now();
    var nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    
    // Ensure we're scheduling for local time
    return nextMidnight;
  }
  
  // Haiku Rate Limiting Helpers
  static Duration get haikuRateLimitWindow => const Duration(hours: 1);
  static bool isWithinHaikuRateLimit(int requestsInLastHour) {
    return requestsInLastHour < haikuRateLimit;
  }
  
  // Haiku Cost Tracking Helpers
  static double calculateHaikuCost(int inputTokens, int outputTokens) {
    // Claude 3 Haiku pricing: $0.25/1M input tokens, $1.25/1M output tokens
    const inputCostPer1M = 0.25;
    const outputCostPer1M = 1.25;
    
    final inputCost = (inputTokens / 1000000) * inputCostPer1M;
    final outputCost = (outputTokens / 1000000) * outputCostPer1M;
    
    return inputCost + outputCost;
  }
  
  static bool isWithinDailyCostLimit(double currentDailyCost) {
    return currentDailyCost < haikuMaxDailyCostPerUser;
  }
  
  static bool isWithinMonthlyCostLimit(double currentMonthlyCost) {
    return currentMonthlyCost < haikuMaxMonthlyCostPerUser;
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
