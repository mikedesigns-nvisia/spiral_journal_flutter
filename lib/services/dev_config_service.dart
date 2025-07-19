import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Development-only configuration service
/// This service is only active in debug mode and provides
/// API key configuration for testing purposes
class DevConfigService {
  static final DevConfigService _instance = DevConfigService._internal();
  factory DevConfigService() => _instance;
  DevConfigService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _devClaudeApiKeyKey = 'dev_claude_api_key';
  static const String _devModeEnabledKey = 'dev_mode_enabled';

  /// Check if we're in development mode
  static bool get isDevMode => kDebugMode;

  /// Check if development features are enabled
  /// Always returns false in production/TestFlight builds
  Future<bool> isDevModeEnabled() async {
    if (!isDevMode || kReleaseMode) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_devModeEnabledKey) ?? false;
      return enabled;
    } catch (error) {
      debugPrint('DevConfigService isDevModeEnabled error: $error');
      return false;
    }
  }

  /// Enable/disable development mode features
  Future<void> setDevModeEnabled(bool enabled) async {
    if (!isDevMode) return; // Only works in debug builds
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (enabled) {
        await prefs.setBool(_devModeEnabledKey, true);
      } else {
        await prefs.remove(_devModeEnabledKey);
        // Also clear the API key when disabling dev mode
        try {
          await _secureStorage.delete(key: _devClaudeApiKeyKey);
        } catch (e) {
          // Log but don't fail the operation
          debugPrint('DevConfigService setDevModeEnabled_clearApiKey error: $e');
        }
      }
    } catch (e) {
      debugPrint('DevConfigService setDevModeEnabled error: $e');
      rethrow;
    }
  }

  /// Get development Claude API key
  Future<String?> getDevClaudeApiKey() async {
    if (!isDevMode) return null;
    
    try {
      return await _secureStorage.read(key: _devClaudeApiKeyKey);
    } catch (error) {
      debugPrint('DevConfigService getDevClaudeApiKey error: $error');
      return null;
    }
  }

  /// Set development Claude API key
  Future<bool> setDevClaudeApiKey(String apiKey) async {
    if (!isDevMode) return false;
    
    try {
      if (apiKey.isEmpty) {
        await _secureStorage.delete(key: _devClaudeApiKeyKey);
      } else {
        await _secureStorage.write(key: _devClaudeApiKeyKey, value: apiKey);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate Claude API key format
  bool isValidClaudeApiKey(String apiKey) {
    return apiKey.startsWith('sk-ant-') && apiKey.length > 20;
  }

  /// Clear all development configuration
  Future<void> clearDevConfig() async {
    if (!isDevMode) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_devModeEnabledKey);
      
      try {
        await _secureStorage.delete(key: _devClaudeApiKeyKey);
      } catch (e) {
        debugPrint('DevConfigService: Could not clear API key: $e');
      }
    } catch (e) {
      // Ignore clear errors
    }
  }

  /// Get development status info
  Future<Map<String, dynamic>> getDevStatus() async {
    if (!isDevMode) {
      return {
        'isDevMode': false,
        'devModeEnabled': false,
        'hasApiKey': false,
        'buildMode': 'production',
      };
    }

    final devModeEnabled = await isDevModeEnabled();
    final apiKey = await getDevClaudeApiKey();

    return {
      'isDevMode': true,
      'devModeEnabled': devModeEnabled,
      'hasApiKey': apiKey != null && apiKey.isNotEmpty,
      'apiKeyValid': apiKey != null ? isValidClaudeApiKey(apiKey) : false,
      'buildMode': 'debug',
    };
  }
}
