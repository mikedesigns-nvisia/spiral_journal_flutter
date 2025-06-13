import 'package:shared_preferences/shared_preferences.dart';

/// Configuration service for managing API keys and app settings
class ConfigService {
  static const String _claudeApiKeyKey = 'claude_api_key';
  static const String _firebaseConfiguredKey = 'firebase_configured';
  static const String _analysisEnabledKey = 'analysis_enabled';
  static const String _demoModeKey = 'demo_mode';

  static ConfigService? _instance;
  SharedPreferences? _prefs;

  ConfigService._();

  static Future<ConfigService> getInstance() async {
    _instance ??= ConfigService._();
    _instance!._prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Claude API Configuration
  
  /// Set Claude API key
  Future<void> setClaudeApiKey(String apiKey) async {
    await _prefs!.setString(_claudeApiKeyKey, apiKey);
  }

  /// Get Claude API key
  String? getClaudeApiKey() {
    return _prefs!.getString(_claudeApiKeyKey);
  }

  /// Check if Claude API is configured
  bool get isClaudeConfigured => getClaudeApiKey()?.isNotEmpty == true;

  /// Remove Claude API key
  Future<void> clearClaudeApiKey() async {
    await _prefs!.remove(_claudeApiKeyKey);
  }

  /// Firebase Configuration

  /// Mark Firebase as configured
  Future<void> setFirebaseConfigured(bool configured) async {
    await _prefs!.setBool(_firebaseConfiguredKey, configured);
  }

  /// Check if Firebase is configured
  bool get isFirebaseConfigured => _prefs!.getBool(_firebaseConfiguredKey) ?? false;

  /// Analysis Settings

  /// Enable/disable AI analysis
  Future<void> setAnalysisEnabled(bool enabled) async {
    await _prefs!.setBool(_analysisEnabledKey, enabled);
  }

  /// Check if AI analysis is enabled
  bool get isAnalysisEnabled => _prefs!.getBool(_analysisEnabledKey) ?? true;

  /// Demo Mode Settings

  /// Enable/disable demo mode (anonymous user with limited features)
  Future<void> setDemoMode(bool demoMode) async {
    await _prefs!.setBool(_demoModeKey, demoMode);
  }

  /// Check if in demo mode
  bool get isDemoMode => _prefs!.getBool(_demoModeKey) ?? false;

  /// Configuration Status

  /// Check if app is ready for production features
  bool get isFullyConfigured => isClaudeConfigured && isFirebaseConfigured;

  /// Check if app can run in demo mode
  bool get canRunDemo => isFirebaseConfigured; // Firebase needed even for demo

  /// Get configuration summary for debugging
  Map<String, dynamic> getConfigSummary() {
    return {
      'claude_configured': isClaudeConfigured,
      'firebase_configured': isFirebaseConfigured,
      'analysis_enabled': isAnalysisEnabled,
      'demo_mode': isDemoMode,
      'fully_configured': isFullyConfigured,
      'can_run_demo': canRunDemo,
    };
  }

  /// Reset all configuration
  Future<void> resetConfiguration() async {
    await Future.wait([
      clearClaudeApiKey(),
      setFirebaseConfigured(false),
      setAnalysisEnabled(true),
      setDemoMode(false),
    ]);
  }
}

/// Environment configuration for different deployment stages
class EnvironmentConfig {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  static String get current {
    // In a real app, this would be set during build
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: development);
    return environment;
  }

  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;

  /// Firebase project configurations
  static String get firebaseProjectId {
    switch (current) {
      case production:
        return 'spiral-journal-prod';
      case staging:
        return 'spiral-journal-staging';
      default:
        return 'spiral-journal-dev';
    }
  }

  /// Claude API configuration
  static Map<String, dynamic> get claudeConfig {
    return {
      'base_url': 'https://api.anthropic.com/v1/messages',
      'model': 'claude-3-sonnet-20240229',
      'max_tokens': isDevelopment ? 500 : 1000, // Lower tokens in dev
      'timeout_seconds': isDevelopment ? 15 : 30,
    };
  }

  /// Analytics configuration
  static bool get analyticsEnabled => !isDevelopment;

  /// Logging configuration
  static bool get debugLogging => !isProduction;
}

/// API endpoints configuration
class ApiConfig {
  static const String claudeBaseUrl = 'https://api.anthropic.com/v1';
  static const String anthropicVersion = '2023-06-01';
  
  // Rate limiting
  static const int maxRequestsPerMinute = 50;
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}

/// Feature flags for gradual rollout
class FeatureFlags {
  static const Map<String, bool> _flags = {
    'real_time_analysis': true,
    'core_evolution': true,
    'trend_analysis': true,
    'export_data': false, // Not implemented yet
    'social_sharing': false, // Future feature
    'voice_journaling': false, // Future feature
  };

  static bool isEnabled(String feature) {
    return _flags[feature] ?? false;
  }

  static Map<String, bool> getAllFlags() => Map.from(_flags);
}
