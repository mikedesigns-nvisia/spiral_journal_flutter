import 'package:flutter/foundation.dart';
import 'lib/services/production_environment_loader.dart';
import 'lib/config/environment.dart';

/// Test script to verify environment loading works correctly
void main() async {
  debugPrint('🔧 Testing environment loading...');
  
  try {
    // Test ProductionEnvironmentLoader
    debugPrint('📋 Testing ProductionEnvironmentLoader...');
    await ProductionEnvironmentLoader.ensureLoaded();
    
    final status = ProductionEnvironmentLoader.getStatus();
    debugPrint('✅ ProductionEnvironmentLoader status:');
    debugPrint(status.toString());
    
    // Test EnvironmentConfig
    debugPrint('📋 Testing EnvironmentConfig...');
    final apiKey = EnvironmentConfig.claudeApiKey;
    debugPrint('✅ EnvironmentConfig.claudeApiKey: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 20)}..." : "empty"}');
    
    // Test API key validation
    if (apiKey.isNotEmpty) {
      final isValid = apiKey.startsWith('sk-ant-') && apiKey.length >= 50;
      debugPrint('✅ API key validation: ${isValid ? "Valid" : "Invalid"}');
      
      if (isValid) {
        debugPrint('🎉 Environment loading test PASSED');
      } else {
        debugPrint('❌ Environment loading test FAILED - Invalid API key format');
      }
    } else {
      debugPrint('❌ Environment loading test FAILED - No API key found');
    }
    
  } catch (e, stackTrace) {
    debugPrint('❌ Environment loading test FAILED with error: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}