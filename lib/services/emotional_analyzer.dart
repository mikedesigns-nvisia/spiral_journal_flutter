import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';

/// Service for analyzing emotional patterns and extracting structured insights from AI responses.
/// 
/// This service processes raw AI analysis results and converts them into structured data
/// that can be used to update emotional cores, identify patterns, and generate insights.
class EmotionalAnalyzer {
  static final EmotionalAnalyzer _instance = EmotionalAnalyzer._internal();
  factory EmotionalAnalyzer() => _instance;
  EmotionalAnalyzer._internal();

  // Cache for recent analysis results to improve performance
  final Map<String, EmotionalAnalysisResult> _analysisCache = {};
  static const int _maxCacheSize = 100;

  /// Process AI analysis response into structured emotional analysis
  EmotionalAnalysisResult processAnalysis(
    Map<String, dynamic> aiResponse,
    JournalEntry entry,
  ) {
    try {
      return EmotionalAnalysisResult(
        primaryEmotions: _extractPrimaryEmotions(aiResponse),
        emotionalIntensity: _extractEmotionalIntensity(aiResponse),
        keyThemes: _extractKeyThemes(aiResponse),
        overallSentiment: _calculateOverallSentiment(aiResponse, entry),
        personalizedInsight: _extractPersonalizedInsight(aiResponse),
        coreImpacts: _extractCoreImpacts(aiResponse),
        emotionalPatterns: _extractEmotionalPatterns(aiResponse),
        growthIndicators: _extractGrowthIndicators(aiResponse),
        validationScore: _calculateValidationScore(aiResponse),
      );
    } catch (e) {
      debugPrint('EmotionalAnalyzer processAnalysis error: $e');
      return _createFallbackAnalysis(entry);
    }
  }

  /// Validate and sanitize AI analysis results before storage
  bool validateAnalysisResult(EmotionalAnalysisResult result) {
    try {
      // Check required fields
      if (result.primaryEmotions.isEmpty) return false;
      if (result.emotionalIntensity < 0 || result.emotionalIntensity > 10) return false;
      if (result.overallSentiment < -1 || result.overallSentiment > 1) return false;
      if (result.personalizedInsight.isEmpty) return false;

      // Validate core impacts
      for (final impact in result.coreImpacts.values) {
        if (impact < -1.0 || impact > 1.0) return false;
      }

      // Check validation score
      if (result.validationScore < 0.0 || result.validationScore > 1.0) return false;

      return true;
    } catch (e) {
      debugPrint('EmotionalAnalyzer validateAnalysisResult error: $e');
      return false;
    }
  }

  /// Sanitize analysis result by removing potentially harmful content
  EmotionalAnalysisResult sanitizeAnalysisResult(EmotionalAnalysisResult result) {
    try {
      return EmotionalAnalysisResult(
        primaryEmotions: result.primaryEmotions
            .map((emotion) => _sanitizeText(emotion))
            .where((emotion) => emotion.isNotEmpty)
            .take(5) // Limit to 5 emotions max
            .toList(),
        emotionalIntensity: result.emotionalIntensity.clamp(0.0, 10.0),
        keyThemes: result.keyThemes
            .map((theme) => _sanitizeText(theme))
            .where((theme) => theme.isNotEmpty)
            .take(5) // Limit to 5 themes max
            .toList(),
        overallSentiment: result.overallSentiment.clamp(-1.0, 1.0),
        personalizedInsight: _sanitizeText(result.personalizedInsight, maxLength: 500),
        coreImpacts: result.coreImpacts.map((key, value) => 
            MapEntry(key, value.clamp(-1.0, 1.0))),
        emotionalPatterns: result.emotionalPatterns
            .map((pattern) => EmotionalPattern(
              title: _sanitizeText(pattern.title),
              description: _sanitizeText(pattern.description, maxLength: 200),
              type: pattern.type,
              category: _sanitizeText(pattern.category),
              confidence: pattern.confidence,
              firstDetected: pattern.firstDetected,
              lastSeen: pattern.lastSeen,
              relatedEmotions: pattern.relatedEmotions,
            ))
            .take(3) // Limit to 3 patterns max
            .toList(),
        growthIndicators: result.growthIndicators
            .map((indicator) => _sanitizeText(indicator))
            .where((indicator) => indicator.isNotEmpty)
            .take(5) // Limit to 5 indicators max
            .toList(),
        validationScore: result.validationScore.clamp(0.0, 1.0),
      );
    } catch (e) {
      debugPrint('EmotionalAnalyzer sanitizeAnalysisResult error: $e');
      return result; // Return original if sanitization fails
    }
  }

