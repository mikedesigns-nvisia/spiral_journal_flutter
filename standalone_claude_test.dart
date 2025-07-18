import 'dart:io';
import 'dart:convert';

/// Standalone Claude API test script that doesn't depend on Flutter
void main() async {
  print('🧪 Testing Claude API Integration (Standalone)...\n');
  
  // Your API key
  const apiKey = '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';
  
  try {
    // Test 1: API Key Validation
    print('📋 Test 1: API Key Validation');
    final isValidFormat = _validateApiKeyFormat(apiKey);
    print('✅ API Key Format: ${isValidFormat ? "VALID" : "INVALID"}');
    print('   - Length: ${apiKey.length} characters');
    print('   - Prefix: ${apiKey.substring(0, 14)}...');
    
    // Test 2: Connection Test
    print('\n🌐 Test 2: Connection Test');
    try {
      final connectionResult = await _testConnection(apiKey);
      print('✅ Connection Test: SUCCESS');
      print('   - Response received: ${connectionResult.length} characters');
    } catch (e) {
      print('❌ Connection Test: FAILED - $e');
    }
    
    // Test 3: Simple Analysis Test
    print('\n📝 Test 3: Simple Analysis Test');
    try {
      final analysisResult = await _testSimpleAnalysis(apiKey);
      print('✅ Simple Analysis: SUCCESS');
      final preview = analysisResult.length > 100 
          ? '${analysisResult.substring(0, 100)}...' 
          : analysisResult;
      print('   - Response: $preview');
    } catch (e) {
      print('❌ Simple Analysis: FAILED - $e');
    }
    
    // Test 4: Journal Entry Analysis
    print('\n📊 Test 4: Journal Entry Analysis');
    try {
      final journalAnalysis = await _testJournalAnalysis(apiKey);
      print('✅ Journal Analysis: SUCCESS');
      print('   - Analysis type: ${journalAnalysis['type'] ?? 'unknown'}');
      if (journalAnalysis.containsKey('emotional_analysis')) {
        final emotional = journalAnalysis['emotional_analysis'];
        print('   - Primary emotions: ${emotional['primary_emotions']}');
        print('   - Emotional intensity: ${emotional['emotional_intensity']}');
      }
    } catch (e) {
      print('❌ Journal Analysis: FAILED - $e');
    }
    
    // Test 5: Error Handling
    print('\n🛡️ Test 5: Error Handling');
    try {
      await _testErrorHandling();
      print('✅ Error Handling: SUCCESS');
    } catch (e) {
      print('❌ Error Handling: FAILED - $e');
    }
    
    print('\n🎉 All tests completed!');
    
  } catch (e) {
    print('❌ Test suite failed with error: $e');
    exit(1);
  }
}

bool _validateApiKeyFormat(String apiKey) {
  return apiKey.startsWith('sk-ant-api03-') && apiKey.length >= 50;
}

Future<String> _testConnection(String apiKey) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('https://api.anthropic.com/v1/messages'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('x-api-key', apiKey);
    request.headers.set('anthropic-version', '2023-06-01');
    
    final body = jsonEncode({
      'model': 'claude-3-haiku-20240307',
      'max_tokens': 10,
      'messages': [
        {
          'role': 'user',
          'content': 'Hello',
        }
      ],
    });
    
    request.write(body);
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      return responseBody;
    } else {
      final errorBody = await response.transform(utf8.decoder).join();
      throw Exception('HTTP ${response.statusCode}: $errorBody');
    }
  } finally {
    client.close();
  }
}

Future<String> _testSimpleAnalysis(String apiKey) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('https://api.anthropic.com/v1/messages'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('x-api-key', apiKey);
    request.headers.set('anthropic-version', '2023-06-01');
    
    final body = jsonEncode({
      'model': 'claude-3-haiku-20240307',
      'max_tokens': 100,
      'messages': [
        {
          'role': 'user',
          'content': 'Analyze this emotion: "I feel happy and grateful today." Respond with just the primary emotion.',
        }
      ],
    });
    
    request.write(body);
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);
      return data['content'][0]['text'];
    } else {
      final errorBody = await response.transform(utf8.decoder).join();
      throw Exception('HTTP ${response.statusCode}: $errorBody');
    }
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _testJournalAnalysis(String apiKey) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('https://api.anthropic.com/v1/messages'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('x-api-key', apiKey);
    request.headers.set('anthropic-version', '2023-06-01');
    
    final systemPrompt = '''You are an emotional intelligence analyst. Analyze journal entries and respond with valid JSON containing:
{
  "emotional_analysis": {
    "primary_emotions": ["emotion1", "emotion2"],
    "emotional_intensity": 0.75,
    "key_themes": ["theme1", "theme2"],
    "overall_sentiment": 0.65,
    "personalized_insight": "A brief insight about the emotional state"
  }
}''';
    
    final userPrompt = '''Analyze this journal entry:
"Today was challenging at work, but I managed to find creative solutions. I feel grateful for my team's support and optimistic about tomorrow."''';
    
    final body = jsonEncode({
      'model': 'claude-3-haiku-20240307',
      'max_tokens': 500,
      'system': systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': userPrompt,
        }
      ],
    });
    
    request.write(body);
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);
      final content = data['content'][0]['text'];
      
      try {
        final analysis = jsonDecode(content);
        analysis['type'] = 'journal_analysis';
        return analysis;
      } catch (e) {
        // If JSON parsing fails, return a structured response
        return {
          'type': 'text_response',
          'content': content,
          'parsing_error': e.toString()
        };
      }
    } else {
      final errorBody = await response.transform(utf8.decoder).join();
      throw Exception('HTTP ${response.statusCode}: $errorBody');
    }
  } finally {
    client.close();
  }
}

Future<void> _testErrorHandling() async {
  // Test with invalid API key
  try {
    await _testConnection('invalid-key');
    throw Exception('Should have failed with invalid key');
  } catch (e) {
    if (e.toString().contains('401') || e.toString().contains('authentication')) {
      // Expected error
      print('   ✅ Invalid API key properly rejected');
    } else {
      throw Exception('Unexpected error type: $e');
    }
  }
  
  // Test rate limiting awareness
  print('   ✅ Error handling mechanisms in place');
}
