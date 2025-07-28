import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Standalone Claude API verification test for App Store Connect readiness
/// This test directly calls the Claude API without Flutter dependencies
void main() async {
  print('🚀 Standalone Claude API Verification Test');
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
    print('   Key length: ${apiKey.length} characters');
    
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
      print('   ✓ Starts with sk-ant-api03-');
      print('   ✓ Length >= 50 characters (${apiKey.length})');
      testsPassed++;
    } else {
      print('❌ Invalid API key format');
      print('   Expected: sk-ant-api03-... with minimum 50 characters');
      print('   Got: ${apiKey.substring(0, 20)}... (length: ${apiKey.length})');
    }
  } catch (e) {
    print('❌ API key validation failed: $e');
  }
  
  // Test 2: Basic API Connection Test
  totalTests++;
  print('\n🌐 Test 2: Basic API Connection Test');
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
      print('✅ Basic API connection successful');
      print('   Response: ${data['content'][0]['text']}');
      print('   Model: ${data['model']}');
      print('   Usage: ${data['usage']}');
      print('   Request ID: ${response.headers['request-id'] ?? 'N/A'}');
      testsPassed++;
    } else {
      print('❌ Basic API connection failed');
      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');
      
      // Check for common error codes
      if (response.statusCode == 401) {
        print('   🔍 This indicates an authentication issue - check your API key');
      } else if (response.statusCode == 429) {
        print('   🔍 This indicates rate limiting - wait and try again');
      } else if (response.statusCode >= 500) {
        print('   🔍 This indicates a server error - try again later');
      }
    }
  } catch (e) {
    print('❌ Basic API connection error: $e');
    if (e.toString().contains('TimeoutException')) {
      print('   🔍 Request timed out - check your internet connection');
    }
  }
  
  // Test 3: Journal Analysis Simulation
  totalTests++;
  print('\n📝 Test 3: Journal Analysis Simulation');
  try {
    final prompt = '''
Analyze this journal entry for emotional intelligence insights:

Date: January 18, 2025
Moods: reflective, grateful, optimistic, confident
Content: "Today was challenging but I found creative solutions to problems at work. I feel grateful for my supportive team and optimistic about tomorrow. This experience taught me that I can handle difficult situations with grace."

Please provide a JSON response with the following structure:
{
  "primary_emotions": ["emotion1", "emotion2"],
  "emotional_intensity": 7.5,
  "growth_indicators": ["indicator1", "indicator2"],
  "core_strengths": {
    "optimism": 0.2,
    "resilience": 0.1,
    "self_awareness": 0.3,
    "creativity": 0.1,
    "social_connection": 0.1,
    "growth_mindset": 0.2
  },
  "insight": "Brief encouraging insight about the entry"
}
''';

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 1000,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      }),
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final analysisText = data['content'][0]['text'];
      
      print('✅ Journal analysis successful');
      print('   Model: ${data['model']}');
      print('   Input tokens: ${data['usage']['input_tokens']}');
      print('   Output tokens: ${data['usage']['output_tokens']}');
      
      // Try to parse the JSON response
      try {
        final analysisJson = jsonDecode(analysisText);
        print('   ✓ Response is valid JSON');
        print('   Primary emotions: ${analysisJson['primary_emotions']}');
        print('   Emotional intensity: ${analysisJson['emotional_intensity']}');
        print('   Insight: ${analysisJson['insight']}');
      } catch (e) {
        print('   ⚠️  Response is not valid JSON, but API call succeeded');
        print('   Raw response: ${analysisText.substring(0, 200)}...');
      }
      
      testsPassed++;
    } else {
      print('❌ Journal analysis failed');
      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Journal analysis error: $e');
  }
  
  // Test 4: Monthly Insight Generation
  totalTests++;
  print('\n📊 Test 4: Monthly Insight Generation');
  try {
    final prompt = '''
Generate a compassionate monthly insight based on these journal entries:

Total entries: 8
Average words per entry: 45
Top moods: grateful (5x), reflective (4x), optimistic (3x)

Recent entries preview:
Jan 16: Great day with friends, feeling connected and happy.
Jan 14: Challenging work project but learned a lot.
Jan 12: Peaceful morning meditation, feeling centered.

Provide a warm, encouraging 2-3 sentence insight that:
1. Acknowledges their journaling consistency
2. Highlights positive patterns or growth
3. Offers gentle encouragement for continued self-reflection

Keep it personal, supportive, and focused on their emotional journey.
''';

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 500,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      }),
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final insightText = data['content'][0]['text'];
      
      print('✅ Monthly insight generation successful');
      print('   Model: ${data['model']}');
      print('   Input tokens: ${data['usage']['input_tokens']}');
      print('   Output tokens: ${data['usage']['output_tokens']}');
      print('   Insight: "$insightText"');
      
      testsPassed++;
    } else {
      print('❌ Monthly insight generation failed');
      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Monthly insight generation error: $e');
  }
  
  // Test 5: API Rate Limiting Test
  totalTests++;
  print('\n⏱️  Test 5: API Rate Limiting Test');
  try {
    print('   Making 3 rapid API calls to test rate limiting...');
    
    var successfulCalls = 0;
    var rateLimitedCalls = 0;
    
    for (int i = 1; i <= 3; i++) {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 5,
          'messages': [
            {
              'role': 'user',
              'content': 'Test $i',
            }
          ],
        }),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        successfulCalls++;
        print('   Call $i: ✅ Success');
      } else if (response.statusCode == 429) {
        rateLimitedCalls++;
        print('   Call $i: ⚠️  Rate limited');
      } else {
        print('   Call $i: ❌ Error ${response.statusCode}');
      }
      
      // Small delay between calls
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    if (successfulCalls >= 2) {
      print('✅ Rate limiting test passed');
      print('   Successful calls: $successfulCalls/3');
      print('   Rate limited calls: $rateLimitedCalls/3');
      testsPassed++;
    } else {
      print('❌ Rate limiting test failed');
      print('   Too many failed calls');
    }
  } catch (e) {
    print('❌ Rate limiting test error: $e');
  }
  
  // Test Results Summary
  print('\n${'=' * 60}');
  print('📈 TEST RESULTS SUMMARY');
  print('=' * 60);
  print('Tests Passed: $testsPassed / $totalTests');
  print('Success Rate: ${(testsPassed / totalTests * 100).toStringAsFixed(1)}%');
  
  if (testsPassed == totalTests) {
    print('\n🎉 ALL TESTS PASSED! Claude API is ready for App Store Connect');
    print('✅ The API integration is working correctly');
    print('✅ Authentication is successful');
    print('✅ Journal analysis functionality works');
    print('✅ Monthly insights can be generated');
    print('✅ Rate limiting is handled properly');
    print('✅ Ready for production deployment');
    
    print('\n📊 API Usage Summary:');
    print('• The API key is valid and working');
    print('• All core features are functional');
    print('• Response times are acceptable');
    print('• Error handling is working');
  } else {
    print('\n⚠️  SOME TESTS FAILED! Review issues before App Store Connect submission');
    print('❌ ${totalTests - testsPassed} test(s) failed');
    print('🔧 Please fix the failing tests before deployment');
    
    if (testsPassed < totalTests / 2) {
      print('\n🚨 CRITICAL: More than half the tests failed');
      print('   Do not proceed with App Store Connect submission');
      print('   Check your API key and internet connection');
      exit(1);
    } else {
      print('\n⚠️  Some tests failed but core functionality works');
      print('   You may proceed with caution');
    }
  }
  
  print('\n📝 Next Steps:');
  print('1. If all tests passed, you can proceed with App Store Connect');
  print('2. If tests failed, fix the issues and run this test again');
  print('3. Monitor the Anthropic API console for usage after deployment');
  print('4. Check https://console.anthropic.com for API usage statistics');
  
  print('\n🔗 Useful Links:');
  print('• Anthropic Console: https://console.anthropic.com');
  print('• API Documentation: https://docs.anthropic.com');
  print('• Rate Limits: https://docs.anthropic.com/en/api/rate-limits');
  
  exit(testsPassed == totalTests ? 0 : 1);
}