  /// Extract emotional patterns from multiple journal entries
  List<EmotionalPattern> identifyPatterns(List<JournalEntry> entries) {
    if (entries.isEmpty) return [];

    try {
      final patterns = <EmotionalPattern>[];

      // Analyze mood frequency patterns
      final moodFrequency = _analyzeMoodFrequency(entries);
      if (moodFrequency.isNotEmpty) {
        patterns.add(_createMoodPattern(moodFrequency));
      }

      // Analyze temporal patterns
      final temporalPattern = _analyzeTemporalPatterns(entries);
      if (temporalPattern != null) {
        patterns.add(temporalPattern);
      }

      // Analyze content length patterns
      final lengthPattern = _analyzeContentLengthPatterns(entries);
      if (lengthPattern != null) {
        patterns.add(lengthPattern);
      }

      // Analyze emotional intensity patterns
      final intensityPattern = _analyzeIntensityPatterns(entries);
      if (intensityPattern != null) {
        patterns.add(intensityPattern);
      }

      return patterns.take(5).toList(); // Limit to 5 patterns
    } catch (e) {
      debugPrint('EmotionalAnalyzer identifyPatterns error: $e');
      return [];
    }
  }

  /// Cache analysis result for improved performance
  void cacheAnalysisResult(String entryId, EmotionalAnalysisResult result) {
    try {
      if (_analysisCache.length >= _maxCacheSize) {
        // Remove oldest entry
        final oldestKey = _analysisCache.keys.first;
        _analysisCache.remove(oldestKey);
      }
      _analysisCache[entryId] = result;
    } catch (e) {
      debugPrint('EmotionalAnalyzer cacheAnalysisResult error: $e');
    }
  }

  /// Get cached analysis result if available
  EmotionalAnalysisResult? getCachedAnalysisResult(String entryId) {
    try {
      return _analysisCache[entryId];
    } catch (e) {
      debugPrint('EmotionalAnalyzer getCachedAnalysisResult error: $e');
      return null;
    }
  }

  /// Clear analysis cache
  void clearCache() {
    _analysisCache.clear();
  }

  /// Process and cache analysis result
  EmotionalAnalysisResult processAndCacheAnalysis(
    Map<String, dynamic> aiResponse,
    JournalEntry entry,
  ) {
    try {
      // Check cache first
      final cached = getCachedAnalysisResult(entry.id);
      if (cached != null) {
        return cached;
      }

      // Process new analysis
      final result = processAnalysis(aiResponse, entry);
      
      // Validate and sanitize
      if (validateAnalysisResult(result)) {
        final sanitized = sanitizeAnalysisResult(result);
        cacheAnalysisResult(entry.id, sanitized);
        return sanitized;
      } else {
        // Return fallback if validation fails
        final fallback = _createFallbackAnalysis(entry);
        cacheAnalysisResult(entry.id, fallback);
        return fallback;
      }
    } catch (e) {
      debugPrint('EmotionalAnalyzer processAndCacheAnalysis error: $e');
      final fallback = _createFallbackAnalysis(entry);
      cacheAnalysisResult(entry.id, fallback);
      return fallback;
    }
  }

