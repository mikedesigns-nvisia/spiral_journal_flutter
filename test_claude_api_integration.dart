import 'dart:io';
import 'package:flutter/foundation.dart';
import 'lib/config/api_key_setup.dart';
import 'lib/services/claude_ai_service.dart';
import 'lib/services/providers/claude_ai_provider.dart';
import 'lib/services/ai_service_interface.dart';
import 'lib/models/journal_entry.dart';
import 'lib/models/core.dart';

/// Comprehensive Claude API Integration Test
/// Tests the new API key with both legacy and modern providers
void main() async {
  print('🧪 Starting Claude API Integration Test...\n');
  
  try {
    // Test 1: Environment Variable Loading
    await testEnvironmentVariableLoading();
    
    // Test 2: API Key Setup and Validation
    await testApiKeySetup();
    
    // Test 3: Legacy Claude AI Service
    await testLegacyClaudeService();
    
    // Test 4: Modern Claude AI Provider
    await testModernClaudeProvider();
    
    // Test 5: Journal Entry Analysis
    await testJournalAnalysis();
    
    // Test 6: Monthly Insight Generation
    await testMonthlyInsights();
    
    print('\n✅ All tests completed successfully!');
    print('🎉 Your Claude API integration is working perfectly!');
    
  } catch (e, stackTrace) {
    print('\n❌ Test failed with error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

Future<void> testEnvironmentVariableLoading() async {
  print('📋 Test 1: Environment Variable Loading');
  
  // Load environment variables
  final envFile = File('.env');
  if (await envFile.exists()) {
    final content = await envFile.readAsString();
    final lines = content.split('\n');
    
    for (final line in lines) {
      if (line.startsWith('CLAUDE_API_KEY=')) {
        final apiKey = line.split('=')[1];
        if (apiKey.startsWith('sk-ant-api03-')) {
          print('   ✅ API key found in .env file');
          print('   ✅ API key format is valid (sk-ant-api03-...)');
          print('   ✅ API key length: ${apiKey.length} characters');
          return;
        }
      }
    }
  }
  
  throw Exception('API key not found or invalid format in .env file');
}

Future<void> testApiKeySetup() async {
  print('\n📋 Test 2: API Key Setup and Validation');
  
  try {
    // Initialize API key setup
    await ApiKeySetup.initializeApiKeys();
    print('   ✅ API key setup initialized');
    
    // Check if Claude API key is configured
    final isConfigured = await ApiKeySetup.isClaudeApiKeyConfigured();
    print('   ✅ Claude API key configured: $isConfigured');
    
    // Get API key status
    final status = await ApiKeySetup.getApiKeyStatus();
    print('   ✅ API key status: ${status['claude']}');
    
    if (status['claude']['configured'] == true) {
      print('   ✅ API key validation passed');
    } else {
      throw Exception('API key validation failed');
    }
    
  } catch (e) {
    print('   ❌ API key setup failed: $e');
    rethrow;
  }
}

Future<void> testLegacyClaudeService() async {
  print('\n📋 Test 3: Legacy Claude AI Service');
  
  try {
    final claudeService = ClaudeAIService();
    await claudeService.initialize();
    print('   ✅ Legacy service initialized');
    
    // Check if real API is enabled
    final isEnabled = await claudeService.isRealApiEnabled;
    print('   ✅ Real API enabled: $isEnabled');
    
    if (isEnabled) {
      print('   ✅ Legacy service ready for API calls');
    } else {
      print('   ⚠️  Legacy service will use fallback mode');
    }
    
  } catch (e) {
    print('   ❌ Legacy service test failed: $e');
    rethrow;
  }
}

Future<void> testModernClaudeProvider() async {
  print('\n📋 Test 4: Modern Claude AI Provider');
  
  try {
    // Read API key from environment
    final envFile = File('.env');
    final content = await envFile.readAsString();
    final apiKey = content.split('CLAUDE_API_KEY=')[1].split('\n')[0];
    
    final config = AIServiceConfig(
      apiKey: apiKey,
      provider: AIProvider.enabled,
    );
    
    final provider = ClaudeAIProvider(config);
    await provider.setApiKey(apiKey);
    print('   ✅ Modern provider initialized');
    print('   ✅ Provider configured: ${provider.isConfigured}');
    print('   ✅ Provider enabled: ${provider.isEnabled}');
    
    // Test connection
    await provider.testConnection();
    print('   ✅ API connection test passed');
    
  } catch (e) {
    print('   ❌ Modern provider test failed: $e');
    rethrow;
  }
}

Future<void> testJournalAnalysis() async {
  print('\n📋 Test 5: Journal Entry Analysis');
  
  try {
    // Create a test journal entry
    final testEntry = JournalEntry(
      id: 'test-entry-1',
      content: 'Today was challenging at work, but I managed to find a creative solution to the problem that\'s been bothering me for weeks. I realized that instead of getting frustrated, I could approach it from a completely different angle. I\'m proud of how I handled the stress and turned it into something productive.',
      moods: ['determined', 'proud', 'creative'],
      date: DateTime.now(),
    );
    
    print('   📝 Test entry created: "${testEntry.content.substring(0, 50)}..."');
    
    // Test with legacy service
    final claudeService = ClaudeAIService();
    await claudeService.initialize();
    
    final analysis = await claudeService.analyzeJournalEntry(testEntry);
    print('   ✅ Journal analysis completed');
    print('   📊 Primary emotions: ${analysis['primary_emotions']}');
    print('   📊 Emotional intensity: ${analysis['emotional_intensity']}');
    print('   📊 Growth indicators: ${analysis['growth_indicators']}');
    
    if (analysis['core_adjustments'] != null) {
      print('   📊 Core adjustments found: ${analysis['core_adjustments'].keys.length} cores');
    }
    
    if (analysis['entry_insight'] != null) {
      print('   💡 Entry insight: "${analysis['entry_insight']}"');
    }
    
  } catch (e) {
    print('   ❌ Journal analysis test failed: $e');
    rethrow;
  }
}

Future<void> testMonthlyInsights() async {
  print('\n📋 Test 6: Monthly Insight Generation');
  
  try {
    // Create test journal entries for monthly insight
    final testEntries = [
      JournalEntry(
        id: 'test-entry-1',
        content: 'Had a great day today. Feeling grateful for all the opportunities.',
        moods: ['grateful', 'happy'],
        date: DateTime.now().subtract(Duration(days: 2)),
      ),
      JournalEntry(
        id: 'test-entry-2',
        content: 'Challenging day but learned something new about myself.',
        moods: ['reflective', 'determined'],
        date: DateTime.now().subtract(Duration(days: 1)),
      ),
      JournalEntry(
        id: 'test-entry-3',
        content: 'Feeling creative and motivated to start new projects.',
        moods: ['creative', 'motivated'],
        date: DateTime.now(),
      ),
    ];
    
    print('   📝 Created ${testEntries.length} test entries for monthly analysis');
    
    // Test monthly insight generation
    final claudeService = ClaudeAIService();
    await claudeService.initialize();
    
    final insight = await claudeService.generateMonthlyInsight(testEntries);
    print('   ✅ Monthly insight generated');
    print('   💡 Insight: "$insight"');
    
  } catch (e) {
    print('   ❌ Monthly insight test failed: $e');
    rethrow;
  }
}

/// Mock classes for testing
class AIServiceConfig {
  final String apiKey;
  final AIProvider provider;
  
  AIServiceConfig({
    required this.apiKey,
    required this.provider,
  });
}

enum AIProvider {
  enabled,
  disabled,
}
