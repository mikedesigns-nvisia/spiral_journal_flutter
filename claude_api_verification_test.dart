import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/config/api_key_setup.dart';
import 'lib/services/providers/claude_ai_provider.dart';
import 'lib/services/ai_service_interface.dart';
import 'lib/models/journal_entry.dart';
import 'lib/models/core.dart';

/// Comprehensive Claude API verification test for App Store Connect readiness
/// This test ensures the Claude API integration is working properly before deployment
void main() async {
  print('🚀 Claude API Verification Test for App Store Connect');
  print('=' * 60);
  
  // Load API key from environment
  String? apiKey;
  try {
    final envFile = File('.env');
    if (await envFile.exists()) {
      final envContent = await envFile.readAsString();
      final lines = envContent.split('\n');
      for (final line in lines) {
        if (line.startsWith('CLAUDE_API_KEY=')) {
          apiKey = line.split('=')[1].trim();
          break;
        }
      }
    }
    
    if (apiKey == null || apiKey.isEmpty) {
      print('❌ CRITICAL: No Claude API key found in .env file');
      print('   Please add CLAUDE_API_KEY=your_key_here to .env file');
      exit(1);
    }
    
    print('✅ API key loaded from environment');
    print('   Key format: ${apiKey.substring(0, 20)}...');
    
  } catch (e) {
    print('❌ CRITICAL: Failed to load environment: $e');
    exit(1);
  }
  
  var testsPassed = 0;
  var totalTests = 0;
  
  // Test 1: API Key Format Validation
  totalTests++;
  print('\n📋 Test 1: API Key Format Validation');
  try {
    if (apiKey.startsWith('sk-ant-api03-') && apiKey.length >= 50) {
      print('✅ API key format is valid');
      testsPassed++;
    } else {
      print('❌ Invalid API key format');
      print('   Expected: sk-ant-api03-... with minimum 50 characters');
      print('   Got: ${apiKey.substring(0, 20)}... (length: ${apiKey.length})');
    }
  } catch (e) {
    print('❌ API key validation failed: $e');
  }
  
  // Test 2: Direct API Connection Test
  totalTests++;
  print('\n🌐 Test 2: Direct API Connection Test');
  try {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 10,
        'messages': [
          {
            'role': 'user',
            'content': 'Hello',
          }
        ],
      }),
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Direct API connection successful');
      print('   Response: ${data['content'][0]['text']}');
      print('   Model: ${data['model']}');
      print('   Usage: ${data['usage']}');
      testsPassed++;
    } else {
      print('❌ Direct API connection failed');
      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Direct API connection error: $e');
  }
  
  // Test 3: API Key Setup Service
  totalTests++;
  print('\n🔧 Test 3: API Key Setup Service');
  try {
    final setupResult = await ApiKeySetup.setClaudeApiKey(apiKey);
    if (setupResult) {
      print('✅ API Key Setup Service working');
      testsPassed++;
    } else {
      print('❌ API Key Setup Service failed');
    }
    
    final status = await ApiKeySetup.getApiKeyStatus();
    print('   Status Details:');
    print('   - Configured: ${status['claude']['configured']}');
    print('   - Valid Format: ${status['claude']['validFormat']}');
    print('   - Key Length: ${status['claude']['keyLength']}');
  } catch (e) {
    print('❌ API Key Setup Service error: $e');
  }
  
  // Test 4: Claude AI Provider Initialization
  totalTests++;
  print('\n🏗️ Test 4: Claude AI Provider Initialization');
  try {
    final config = AIServiceConfig(
      apiKey: apiKey,
      provider: AIProvider.enabled,
    );
    final provider = ClaudeAIProvider(config);
    await provider.setApiKey(apiKey);
    
    if (provider.isConfigured && provider.isEnabled) {
      print('✅ Claude AI Provider initialized successfully');
      print('   Configured: ${provider.isConfigured}');
      print('   Enabled: ${provider.isEnabled}');
      testsPassed++;
    } else {
      print('❌ Claude AI Provider initialization failed');
      print('   Configured: ${provider.isConfigured}');
      print('   Enabled: ${provider.isEnabled}');
    }
  } catch (e) {
    print('❌ Claude AI Provider initialization error: $e');
  }
  
  // Test 5: Provider Connection Test
  totalTests++;
  print('\n🔌 Test 5: Provider Connection Test');
  try {
    final config = AIServiceConfig(
      apiKey: apiKey,
      provider: AIProvider.enabled,
    );
    final provider = ClaudeAIProvider(config);
    await provider.setApiKey(apiKey);
    await provider.testConnection();
    
    print('✅ Provider connection test passed');
    testsPassed++;
  } catch (e) {
    print('❌ Provider connection test failed: $e');
  }
  
  // Test 6: Journal Entry Analysis
  totalTests++;
  print('\n📝 Test 6: Journal Entry Analysis');
  try {
    final config = AIServiceConfig(
      apiKey: apiKey,
      provider: AIProvider.enabled,
    );
    final provider = ClaudeAIProvider(config);
    await provider.setApiKey(apiKey);
    
    final sampleEntry = JournalEntry(
      id: 'test-001',
      content: 'Today was challenging but I found creative solutions to problems at work. I feel grateful for my supportive team and optimistic about tomorrow. This experience taught me that I can handle difficult situations with grace.',
      moods: ['reflective', 'grateful', 'optimistic', 'confident'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      date: DateTime.now(),
      dayOfWeek: DateTime.now().weekday.toString(),
      userId: 'test-user',
    );
    
    final analysis = await provider.analyzeJournalEntry(sampleEntry);
    
    print('✅ Journal analysis successful');
    print('   Primary Emotions: ${analysis['primary_emotions']}');
    print('   Emotional Intensity: ${analysis['emotional_intensity']}');
    print('   Growth Indicators: ${analysis['growth_indicators']}');
    
    if (analysis.containsKey('mind_reflection')) {
      final reflection = analysis['mind_reflection'];
      print('   Insight: ${reflection['summary']}');
    }
    
    if (analysis.containsKey('core_adjustments')) {
      print('   Core Adjustments: ${analysis['core_adjustments']}');
    }
    
    testsPassed++;
  } catch (e) {
    print('❌ Journal analysis failed: $e');
  }
  
  // Test 7: Core Updates Calculation
  totalTests++;
  print('\n🎯 Test 7: Core Updates Calculation');
  try {
    final config = AIServiceConfig(
      apiKey: apiKey,
      provider: AIProvider.enabled,
    );
    final provider = ClaudeAIProvider(config);
    await provider.setApiKey(apiKey);
    
    final sampleEntry = JournalEntry(
      id: 'test-002',
      content: 'I tackled a difficult project today and learned something new. Even though it was stressful, I stayed positive and asked for help when needed.',
      moods: ['motivated', 'curious', 'social'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      date: DateTime.now(),
      dayOfWeek: DateTime.now().weekday.toString(),
      userId: 'test-user',
    );
    
    final currentCores = [
      EmotionalCore(
        id: 'optimism',
        name: 'Optimism',
        description: 'Your ability to maintain hope and positive outlook',
        percentage: 70.0,
        trend: 'stable',
        color: '#FF6B35',
        iconPath: 'assets/icons/optimism.png',
        insight: 'Current optimism level',
        relatedCores: ['resilience', 'growth_mindset'],
      ),
      EmotionalCore(
        id: 'growth_mindset',
        name: 'Growth Mindset',
        description: 'Your openness to learning and embracing challenges',
        percentage: 65.0,
        trend: 'stable',
        color: '#DDA0DD',
        iconPath: 'assets/icons/growth_mindset.png',
        insight: 'Current growth mindset level',
        relatedCores: ['optimism', 'self_awareness'],
      ),
    ];
    
    final coreUpdates = await provider.calculateCoreUpdates(sampleEntry, currentCores);
    
    print('✅ Core updates calculation successful');
    print('   Updates: $coreUpdates');
    testsPassed++;
  } catch (e) {
    print('❌ Core updates calculation failed: $e');
  }
  
  // Test 8: Monthly Insight Generation
  totalTests++;
  print('\n📊 Test 8: Monthly Insight Generation');
  try {
    final config = AIServiceConfig(
      apiKey: apiKey,
      provider: AIProvider.enabled,
    );
    final provider = ClaudeAIProvider(config);
    await provider.setApiKey(apiKey);
    
    final sampleEntries = [
      JournalEntry(
        id: 'test-003',
        content: 'Great day with friends, feeling connected and happy.',
        moods: ['happy', 'social'],
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now().subtract(Duration(days: 5)),
        date: DateTime.now().subtract(Duration(days: 5)),
        dayOfWeek: DateTime.now().subtract(Duration(days: 5)).weekday.toString(),
        userId: 'test-user',
      ),
      JournalEntry(
        id: 'test-004',
        content: 'Challenging work project but learned a lot.',
        moods: ['motivated', 'reflective'],
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        updatedAt: DateTime.now().subtract(Duration(days: 2)),
        date: DateTime.now().subtract(Duration(days: 2)),
        dayOfWeek: DateTime.now().subtract(Duration(days: 2)).weekday.toString(),
        userId: 'test-user',
      ),
    ];
    
    final insight = await provider.generateMonthlyInsight(sampleEntries);
    
    print('✅ Monthly insight generation successful');
    print('   Insight: $insight');
    testsPassed++;
  } catch (e) {
    print('❌ Monthly insight generation failed: $e');
  }
  
  // Test Results Summary
  print('\n' + '=' * 60);
  print('📈 TEST RESULTS SUMMARY');
  print('=' * 60);
  print('Tests Passed: $testsPassed / $totalTests');
  print('Success Rate: ${(testsPassed / totalTests * 100).toStringAsFixed(1)}%');
  
  if (testsPassed == totalTests) {
    print('\n🎉 ALL TESTS PASSED! Claude API is ready for App Store Connect');
    print('✅ The API integration is working correctly');
    print('✅ All core features are functional');
    print('✅ Ready for production deployment');
  } else {
    print('\n⚠️  SOME TESTS FAILED! Review issues before App Store Connect submission');
    print('❌ ${totalTests - testsPassed} test(s) failed');
    print('🔧 Please fix the failing tests before deployment');
    
    if (testsPassed < totalTests / 2) {
      print('\n🚨 CRITICAL: More than half the tests failed');
      print('   Do not proceed with App Store Connect submission');
      exit(1);
    }
  }
  
  print('\n📝 Next Steps:');
  print('1. If all tests passed, you can proceed with App Store Connect');
  print('2. If tests failed, fix the issues and run this test again');
  print('3. Monitor the Anthropic API console for usage after deployment');
  
  exit(testsPassed == totalTests ? 0 : 1);
}