  /// Analyze emotional trends over time
  Map<String, dynamic> analyzeEmotionalTrends(List<JournalEntry> entries) {
    if (entries.isEmpty) return {};

    try {
      // Sort entries by date
      final sortedEntries = List<JournalEntry>.from(entries)
        ..sort((a, b) => a.date.compareTo(b.date));

      // Calculate trend metrics
      final moodTrends = _calculateMoodTrends(sortedEntries);
      final intensityTrend = _calculateIntensityTrend(sortedEntries);
      final sentimentTrend = _calculateSentimentTrend(sortedEntries);
      
      return {
        'mood_trends': moodTrends,
        'intensity_trend': intensityTrend,
        'sentiment_trend': sentimentTrend,
        'total_entries': entries.length,
        'date_range': {
          'start': sortedEntries.first.date.toIso8601String(),
          'end': sortedEntries.last.date.toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('EmotionalAnalyzer analyzeEmotionalTrends error: $e');
      return {};
    }
  }

  // Private methods

  List<String> _extractPrimaryEmotions(Map<String, dynamic> response) {
    try {
      if (response.containsKey('emotional_analysis')) {
        final analysis = response['emotional_analysis'] as Map<String, dynamic>;
        final emotions = analysis['primary_emotions'] as List<dynamic>?;
        return emotions?.cast<String>() ?? [];
      }
      
      // Fallback to legacy format
      final emotions = response['primary_emotions'] as List<dynamic>?;
      return emotions?.cast<String>() ?? ['neutral'];
    } catch (e) {
      return ['neutral'];
    }
  }

  double _extractEmotionalIntensity(Map<String, dynamic> response) {
    try {
      if (response.containsKey('emotional_analysis')) {
        final analysis = response['emotional_analysis'] as Map<String, dynamic>;
        final intensity = analysis['emotional_intensity'] as num?;
        return (intensity?.toDouble() ?? 5.0) * 10; // Convert 0-1 to 0-10 scale
      }
      
      // Fallback to legacy format
      final intensity = response['emotional_intensity'] as num?;
      return intensity?.toDouble() ?? 5.0;
    } catch (e) {
      return 5.0;
    }
  }

  List<String> _extractKeyThemes(Map<String, dynamic> response) {
    try {
      if (response.containsKey('emotional_analysis')) {
        final analysis = response['emotional_analysis'] as Map<String, dynamic>;
        final themes = analysis['key_themes'] as List<dynamic>?;
        return themes?.cast<String>() ?? [];
      }
      
      // Fallback to legacy format
      final indicators = response['growth_indicators'] as List<dynamic>?;
      return indicators?.cast<String>() ?? ['self_reflection'];
    } catch (e) {
      return ['self_reflection'];
    }
  }

  double _calculateOverallSentiment(Map<String, dynamic> response, JournalEntry entry) {
    try {
      if (response.containsKey('emotional_analysis')) {
        final analysis = response['emotional_analysis'] as Map<String, dynamic>;
        final sentiment = analysis['overall_sentiment'] as num?;
        return sentiment?.toDouble() ?? 0.0;
      }
      
      // Calculate from emotions and content
      final emotions = _extractPrimaryEmotions(response);
      final positiveEmotions = ['happy', 'joyful', 'excited', 'grateful', 'content', 'peaceful'];
      final negativeEmotions = ['sad', 'angry', 'frustrated', 'anxious', 'worried'];
      
      double sentiment = 0.0;
      for (final emotion in emotions) {
        if (positiveEmotions.contains(emotion.toLowerCase())) {
          sentiment += 0.3;
        } else if (negativeEmotions.contains(emotion.toLowerCase())) {
          sentiment -= 0.3;
        }
      }
      
      // Adjust based on content analysis
      final content = entry.content.toLowerCase();
      if (content.contains('grateful') || content.contains('thankful')) sentiment += 0.2;
      if (content.contains('love') || content.contains('amazing')) sentiment += 0.2;
      if (content.contains('difficult') || content.contains('hard')) sentiment -= 0.1;
      
      return sentiment.clamp(-1.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  String _extractPersonalizedInsight(Map<String, dynamic> response) {
    try {
      if (response.containsKey('emotional_analysis')) {
        final analysis = response['emotional_analysis'] as Map<String, dynamic>;
        return analysis['personalized_insight'] as String? ?? '';
      }
      
      // Fallback to legacy format
      return response['entry_insight'] as String? ?? 
             response['insight'] as String? ?? 
             'Thank you for taking time to reflect and journal.';
    } catch (e) {
      return 'Thank you for taking time to reflect and journal.';
    }
  }

  Map<String, double> _extractCoreImpacts(Map<String, dynamic> response) {
    try {
      // Try new format first
      if (response.containsKey('core_updates')) {
        final coreUpdates = response['core_updates'] as List<dynamic>;
        final impacts = <String, double>{};
        
        for (final update in coreUpdates) {
          final coreMap = update as Map<String, dynamic>;
          final name = coreMap['name'] as String;
          final trend = coreMap['trend'] as String;
          
          // Convert trend to impact value
          double impact = 0.0;
          switch (trend) {
            case 'rising':
              impact = 0.2;
              break;
            case 'declining':
              impact = -0.1;
              break;
            case 'stable':
            default:
              impact = 0.0;
              break;
          }
          
          impacts[name] = impact;
        }
        
        return impacts;
      }
      
      // Fallback to legacy format
      final coreAdjustments = response['core_adjustments'] as Map<String, dynamic>?;
      if (coreAdjustments != null) {
        return coreAdjustments.map((key, value) => 
            MapEntry(key, (value as num).toDouble()));
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }

  List<EmotionalPattern> _extractEmotionalPatterns(Map<String, dynamic> response) {
    try {
      final patterns = response['emotional_patterns'] as List<dynamic>?;
      if (patterns != null) {
        return patterns.map((pattern) {
          final patternMap = pattern as Map<String, dynamic>;
          return EmotionalPattern(
            title: patternMap['title'] as String? ?? 'Emotional Development',
            description: patternMap['description'] as String? ?? 'Developing emotional awareness',
            type: patternMap['type'] as String? ?? 'growth',
            category: patternMap['category'] as String? ?? 'Growth',
            confidence: (patternMap['confidence'] as num?)?.toDouble() ?? 0.7,
            firstDetected: patternMap['firstDetected'] != null 
                ? DateTime.parse(patternMap['firstDetected'])
                : DateTime.now(),
            lastSeen: patternMap['lastSeen'] != null 
                ? DateTime.parse(patternMap['lastSeen'])
                : DateTime.now(),
            relatedEmotions: patternMap['relatedEmotions'] != null 
                ? List<String>.from(patternMap['relatedEmotions'])
                : [],
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  List<String> _extractGrowthIndicators(Map<String, dynamic> response) {
    try {
      final indicators = response['growth_indicators'] as List<dynamic>?;
      return indicators?.cast<String>() ?? ['self_reflection'];
    } catch (e) {
      return ['self_reflection'];
    }
  }

  double _calculateValidationScore(Map<String, dynamic> response) {
    try {
      double score = 0.0;
      
      // Check for required fields
      if (response.containsKey('primary_emotions')) score += 0.2;
      if (response.containsKey('emotional_intensity')) score += 0.2;
      if (response.containsKey('entry_insight') || response.containsKey('insight')) score += 0.2;
      if (response.containsKey('core_adjustments') || response.containsKey('core_updates')) score += 0.2;
      if (response.containsKey('growth_indicators')) score += 0.2;
      
      return score.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5; // Medium confidence if validation fails
    }
  }

  EmotionalAnalysisResult _createFallbackAnalysis(JournalEntry entry) {
    return EmotionalAnalysisResult(
      primaryEmotions: entry.moods.isNotEmpty ? [entry.moods.first] : ['neutral'],
      emotionalIntensity: 5.0,
      keyThemes: ['self_reflection'],
      overallSentiment: 0.0,
      personalizedInsight: 'Thank you for taking time to reflect and journal.',
      coreImpacts: {'Self-Awareness': 0.1},
      emotionalPatterns: [
        EmotionalPattern(
          title: 'Journaling Practice',
          description: 'Building emotional awareness through writing',
          type: 'growth',
          category: 'Growth',
          confidence: 0.7,
          firstDetected: DateTime.now(),
          lastSeen: DateTime.now(),
          relatedEmotions: entry.moods.isNotEmpty ? [entry.moods.first] : ['neutral'],
        ),
      ],
      growthIndicators: ['self_reflection'],
      validationScore: 0.3,
    );
  }

  String _sanitizeText(String text, {int maxLength = 100}) {
    if (text.isEmpty) return text;
    
    // Remove potentially harmful content
    String sanitized = text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s\-.,!?()"]'), '') // Keep only safe characters
        .trim();
    
    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = '${sanitized.substring(0, maxLength - 3)}...';
    }
    
    return sanitized;
  }

  // Pattern analysis methods

  Map<String, int> _analyzeMoodFrequency(List<JournalEntry> entries) {
    final frequency = <String, int>{};
    
    for (final entry in entries) {
      for (final mood in entry.moods) {
        frequency[mood] = (frequency[mood] ?? 0) + 1;
      }
    }
    
    return frequency;
  }

  EmotionalPattern _createMoodPattern(Map<String, int> moodFrequency) {
    final sortedMoods = moodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topMood = sortedMoods.first.key;
    final frequency = sortedMoods.first.value;
    
    return EmotionalPattern(
      title: 'Dominant Emotional State',
      description: 'Your most frequent mood is "$topMood" appearing $frequency times, indicating a consistent emotional pattern.',
      type: 'recurring',
      category: 'Mood Patterns',
      confidence: 0.8,
      firstDetected: DateTime.now().subtract(const Duration(days: 30)),
      lastSeen: DateTime.now(),
      relatedEmotions: [topMood],
    );
  }

  EmotionalPattern? _analyzeTemporalPatterns(List<JournalEntry> entries) {
    if (entries.length < 3) return null;
    
    // Analyze day of week patterns
    final dayFrequency = <String, int>{};
    for (final entry in entries) {
      dayFrequency[entry.dayOfWeek] = (dayFrequency[entry.dayOfWeek] ?? 0) + 1;
    }
    
    final sortedDays = dayFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedDays.isNotEmpty && sortedDays.first.value > 1) {
      final topDay = sortedDays.first.key;
      return EmotionalPattern(
        title: 'Journaling Rhythm',
        description: 'You tend to journal most frequently on $topDay, showing a consistent reflection pattern.',
        type: 'recurring',
        category: 'Temporal Patterns',
        confidence: 0.7,
        firstDetected: DateTime.now().subtract(const Duration(days: 21)),
        lastSeen: DateTime.now(),
        relatedEmotions: ['consistent', 'routine'],
      );
    }
    
    return null;
  }

  EmotionalPattern? _analyzeContentLengthPatterns(List<JournalEntry> entries) {
    if (entries.length < 3) return null;
    
    final lengths = entries.map((e) => e.content.split(' ').length).toList();
    final avgLength = lengths.reduce((a, b) => a + b) / lengths.length;
    
    if (avgLength > 100) {
      return EmotionalPattern(
        title: 'Detailed Reflection',
        description: 'Your entries average ${avgLength.round()} words, showing deep, thoughtful reflection.',
        type: 'growth',
        category: 'Expression Patterns',
        confidence: 0.8,
        firstDetected: DateTime.now().subtract(const Duration(days: 14)),
        lastSeen: DateTime.now(),
        relatedEmotions: ['thoughtful', 'expressive'],
      );
    } else if (avgLength < 30) {
      return EmotionalPattern(
        title: 'Concise Expression',
        description: 'Your entries are concise, averaging ${avgLength.round()} words. Consider expanding for deeper insights.',
        type: 'awareness',
        category: 'Expression Patterns',
        confidence: 0.6,
        firstDetected: DateTime.now().subtract(const Duration(days: 14)),
        lastSeen: DateTime.now(),
        relatedEmotions: ['brief', 'focused'],
      );
    }
    
    return null;
  }

  EmotionalPattern? _analyzeIntensityPatterns(List<JournalEntry> entries) {
    if (entries.length < 3) return null;
    
    // Simple intensity calculation based on mood variety and content
    final intensities = entries.map((entry) {
      double intensity = entry.moods.length.toDouble(); // More moods = higher intensity
      if (entry.content.contains('!')) intensity += 0.5;
      if (entry.content.contains('very') || entry.content.contains('extremely')) intensity += 0.5;
      return intensity;
    }).toList();
    
    final avgIntensity = intensities.reduce((a, b) => a + b) / intensities.length;
    
    if (avgIntensity > 2.5) {
      return EmotionalPattern(
        title: 'High Emotional Engagement',
        description: 'Your entries show high emotional intensity, indicating deep engagement with your feelings.',
        type: 'growth',
        category: 'Emotional Intensity',
        confidence: 0.8,
        firstDetected: DateTime.now().subtract(const Duration(days: 7)),
        lastSeen: DateTime.now(),
        relatedEmotions: ['intense', 'engaged'],
      );
    }
    
    return null;
  }

  // Trend analysis methods

  Map<String, dynamic> _calculateMoodTrends(List<JournalEntry> entries) {
    if (entries.length < 2) return {};

    try {
      final moodCounts = <String, List<int>>{};
      final timeWindows = _createTimeWindows(entries);

      // Count moods in each time window
      for (int i = 0; i < timeWindows.length; i++) {
        final windowEntries = timeWindows[i];
        final windowMoods = <String, int>{};
        
        for (final entry in windowEntries) {
          for (final mood in entry.moods) {
            windowMoods[mood] = (windowMoods[mood] ?? 0) + 1;
          }
        }

        // Add counts to trend data
        for (final mood in windowMoods.keys) {
          moodCounts[mood] ??= List.filled(timeWindows.length, 0);
          moodCounts[mood]![i] = windowMoods[mood]!;
        }
      }

      // Calculate trend direction for each mood
      final trends = <String, String>{};
      for (final mood in moodCounts.keys) {
        final counts = moodCounts[mood]!;
        final trend = _calculateTrendDirection(counts);
        trends[mood] = trend;
      }

      return {
        'mood_counts': moodCounts,
        'trends': trends,
        'time_windows': timeWindows.length,
      };
    } catch (e) {
      debugPrint('EmotionalAnalyzer _calculateMoodTrends error: $e');
      return {};
    }
  }

  double _calculateIntensityTrend(List<JournalEntry> entries) {
    if (entries.length < 2) return 0.0;

    try {
      final intensities = entries.map((entry) {
        // Calculate intensity based on mood count and content analysis
        double intensity = entry.moods.length.toDouble();
        if (entry.content.contains('!')) intensity += 0.5;
        if (entry.content.contains('very') || entry.content.contains('extremely')) intensity += 0.5;
        return intensity;
      }).toList();

      // Calculate trend using linear regression slope
      return _calculateLinearTrend(intensities);
    } catch (e) {
      debugPrint('EmotionalAnalyzer _calculateIntensityTrend error: $e');
      return 0.0;
    }
  }

  double _calculateSentimentTrend(List<JournalEntry> entries) {
    if (entries.length < 2) return 0.0;

    try {
      final sentiments = entries.map((entry) {
        // Simple sentiment calculation based on mood analysis
        final positiveEmotions = ['happy', 'joyful', 'excited', 'grateful', 'content', 'peaceful'];
        final negativeEmotions = ['sad', 'angry', 'frustrated', 'anxious', 'worried'];
        
        double sentiment = 0.0;
        for (final mood in entry.moods) {
          if (positiveEmotions.contains(mood.toLowerCase())) {
            sentiment += 0.3;
          } else if (negativeEmotions.contains(mood.toLowerCase())) {
            sentiment -= 0.3;
          }
        }
        
        return sentiment.clamp(-1.0, 1.0);
      }).toList();

      // Calculate trend using linear regression slope
      return _calculateLinearTrend(sentiments);
    } catch (e) {
      debugPrint('EmotionalAnalyzer _calculateSentimentTrend error: $e');
      return 0.0;
    }
  }

  List<List<JournalEntry>> _createTimeWindows(List<JournalEntry> entries) {
    if (entries.length <= 7) {
      // If we have 7 or fewer entries, treat each as its own window
      return entries.map((entry) => [entry]).toList();
    }

    // Create weekly windows
    final windows = <List<JournalEntry>>[];
    final windowSize = (entries.length / 4).ceil(); // Aim for ~4 windows
    
    for (int i = 0; i < entries.length; i += windowSize) {
      final end = (i + windowSize < entries.length) ? i + windowSize : entries.length;
      windows.add(entries.sublist(i, end));
    }

    return windows;
  }

  String _calculateTrendDirection(List<int> values) {
    if (values.length < 2) return 'stable';

    final trend = _calculateLinearTrend(values.map((v) => v.toDouble()).toList());
    
    if (trend > 0.1) return 'rising';
    if (trend < -0.1) return 'declining';
    return 'stable';
  }

  double _calculateLinearTrend(List<double> values) {
    if (values.length < 2) return 0.0;

    try {
      final n = values.length;
      final xSum = (n * (n - 1)) / 2; // Sum of indices 0, 1, 2, ..., n-1
      final ySum = values.reduce((a, b) => a + b);
      final xySum = values.asMap().entries
          .map((entry) => entry.key * entry.value)
          .reduce((a, b) => a + b);
      final xxSum = (n * (n - 1) * (2 * n - 1)) / 6; // Sum of squares of indices

      // Calculate slope using least squares method
      final slope = (n * xySum - xSum * ySum) / (n * xxSum - xSum * xSum);
      
      return slope;
    } catch (e) {
      debugPrint('EmotionalAnalyzer _calculateLinearTrend error: $e');
      return 0.0;
    }
  }
}

/// Structured result of emotional analysis
class EmotionalAnalysisResult {
  final List<String> primaryEmotions;
  final double emotionalIntensity; // 0-10 scale
  final List<String> keyThemes;
  final double overallSentiment; // -1 to 1 scale
  final String personalizedInsight;
  final Map<String, double> coreImpacts; // Core name -> impact value
  final List<EmotionalPattern> emotionalPatterns;
  final List<String> growthIndicators;
  final double validationScore; // 0-1 confidence score

  EmotionalAnalysisResult({
    required this.primaryEmotions,
    required this.emotionalIntensity,
    required this.keyThemes,
    required this.overallSentiment,
    required this.personalizedInsight,
    required this.coreImpacts,
    required this.emotionalPatterns,
    required this.growthIndicators,
    required this.validationScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'primary_emotions': primaryEmotions,
      'emotional_intensity': emotionalIntensity,
      'key_themes': keyThemes,
      'overall_sentiment': overallSentiment,
      'personalized_insight': personalizedInsight,
      'core_impacts': coreImpacts,
      'emotional_patterns': emotionalPatterns.map((p) => {
        'category': p.category,
        'title': p.title,
        'description': p.description,
        'type': p.type,
      }).toList(),
      'growth_indicators': growthIndicators,
      'validation_score': validationScore,
    };
  }
}
