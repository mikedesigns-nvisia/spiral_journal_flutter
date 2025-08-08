import 'package:flutter/foundation.dart';
import '../../models/journal_entry.dart';
import '../../models/core.dart';
import '../ai_service_interface.dart';
import '../ai_service_error_tracker.dart';

class FallbackProvider implements AIServiceInterface {
  // Config not needed for fallback provider but kept for interface consistency
  // ignore: unused_field
  final AIServiceConfig _config;

  FallbackProvider(this._config);

  @override
  AIProvider get provider => AIProvider.disabled;

  @override
  bool get isConfigured => true; // Always configured

  @override
  bool get isEnabled => true; // Always enabled

  @override
  Future<void> setApiKey(String apiKey) async {
    // No API key needed for fallback
  }

  @override
  Future<void> testConnection() async {
    // Always passes
  }

  @override
  Future<Map<String, dynamic>> analyzeJournalEntry(JournalEntry entry) async {
    try {
      debugPrint('📝 FallbackProvider: Analyzing journal entry ${entry.id} with basic analysis');
      
      // Log that we're using fallback analysis
      AIServiceErrorTracker.logFallback(
        'Using fallback analysis for journal entry',
        'ClaudeAIProvider',
        context: {
          'entryId': entry.id,
          'entryLength': entry.content.length,
          'moods': entry.moods,
          'reason': 'AI service unavailable',
        },
      );
      
      // Simple mood-based analysis with simulated processing time
      await Future.delayed(const Duration(milliseconds: 200));
      final result = _analyzeEntry(entry);
      
      debugPrint('✅ FallbackProvider: Basic analysis completed for entry ${entry.id}');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ FallbackProvider analyzeJournalEntry error: $e');
      AIServiceErrorTracker.logError(
        'analyzeJournalEntry',
        e,
        stackTrace: stackTrace,
        context: {
          'entryId': entry.id,
          'entryLength': entry.content.length,
          'moods': entry.moods,
        },
        provider: 'FallbackProvider',
      );
      // Return basic analysis even if there's an error
      return _getBasicAnalysis(entry);
    }
  }

  @override
  Future<String> generateMonthlyInsight(List<JournalEntry> entries) async {
    try {
      debugPrint('📊 FallbackProvider: Generating monthly insight for ${entries.length} entries');
      
      // Log that we're using fallback for monthly insights
      AIServiceErrorTracker.logFallback(
        'Using fallback analysis for monthly insight',
        'ClaudeAIProvider',
        context: {
          'entriesCount': entries.length,
          'reason': 'AI service unavailable',
        },
      );
      
      await Future.delayed(const Duration(milliseconds: 300));
      final result = _generateInsight(entries);
      
      debugPrint('✅ FallbackProvider: Monthly insight generated');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ FallbackProvider generateMonthlyInsight error: $e');
      AIServiceErrorTracker.logError(
        'generateMonthlyInsight',
        e,
        stackTrace: stackTrace,
        context: {
          'entriesCount': entries.length,
        },
        provider: 'FallbackProvider',
      );
      // Return basic insight even if there's an error
      return _getBasicInsight(entries);
    }
  }

