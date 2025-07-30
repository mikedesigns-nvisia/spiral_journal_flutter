import 'dart:convert';
import 'dart:math';
import 'package:spiral_journal/models/journal_entry.dart';

/// Mock service for Haiku AI responses in tests  
/// Provides realistic but deterministic responses for testing
class MockHaikuService {
  static final Random _random = Random(42); // Fixed seed for deterministic tests

  /// Mock AI analysis response for a journal entry
  static Map<String, dynamic> generateMockAnalysis(JournalEntry entry) {
    final emotions = _selectMockEmotions(entry);
    final themes = _selectMockThemes(entry);
    final sentiment = _calculateMockSentiment(entry);
    final intensity = _calculateMockIntensity(entry);
    final cores = _generateMockCores(entry);
    final patterns = _generateMockPatterns(entry);
    final growth = _generateMockGrowth(entry);
    final insight = _generateMockInsight(entry, emotions, themes);

    return {
      "id": entry.id,
      "emotions": emotions,
      "intensity": intensity,
      "themes": themes,
      "sentiment": sentiment,
      "insight": insight,
      "cores": cores,
      "patterns": patterns,
      "growth": growth,
      "metadata": {
        "processedAt": DateTime.now().toIso8601String(),
        "model": "mock-haiku-v1",
        "confidence": _random.nextDouble() * 0.3 + 0.7, // 0.7-1.0
      }
    };
  }

  /// Generate mock batch analysis response
  static Map<String, dynamic> generateMockBatchResponse(List<JournalEntry> entries) {
    final analyses = entries.map((entry) => generateMockAnalysis(entry)).toList();
    
    return {
      'usage': {
        'input_tokens': _estimateInputTokens(entries),
        'output_tokens': _estimateOutputTokens(entries),
      },
      'content': [
        {
          'text': jsonEncode(analyses)
        }
      ],
      'metadata': {
        'batchSize': entries.length,
        'processedAt': DateTime.now().toIso8601String(),
        'model': 'mock-haiku-batch-v1',
      }
    };
  }

  /// Generate mock insight template response
  static String generateMockInsightFromTemplate(String templatePrompt, JournalEntry entry) {
    final templates = [
      "Your reflection on ${_getMainTheme(entry)} shows meaningful growth in self-awareness.",
      "The emotions you've expressed around ${_getMainMood(entry)} indicate positive development.",
      "Your journal entry reveals important insights about your personal journey.",
      "The patterns in your writing suggest strong emotional intelligence.",
      "Your ability to articulate these feelings demonstrates growing mindfulness.",
    ];
    
    return templates[_random.nextInt(templates.length)];
  }

  /// Select mock emotions based on entry content and moods
  static List<String> _selectMockEmotions(JournalEntry entry) {
    final possibleEmotions = [
      'hopeful', 'reflective', 'grateful', 'peaceful', 'curious',
      'determined', 'content', 'inspired', 'thoughtful', 'optimistic',
      'empowered', 'aware', 'balanced', 'focused', 'resilient'
    ];

    // If entry has moods, use some of them as emotions
    final emotions = <String>[];
    if (entry.moods.isNotEmpty) {
      emotions.addAll(entry.moods.take(2));
    }

    // Add random emotions to reach 2-3 total
    while (emotions.length < 3) {
      final emotion = possibleEmotions[_random.nextInt(possibleEmotions.length)];
      if (!emotions.contains(emotion)) {
        emotions.add(emotion);
      }
    }

    return emotions.take(3).toList();
  }

  /// Select mock themes based on entry content
  static List<String> _selectMockThemes(JournalEntry entry) {
    final content = entry.content.toLowerCase();
    final themes = <String>[];

    // Content-based theme detection
    if (content.contains(RegExp(r'\b(growth|learn|develop|improve)\b'))) {
      themes.add('personal-growth');
    }
    if (content.contains(RegExp(r'\b(friend|family|relationship|social)\b'))) {
      themes.add('relationships');
    }
    if (content.contains(RegExp(r'\b(work|career|job|project)\b'))) {
      themes.add('professional-development');
    }
    if (content.contains(RegExp(r'\b(feel|emotion|mood|mental)\b'))) {
      themes.add('emotional-awareness');
    }
    if (content.contains(RegExp(r'\b(challenge|difficult|problem|overcome)\b'))) {
      themes.add('resilience');
    }

    // Default themes if none detected
    if (themes.isEmpty) {
      themes.addAll(['self-reflection', 'daily-experience', 'mindfulness']);
    }

    return themes.take(3).toList();
  }

