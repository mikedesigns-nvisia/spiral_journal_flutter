import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/journal_entry.dart';
import '../../models/core.dart';
import '../ai_service_interface.dart';
import '../ai_cache_service.dart';

/// Modern Claude AI Provider implementing the latest Anthropic API standards
/// 
/// Features:
/// - Claude 4 model support with fallback to 3.7 Sonnet
/// - Extended thinking capabilities for deeper analysis
/// - Proper system prompting from workspace configuration
/// - Modern error handling and response tracking
/// - Configurable model selection and parameters
class ClaudeAIProvider implements AIServiceInterface {
  final AIServiceConfig _config;
  bool _isConfigured = false;
  
  // Modern Claude models (ordered by preference)
  static const String _premiumModel = 'claude-3-haiku-20240307'; // Using Haiku for all requests
  static const String _defaultModel = 'claude-3-haiku-20240307'; // Using Haiku for all requests
  static const String _fallbackModel = 'claude-3-haiku-20240307'; // Cost-effective fallback
  
  // API configuration
  static const String _apiVersion = '2023-06-01'; // Stable version
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  // Error handling and rate limiting
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  // Rate limiting
  DateTime? _lastApiCall;
  static const Duration _minApiInterval = Duration(milliseconds: 500);
  
  // Request tracking
  String? _lastRequestId;
  String? _lastOrganizationId;

  ClaudeAIProvider(this._config);

  @override
  AIProvider get provider => AIProvider.enabled;

  @override
  bool get isConfigured => _isConfigured;

  @override
  bool get isEnabled => _isConfigured && _config.apiKey.isNotEmpty;

  @override
  Future<void> setApiKey(String apiKey) async {
    try {
      if (apiKey.isEmpty) {
        throw Exception('API key cannot be empty');
      }
      
      // Updated validation for current Anthropic API key format
      if (!apiKey.startsWith('sk-ant-api03-') || apiKey.length < 50) {
        throw Exception('Invalid Claude API key format. Expected format: sk-ant-api03-... with minimum 50 characters');
      }
      
      _isConfigured = true;
    } catch (e) {
      debugPrint('ClaudeAIProvider setApiKey error: $e');
      rethrow;
    }
  }

