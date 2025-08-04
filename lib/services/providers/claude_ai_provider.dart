import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/journal_entry.dart';
import '../../models/core.dart';
import '../ai_service_interface.dart';
import '../ai_cache_service.dart';
import '../../config/ai_model_config.dart';

/// Modern Claude AI Provider with flexible model configuration
/// 
/// Features:
/// - Configurable AI models via AIModelConfig
/// - Automatic model selection based on strategy
/// - Token-optimized prompts for efficient responses
/// - Modern error handling and response tracking
/// - Cost tracking and optimization
class ClaudeAIProvider implements AIServiceInterface {
  final AIServiceConfig _config;
  bool _isConfigured = false;
  
  // Model configuration
  AIModelConfig? _currentModel;
  ModelSelectionStrategy _strategy = ModelSelectionStrategy.defaultOnly;
  
  // API configuration
  static const String _apiVersion = '2023-06-01'; // Stable version
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  // Error handling and rate limiting
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  // Rate limiting and debouncing
  DateTime? _lastApiCall;
  static const Duration _minApiInterval = Duration(milliseconds: 500); // Minimum 500ms between calls
  
  // Request tracking
  String? _lastRequestId;

  ClaudeAIProvider(this._config) {
    _initializeModel();
  }
  
  /// Initialize the model configuration
  Future<void> _initializeModel() async {
    _currentModel = await AIModelManager.getSelectedModel();
    _strategy = await AIModelManager.getStrategy();
  }

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
      if (!apiKey.startsWith('sk-ant-') || apiKey.length < 40) {
        throw Exception('Invalid Claude API key format. Expected format: sk-ant-... with minimum 40 characters');
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
      // Ensure model is initialized
      if (_currentModel == null) {
        await _initializeModel();
      }
      
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _config.apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _currentModel!.modelId,
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

      // Select optimal model for this entry
      final model = await AIModelManager.selectOptimalModel(
        content: entry.content,
        strategy: _strategy,
      );
      
      // Make API call if not cached
      final prompt = _buildAnalysisPrompt(entry);
      final response = await _callClaudeAPIWithModel(prompt, model);
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

      // Select optimal model for insights (may use better model)
      final combinedContent = entries.map((e) => e.content).join(' ');
      final model = await AIModelManager.selectOptimalModel(
        content: combinedContent,
        strategy: _strategy,
      );
      
      // Make API call if not cached
      final prompt = _buildInsightPrompt(entries);
      final response = await _callClaudeAPIWithModel(prompt, model);
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
  /// Call API with specific model configuration
  Future<String> _callClaudeAPIWithModel(String prompt, AIModelConfig model) async {
    return await _callClaudeAPIWithModelId(prompt, model.modelId, model);
  }

  /// Make API call with specific model ID and configuration
  Future<String> _callClaudeAPIWithModelId(String prompt, String modelId, AIModelConfig modelConfig) async {
    // Rate limiting
    await _enforceRateLimit();

    // Retry logic with exponential backoff
    Exception? lastException;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _makeApiRequestWithModel(prompt, modelId, modelConfig);
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

  Future<String> _makeApiRequestWithModel(String prompt, String modelId, AIModelConfig modelConfig) async {
    final requestBody = _buildRequestBody(modelId, prompt, modelConfig);
    
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
    
    if (kDebugMode && _lastRequestId != null) {
      debugPrint('Claude API Request ID: $_lastRequestId (Model: $modelId)');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['content'] != null && data['content'].isNotEmpty) {
        // Extract token usage information for optimization tracking
        final responseText = data['content'][0]['text'];
        final usage = data['usage'] as Map<String, dynamic>?;
        
        if (kDebugMode && usage != null) {
          final inputTokens = usage['input_tokens'] as int? ?? 0;
          final outputTokens = usage['output_tokens'] as int? ?? 0;
          final cost = modelConfig.calculateCost(inputTokens, outputTokens);
          debugPrint('🔢 Token usage - Input: $inputTokens, Output: $outputTokens');
          debugPrint('💰 Estimated cost: \$${cost.toStringAsFixed(4)}');
        }
        
        return responseText;
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
  Map<String, dynamic> _buildRequestBody(String modelId, String prompt, AIModelConfig modelConfig) {
    final body = <String, dynamic>{
      'model': modelId,
      'max_tokens': modelConfig.maxTokens,
      'temperature': modelConfig.temperature,
      'system': _getSystemPrompt(),
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    };

    // Extended Thinking not supported by Haiku - removed for cost optimization

    return body;
  }

  /// Get model configuration for display
  AIModelConfig get currentModel => _currentModel ?? AIModels.defaultModel;
  
  /// Set model selection strategy
  Future<void> setModelStrategy(ModelSelectionStrategy strategy) async {
    _strategy = strategy;
    await AIModelManager.setStrategy(strategy);
  }
  
  /// Manually set the model to use
  Future<void> setModel(String modelId) async {
    final model = AIModels.getById(modelId);
    if (model != null && model.isEnabled) {
      _currentModel = model;
      await AIModelManager.setSelectedModel(modelId);
    }
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
    return '''You are an AI emotional analyst for Spiral Journal. Analyze journal entries and provide concise emotional insights.

IMPORTANT: Respond ONLY with valid JSON. No extra text or markdown blocks.

## Six Personality Cores:
1. **Optimism** - Hope, positive outlook
2. **Resilience** - Bouncing back, adaptability  
3. **Self-Awareness** - Emotional understanding, reflection
4. **Creativity** - Innovation, problem-solving
5. **Social Connection** - Relationships, empathy
6. **Growth Mindset** - Learning, embracing challenges

## Required JSON Format:
{
  "primary_emotions": ["emotion1", "emotion2"],
  "emotional_intensity": 0.65,
  "growth_indicators": ["indicator1", "indicator2"],
  "core_adjustments": {
    "Optimism": 0.1,
    "Resilience": 0.0,
    "Self-Awareness": 0.2,
    "Creativity": 0.0,
    "Social Connection": 0.0,
    "Growth Mindset": 0.1
  },
  "mind_reflection": {
    "title": "Brief Emotional Theme",
    "summary": "1-2 encouraging sentences about growth",
    "insights": ["Insight 1", "Insight 2"]
  },
  "emotional_patterns": [
    {
      "category": "Pattern Category",
      "title": "Pattern Title", 
      "description": "Brief pattern description",
      "type": "growth"
    }
  ],
  "entry_insight": "Brief encouraging insight"
}

## Guidelines:
- Core adjustments: -0.5 to +0.5 (small, evidence-based changes)
- Emotional intensity: 0.0-1.0 scale (0.5 = typical daily reflection)
- Keep all text brief and impactful
- Focus on strongest emotional patterns
- Always encouraging and growth-focused
- Return valid JSON only

Analyze this journal entry:''';
  }

  String _buildAnalysisPrompt(JournalEntry entry) {
    // Truncate content to 500 characters for cost optimization
    final truncatedContent = entry.content.length > 500 
        ? '${entry.content.substring(0, 500)}...'
        : entry.content;
    
    return '''
JOURNAL ENTRY:
Date: ${entry.formattedDate} (${entry.dayOfWeek})
Selected Moods: ${entry.moods.join(', ')}
Content: "$truncatedContent"
''';
  }

  String _buildInsightPrompt(List<JournalEntry> entries) {
    // Limit to max 10 entries for cost optimization
    final limitedEntries = entries.take(10).toList();
    final moodCounts = <String, int>{};
    final totalWords = limitedEntries.fold(0, (sum, entry) => sum + entry.content.split(' ').length);
    
    for (final entry in limitedEntries) {
      for (final mood in entry.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    final topMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return '''
Generate a compassionate monthly insight based on these journal entries:

Total entries: ${limitedEntries.length}
Average words per entry: ${totalWords / limitedEntries.length}
Top moods: ${topMoods.take(3).map((e) => '${e.key} (${e.value}x)').join(', ')}

Recent entries preview:
${limitedEntries.take(3).map((e) => '${e.formattedDate}: ${e.preview}').join('\n')}

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

      // Use current model for batch analysis
      final model = _currentModel ?? AIModels.defaultModel;
      final response = await _makeApiRequestWithModel(prompt, model.modelId, model);

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
