import 'package:flutter/foundation.dart';
import '../services/secure_api_key_service.dart';
import '../services/dev_config_service.dart';
import 'environment.dart';

/// API Key Setup Helper
/// This class helps initialize API keys for development and production
class ApiKeySetup {
  static final SecureApiKeyService _secureApiKeyService = SecureApiKeyService();
  static final DevConfigService _devConfigService = DevConfigService();

  /// Initialize all API keys based on environment
  static Future<void> initializeApiKeys() async {
    try {
      await _secureApiKeyService.initialize();
      
      // Set up Claude API key
      await _setupClaudeApiKey();
      
      if (kDebugMode) {
        debugPrint('API keys initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing API keys: $e');
      }
    }
  }

  /// Set up Claude API key from environment configuration
  static Future<void> _setupClaudeApiKey() async {
    try {
      final apiKey = EnvironmentConfig.claudeApiKey;
      
      if (apiKey.isNotEmpty && apiKey != 'your-dev-claude-api-key' && apiKey != 'your-prod-claude-api-key') {
        // Store in secure storage
        await _secureApiKeyService.storeApiKey('claude', apiKey);
        
        // Also set in dev config if in debug mode
        if (kDebugMode) {
          await _devConfigService.setDevClaudeApiKey(apiKey);
          await _devConfigService.setDevModeEnabled(true);
        }
        
        if (kDebugMode) {
          debugPrint('Claude API key configured successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('No valid Claude API key found in environment configuration');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting up Claude API key: $e');
      }
    }
  }

  /// Manually set Claude API key (for runtime configuration)
  static Future<bool> setClaudeApiKey(String apiKey) async {
    try {
      await _secureApiKeyService.initialize();
      
      if (apiKey.isEmpty) {
        return false;
      }
      
      // Validate API key format (updated for current Claude API format)
      if (!apiKey.startsWith('sk-ant-api03-') || apiKey.length < 50) {
        if (kDebugMode) {
          debugPrint('Invalid Claude API key format. Expected format: sk-ant-api03-...');
        }
        return false;
      }
      
      // Store in secure storage
      await _secureApiKeyService.storeApiKey('claude', apiKey);
      
      // Also set in dev config if in debug mode
      if (kDebugMode) {
        await _devConfigService.setDevClaudeApiKey(apiKey);
        await _devConfigService.setDevModeEnabled(true);
      }
      
      if (kDebugMode) {
        debugPrint('Claude API key set successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting Claude API key: $e');
      }
      return false;
    }
  }

  /// Check if Claude API key is configured
  static Future<bool> isClaudeApiKeyConfigured() async {
    try {
      await _secureApiKeyService.initialize();
      final apiKey = await _secureApiKeyService.getApiKey('claude');
      return apiKey != null && apiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get API key status for debugging
  static Future<Map<String, dynamic>> getApiKeyStatus() async {
    try {
      await _secureApiKeyService.initialize();
      
      final claudeKey = await _secureApiKeyService.getApiKey('claude');
      final devStatus = await _devConfigService.getDevStatus();
      
      return {
        'claude': {
          'configured': claudeKey != null && claudeKey.isNotEmpty,
          'keyLength': claudeKey?.length ?? 0,
          'validFormat': claudeKey?.startsWith('sk-ant-') ?? false,
        },
        'development': devStatus,
        'environment': EnvironmentConfig.current.toString(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}