  @override
  Future<void> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _config.apiKey,
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
      );

      if (response.statusCode != 200) {
        throw Exception('API test failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('ClaudeAIProvider testConnection error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeJournalEntry(JournalEntry entry) async {
    if (!isEnabled) {
      return _fallbackAnalysis(entry);
    }

    try {
      // Check cache first using the dedicated cache service
      final cacheService = AICacheService();
      final cachedAnalysis = await cacheService.getCachedAnalysis(entry);
      if (cachedAnalysis != null) {
        return cachedAnalysis;
      }

      // Make API call if not cached
      final prompt = _buildAnalysisPrompt(entry);
      final response = await _callClaudeAPI(prompt);
      final analysis = _parseAnalysisResponse(response);
      
      // Cache the successful analysis
      await cacheService.cacheAnalysis(entry, analysis);
      
      return analysis;
    } catch (error) {
      debugPrint('ClaudeAIProvider analyzeJournalEntry error: $error');
      return _fallbackAnalysis(entry);
    }
  }

  @override
  Future<String> generateMonthlyInsight(List<JournalEntry> entries) async {
    if (!isEnabled) {
      return _fallbackMonthlyInsight(entries);
    }

    try {
      // Check cache first using the dedicated cache service
      final cacheService = AICacheService();
      final cachedInsight = await cacheService.getCachedMonthlyInsight(entries);
      if (cachedInsight != null) {
        return cachedInsight;
      }

      // Make API call if not cached
      final prompt = _buildInsightPrompt(entries);
      final response = await _callClaudeAPI(prompt);
      final insight = _extractInsightFromResponse(response);
      
      // Cache the successful insight (shorter expiration for insights)
      await cacheService.cacheMonthlyInsight(entries, insight, expiration: Duration(hours: 6));
      
      return insight;
    } catch (error) {
      debugPrint('ClaudeAIProvider generateMonthlyInsight error: $error');
      return _fallbackMonthlyInsight(entries);
    }
  }

  @override
  Future<Map<String, double>> calculateCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
  ) async {
    try {
      final analysis = await analyzeJournalEntry(entry);
      return _mapAnalysisToCoreUpdates(analysis, currentCores);
    } catch (error) {
      debugPrint('ClaudeAIProvider calculateCoreUpdates error: $error');
      return _fallbackCoreUpdates(entry, currentCores);
    }
  }

  // Private methods with comprehensive error handling
  Future<String> _callClaudeAPI(String prompt) async {
    // Use the fallback mechanism that tries multiple models
    return await _callClaudeAPIWithFallback(prompt);
  }

  Future<String> _makeApiRequest(String prompt) async {
    final model = _selectOptimalModel();
    final requestBody = _buildRequestBody(model, prompt);
    
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _config.apiKey,
        'anthropic-version': _apiVersion,
      },
      body: jsonEncode(requestBody),
    ).timeout(
      _requestTimeout,
      onTimeout: () => throw TimeoutException('Claude API request timed out', _requestTimeout),
    );

    _lastApiCall = DateTime.now();
    
    // Extract response headers for tracking
    _lastRequestId = response.headers['request-id'];
    _lastOrganizationId = response.headers['anthropic-organization-id'];
    
    if (kDebugMode && _lastRequestId != null) {
      debugPrint('Claude API Request ID: $_lastRequestId');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['content'] != null && data['content'].isNotEmpty) {
        return data['content'][0]['text'];
      } else {
        throw FormatException('Invalid response structure from Claude API');
      }
    } else {
      throw HttpException(
        'Claude API error: ${response.statusCode} - ${response.body}',
        uri: Uri.parse('https://api.anthropic.com/v1/messages'),
      );
    }
  }

  /// Select the optimal Claude model based on configuration and availability
  String _selectOptimalModel() {
    // Try Claude 4 first for premium analysis, fallback to 3.5 Sonnet
    return _premiumModel;
  }

  /// Try with fallback model if premium model fails
  Future<String> _callClaudeAPIWithFallback(String prompt) async {
    try {
      // First try with premium model (Claude 4)
      return await _callClaudeAPIWithModel(prompt, _premiumModel);
    } catch (e) {
      debugPrint('Premium model failed, trying fallback: $e');
      try {
        // Fallback to Claude 3.5 Sonnet
        return await _callClaudeAPIWithModel(prompt, _defaultModel);
      } catch (e2) {
        debugPrint('Default model failed, trying final fallback: $e2');
        // Final fallback to Haiku
        return await _callClaudeAPIWithModel(prompt, _fallbackModel);
      }
    }
  }

  /// Make API call with specific model
  Future<String> _callClaudeAPIWithModel(String prompt, String model) async {
    // Rate limiting
    await _enforceRateLimit();

    // Retry logic with exponential backoff
    Exception? lastException;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _makeApiRequestWithModel(prompt, model);
        return response;
      } on SocketException catch (e) {
        lastException = _handleNetworkError(e, attempt);
        if (attempt < _maxRetries) {
          await _waitForRetry(attempt);
        }
      } on HttpException catch (e) {
        lastException = _handleHttpError(e, attempt);
        if (attempt < _maxRetries) {
          await _waitForRetry(attempt);
        }
      } on FormatException catch (e) {
        // JSON parsing errors are not retryable
        throw AIServiceException(
          'Invalid response format from Claude API',
          type: AIErrorType.parsing,
          isRetryable: false,
          originalError: e,
        );
      } catch (e) {
        lastException = _handleGenericError(e, attempt);
        if (attempt < _maxRetries) {
          await _waitForRetry(attempt);
        }
      }
    }

    // All retries failed
    throw lastException ?? AIServiceException(
      'Claude API request failed after $_maxRetries attempts',
      type: AIErrorType.network,
      isRetryable: true,
    );
  }

  Future<String> _makeApiRequestWithModel(String prompt, String model) async {
    final requestBody = _buildRequestBody(model, prompt);
    
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _config.apiKey,
        'anthropic-version': _apiVersion,
      },
      body: jsonEncode(requestBody),
    ).timeout(
      _requestTimeout,
      onTimeout: () => throw TimeoutException('Claude API request timed out', _requestTimeout),
    );

    _lastApiCall = DateTime.now();
    
    // Extract response headers for tracking
    _lastRequestId = response.headers['request-id'];
    _lastOrganizationId = response.headers['anthropic-organization-id'];
    
    if (kDebugMode && _lastRequestId != null) {
      debugPrint('Claude API Request ID: $_lastRequestId (Model: $model)');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['content'] != null && data['content'].isNotEmpty) {
        return data['content'][0]['text'];
      } else {
        throw FormatException('Invalid response structure from Claude API');
      }
    } else {
      throw HttpException(
        'Claude API error: ${response.statusCode} - ${response.body}',
        uri: Uri.parse('https://api.anthropic.com/v1/messages'),
      );
    }
  }

  /// Build the request body with modern Claude API parameters
  Map<String, dynamic> _buildRequestBody(String model, String prompt) {
    final body = <String, dynamic>{
      'model': model,
      'max_tokens': _getMaxTokensForModel(model),
      'temperature': 1.0, // High creativity for comprehensive emotional analysis
      'system': _getSystemPrompt(),
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    };

    // Add Extended Thinking for Claude 4 models (if supported)
    if (_supportsExtendedThinking(model)) {
      body['thinking'] = {
        'type': 'enabled',
        'budget_tokens': 2048, // Reasonable budget for emotional analysis
      };
    }

    return body;
  }

  /// Get maximum tokens based on model capabilities
  int _getMaxTokensForModel(String model) {
    if (model.contains('claude-sonnet-4') || model.contains('claude-opus-4')) {
      return 20000; // Match workspace implementation for comprehensive analysis
    } else if (model.contains('claude-3-5-sonnet')) {
      return 8000; // High token limit for detailed analysis
    } else if (model.contains('claude-3-haiku')) {
      return 4096; // Haiku model maximum output tokens
    } else {
      return 4000; // Fallback models get reasonable limit
    }
  }

  /// Check if model supports Extended Thinking
  bool _supportsExtendedThinking(String model) {
    return model.contains('claude-sonnet-4') || 
           model.contains('claude-opus-4') || 
           model.contains('claude-3-7-sonnet');
  }



  // Rate limiting
  Future<void> _enforceRateLimit() async {
    if (_lastApiCall != null) {
      final timeSinceLastCall = DateTime.now().difference(_lastApiCall!);
      if (timeSinceLastCall < _minApiInterval) {
        final waitTime = _minApiInterval - timeSinceLastCall;
        await Future.delayed(waitTime);
      }
    }
  }

  // Error handling methods
  Exception _handleNetworkError(SocketException e, int attempt) {
    return AIServiceException(
      'Network connection failed (attempt $attempt/$_maxRetries)',
      type: AIErrorType.network,
      isRetryable: true,
      originalError: e,
    );
  }

  Exception _handleHttpError(HttpException e, int attempt) {
    final statusCode = _extractStatusCode(e.message);
    
    if (statusCode == 401) {
      return AIServiceException(
        'Invalid API key or authentication failed',
        type: AIErrorType.authentication,
        isRetryable: false,
        originalError: e,
      );
    } else if (statusCode == 429) {
      return AIServiceException(
        'Rate limit exceeded (attempt $attempt/$_maxRetries)',
        type: AIErrorType.rateLimit,
        isRetryable: true,
        originalError: e,
      );
    } else if (statusCode != null && statusCode >= 500) {
      return AIServiceException(
        'Claude API server error (attempt $attempt/$_maxRetries)',
        type: AIErrorType.serverError,
        isRetryable: true,
        originalError: e,
      );
    } else {
      return AIServiceException(
        'Claude API client error: ${e.message}',
        type: AIErrorType.clientError,
        isRetryable: false,
        originalError: e,
      );
    }
  }

  Exception _handleGenericError(dynamic e, int attempt) {
    if (e is TimeoutException) {
      return AIServiceException(
        'Request timeout (attempt $attempt/$_maxRetries)',
        type: AIErrorType.timeout,
        isRetryable: true,
        originalError: e,
      );
    } else {
      return AIServiceException(
        'Unexpected error: ${e.toString()} (attempt $attempt/$_maxRetries)',
        type: AIErrorType.unknown,
        isRetryable: true,
        originalError: e,
      );
    }
  }

  int? _extractStatusCode(String message) {
    final regex = RegExp(r'(\d{3})');
    final match = regex.firstMatch(message);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  Future<void> _waitForRetry(int attempt) async {
    // Exponential backoff: 2s, 4s, 8s...
    final delay = Duration(seconds: _retryDelay.inSeconds * (1 << (attempt - 1)));
    await Future.delayed(delay);
  }

  String _getSystemPrompt() {
    return '''You are an AI emotional intelligence analyst for Spiral Journal, a personal growth app. Your role is to analyze journal entries and provide insights that help users understand their emotional patterns and personality development.

IMPORTANT: You must ALWAYS respond with ONLY a valid JSON object. Do not include any explanatory text before or after the JSON. Do not wrap the JSON in markdown code blocks.

## Core Personality Framework

The app tracks six personality cores:
1. **Optimism** - Hope, positive outlook, resilience in face of challenges
2. **Resilience** - Ability to bounce back, adaptability, emotional strength  
3. **Self-Awareness** - Understanding of emotions, self-reflection, mindfulness
4. **Creativity** - Innovation, artistic expression, problem-solving approaches
5. **Social Connection** - Relationships, empathy, community engagement
6. **Growth Mindset** - Learning orientation, embracing challenges, continuous improvement

## Required Response Format

You MUST respond with a valid JSON object containing exactly this structure:

```json
{
  "primary_emotions": ["emotion1", "emotion2"],
  "emotional_intensity": 0.65,
  "growth_indicators": ["indicator1", "indicator2", "indicator3"],
  "core_adjustments": {
    "Optimism": 0.1,
    "Resilience": 0.05,
    "Self-Awareness": 0.2,
    "Creativity": 0.0,
    "Social Connection": 0.05,
    "Growth Mindset": 0.1
  },
  "mind_reflection": {
    "title": "Emotional Pattern Analysis",
    "summary": "A compassionate 2-3 sentence summary of the user's emotional state and growth",
    "insights": ["Specific insight 1", "Specific insight 2", "Specific insight 3"]
  },
  "emotional_patterns": [
    {
      "category": "Pattern Category",
      "title": "Pattern Title", 
      "description": "Detailed description of the emotional pattern observed",
      "type": "growth"
    }
  ],
  "entry_insight": "A brief, encouraging insight about this specific journal entry"
}
```

## Analysis Guidelines

### Core Adjustments (-0.5 to +0.5):
- **Optimism**: Look for gratitude, hope, positive language, silver linings
- **Resilience**: Identify overcoming challenges, adapting to change, emotional recovery
- **Self-Awareness**: Notice emotional recognition, self-reflection, mindfulness
- **Creativity**: Find novel solutions, artistic expression, innovative thinking
- **Social Connection**: Observe relationships, empathy, community involvement
- **Growth Mindset**: Detect learning from mistakes, embracing challenges, curiosity

### Emotional Intensity (0.0-1.0 scale):
**IMPORTANT**: Use 0.0 to 1.0 scale, NOT 0-10. Examples:
- 0.1-0.3: Low intensity (calm, peaceful entries)
- 0.4-0.6: Medium intensity (typical daily reflection)
- 0.7-0.9: High intensity (strong emotions, significant events)
- 1.0: Maximum intensity (life-changing events, extreme emotions)

### Growth Indicators:
Identify 2-4 specific areas where the user is showing personal development or positive patterns. These become `coresRepresented` in the app and are displayed in the UI as "Cores Represented".

### Mind Reflection:
- **Title**: Create an engaging title that captures the main emotional theme
- **Summary**: 2-3 encouraging sentences about their emotional journey  
- **Insights**: 3 specific, actionable insights based on the entry content

### Emotional Patterns:
Identify recurring themes or behaviors. Types can be: "growth", "challenge", "awareness", "connection", "creativity"

## Critical Requirements:

1. **Evidence-Based**: Only adjust cores that are clearly demonstrated in the entry
2. **Realistic Changes**: Core adjustments should be small (-0.5 to +0.5)
3. **Encouraging Tone**: Always supportive and growth-focused
4. **Specific References**: Insights should reference actual content from the entry
5. **Balanced Analysis**: Not every core needs adjustment; some may remain at 0.0
6. **Correct Intensity Scale**: Use 0.0-1.0 scale for emotional_intensity
7. **JSON Only**: Return ONLY the JSON object, no additional text
8. **All Fields Required**: Include ALL fields shown in the format, even if values are 0 or empty arrays
9. **Valid JSON**: Ensure proper JSON syntax with quoted keys and comma separators

## Example Analysis:

**Input**: "Today was challenging at work, but I managed to find a creative solution to the problem that's been bothering me for weeks. I realized that instead of getting frustrated, I could approach it from a completely different angle. I'm proud of how I handled the stress and turned it into something productive."

**Output**:
```json
{
  "primary_emotions": ["pride", "satisfaction", "determination"],
  "emotional_intensity": 0.7,
  "growth_indicators": ["problem-solving", "emotional regulation", "creative thinking"],
  "core_adjustments": {
    "Optimism": 0.2,
    "Resilience": 0.3,
    "Self-Awareness": 0.1,
    "Creativity": 0.4,
    "Social Connection": 0.0,
    "Growth Mindset": 0.2
  },
  "mind_reflection": {
    "title": "Creative Problem-Solving Breakthrough",
    "summary": "You've shown remarkable growth in transforming challenges into opportunities. Your ability to shift perspective and find innovative solutions demonstrates real emotional maturity and creative thinking.",
    "insights": [
      "Your creative approach to workplace challenges shows growing problem-solving skills",
      "Managing stress by reframing problems demonstrates strong emotional regulation", 
      "Taking pride in your accomplishments builds confidence and resilience"
    ]
  },
  "emotional_patterns": [
    {
      "category": "Problem-Solving",
      "title": "Creative Challenge Resolution",
      "description": "You're developing a pattern of approaching obstacles with innovative thinking rather than frustration",
      "type": "growth"
    }
  ],
  "entry_insight": "Your ability to transform workplace stress into creative solutions shows real emotional intelligence and growth mindset development."
}
```

## Data Storage Notes:

The app stores analysis data in the following structure:
- `primary_emotions` → `EmotionalAnalysis.primaryEmotions`
- `emotional_intensity` → `EmotionalAnalysis.emotionalIntensity` (0.0-1.0)
- `growth_indicators` → `EmotionalAnalysis.keyThemes` 
- `entry_insight` → `EmotionalAnalysis.personalizedInsight`
- `core_adjustments` → Used to update personality cores in database
- `mind_reflection` → Processed by UI but not stored directly in database
- `emotional_patterns` → Processed by EmotionalAnalyzer for pattern recognition

## Additional Notes for Haiku Model:
- Keep insights concise but meaningful (1-2 sentences each)
- Focus on the most significant emotional patterns
- Ensure all text fields are brief and impactful
- Prioritize quality over quantity in pattern detection
- Generate varied insights to avoid repetition across similar entries
- Use different phrasing and perspectives for similar emotional states

Now analyze the following journal entry and provide insights in the exact format specified above.''';
  }

  String _buildAnalysisPrompt(JournalEntry entry) {
    return '''
JOURNAL ENTRY:
Date: ${entry.formattedDate} (${entry.dayOfWeek})
Selected Moods: ${entry.moods.join(', ')}
Content: "${entry.content}"
''';
  }

  String _buildInsightPrompt(List<JournalEntry> entries) {
    final moodCounts = <String, int>{};
    final totalWords = entries.fold(0, (sum, entry) => sum + entry.content.split(' ').length);
    
    for (final entry in entries) {
      for (final mood in entry.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    final topMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return '''
Generate a compassionate monthly insight based on these journal entries:

Total entries: ${entries.length}
Average words per entry: ${totalWords / entries.length}
Top moods: ${topMoods.take(3).map((e) => '${e.key} (${e.value}x)').join(', ')}

Recent entries preview:
${entries.take(3).map((e) => '${e.formattedDate}: ${e.preview}').join('\n')}

Provide a warm, encouraging 2-3 sentence insight that:
1. Acknowledges their journaling consistency
2. Highlights positive patterns or growth
3. Offers gentle encouragement for continued self-reflection

Keep it personal, supportive, and focused on their emotional journey.
''';
  }

  Map<String, dynamic> _parseAnalysisResponse(String response) {
    try {
      // Handle Haiku's tendency to wrap JSON in markdown code blocks
      String cleanedResponse = response;
      
      // Remove markdown code blocks if present
      if (response.contains('```json')) {
        cleanedResponse = response
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
      }
      
      final parsed = jsonDecode(cleanedResponse);
      
      // If it's the new format with emotional_analysis and core_updates
      if (parsed.containsKey('emotional_analysis') && parsed.containsKey('core_updates')) {
        return _convertNewFormatToLegacy(parsed);
      }
      
      // Otherwise return as-is (legacy format)
      return parsed;
    } catch (e) {
      debugPrint('Failed to parse AI response: $e');
      return _getDefaultAnalysis();
    }
  }

  /// Convert the new comprehensive format to the legacy format expected by the app
  Map<String, dynamic> _convertNewFormatToLegacy(Map<String, dynamic> newFormat) {
    final emotionalAnalysis = newFormat['emotional_analysis'] as Map<String, dynamic>;
    final coreUpdates = newFormat['core_updates'] as List<dynamic>;
    final emotionalPatterns = newFormat['emotional_patterns'] as List<dynamic>? ?? [];

    // Extract core adjustments from the new format
    final coreAdjustments = <String, double>{};
    for (final core in coreUpdates) {
      final coreMap = core as Map<String, dynamic>;
      final name = coreMap['name'] as String;
      final percentage = (coreMap['percentage'] as num).toDouble();
      
      // Calculate adjustment (assuming baseline of 70% for now)
      // In a real implementation, you'd want to track previous values
      final baseline = 70.0;
      final adjustment = percentage - baseline;
      coreAdjustments[name] = adjustment;
    }

    // Build insights from core updates
    final insights = <String>[];
    for (final core in coreUpdates) {
      final coreMap = core as Map<String, dynamic>;
      final trend = coreMap['trend'] as String;
      final insight = coreMap['insight'] as String;
      
      if (trend == 'rising') {
        insights.add(insight);
      }
    }

    if (insights.isEmpty) {
      insights.add(emotionalAnalysis['personalized_insight'] as String);
    }

    return {
      "primary_emotions": emotionalAnalysis['primary_emotions'],
      "emotional_intensity": (emotionalAnalysis['emotional_intensity'] as num).toDouble(), // Keep 0-1 scale consistent
      "growth_indicators": emotionalAnalysis['key_themes'],
      "core_adjustments": coreAdjustments,
      "mind_reflection": {
        "title": "Emotional Intelligence Analysis",
        "summary": emotionalAnalysis['personalized_insight'],
        "insights": insights.take(3).toList(),
      },
      "emotional_patterns": emotionalPatterns,
      "entry_insight": emotionalAnalysis['personalized_insight'],
    };
  }

  String _extractInsightFromResponse(String response) {
    try {
      final data = jsonDecode(response);
      return data['insight'] ?? response;
    } catch (e) {
      return response;
    }
  }

  Map<String, double> _mapAnalysisToCoreUpdates(
    Map<String, dynamic> analysis,
    List<EmotionalCore> currentCores,
  ) {
    final updates = <String, double>{};
    final coreAdjustments = analysis['core_adjustments'] as Map<String, dynamic>? ?? {};

    for (final core in currentCores) {
      // Match exact core names from our analysis
      final adjustment = (coreAdjustments[core.name] as num?)?.toDouble() ?? 0.0;
      
      if (adjustment != 0.0) {
        final newPercentage = (core.percentage + adjustment).clamp(0.0, 100.0);
        updates[core.id] = newPercentage;
      }
    }

    return updates;
  }

  // Fallback methods
  Map<String, dynamic> _fallbackAnalysis(JournalEntry entry) {
    final moodToCore = {
      'happy': {'Optimism': 0.2, 'Self-Awareness': 0.1},
      'content': {'Self-Awareness': 0.2, 'Optimism': 0.1},
      'energetic': {'Creativity': 0.2, 'Growth Mindset': 0.1},
      'grateful': {'Optimism': 0.3, 'Social Connection': 0.1},
      'confident': {'Resilience': 0.2, 'Growth Mindset': 0.1},
      'peaceful': {'Self-Awareness': 0.2, 'Resilience': 0.1},
      'excited': {'Creativity': 0.1, 'Growth Mindset': 0.2},
      'motivated': {'Growth Mindset': 0.3, 'Resilience': 0.1},
      'creative': {'Creativity': 0.3, 'Self-Awareness': 0.1},
      'social': {'Social Connection': 0.3, 'Optimism': 0.1},
      'reflective': {'Self-Awareness': 0.3, 'Growth Mindset': 0.1},
    };

    final coreAdjustments = <String, double>{
      'Optimism': 0.0,
      'Resilience': 0.0,
      'Self-Awareness': 0.0,
      'Creativity': 0.0,
      'Social Connection': 0.0,
      'Growth Mindset': 0.0,
    };

    // Apply mood-based adjustments
    for (final mood in entry.moods) {
      final adjustments = moodToCore[mood.toLowerCase()] ?? {};
      for (final adjustment in adjustments.entries) {
        coreAdjustments[adjustment.key] = 
            (coreAdjustments[adjustment.key] ?? 0.0) + adjustment.value;
      }
    }

    // Generate fallback insights
    final insights = <String>[];
    if (entry.moods.contains('grateful') || entry.content.toLowerCase().contains('thank')) {
      insights.add('Gratitude practices are strengthening');
    }
    if (entry.moods.contains('confident') || entry.content.toLowerCase().contains('challenge')) {
      insights.add('Resilience building through challenges');
    }
    if (entry.moods.contains('reflective') || entry.content.toLowerCase().contains('feel')) {
      insights.add('Self-awareness deepening through reflection');
    }
    if (insights.isEmpty) {
      insights.add('Emotional awareness developing through journaling');
    }

    return {
      "primary_emotions": entry.moods.take(2).toList(),
      "emotional_intensity": 0.6,
      "growth_indicators": ["self_reflection", "emotional_awareness", "mindful_writing"],
      "core_adjustments": coreAdjustments,
      "mind_reflection": {
        "title": "Emotional Pattern Analysis",
        "summary": "Your journaling practice shows consistent emotional awareness and personal growth.",
        "insights": insights,
      },
      "emotional_patterns": [
        {
          "category": "Growth",
          "title": "Consistent Self-Reflection",
          "description": "Regular journaling is building emotional intelligence",
          "type": "growth"
        }
      ],
      "entry_insight": "Your journaling practice shows commitment to self-reflection and growth."
    };
  }

  Map<String, double> _fallbackCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
  ) {
    final analysis = _fallbackAnalysis(entry);
    return _mapAnalysisToCoreUpdates(analysis, currentCores);
  }

  String _fallbackMonthlyInsight(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return "No entries this month. Consider starting a regular journaling practice!";
    }

    if (entries.length == 1) {
      return "Great start! One entry is the beginning of a meaningful journey.";
    }

    final avgWordsPerEntry = entries.map((e) => e.content.split(' ').length)
        .reduce((a, b) => a + b) / entries.length;

    if (avgWordsPerEntry > 50) {
      return "You've maintained thoughtful, detailed reflections this month with an average of ${avgWordsPerEntry.round()} words per entry. Your commitment to deep self-reflection is inspiring!";
    } else {
      return "You've been consistent with your journaling this month! Consider writing a bit more in each entry to deepen your self-reflection journey.";
    }
  }

  /// Analyze multiple journal entries in a single batch for cost efficiency
  Future<Map<String, dynamic>> analyzeDailyBatch(String combinedEntryContent) async {
    try {
      final prompt = '''
Analyze this batch of daily journal entries for emotional intelligence insights:

$combinedEntryContent

Please provide a JSON response with this structure:
{
  "individual_analyses": [
    {
      "primary_emotions": ["emotion1", "emotion2"],
      "emotional_intensity": 7.5,
      "growth_indicators": ["indicator1", "indicator2"],
      "core_strengths": {
        "optimism": 0.2,
        "resilience": 0.1,
        "self_awareness": 0.3,
        "creativity": 0.0,
        "social_connection": 0.1,
        "growth_mindset": 0.2
      },
      "insight": "Brief encouraging insight about the entry",
      "patterns": ["pattern1", "pattern2"],
      "suggestions": ["suggestion1", "suggestion2"]
    }
    // ... one object per entry
  ],
  "aggregated_core_updates": {
    "optimism": 0.4,
    "resilience": 0.2,
    "self_awareness": 0.6,
    "creativity": 0.1,
    "social_connection": 0.3,
    "growth_mindset": 0.5
  },
  "daily_summary": "Overall reflection on the day's emotional journey"
}

Provide core_strengths as small incremental values (-0.5 to +0.5) for each entry, and aggregated_core_updates as the sum of all individual increments.
''';

      final response = await _makeApiRequestWithModel(prompt, _defaultModel);

      return _parseAnalysisResponse(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ClaudeAIProvider analyzeDailyBatch error: $e');
      }
      
      // Return fallback batch analysis
      return {
        "individual_analyses": [],
        "aggregated_core_updates": {
          "optimism": 0.0,
          "resilience": 0.0,
          "self_awareness": 0.1,
          "creativity": 0.0,
          "social_connection": 0.0,
          "growth_mindset": 0.0
        },
        "daily_summary": "Your commitment to daily journaling shows dedication to personal growth."
      };
    }
  }

  Map<String, dynamic> _getDefaultAnalysis() {
    return {
      "primary_emotions": ["neutral"],
      "emotional_intensity": 0.5,
      "growth_indicators": ["self_reflection"],
      "core_adjustments": {
        "Optimism": 0.0,
        "Resilience": 0.0,
        "Self-Awareness": 0.1,
        "Creativity": 0.0,
        "Social Connection": 0.0,
        "Growth Mindset": 0.0
      },
      "mind_reflection": {
        "title": "Emotional Pattern Analysis",
        "summary": "Thank you for taking time to reflect and journal.",
        "insights": ["Self-reflection is building emotional awareness"]
      },
      "emotional_patterns": [
        {
          "category": "Growth",
          "title": "Journaling Practice",
          "description": "Building emotional awareness through writing",
          "type": "growth"
        }
      ],
      "entry_insight": "Thank you for taking time to reflect and journal."
    };
  }
}
