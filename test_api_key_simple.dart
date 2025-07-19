import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple Claude API Key Test
/// Tests the API key directly without Flutter dependencies
void main() async {
  print('🧪 Testing Claude API Key Integration...\n');
  
  try {
    // Test 1: Read API key from .env file
    await testApiKeyFromEnv();
    
    // Test 2: Test direct API connection
    await testDirectApiConnection();
    
    print('\n✅ All tests passed! Your Claude API key is working correctly.');
    
  } catch (e) {
    print('\n❌ Test failed: $e');
    exit(1);
  }
}

Future<void> testApiKeyFromEnv() async {
  print('📋 Test 1: Reading API Key from .env file');
  
  final envFile = File('.env');
  if (!await envFile.exists()) {
    throw Exception('.env file not found');
  }
  
  final content = await envFile.readAsString();
  final lines = content.split('\n');
  
  String? apiKey;
  for (final line in lines) {
    if (line.startsWith('CLAUDE_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }
  
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('CLAUDE_API_KEY not found in .env file');
  }
  
  if (!apiKey.startsWith('sk-ant-api03-')) {
    throw Exception('Invalid API key format. Expected: sk-ant-api03-...');
  }
  
  print('   ✅ API key found in .env file');
  print('   ✅ API key format is valid');
  print('   ✅ API key length: ${apiKey.length} characters');
}

Future<void> testDirectApiConnection() async {
  print('\n📋 Test 2: Testing Direct API Connection');
  
  // Read API key
  final envFile = File('.env');
  final content = await envFile.readAsString();
  final apiKey = content.split('CLAUDE_API_KEY=')[1].split('\n')[0].trim();
  
  print('   🔑 Using API key: ${apiKey.substring(0, 20)}...');
  
  // Test API connection with a simple request
  final response = await http.post(
    Uri.parse('https://api.anthropic.com/v1/messages'),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: jsonEncode({
      'model': 'claude-3-haiku-20240307',
      'max_tokens': 50,
      'messages': [
        {
          'role': 'user',
          'content': 'Hello! Please respond with just "API test successful" to confirm the connection.',
        }
      ],
    }),
  ).timeout(
    Duration(seconds: 30),
    onTimeout: () => throw Exception('API request timed out'),
  );
  
  print('   📡 API Response Status: ${response.statusCode}');
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final responseText = data['content'][0]['text'];
    
    print('   ✅ API connection successful!');
    print('   💬 Claude response: "$responseText"');
    
    // Test journal analysis with a real example
    await testJournalAnalysis(apiKey);
    
  } else {
    print('   ❌ API Error: ${response.statusCode}');
    print('   📄 Response body: ${response.body}');
    throw Exception('API connection failed with status ${response.statusCode}');
  }
}

Future<void> testJournalAnalysis(String apiKey) async {
  print('\n📋 Test 3: Testing Journal Analysis');
  
  final journalPrompt = '''
Analyze this journal entry for emotional intelligence insights:

Date: January 18, 2025 (Saturday)
Moods: determined, proud, creative
Content: "Today was challenging at work, but I managed to find a creative solution to the problem that's been bothering me for weeks. I realized that instead of getting frustrated, I could approach it from a completely different angle. I'm proud of how I handled the stress and turned it into something productive."

Please provide a JSON response with the following structure:
{
  "primary_emotions": ["emotion1", "emotion2"],
  "emotional_intensity": 0.75,
  "growth_indicators": ["indicator1", "indicator2"],
  "core_adjustments": {
    "Optimism": 0.1,
    "Resilience": 0.2,
    "Self-Awareness": 0.1,
    "Creativity": 0.3,
    "Social Connection": 0.0,
    "Growth Mindset": 0.2
  },
  "entry_insight": "Brief encouraging insight about the entry"
}

Focus on emotional patterns, growth mindset, resilience, creativity, and self-awareness.
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
          'content': journalPrompt,
        }
      ],
    }),
  ).timeout(Duration(seconds: 30));
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final analysisText = data['content'][0]['text'];
    
    print('   ✅ Journal analysis completed');
    print('   📊 Analysis response length: ${analysisText.length} characters');
    
    // Try to parse as JSON
    try {
      final analysis = jsonDecode(analysisText);
      print('   ✅ Analysis is valid JSON');
      print('   📊 Primary emotions: ${analysis['primary_emotions']}');
      print('   📊 Emotional intensity: ${analysis['emotional_intensity']}');
      print('   💡 Entry insight: "${analysis['entry_insight']}"');
      
      if (analysis['core_adjustments'] != null) {
        final coreAdjustments = analysis['core_adjustments'] as Map<String, dynamic>;
        print('   📊 Core adjustments:');
        coreAdjustments.forEach((core, value) {
          if (value != 0.0) {
            print('      - $core: ${value > 0 ? '+' : ''}$value');
          }
        });
      }
      
    } catch (e) {
      print('   ⚠️  Analysis response is not JSON, but API call succeeded');
      print('   📄 Raw response: ${analysisText.substring(0, 200)}...');
    }
    
  } else {
    print('   ❌ Journal analysis failed: ${response.statusCode}');
    print('   📄 Response: ${response.body}');
    throw Exception('Journal analysis failed');
  }
}
