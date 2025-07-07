import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/ai_analysis.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';

/// Claude AI service for analyzing journal entries and generating insights
class ClaudeAIService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-3-sonnet-20240229';
  
  final Dio _dio;
  final String _apiKey;

  ClaudeAIService({required String apiKey}) 
      : _apiKey = apiKey,
        _dio = Dio() {
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'x-api-key': _apiKey,
      'anthropic-version': '2023-06-01',
    };
  }

  /// Main analysis pipeline - transforms journal entry into comprehensive insights
  Future<AIAnalysis> analyzeJournalEntry({
    required JournalEntry entry,
    required String userId,
    Map<String, EmotionalCore>? currentCores,
    String? recentPatterns,
  }) async {
    try {
      // Multi-stage analysis for comprehensive insights
      final emotionalAnalysis = await _analyzeEmotions(entry.content);
      final cognitivePatterns = await _analyzeCognition(entry.content);
      final growthIndicators = await _analyzeGrowth(entry.content);
      final coreEvolution = await _calculateCoreChanges(
        entry.content, 
        currentCores ?? {}
      );
      final personalizedInsights = await _generateInsights(
        entry.content,
        recentPatterns ?? '',
      );

      return AIAnalysis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        entryId: entry.id,
        userId: userId,
        emotionalAnalysis: emotionalAnalysis,
        cognitivePatterns: cognitivePatterns,
        growthIndicators: growthIndicators,
        coreEvolution: coreEvolution,
        personalizedInsights: personalizedInsights,
        analyzedAt: DateTime.now(),
        confidence: 0.85, // Claude is generally high confidence
      );
    } catch (e) {
      throw AIAnalysisException('Failed to analyze journal entry: $e');
    }
  }

  /// Emotional intelligence analysis using Claude
  Future<EmotionalAnalysis> _analyzeEmotions(String text) async {
    final prompt = '''
You are an expert in emotional intelligence and psychology. Analyze this journal entry with deep empathy and insight.

Journal Entry: "$text"

Please provide a structured analysis in JSON format:
{
  "primary_emotions": ["list of 2-3 main emotions detected"],
  "emotional_intensity": "scale 1-10 with reasoning",
  "emotional_progression": "how emotions evolved throughout the entry",
  "emotional_complexity": "nuanced emotional states beyond basic categories",
  "coping_mechanisms": ["any strategies the person used"],
  "emotional_strengths": ["positive emotional patterns observed"],
  "gentle_observations": "kind, non-judgmental insights about emotional patterns"
}

Be compassionate, strengths-focused, and avoid clinical language. Focus on growth and resilience.
''';

    final response = await _sendMessage(prompt);
    final jsonResponse = _extractJsonFromResponse(response);
    return EmotionalAnalysis.fromJson(jsonResponse);
  }

  /// Cognitive pattern recognition analysis
  Future<CognitivePatterns> _analyzeCognition(String text) async {
    final prompt = '''
You are a cognitive behavioral therapy expert. Analyze thinking patterns in this journal entry.

Journal Entry: "$text"

Identify cognitive patterns in JSON format:
{
  "thinking_styles": ["problem-solving", "rumination", "creative", "analytical", etc.],
  "cognitive_strengths": ["positive thought patterns observed"],
  "growth_mindset_indicators": ["evidence of learning orientation"],
  "self_awareness_signs": ["instances of metacognition"],
  "problem_solving_approach": "how they approach challenges",
  "reframing_abilities": "evidence of perspective-taking",
  "cognitive_flexibility": "ability to see multiple viewpoints"
}

Focus on strengths and growth potential, not deficits.
''';

    final response = await _sendMessage(prompt);
    final jsonResponse = _extractJsonFromResponse(response);
    return CognitivePatterns.fromJson(jsonResponse);
  }

  /// Growth and development analysis
  Future<GrowthIndicators> _analyzeGrowth(String text) async {
    final prompt = '''
You are a personal development expert. Analyze this journal entry for signs of growth and learning.

Journal Entry: "$text"

Provide growth analysis in JSON format:
{
  "evidence_of_growth": ["specific examples of personal development"],
  "areas_of_development": ["gentle areas for continued growth"],
  "resilience_score": "scale 1-10 based on coping and adaptation",
  "self_compassion_level": "scale 1-10 based on self-kindness",
  "learning_orientation": "evidence of growth mindset and learning"
}

Be encouraging and focus on positive development trends.
''';

    final response = await _sendMessage(prompt);
    final jsonResponse = _extractJsonFromResponse(response);
    return GrowthIndicators.fromJson(jsonResponse);
  }

  /// Core personality evolution calculation
  Future<CoreEvolution> _calculateCoreChanges(
    String text, 
    Map<String, EmotionalCore> currentCores
  ) async {
    final coresContext = currentCores.entries
        .map((e) => '${e.key}: ${e.value.percentage}%')
        .join(', ');

    final prompt = '''
You are analyzing how this journal entry reflects growth in core personality dimensions.

Current Core Percentages: $coresContext
Journal Entry: "$text"

Based on this entry, suggest adjustments to these cores (can be +/- 1-3 points):

{
  "optimism": {
    "adjustment": 0,
    "reasoning": "why this adjustment"
  },
  "resilience": {
    "adjustment": 0,
    "reasoning": "evidence in the text"
  },
  "self_awareness": {
    "adjustment": 0,
    "reasoning": "metacognitive indicators"
  },
  "creativity": {
    "adjustment": 0,
    "reasoning": "creative expression or thinking"
  },
  "social_connection": {
    "adjustment": 0,
    "reasoning": "relationship patterns"
  },
  "growth_mindset": {
    "adjustment": 0,
    "reasoning": "learning orientation evidence"
  }
}

Be conservative with adjustments. Small, consistent changes over time create authentic growth tracking.
''';

    final response = await _sendMessage(prompt);
    final jsonResponse = _extractJsonFromResponse(response);
    return CoreEvolution.fromJson(jsonResponse);
  }

  /// Generate personalized insights and encouragement
  Future<PersonalizedInsights> _generateInsights(
    String text,
    String recentPatterns,
  ) async {
    final prompt = '''
You are a wise, caring mentor providing personalized insights to someone on their growth journey.

Recent patterns: $recentPatterns
Today's entry: "$text"

Generate encouraging, actionable insights:

{
  "pattern_recognition": "gentle observation about patterns (what I notice is...)",
  "strength_celebration": "specific strength you observed in this entry",
  "growth_acknowledgment": "evidence of personal development",
  "gentle_suggestion": "one small, actionable insight or invitation",
  "connection_to_journey": "how this entry fits their broader growth story",
  "encouragement": "warm, specific encouragement based on their writing"
}

Tone: Warm, wise friend who truly sees and believes in them. Avoid therapy-speak.
''';

    final response = await _sendMessage(prompt);
    final jsonResponse = _extractJsonFromResponse(response);
    return PersonalizedInsights.fromJson(jsonResponse);
  }

  /// Send message to Claude API
  Future<String> _sendMessage(String prompt) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        data: {
          'model': _model,
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['content'][0]['text'] as String;
        return content;
      } else {
        throw AIAnalysisException('Claude API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw AIAnalysisException('Network error: ${e.message}');
    }
  }

  /// Extract JSON from Claude's response (handles cases where Claude adds explanation text)
  Map<String, dynamic> _extractJsonFromResponse(String response) {
    try {
      // First try to parse the entire response as JSON
      return json.decode(response);
    } catch (e) {
      // If that fails, try to extract JSON from the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        try {
          return json.decode(jsonMatch.group(0)!);
        } catch (e) {
          // If JSON parsing still fails, return a default structure
          print('Failed to parse JSON from Claude response: $response');
          return {};
        }
      }
      
      // Fallback: return empty structure
      print('No JSON found in Claude response: $response');
      return {};
    }
  }
}

/// Exception thrown when AI analysis fails
class AIAnalysisException implements Exception {
  final String message;
  
  AIAnalysisException(this.message);
  
  @override
  String toString() => 'AIAnalysisException: $message';
}

/// Configuration class for Claude AI service
class ClaudeConfig {
  static const String defaultModel = 'claude-3-sonnet-20240229';
  static const int defaultMaxTokens = 1000;
  static const double defaultTemperature = 0.7;
  
  // Rate limiting - Claude has generous limits but good to be respectful
  static const int maxRequestsPerMinute = 50;
  static const Duration analysisTimeout = Duration(seconds: 30);
}
