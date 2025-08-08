import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';

/// Production Environment Loader
/// 
/// Ensures environment variables are properly loaded in production Flutter builds.
/// This addresses the common issue where .env files aren't properly loaded
/// in production builds, causing API keys to be unavailable.
class ProductionEnvironmentLoader {
  static bool _isLoaded = false;
  static final Map<String, String> _envVars = {};
  static String? _lastError;
  static DateTime? _loadedAt;

  /// Ensure environment variables are loaded
  /// This method is safe to call multiple times
  static Future<void> ensureLoaded() async {
    if (_isLoaded) return;

    try {
      debugPrint('🔧 ProductionEnvironmentLoader: Starting environment loading...');
      
      // Try multiple methods to load environment variables
      await _loadFromEnvFile();
      await _loadFromEnvironmentConfig();
      
      _isLoaded = true;
      _loadedAt = DateTime.now();
      
      // Set the API key in EnvironmentConfig so it can be accessed
      EnvironmentConfig.setClaudeApiKeyFromLoader(getClaudeApiKey());
      
      debugPrint('✅ Environment loaded successfully');
      debugPrint('   Variables loaded: ${_envVars.keys.length}');
      debugPrint('   Claude API key configured: ${hasClaudeApiKey()}');
      
    } catch (e, stackTrace) {
      _lastError = e.toString();
      debugPrint('❌ Environment loading failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Load from .env file
  static Future<void> _loadFromEnvFile() async {
    try {
      final envFile = File('.env');
      if (await envFile.exists()) {
        final content = await envFile.readAsString();
        _parseEnvContent(content);
        debugPrint('✅ Loaded environment from .env file');
      } else {
        debugPrint('⚠️  .env file not found');
      }
    } catch (e) {
      debugPrint('⚠️  Failed to load .env file: $e');
    }
  }

  /// Load from EnvironmentConfig (dart-define values)
  static Future<void> _loadFromEnvironmentConfig() async {
    try {
      // Try to get the API key from dart-define
      const claudeKey = String.fromEnvironment('CLAUDE_API_KEY');
      if (claudeKey.isNotEmpty) {
        _envVars['CLAUDE_API_KEY'] = claudeKey;
        debugPrint('✅ Loaded CLAUDE_API_KEY from dart-define');
      } else {
        debugPrint('⚠️  CLAUDE_API_KEY not found in dart-define');
      }
    } catch (e) {
      debugPrint('⚠️  Failed to load from dart-define: $e');
    }
  }

  /// Parse .env file content
  static void _parseEnvContent(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      
      final parts = trimmed.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        _envVars[key] = value;
      }
    }
  }

  /// Get Claude API key
  static String? getClaudeApiKey() {
    return _envVars['CLAUDE_API_KEY'];
  }

  /// Check if Claude API key is available
  static bool hasClaudeApiKey() {
    final key = getClaudeApiKey();
    return key != null && key.isNotEmpty && key.startsWith('sk-ant-');
  }

  /// Get all environment variables (for debugging)
  static Map<String, String> getAllEnvVars() {
    return Map.unmodifiable(_envVars);
  }

  /// Get loading status
  static EnvironmentLoadingStatus getStatus() {
    return EnvironmentLoadingStatus(
      isLoaded: _isLoaded,
      loadedAt: _loadedAt,
      lastError: _lastError,
      variableCount: _envVars.length,
      hasClaudeApiKey: hasClaudeApiKey(),
      claudeApiKeyPreview: _getApiKeyPreview(),
    );
  }

  /// Get API key status for debugging (no actual key data)
  static String? _getApiKeyPreview() {
    final key = getClaudeApiKey();
    if (key == null) return 'not_configured';
    return key.isNotEmpty ? 'configured' : 'empty';
  }

  /// Reset loading state (for testing)
  static void reset() {
    _isLoaded = false;
    _envVars.clear();
    _lastError = null;
    _loadedAt = null;
  }

  /// Force reload environment variables
  static Future<void> forceReload() async {
    reset();
    await ensureLoaded();
  }
}

/// Environment loading status for debugging
class EnvironmentLoadingStatus {
  final bool isLoaded;
  final DateTime? loadedAt;
  final String? lastError;
  final int variableCount;
  final bool hasClaudeApiKey;
  final String? claudeApiKeyPreview;

  EnvironmentLoadingStatus({
    required this.isLoaded,
    this.loadedAt,
    this.lastError,
    required this.variableCount,
    required this.hasClaudeApiKey,
    this.claudeApiKeyPreview,
  });

  Map<String, dynamic> toJson() => {
    'isLoaded': isLoaded,
    'loadedAt': loadedAt?.toIso8601String(),
    'lastError': lastError,
    'variableCount': variableCount,
    'hasClaudeApiKey': hasClaudeApiKey,
    'claudeApiKeyPreview': claudeApiKeyPreview,
  };

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Environment Loading Status:');
    buffer.writeln('  Loaded: $isLoaded');
    if (loadedAt != null) {
      buffer.writeln('  Loaded at: $loadedAt');
    }
    if (lastError != null) {
      buffer.writeln('  Last error: $lastError');
    }
    buffer.writeln('  Variables: $variableCount');
    buffer.writeln('  Claude API key: $hasClaudeApiKey');
    if (claudeApiKeyPreview != null) {
      buffer.writeln('  Key preview: $claudeApiKeyPreview');
    }
    return buffer.toString();
  }
}