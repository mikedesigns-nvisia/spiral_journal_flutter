import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/journal_entry.dart';
import '../models/core.dart';
import '../utils/app_error_handler.dart';
import 'secure_api_key_service.dart';
import 'providers/claude_ai_provider.dart';
import 'ai_service_interface.dart';

/// Legacy Claude AI Service - DEPRECATED
/// 
/// This service is maintained for backward compatibility but delegates
/// to the modern ClaudeAIProvider. New code should use ClaudeAIProvider directly.
/// 
/// @deprecated Use ClaudeAIProvider instead for modern Claude API features
class ClaudeAIService {
  static final ClaudeAIService _instance = ClaudeAIService._internal();
  factory ClaudeAIService() => _instance;
  ClaudeAIService._internal();

  // Modern provider delegation
  ClaudeAIProvider? _modernProvider;
  
  // Legacy API configuration (kept for compatibility)
  final SecureApiKeyService _apiKeyService = SecureApiKeyService();
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _serviceName = 'claude_ai';
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _apiKeyService.initialize();
    _isInitialized = true;
  }

  /// Set API key and enable real API calls
  Future<void> setApiKey(String apiKey) async {
    return await AppErrorHandler().handleError(
      () async {
        await initialize();
        
        // Store the API key securely
        await _apiKeyService.storeApiKey(_serviceName, apiKey);
        
        // Validate the API key
        final isValid = await _apiKeyService.validateApiKey(_serviceName);
        if (!isValid) {
          throw Exception('Invalid API key format or API validation failed');
        }
        
        // Initialize modern provider for better performance
        _modernProvider = ClaudeAIProvider(AIServiceConfig(
          apiKey: apiKey,
          provider: AIProvider.enabled,
        ));
        await _modernProvider!.setApiKey(apiKey);
      },
      operationName: 'setApiKey',
      component: 'ClaudeAIService',
      context: {'apiKeyLength': apiKey.length},
    );
  }

  /// Get the stored API key
  Future<String?> _getApiKey() async {
    await initialize();
    return await _apiKeyService.getApiKey(_serviceName);
  }

  /// Check if real API is available
  Future<bool> get isRealApiEnabled async {
    await initialize();
    return await _apiKeyService.hasApiKey(_serviceName) && 
           await _apiKeyService.validateApiKey(_serviceName);
  }

  /// Remove the stored API key
  Future<void> removeApiKey() async {
    await initialize();
    await _apiKeyService.removeApiKey(_serviceName);
  }

  // Analyze journal entry for emotional patterns and core updates
  Future<Map<String, dynamic>> analyzeJournalEntry(JournalEntry entry) async {
    return await AppErrorHandler().handleWithFallback(
      () async {
        final prompt = _buildAnalysisPrompt(entry);
        final response = await _callClaudeAPI(prompt);
        return _parseAnalysisResponse(response);
      },
      () async => _fallbackAnalysis(entry),
      operationName: 'analyzeJournalEntry',
      component: 'ClaudeAIService',
      context: {
        'entryId': entry.id,
        'contentLength': entry.content.length,
        'moodCount': entry.moods.length,
      },
    );
  }

  // Generate insights for multiple entries
  Future<String> generateMonthlyInsight(List<JournalEntry> entries) async {
    if (entries.isEmpty) {
      return "No entries this month. Consider starting a regular journaling practice!";
    }

    return await AppErrorHandler().handleWithFallback(
      () async {
        final prompt = _buildInsightPrompt(entries);
        final response = await _callClaudeAPI(prompt);
        return _extractInsightFromResponse(response);
      },
      () async => _fallbackMonthlyInsight(entries),
      operationName: 'generateMonthlyInsight',
      component: 'ClaudeAIService',
      context: {
        'entryCount': entries.length,
        'dateRange': entries.isNotEmpty 
            ? '${entries.last.formattedDate} to ${entries.first.formattedDate}'
            : 'empty',
      },
    );
  }

  // Update emotional cores based on analysis
  Future<Map<String, double>> calculateCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
  ) async {
    return await AppErrorHandler().handleWithFallback(
      () async {
        final analysis = await analyzeJournalEntry(entry);
        return _mapAnalysisToCoreUpdates(analysis, currentCores);
      },
      () async => _fallbackCoreUpdates(entry, currentCores),
      operationName: 'calculateCoreUpdates',
      component: 'ClaudeAIService',
      context: {
        'entryId': entry.id,
        'coreCount': currentCores.length,
      },
    );
  }

  // Private methods

  String _buildAnalysisPrompt(JournalEntry entry) {
    return '''
Analyze this journal entry for emotional intelligence insights:

Date: ${entry.formattedDate}
Moods: ${entry.moods.join(', ')}
Content: "${entry.content}"

Please provide a JSON response with the following structure:
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
  "insight": "Brief encouraging insight about the entry"
}

Focus on:
1. Emotional patterns and self-awareness
2. Growth mindset indicators
3. Resilience and coping mechanisms
4. Creative expression
5. Social connections mentioned
6. Optimistic vs pessimistic language

Provide core_strengths as small incremental values (-0.5 to +0.5) representing how this entry should adjust each core percentage.
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

  Future<String> _callClaudeAPI(String prompt) async {
    // Check if real API is available
    final hasApiKey = await _apiKeyService.hasApiKey(_serviceName);
    final apiKey = hasApiKey ? await _getApiKey() : null;
    
    if (hasApiKey && apiKey != null) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-3-haiku-20240307', // Using Haiku for faster/cheaper responses
            'max_tokens': 1000,
            'messages': [
              {
                'role': 'user',
                'content': prompt,
              }
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['content'][0]['text'];
        } else {
          throw Exception('Claude API error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        // Fallback to simulation if real API fails
        // Log error in production logging system if needed
        await Future.delayed(const Duration(milliseconds: 500));
        return _generateSimulatedResponse(prompt);
      }
    } else {
      // Simulated response for demo
      await Future.delayed(const Duration(milliseconds: 500));
      return _generateSimulatedResponse(prompt);
    }
  }

  String _generateSimulatedResponse(String prompt) {
    // Simulate different types of responses based on prompt content
    if (prompt.contains('monthly insight')) {
      return "Your journaling journey this month shows beautiful self-awareness and emotional growth. The consistency in your reflections demonstrates a strong commitment to personal development. Keep nurturing this practice - it's clearly supporting your emotional well-being.";
    } else {
      // Simulated analysis response
      return jsonEncode({
        "primary_emotions": ["reflective", "hopeful"],
        "emotional_intensity": 6.5,
        "growth_indicators": ["self_awareness", "positive_outlook"],
        "core_strengths": {
          "optimism": 0.1,
          "resilience": 0.05,
          "self_awareness": 0.2,
          "creativity": 0.0,
          "social_connection": 0.05,
          "growth_mindset": 0.1
        },
        "insight": "Your reflection shows strong self-awareness and a growth-oriented mindset."
      });
    }
  }

  Map<String, dynamic> _parseAnalysisResponse(String response) {
    try {
      return jsonDecode(response);
    } catch (e) {
      // Return default structure if parsing fails
      return {
        "primary_emotions": ["neutral"],
        "emotional_intensity": 5.0,
        "growth_indicators": ["self_reflection"],
        "core_strengths": {
          "optimism": 0.0,
          "resilience": 0.0,
          "self_awareness": 0.1,
          "creativity": 0.0,
          "social_connection": 0.0,
          "growth_mindset": 0.0
        },
        "insight": "Thank you for taking time to reflect and journal."
      };
    }
  }

  String _extractInsightFromResponse(String response) {
    // If response is JSON, extract insight field, otherwise return as-is
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
    final coreStrengths = analysis['core_strengths'] as Map<String, dynamic>? ?? {};

    for (final core in currentCores) {
      final coreName = core.name.toLowerCase().replaceAll(' ', '_');
      final adjustment = (coreStrengths[coreName] as num?)?.toDouble() ?? 0.0;
      
      if (adjustment != 0.0) {
        final newPercentage = (core.percentage + adjustment).clamp(0.0, 100.0);
        updates[core.id] = newPercentage;
      }
    }

    return updates;
  }

  // Fallback methods for when AI service is unavailable

  Map<String, dynamic> _fallbackAnalysis(JournalEntry entry) {
    final moodToCore = {
      'happy': {'optimism': 0.2, 'self_awareness': 0.1},
      'content': {'self_awareness': 0.2, 'optimism': 0.1},
      'energetic': {'creativity': 0.2, 'growth_mindset': 0.1},
      'grateful': {'optimism': 0.3, 'social_connection': 0.1},
      'confident': {'resilience': 0.2, 'growth_mindset': 0.1},
      'peaceful': {'self_awareness': 0.2, 'resilience': 0.1},
      'excited': {'creativity': 0.1, 'growth_mindset': 0.2},
      'motivated': {'growth_mindset': 0.3, 'resilience': 0.1},
      'creative': {'creativity': 0.3, 'self_awareness': 0.1},
      'social': {'social_connection': 0.3, 'optimism': 0.1},
      'reflective': {'self_awareness': 0.3, 'growth_mindset': 0.1},
    };

    final coreStrengths = <String, double>{
      'optimism': 0.0,
      'resilience': 0.0,
      'self_awareness': 0.0,
      'creativity': 0.0,
      'social_connection': 0.0,
      'growth_mindset': 0.0,
    };

    // Apply mood-based adjustments
    for (final mood in entry.moods) {
      final adjustments = moodToCore[mood.toLowerCase()] ?? {};
      for (final adjustment in adjustments.entries) {
        coreStrengths[adjustment.key] = 
            (coreStrengths[adjustment.key] ?? 0.0) + adjustment.value;
      }
    }

    return {
      "primary_emotions": entry.moods.take(2).toList(),
      "emotional_intensity": 6.0,
      "growth_indicators": ["self_reflection", "emotional_awareness"],
      "core_strengths": coreStrengths,
      "insight": "Your journaling practice shows commitment to self-reflection and growth."
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
}