  @override
  Future<Map<String, double>> calculateCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
  ) async {
    try {
      debugPrint('🎯 FallbackProvider: Calculating core updates for entry ${entry.id}');
      
      // Log that we're using fallback for core updates
      AIServiceErrorTracker.logFallback(
        'Using fallback analysis for core updates',
        'ClaudeAIProvider',
        context: {
          'entryId': entry.id,
          'coresCount': currentCores.length,
          'reason': 'AI service unavailable',
        },
      );
      
      final analysis = await analyzeJournalEntry(entry);
      final result = _mapAnalysisToCoreUpdates(analysis, currentCores);
      
      debugPrint('✅ FallbackProvider: Core updates calculated: ${result.length} cores affected');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ FallbackProvider calculateCoreUpdates error: $e');
      AIServiceErrorTracker.logError(
        'calculateCoreUpdates',
        e,
        stackTrace: stackTrace,
        context: {
          'entryId': entry.id,
          'coresCount': currentCores.length,
        },
        provider: 'FallbackProvider',
      );
      // Return minimal core updates even if there's an error
      return _getBasicCoreUpdates(entry, currentCores);
    }
  }

  // Private methods
  Map<String, dynamic> _analyzeEntry(JournalEntry entry) {
    final moodToCore = {
      'happy': {'optimism': 0.3, 'self_awareness': 0.1},
      'content': {'self_awareness': 0.3, 'optimism': 0.1},
      'energetic': {'creativity': 0.3, 'growth_mindset': 0.1},
      'grateful': {'optimism': 0.4, 'social_connection': 0.2},
      'confident': {'resilience': 0.3, 'growth_mindset': 0.2},
      'peaceful': {'self_awareness': 0.3, 'resilience': 0.1},
      'excited': {'creativity': 0.2, 'growth_mindset': 0.3},
      'motivated': {'growth_mindset': 0.4, 'resilience': 0.1},
      'creative': {'creativity': 0.4, 'self_awareness': 0.1},
      'social': {'social_connection': 0.4, 'optimism': 0.1},
      'reflective': {'self_awareness': 0.4, 'growth_mindset': 0.1},
      'tired': {'resilience': -0.1, 'self_awareness': 0.1},
      'stressed': {'resilience': 0.1, 'self_awareness': 0.2},
      'sad': {'resilience': 0.2, 'self_awareness': 0.2},
      'unsure': {'self_awareness': 0.2, 'growth_mindset': 0.1},
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

    // Content-based analysis (simple keyword matching)
    final content = entry.content.toLowerCase();
    final contentAnalysis = _analyzeContent(content);
    
    // Merge content analysis with mood analysis
    for (final adjustment in contentAnalysis.entries) {
      coreStrengths[adjustment.key] = 
          (coreStrengths[adjustment.key] ?? 0.0) + adjustment.value;
    }

    // Generate insight based on moods and content
    final insight = _generateEntryInsight(entry, coreStrengths);

    // Generate fallback insights based on content analysis
    final insights = _generateFallbackInsights(entry);

    return {
      "primary_emotions": entry.moods.take(2).toList(),
      "emotional_intensity": _calculateIntensity(entry),
      "growth_indicators": _identifyGrowthIndicators(entry),
      "core_adjustments": _convertToNewCoreFormat(coreStrengths),
      "mind_reflection": {
        "title": "Emotional Pattern Analysis",
        "summary": _generateEntrySummary(entry),
        "insights": insights,
      },
      "emotional_patterns": [
        {
          "category": "Growth",
          "title": _getPatternTitle(entry),
          "description": _getPatternDescription(entry),
          "type": "growth"
        }
      ],
      "entry_insight": insight,
    };
  }

  Map<String, double> _analyzeContent(String content) {
    final adjustments = <String, double>{
      'optimism': 0.0,
      'resilience': 0.0,
      'self_awareness': 0.0,
      'creativity': 0.0,
      'social_connection': 0.0,
      'growth_mindset': 0.0,
    };

    // Positive keywords
    final positiveWords = ['amazing', 'wonderful', 'great', 'awesome', 'fantastic', 'love', 'joy', 'happy', 'excited'];
    final resilientWords = ['overcome', 'challenge', 'difficult', 'persevere', 'strength', 'tough', 'handle'];
    final reflectiveWords = ['think', 'feel', 'realize', 'understand', 'learn', 'reflect', 'consider'];
    final creativeWords = ['create', 'design', 'art', 'music', 'write', 'imagine', 'idea', 'inspiration'];
    final socialWords = ['friend', 'family', 'together', 'share', 'connect', 'relationship', 'love'];
    final growthWords = ['learn', 'grow', 'improve', 'better', 'develop', 'progress', 'goal'];

    for (final word in positiveWords) {
      if (content.contains(word)) {
        adjustments['optimism'] = (adjustments['optimism'] ?? 0.0) + 0.1;
      }
    }

    for (final word in resilientWords) {
      if (content.contains(word)) {
        adjustments['resilience'] = (adjustments['resilience'] ?? 0.0) + 0.1;
      }
    }

    for (final word in reflectiveWords) {
      if (content.contains(word)) {
        adjustments['self_awareness'] = (adjustments['self_awareness'] ?? 0.0) + 0.1;
      }
    }

    for (final word in creativeWords) {
      if (content.contains(word)) {
        adjustments['creativity'] = (adjustments['creativity'] ?? 0.0) + 0.1;
      }
    }

    for (final word in socialWords) {
      if (content.contains(word)) {
        adjustments['social_connection'] = (adjustments['social_connection'] ?? 0.0) + 0.1;
      }
    }

    for (final word in growthWords) {
      if (content.contains(word)) {
        adjustments['growth_mindset'] = (adjustments['growth_mindset'] ?? 0.0) + 0.1;
      }
    }

    return adjustments;
  }

  double _calculateIntensity(JournalEntry entry) {
    final intenseMoods = ['excited', 'energetic', 'stressed', 'sad', 'angry'];
    final mildMoods = ['content', 'peaceful', 'calm', 'relaxed'];
    
    double intensity = 5.0; // Base intensity
    
    for (final mood in entry.moods) {
      if (intenseMoods.contains(mood.toLowerCase())) {
        intensity += 1.0;
      } else if (mildMoods.contains(mood.toLowerCase())) {
        intensity -= 0.5;
      }
    }
    
    // Content length can indicate intensity
    final wordCount = entry.content.split(' ').length;
    if (wordCount > 100) {
      intensity += 0.5;
    }
    
    return intensity.clamp(1.0, 10.0);
  }

  List<String> _identifyGrowthIndicators(JournalEntry entry) {
    final indicators = <String>[];
    final content = entry.content.toLowerCase();
    
    if (content.contains('learn') || content.contains('understand')) {
      indicators.add('learning_orientation');
    }
    
    if (content.contains('feel') || content.contains('realize')) {
      indicators.add('self_awareness');
    }
    
    if (content.contains('challenge') || content.contains('difficult')) {
      indicators.add('resilience_building');
    }
    
    if (content.contains('goal') || content.contains('plan')) {
      indicators.add('goal_setting');
    }
    
    if (content.contains('grateful') || content.contains('thankful')) {
      indicators.add('gratitude_practice');
    }
    
    if (indicators.isEmpty) {
      indicators.add('self_reflection');
    }
    
    return indicators;
  }

  String _generateEntryInsight(JournalEntry entry, Map<String, double> coreStrengths) {
    final strongestCore = coreStrengths.entries
        .where((e) => e.value > 0)
        .fold<MapEntry<String, double>?>(null, (prev, curr) => 
            prev == null || curr.value > prev.value ? curr : prev);
    
    if (strongestCore != null) {
      final coreName = strongestCore.key.replaceAll('_', ' ');
      return "This entry shows growth in your $coreName. Your willingness to reflect and share your experiences demonstrates emotional maturity.";
    }
    
    if (entry.moods.isNotEmpty) {
      final mood = entry.moods.first;
      return "Your $mood mood today reflects your emotional awareness. Continuing to journal will help you understand these patterns better.";
    }
    
    return "Thank you for taking time to reflect and journal. This practice of self-awareness is valuable for your personal growth.";
  }

  String _generateInsight(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return "No entries this month. Consider starting a regular journaling practice to track your emotional journey and personal growth!";
    }

    if (entries.length == 1) {
      return "Great start with your first entry! One entry is the beginning of a meaningful self-reflection journey. Try to journal regularly to see patterns emerge.";
    }

    final totalWords = entries.fold(0, (sum, entry) => sum + entry.content.split(' ').length);
    final avgWordsPerEntry = totalWords / entries.length;
    
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      for (final mood in entry.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    final topMood = moodCounts.entries.isNotEmpty 
        ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'reflective';

    if (entries.length >= 10) {
      return "Excellent consistency with ${entries.length} entries this month! Your dominant mood was '$topMood', and you averaged ${avgWordsPerEntry.round()} words per entry. This level of self-reflection shows real commitment to personal growth.";
    } else if (entries.length >= 5) {
      return "Good progress with ${entries.length} entries this month. Your '$topMood' mood appeared most frequently, showing emotional patterns. Keep up the regular journaling to deepen your self-awareness!";
    } else {
      return "You've made ${entries.length} entries this month with '$topMood' being your most common mood. Try to journal more regularly to better understand your emotional patterns and growth.";
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

  // Helper methods for new analysis structure
  Map<String, double> _convertToNewCoreFormat(Map<String, double> oldFormat) {
    return {
      'Optimism': oldFormat['optimism'] ?? 0.0,
      'Resilience': oldFormat['resilience'] ?? 0.0,
      'Self-Awareness': oldFormat['self_awareness'] ?? 0.0,
      'Creativity': oldFormat['creativity'] ?? 0.0,
      'Social Connection': oldFormat['social_connection'] ?? 0.0,
      'Growth Mindset': oldFormat['growth_mindset'] ?? 0.0,
    };
  }

  List<String> _generateFallbackInsights(JournalEntry entry) {
    final insights = <String>[];
    final content = entry.content.toLowerCase();
    
    if (entry.moods.any((m) => ['grateful', 'thankful', 'blessed'].contains(m.toLowerCase())) ||
        content.contains('thank') || content.contains('grateful')) {
      insights.add('Gratitude practices are strengthening');
    }
    
    if (entry.moods.any((m) => ['confident', 'strong', 'resilient'].contains(m.toLowerCase())) ||
        content.contains('challenge') || content.contains('overcome')) {
      insights.add('Resilience building through challenges');
    }
    
    if (entry.moods.any((m) => ['reflective', 'thoughtful', 'aware'].contains(m.toLowerCase())) ||
        content.contains('feel') || content.contains('realize')) {
      insights.add('Self-awareness deepening through reflection');
    }
    
    if (entry.moods.any((m) => ['creative', 'inspired', 'artistic'].contains(m.toLowerCase())) ||
        content.contains('create') || content.contains('idea')) {
      insights.add('Creative expression emerging');
    }
    
    if (entry.moods.any((m) => ['social', 'connected', 'loved'].contains(m.toLowerCase())) ||
        content.contains('friend') || content.contains('family')) {
      insights.add('Social connections strengthening');
    }
    
    if (insights.isEmpty) {
      insights.add('Emotional awareness developing through journaling');
    }
    
    return insights.take(3).toList();
  }

  String _generateEntrySummary(JournalEntry entry) {
    if (entry.moods.isEmpty) {
      return 'Your journaling practice shows consistent emotional awareness and personal growth.';
    }
    
    final dominantMood = entry.moods.first.toLowerCase();
    switch (dominantMood) {
      case 'happy':
      case 'joyful':
      case 'excited':
        return 'Your positive emotional state reflects growing optimism and life satisfaction.';
      case 'grateful':
      case 'thankful':
        return 'Your gratitude practice is strengthening emotional resilience and well-being.';
      case 'reflective':
      case 'thoughtful':
        return 'Your introspective nature is deepening self-awareness and emotional intelligence.';
      case 'confident':
      case 'strong':
        return 'Your confidence shows growing resilience and self-assurance.';
      case 'creative':
      case 'inspired':
        return 'Your creative energy reflects expanding imagination and innovative thinking.';
      default:
        return 'Your emotional awareness through journaling supports continued personal growth.';
    }
  }

  String _getPatternTitle(JournalEntry entry) {
    if (entry.content.split(' ').length > 100) {
      return 'Deep Self-Reflection';
    } else if (entry.moods.length > 2) {
      return 'Complex Emotional Awareness';
    } else {
      return 'Consistent Self-Reflection';
    }
  }

  String _getPatternDescription(JournalEntry entry) {
    if (entry.content.split(' ').length > 100) {
      return 'Detailed journaling shows commitment to thorough self-exploration';
    } else if (entry.moods.length > 2) {
      return 'Multiple mood selections indicate nuanced emotional awareness';
    } else {
      return 'Regular journaling is building emotional intelligence';
    }
  }

  // Basic error fallback methods
  Map<String, dynamic> _getBasicAnalysis(JournalEntry entry) {
    return {
      "primary_emotions": entry.moods.isNotEmpty ? [entry.moods.first] : ["neutral"],
      "emotional_intensity": 5.0,
      "growth_indicators": ["self_reflection"],
      "core_adjustments": {
        'Optimism': 0.0,
        'Resilience': 0.0,
        'Self-Awareness': 0.1,
        'Creativity': 0.0,
        'Social Connection': 0.0,
        'Growth Mindset': 0.0,
      },
      "mind_reflection": {
        "title": "Basic Analysis",
        "summary": "Thank you for journaling. This practice supports your emotional growth.",
        "insights": ["Self-reflection is valuable for personal development"],
      },
      "emotional_patterns": [
        {
          "category": "Growth",
          "title": "Journaling Practice",
          "description": "Building emotional awareness through writing",
          "type": "growth"
        }
      ],
      "entry_insight": "Thank you for taking time to reflect and journal.",
    };
  }

  String _getBasicInsight(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return "Consider starting a regular journaling practice for personal growth.";
    }
    return "Your journaling practice shows commitment to self-reflection and emotional awareness.";
  }

  Map<String, double> _getBasicCoreUpdates(JournalEntry entry, List<EmotionalCore> currentCores) {
    final updates = <String, double>{};
    
    // Give a small self-awareness boost for any journaling
    for (final core in currentCores) {
      if (core.name == 'Self-Awareness') {
        final newPercentage = (core.percentage + 0.1).clamp(0.0, 100.0);
        updates[core.id] = newPercentage;
        break;
      }
    }
    
    return updates;
  }
}