  /// Calculate mock sentiment score
  static double _calculateMockSentiment(JournalEntry entry) {
    final content = entry.content.toLowerCase();
    double sentiment = 0.0;

    // Positive words
    if (content.contains(RegExp(r'\b(good|great|happy|amazing|wonderful|grateful|love|joy)\b'))) {
      sentiment += 0.3;
    }
    if (content.contains(RegExp(r'\b(growth|learn|accomplish|success|proud|excited)\b'))) {
      sentiment += 0.2;
    }

    // Negative words
    if (content.contains(RegExp(r'\b(bad|terrible|sad|angry|frustrat|disappoint)\b'))) {
      sentiment -= 0.3;
    }
    if (content.contains(RegExp(r'\b(difficult|hard|challenge|problem|struggle)\b'))) {
      sentiment -= 0.1;
    }

    // Neutral adjustment based on moods
    for (final mood in entry.moods) {
      if (['happy', 'grateful', 'excited', 'proud'].contains(mood)) {
        sentiment += 0.1;
      } else if (['sad', 'angry', 'frustrated', 'worried'].contains(mood)) {
        sentiment -= 0.1;
      }
    }

    return (sentiment + (_random.nextDouble() - 0.5) * 0.2).clamp(-1.0, 1.0);
  }

  /// Calculate mock intensity score
  static double _calculateMockIntensity(JournalEntry entry) {
    final content = entry.content;
    double intensity = 0.3; // Base intensity

    // Length-based intensity
    if (content.length > 200) intensity += 0.2;
    if (content.length > 500) intensity += 0.2;

    // Exclamation marks and caps
    final exclamationCount = '!'.allMatches(content).length;
    intensity += (exclamationCount * 0.1).clamp(0.0, 0.3);

    // Emotional words
    if (content.toLowerCase().contains(RegExp(r'\b(amazing|incredible|terrible|overwhelm)\b'))) {
      intensity += 0.2;
    }

    return (intensity + (_random.nextDouble() - 0.5) * 0.1).clamp(0.0, 1.0);
  }

  /// Generate mock core scores
  static Map<String, double> _generateMockCores(JournalEntry entry) {
    final baseScores = {
      'optimism': 0.5,
      'resilience': 0.5,
      'self_awareness': 0.5,
      'creativity': 0.5,
      'social_connection': 0.5,
      'growth_mindset': 0.5,
    };

    final content = entry.content.toLowerCase();

    // Adjust scores based on content
    if (content.contains(RegExp(r'\b(positive|hopeful|good|bright)\b'))) {
      baseScores['optimism'] = (baseScores['optimism']! + 0.3).clamp(0.0, 1.0);
    }
    if (content.contains(RegExp(r'\b(overcome|challenge|strong|tough)\b'))) {
      baseScores['resilience'] = (baseScores['resilience']! + 0.3).clamp(0.0, 1.0);
    }
    if (content.contains(RegExp(r'\b(realize|understand|aware|reflect)\b'))) {
      baseScores['self_awareness'] = (baseScores['self_awareness']! + 0.3).clamp(0.0, 1.0);
    }
    if (content.contains(RegExp(r'\b(create|art|idea|innovative)\b'))) {
      baseScores['creativity'] = (baseScores['creativity']! + 0.3).clamp(0.0, 1.0);
    }
    if (content.contains(RegExp(r'\b(friend|family|people|social)\b'))) {
      baseScores['social_connection'] = (baseScores['social_connection']! + 0.3).clamp(0.0, 1.0);
    }
    if (content.contains(RegExp(r'\b(learn|grow|develop|improve)\b'))) {
      baseScores['growth_mindset'] = (baseScores['growth_mindset']! + 0.3).clamp(0.0, 1.0);
    }

    // Add some randomness for realistic variation
    baseScores.forEach((key, value) {
      baseScores[key] = (value + (_random.nextDouble() - 0.5) * 0.2).clamp(0.0, 1.0);
    });

    return baseScores;
  }

