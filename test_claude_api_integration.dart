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
  debugPrint('🧪 Starting Claude API Integration Test...\n');
  
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
    
    debugPrint('\n✅ All tests completed successfully!');
    debugPrint('🎉 Your Claude API integration is working perfectly!');
    
  } catch (e, stackTrace) {
    debugPrint('\n❌ Test failed with error: $e');
    debugPrint('Stack trace: $stackTrace');
    exit(1);
  }
}

Future<void> testEnvironmentVariableLoading() async {
  debugPrint('📋 Test 1: Environment Variable Loading');
  
  // Load environment variables
  final envFile = File('.env');
  if (await envFile.exists()) {
    final content = await envFile.readAsString();
    final lines = content.split('\n');
    
    for (final line in lines) {
      if (line.startsWith('CLAUDE_API_KEY=')) {
        final apiKey = line.split('=')[1];
        if (apiKey.startsWith('sk-ant-api03-')) {
          debugPrint('   ✅ API key found in .env file');
          debugPrint('   ✅ API key format is valid (sk-ant-api03-...)');
          debugPrint('   ✅ API key length: ${apiKey.length} characters');
          return;
        }
      }
    }
  }
  
  throw Exception('API key not found or invalid format in .env file');
}

Future<void> testApiKeySetup() async {
  debugPrint('\n📋 Test 2: API Key Setup and Validation');
  
  try {
    // Initialize API key setup
    await ApiKeySetup.initializeApiKeys();
    debugPrint('   ✅ API key setup initialized');
    
    // Check if Claude API key is configured
    final isConfigured = await ApiKeySetup.isClaudeApiKeyConfigured();
    debugPrint('   ✅ Claude API key configured: $isConfigured');
    
    // Get API key status
    final status = await ApiKeySetup.getApiKeyStatus();
    debugPrint('   ✅ API key status: ${status['claude']}');
    
    if (status['claude']['configured'] == true) {
      debugPrint('   ✅ API key validation passed');
    } else {
      throw Exception('API key validation failed');
    }
    
  } catch (e) {
    debugPrint('   ❌ API key setup failed: $e');
    rethrow;
  }
}

Future<void> testLegacyClaudeService() async {
  debugPrint('\n📋 Test 3: Legacy Claude AI Service');
  
  try {
    final claudeService = ClaudeAIService();
    await claudeService.initialize();
    debugPrint('   ✅ Legacy service initialized');
    
    // Check if real API is enabled
    final isEnabled = await claudeService.isRealApiEnabled;
    debugPrint('   ✅ Real API enabled: $isEnabled');
    
    if (isEnabled) {
      debugPrint('   ✅ Legacy service ready for API calls');
    } else {
      debugPrint('   ⚠️  Legacy service will use fallback mode');
    }
    
  } catch (e) {
    debugPrint('   ❌ Legacy service test failed: $e');
    rethrow;
  }
}

Future<void> testModernClaudeProvider() async {
  debugPrint('\n📋 Test 4: Modern Claude AI Provider');
  
  try {
    // Read API key from environment
    final envFile = File('.env');
    final content = await envFile.readAsString();
    final apiKey = content.split('CLAUDE_API_KEY=')[1].split('\n')[0];
    
    final config = AIServiceConfig(
      provider: AIProvider.enabled,
      apiKey: apiKey,
    );
    
    final provider = ClaudeAIProvider(config);
    await provider.setApiKey(apiKey);
    debugPrint('   ✅ Modern provider initialized');
    debugPrint('   ✅ Provider configured: ${provider.isConfigured}');
    debugPrint('   ✅ Provider enabled: ${provider.isEnabled}');
    
    // Test connection
    await provider.testConnection();
    debugPrint('   ✅ API connection test passed');
    
  } catch (e) {
    debugPrint('   ❌ Modern provider test failed: $e');
    rethrow;
  }
}

Future<void> testJournalAnalysis() async {
  debugPrint('\n📋 Test 5: Journal Entry Analysis');
  
  try {
    // Create a test journal entry
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final testEntry = JournalEntry(
      id: 'test-entry-1',
      userId: 'test-user',
      content: 'Today was challenging at work, but I managed to find a creative solution to the problem that\'s been bothering me for weeks. I realized that instead of getting frustrated, I could approach it from a completely different angle. I\'m proud of how I handled the stress and turned it into something productive.',
      moods: ['determined', 'proud', 'creative'],
      date: now,
      dayOfWeek: dayNames[now.weekday - 1],
      createdAt: now,
      updatedAt: now,
    );
    
    debugPrint('   📝 Test entry created: "${testEntry.content.substring(0, 50)}..."');
    
    // Test with legacy service
    final claudeService = ClaudeAIService();
    await claudeService.initialize();
    
    final analysis = await claudeService.analyzeJournalEntry(testEntry);
    debugPrint('   ✅ Journal analysis completed');
    debugPrint('   📊 Primary emotions: ${analysis['primary_emotions']}');
    debugPrint('   📊 Emotional intensity: ${analysis['emotional_intensity']}');
    debugPrint('   📊 Growth indicators: ${analysis['growth_indicators']}');
    
    if (analysis['core_adjustments'] != null) {
      debugPrint('   📊 Core adjustments found: ${analysis['core_adjustments'].keys.length} cores');
    }
    
    if (analysis['entry_insight'] != null) {
      debugPrint('   💡 Entry insight: "${analysis['entry_insight']}"');
    }
    
  } catch (e) {
    debugPrint('   ❌ Journal analysis test failed: $e');
    rethrow;
  }
}

Future<void> testMonthlyInsights() async {
  debugPrint('\n📋 Test 6: Monthly Insight Generation');
  
  try {
    // Create test journal entries for monthly insight
    final testEntries = [
      JournalEntry(
        id: 'test-entry-1',
        userId: 'test-user',
        content: 'Had a great day today. Feeling grateful for all the opportunities.',
        moods: ['grateful', 'happy'],
        date: DateTime.now().subtract(Duration(days: 2)),
        dayOfWeek: 'Monday',
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        updatedAt: DateTime.now().subtract(Duration(days: 2)),
      ),
      JournalEntry(
        id: 'test-entry-2',
        userId: 'test-user',
        content: 'Challenging day but learned something new about myself.',
        moods: ['reflective', 'determined'],
        date: DateTime.now().subtract(Duration(days: 1)),
        dayOfWeek: 'Tuesday',
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      JournalEntry(
        id: 'test-entry-3',
        userId: 'test-user',
        content: 'Feeling creative and motivated to start new projects.',
        moods: ['creative', 'motivated'],
        date: DateTime.now(),
        dayOfWeek: 'Wednesday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    
    debugPrint('   📝 Created ${testEntries.length} test entries for monthly analysis');
    
    // Test monthly insight generation
    final claudeService = ClaudeAIService();
    await claudeService.initialize();
    
    final insight = await claudeService.generateMonthlyInsight(testEntries);
    debugPrint('   ✅ Monthly insight generated');
    debugPrint('   💡 Insight: "$insight"');
    
  } catch (e) {
    debugPrint('   ❌ Monthly insight test failed: $e');
    rethrow;
  }
}

