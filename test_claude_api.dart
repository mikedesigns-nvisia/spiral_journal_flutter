import 'dart:io';
import 'lib/config/api_key_setup.dart';
import 'lib/services/providers/claude_ai_provider.dart';
import 'lib/services/ai_service_interface.dart';
import 'lib/models/journal_entry.dart';

/// Test script to verify Claude API integration
void main() async {
  print('🧪 Testing Claude API Integration...\n');
  
  // Your API key
  const apiKey = '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';
  
  try {
    // Test 1: API Key Setup
    print('📋 Test 1: API Key Setup');
    final setupResult = await ApiKeySetup.setClaudeApiKey(apiKey);
    print('✅ API Key Setup: ${setupResult ? "SUCCESS" : "FAILED"}');
    
    // Test 2: API Key Status
    print('\n📊 Test 2: API Key Status');
    final status = await ApiKeySetup.getApiKeyStatus();
    print('✅ API Key Status:');
    print('   - Configured: ${status['claude']['configured']}');
    print('   - Valid Format: ${status['claude']['validFormat']}');
    print('   - Key Length: ${status['claude']['keyLength']}');
    
    // Test 3: Provider Initialization
    print('\n🔧 Test 3: Provider Initialization');
    final config = AIServiceConfig(
      apiKey: apiKey,
      provider: AIProvider.enabled,
    );
    final provider = ClaudeAIProvider(config);
    await provider.setApiKey(apiKey);
    print('✅ Provider Initialized: ${provider.isConfigured}');
    print('✅ Provider Enabled: ${provider.isEnabled}');
    
    // Test 4: Connection Test
    print('\n🌐 Test 4: Connection Test');
    try {
      await provider.testConnection();
      print('✅ Connection Test: SUCCESS');
    } catch (e) {
      print('❌ Connection Test: FAILED - $e');
    }
    
    // Test 5: Sample Journal Analysis
    print('\n📝 Test 5: Sample Journal Analysis');
    final sampleEntry = JournalEntry(
      id: 'test-001',
      content: 'Today was a challenging day at work, but I managed to find some creative solutions to the problems we were facing. I feel grateful for my team\'s support and optimistic about tomorrow.',
      moods: ['reflective', 'grateful', 'optimistic'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      date: DateTime.now(),
      dayOfWeek: DateTime.now().weekday.toString(),
      userId: 'test-user',
    );
    
    try {
      final analysis = await provider.analyzeJournalEntry(sampleEntry);
      print('✅ Journal Analysis: SUCCESS');
      print('   - Primary Emotions: ${analysis['primary_emotions']}');
      print('   - Emotional Intensity: ${analysis['emotional_intensity']}');
      print('   - Growth Indicators: ${analysis['growth_indicators']}');
      
      if (analysis.containsKey('mind_reflection')) {
        final reflection = analysis['mind_reflection'];
        print('   - Insight: ${reflection['summary']}');
      }
    } catch (e) {
      print('❌ Journal Analysis: FAILED - $e');
    }
    
    print('\n🎉 All tests completed!');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
    exit(1);
  }
}