  /// Generate mock patterns
  static List<String> _generateMockPatterns(JournalEntry entry) {
    final patterns = <String>[];
    final content = entry.content.toLowerCase();

    if (content.contains(RegExp(r'\b(morning|start|begin)\b'))) {
      patterns.add('morning-reflection');
    }
    if (content.contains(RegExp(r'\b(plan|goal|future)\b'))) {
      patterns.add('future-planning');
    }
    if (content.contains(RegExp(r'\b(feel|emotion|mood)\b'))) {
      patterns.add('emotional-processing');
    }
    if (content.contains(RegExp(r'\b(grateful|thank|appreciate)\b'))) {
      patterns.add('gratitude-practice');
    }

    // Default patterns
    if (patterns.isEmpty) {
      patterns.addAll(['self-reflection', 'daily-processing']);
    }

    return patterns.take(3).toList();
  }

  /// Generate mock growth areas
  static List<String> _generateMockGrowth(JournalEntry entry) {
    final growth = <String>[];
    final themes = _selectMockThemes(entry);

    for (final theme in themes) {
      switch (theme) {
        case 'personal-growth':
          growth.add('self-development');
          break;
        case 'relationships':
          growth.add('interpersonal-skills');
          break;
        case 'emotional-awareness':
          growth.add('emotional-intelligence');
          break;
        case 'resilience':
          growth.add('stress-management');
          break;
        default:
          growth.add('mindfulness');
      }
    }

    return growth.take(3).toList();
  }

  /// Generate mock insight text
  static String _generateMockInsight(JournalEntry entry, List<String> emotions, List<String> themes) {
    final insights = [
      "Your reflection shows growth in ${themes.isNotEmpty ? themes.first : 'self-awareness'}.",
      "The ${emotions.isNotEmpty ? emotions.first : 'emotional'} tone suggests positive development.",
      "Your ability to articulate these feelings demonstrates mindfulness.",
      "This entry reveals important patterns in your personal journey.",
      "Your perspective on these experiences shows emotional maturity.",
    ];

    return insights[_random.nextInt(insights.length)];
  }

  /// Helper to get main theme from entry
  static String _getMainTheme(JournalEntry entry) {
    final themes = _selectMockThemes(entry);
    return themes.isNotEmpty ? themes.first.replaceAll('-', ' ') : 'personal growth';
  }

  /// Helper to get main mood from entry
  static String _getMainMood(JournalEntry entry) {
    return entry.moods.isNotEmpty ? entry.moods.first : 'your experiences';
  }

  /// Estimate input tokens for batch processing
  static int _estimateInputTokens(List<JournalEntry> entries) {
    final totalContentLength = entries.fold<int>(0, (sum, entry) => sum + entry.content.length);
    return (totalContentLength / 4).round() + 500; // +500 for batch prompt overhead
  }

  /// Estimate output tokens for batch processing
  static int _estimateOutputTokens(List<JournalEntry> entries) {
    return entries.length * 150; // ~150 tokens per analysis
  }

  /// Generate mock error response
  static Map<String, dynamic> generateMockError(String message) {
    return {
      'error': {
        'type': 'mock_error',
        'message': message,
        'code': 'TEST_ERROR',
      },
      'metadata': {
        'timestamp': DateTime.now().toIso8601String(),
        'model': 'mock-haiku-error',
      }
    };
  }

  /// Generate mock rate limit response
  static Map<String, dynamic> generateMockRateLimit() {
    return {
      'error': {
        'type': 'rate_limit_exceeded',
        'message': 'Rate limit exceeded. Please try again later.',
        'code': 'RATE_LIMIT',
        'retry_after': 60,
      },
      'metadata': {
        'timestamp': DateTime.now().toIso8601String(),
        'model': 'mock-haiku-rate-limit',
      }
    };
  }

  /// Check if content should trigger specific test scenarios
  static bool shouldTriggerError(String content) {
    return content.toLowerCase().contains('trigger_error');
  }

  static bool shouldTriggerRateLimit(String content) {
    return content.toLowerCase().contains('trigger_rate_limit');
  }

  static bool shouldTriggerTimeout(String content) {
    return content.toLowerCase().contains('trigger_timeout');
  }
}