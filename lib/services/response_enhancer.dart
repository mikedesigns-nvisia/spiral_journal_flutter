import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';
import '../models/insight_template.dart';
import 'insight_template_service.dart';

/// Enhanced response service that enriches Haiku's concise output with local intelligence
/// 
/// This service implements sophisticated local analysis to complement Claude Haiku:
/// - Local emotion detection using advanced keyword analysis
/// - Pattern matching based on user's historical behavior
/// - Intelligent caching and learning from user patterns
/// - Blending of Haiku's analysis with local insights for richer output
class ResponseEnhancer {
  static final ResponseEnhancer _instance = ResponseEnhancer._internal();
  factory ResponseEnhancer() => _instance;
  ResponseEnhancer._internal();

  final InsightTemplateService _templateService = InsightTemplateService();
  
  // Cache keys
  static const String _emotionPatternsKey = 'emotion_patterns';
  static const String _userPatternsKey = 'user_patterns';
  static const String _contextHistoryKey = 'context_history';
  static const String _learningDataKey = 'learning_data';
  
  // Learning state
  final Map<String, EmotionPattern> _emotionPatterns = {};
  final Map<String, UserPattern> _userPatterns = {};
  final List<ContextSnapshot> _contextHistory = [];
  final LocalLearningData _learningData = LocalLearningData();
  
  bool _isInitialized = false;

  /// Initialize the response enhancer
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _templateService.initialize();
    await _loadCachedPatterns();
    await _loadUserPatterns();
    await _loadContextHistory();
    await _loadLearningData();
    
    _isInitialized = true;
    
    if (kDebugMode) {
      debugPrint('🧠 ResponseEnhancer initialized - Patterns: ${_emotionPatterns.length}, User Patterns: ${_userPatterns.length}');
    }
  }

  /// Enhance Haiku's response with local intelligence
  Future<EnhancedResponse> enhanceResponse(
    Map<String, dynamic> haikuAnalysis,
    JournalEntry entry, {
    List<JournalEntry>? historicalEntries,
    Map<String, dynamic>? additionalContext,
  }) async {
    if (!_isInitialized) await initialize();
    
    final startTime = DateTime.now();
    
    try {
      // 1. Local emotion detection
      final localEmotions = _detectLocalEmotions(entry.content);
      
      // 2. Pattern analysis from history
      final patterns = await _analyzePatterns(entry, historicalEntries ?? []);
      
      // 3. Contextual insights
      final contextualInsights = _generateContextualInsights(
        entry, 
        localEmotions, 
        patterns,
        additionalContext ?? {},
      );
      
      // 4. Blend with Haiku analysis
      final blendedAnalysis = _blendAnalyses(haikuAnalysis, localEmotions, patterns);
      
      // 5. Generate enhanced insights using templates
      final enhancedInsights = await _generateEnhancedInsights(
        blendedAnalysis,
        contextualInsights,
        entry,
      );
      
      // 6. Update learning data
      await _updateLearningData(entry, localEmotions, patterns, blendedAnalysis);
      
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      
      final response = EnhancedResponse(
        originalHaikuAnalysis: haikuAnalysis,
        localEmotions: localEmotions,
        detectedPatterns: patterns,
        contextualInsights: contextualInsights,
        blendedAnalysis: blendedAnalysis,
        enhancedInsights: enhancedInsights,
        confidenceScores: _calculateConfidenceScores(localEmotions, patterns),
        processingTimeMs: processingTime,
        enhancementVersion: '1.0',
      );
      
      if (kDebugMode) {
        debugPrint('🔮 Enhanced response in ${processingTime}ms - Insights: ${enhancedInsights.length}');
      }
      
      return response;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Enhancement error: $e');
      }
      
      // Fallback to original analysis
      return EnhancedResponse(
        originalHaikuAnalysis: haikuAnalysis,
        localEmotions: LocalEmotionAnalysis(),
        detectedPatterns: [],
        contextualInsights: [],
        blendedAnalysis: haikuAnalysis,
        enhancedInsights: [],
        confidenceScores: ConfidenceScores(),
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        enhancementVersion: '1.0',
        error: e.toString(),
      );
    }
  }

  /// Detect emotions using local keyword analysis
  LocalEmotionAnalysis _detectLocalEmotions(String content) {
    final contentLower = content.toLowerCase();
    final words = contentLower.split(RegExp(r'\W+'));
    
    final emotionScores = <String, double>{};
    final emotionKeywords = <String, List<String>>{};
    
    // Enhanced emotion detection with context-aware scoring
    for (final entry in _emotionKeywordMap.entries) {
      final emotion = entry.key;
      final keywords = entry.value;
      
      double score = 0.0;
      final foundKeywords = <String>[];
      
      for (final keyword in keywords) {
        final keywordPattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
        final matches = keywordPattern.allMatches(contentLower);
        
        if (matches.isNotEmpty) {
          foundKeywords.add(keyword);
          
          // Base score for keyword presence
          score += matches.length * 0.1;
          
          // Context boost - check surrounding words
          for (final match in matches) {
            final contextBoost = _getContextualBoost(contentLower, match.start, match.end, emotion);
            score += contextBoost;
          }
          
          // Intensity modifiers
          final intensityMultiplier = _getIntensityMultiplier(contentLower, keyword);
          score *= intensityMultiplier;
        }
      }
      
      if (score > 0) {
        emotionScores[emotion] = score.clamp(0.0, 1.0);
        emotionKeywords[emotion] = foundKeywords;
      }
    }
    
    // Calculate overall sentiment
    final positiveScore = emotionScores.entries
        .where((e) => _positiveEmotions.contains(e.key))
        .fold(0.0, (sum, e) => sum + e.value);
    
    final negativeScore = emotionScores.entries
        .where((e) => _negativeEmotions.contains(e.key))
        .fold(0.0, (sum, e) => sum + e.value);
    
    final sentiment = positiveScore > 0 || negativeScore > 0
        ? (positiveScore - negativeScore) / (positiveScore + negativeScore)
        : 0.0;
    
    // Emotional complexity (variety of emotions)
    final complexity = emotionScores.length / _emotionKeywordMap.keys.length;
    
    // Dominant emotions (top 3)
    final sortedEmotions = emotionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final dominantEmotions = sortedEmotions.take(3).map((e) => e.key).toList();
    
    return LocalEmotionAnalysis(
      detectedEmotions: emotionScores,
      emotionKeywords: emotionKeywords,
      dominantEmotions: dominantEmotions,
      sentiment: sentiment,
      emotionalComplexity: complexity,
      confidenceScore: _calculateEmotionConfidence(emotionScores, words.length),
    );
  }

  /// Analyze patterns from user history
  Future<List<DetectedPattern>> _analyzePatterns(
    JournalEntry currentEntry,
    List<JournalEntry> historicalEntries,
  ) async {
    final patterns = <DetectedPattern>[];
    
    if (historicalEntries.isEmpty) return patterns;
    
    // 1. Temporal patterns (daily, weekly, monthly)
    patterns.addAll(_detectTemporalPatterns(currentEntry, historicalEntries));
    
    // 2. Emotional patterns
    patterns.addAll(_detectEmotionalPatterns(currentEntry, historicalEntries));
    
    // 3. Content theme patterns
    patterns.addAll(_detectThemePatterns(currentEntry, historicalEntries));
    
    // 4. Behavioral patterns (entry frequency, length, timing)
    patterns.addAll(_detectBehavioralPatterns(currentEntry, historicalEntries));
    
    // 5. Cyclical patterns (recurring themes, emotions)
    patterns.addAll(_detectCyclicalPatterns(currentEntry, historicalEntries));
    
    return patterns;
  }

  /// Generate contextual insights based on local analysis
  List<ContextualInsight> _generateContextualInsights(
    JournalEntry entry,
    LocalEmotionAnalysis emotions,
    List<DetectedPattern> patterns,
    Map<String, dynamic> additionalContext,
  ) {
    final insights = <ContextualInsight>[];
    
    // Emotional context insights
    if (emotions.dominantEmotions.isNotEmpty) {
      insights.add(ContextualInsight(
        type: 'emotional_context',
        title: 'Emotional Landscape',
        content: 'Your emotional landscape shows ${emotions.dominantEmotions.join(", ")} with ${(emotions.emotionalComplexity * 100).round()}% complexity.',
        confidence: emotions.confidenceScore,
        source: 'local_emotion_detection',
      ));
    }
    
    // Pattern-based insights
    for (final pattern in patterns.where((p) => p.confidence > 0.6)) {
      insights.add(ContextualInsight(
        type: 'pattern_insight',
        title: pattern.name,
        content: pattern.description,
        confidence: pattern.confidence,
        source: 'pattern_analysis',
      ));
    }
    
    // Historical comparison insights
    if (_contextHistory.isNotEmpty) {
      final recentContext = _contextHistory.take(10).toList();
      final averageComplexity = recentContext
          .map((c) => c.emotionalComplexity)
          .reduce((a, b) => a + b) / recentContext.length;
      
      if ((emotions.emotionalComplexity - averageComplexity).abs() > 0.2) {
        final direction = emotions.emotionalComplexity > averageComplexity ? 'increased' : 'decreased';
        insights.add(ContextualInsight(
          type: 'complexity_change',
          title: 'Emotional Complexity Shift',
          content: 'Your emotional complexity has $direction compared to recent entries.',
          confidence: 0.8,
          source: 'historical_comparison',
        ));
      }
    }
    
    return insights;
  }

  /// Blend Haiku analysis with local intelligence
  Map<String, dynamic> _blendAnalyses(
    Map<String, dynamic> haikuAnalysis,
    LocalEmotionAnalysis localEmotions,
    List<DetectedPattern> patterns,
  ) {
    final blended = Map<String, dynamic>.from(haikuAnalysis);
    
    // Enrich emotions with local detection
    final haikuEmotions = List<String>.from(blended['emotions'] ?? []);
    final localDominant = localEmotions.dominantEmotions;
    
    // Merge emotions, prioritizing local detection for confidence
    final mergedEmotions = <String>{...haikuEmotions, ...localDominant}.toList();
    blended['emotions'] = mergedEmotions.take(5).toList(); // Limit to 5 top emotions
    
    // Enhance sentiment with local analysis
    final haikuSentiment = blended['sentiment']?.toDouble() ?? 0.0;
    final localSentiment = localEmotions.sentiment;
    
    if (localEmotions.confidenceScore > 0.6) {
      // Weighted blend favoring local analysis for high confidence
      blended['sentiment'] = (haikuSentiment * 0.3 + localSentiment * 0.7);
    } else {
      // Conservative blend
      blended['sentiment'] = (haikuSentiment * 0.7 + localSentiment * 0.3);
    }
    
    // Add pattern-derived themes
    final patternThemes = patterns
        .where((p) => p.type == 'theme' && p.confidence > 0.5)
        .map((p) => p.name.toLowerCase())
        .toList();
    
    final existingThemes = List<String>.from(blended['themes'] ?? []);
    final enhancedThemes = <String>{...existingThemes, ...patternThemes}.toList();
    blended['themes'] = enhancedThemes.take(5).toList(); // Limit to 5 themes
    
    // Add local insights to patterns
    final existingPatterns = List<String>.from(blended['patterns'] ?? []);
    final patternInsights = patterns
        .where((p) => p.confidence > 0.6)
        .map((p) => p.name)
        .toList();
    
    final enhancedPatterns = <String>{...existingPatterns, ...patternInsights}.toList();
    blended['patterns'] = enhancedPatterns.take(5).toList(); // Limit to 5 patterns
    
    // Enhance intensity with emotional complexity
    final haikuIntensity = blended['intensity']?.toDouble() ?? 0.5;
    final complexityBoost = localEmotions.emotionalComplexity * 0.3;
    blended['intensity'] = (haikuIntensity + complexityBoost).clamp(0.0, 1.0);
    
    // Add enhancement metadata
    blended['_enhancement'] = {
      'local_emotion_confidence': localEmotions.confidenceScore,
      'pattern_count': patterns.length,
      'high_confidence_patterns': patterns.where((p) => p.confidence > 0.8).length,
      'emotional_complexity': localEmotions.emotionalComplexity,
    };
    
    return blended;
  }

  /// Generate enhanced insights using template system
  Future<List<EnhancedInsight>> _generateEnhancedInsights(
    Map<String, dynamic> blendedAnalysis,
    List<ContextualInsight> contextualInsights,
    JournalEntry entry,
  ) async {
    final insights = <EnhancedInsight>[];
    
    // Create template context from blended analysis
    final templateContext = TemplateContext.fromCoreAnalysis(
      coreName: 'emotional_intelligence', // Could be dynamic based on analysis
      coreValue: blendedAnalysis['intensity']?.toDouble() ?? 0.5,
      previousValue: 0.4, // Would come from historical data
      timeframe: 'today',
      dominantEmotion: (blendedAnalysis['emotions'] as List?)?.first ?? 'neutral',
      emotionIntensity: blendedAnalysis['sentiment']?.toDouble() ?? 0.0,
      additionalContext: {
        'themes': blendedAnalysis['themes'],
        'patterns': blendedAnalysis['patterns'],
      },
    );
    
    // Generate insights for each category
    for (final category in InsightCategory.values) {
      final selection = _templateService.selectTemplate(
        templateContext,
        category: category,
      );
      
      if (selection != null) {
        insights.add(EnhancedInsight(
          category: category,
          content: selection.generatedInsight,
          confidence: _calculateInsightConfidence(selection.score, contextualInsights),
          template: selection.template,
          source: 'template_generation',
          supportingData: {
            'template_score': selection.score,
            'contextual_support': contextualInsights.length,
          },
        ));
      }
    }
    
    // Add contextual insights as enhanced insights
    for (final contextInsight in contextualInsights.where((c) => c.confidence > 0.7)) {
      insights.add(EnhancedInsight(
        category: InsightCategory.reflection, // Default category for contextual insights
        content: contextInsight.content,
        confidence: contextInsight.confidence,
        template: null,
        source: contextInsight.source,
        supportingData: {
          'insight_type': contextInsight.type,
          'title': contextInsight.title,
        },
      ));
    }
    
    // Sort by confidence and return top insights
    insights.sort((a, b) => b.confidence.compareTo(a.confidence));
    return insights.take(8).toList(); // Return top 8 insights
  }

  /// Update learning data based on analysis results
  Future<void> _updateLearningData(
    JournalEntry entry,
    LocalEmotionAnalysis emotions,
    List<DetectedPattern> patterns,
    Map<String, dynamic> blendedAnalysis,
  ) async {
    // Update emotion patterns
    for (final emotion in emotions.dominantEmotions) {
      final pattern = _emotionPatterns[emotion] ?? EmotionPattern(emotion: emotion);
      pattern.updateFrequency();
      pattern.addKeywords(emotions.emotionKeywords[emotion] ?? []);
      _emotionPatterns[emotion] = pattern;
    }
    
    // Update context history
    _contextHistory.insert(0, ContextSnapshot(
      timestamp: entry.date,
      dominantEmotions: emotions.dominantEmotions,
      sentiment: emotions.sentiment,
      emotionalComplexity: emotions.emotionalComplexity,
      patternCount: patterns.length,
      contentLength: entry.content.length,
    ));
    
    // Keep only recent history (last 100 entries)
    if (_contextHistory.length > 100) {
      _contextHistory.removeRange(100, _contextHistory.length);
    }
    
    // Update learning metrics
    _learningData.totalEntriesProcessed++;
    _learningData.averageEmotionalComplexity = (_learningData.averageEmotionalComplexity * (_learningData.totalEntriesProcessed - 1) + emotions.emotionalComplexity) / _learningData.totalEntriesProcessed;
    _learningData.lastUpdated = DateTime.now();
    
    // Persist updates
    await _saveCachedPatterns();
    await _saveContextHistory();
    await _saveLearningData();
  }

  /// Calculate confidence scores for the enhancement
  ConfidenceScores _calculateConfidenceScores(
    LocalEmotionAnalysis emotions,
    List<DetectedPattern> patterns,
  ) {
    final emotionConfidence = emotions.confidenceScore;
    final patternConfidence = patterns.isNotEmpty 
        ? patterns.map((p) => p.confidence).reduce((a, b) => a + b) / patterns.length
        : 0.0;
    
    final overallConfidence = (emotionConfidence + patternConfidence) / 2;
    
    return ConfidenceScores(
      overall: overallConfidence,
      emotionDetection: emotionConfidence,
      patternMatching: patternConfidence,
      contextualInsights: _contextHistory.length > 5 ? 0.8 : 0.4,
      templateMatching: 0.9, // Template system is highly reliable
    );
  }

  // Helper methods for pattern detection
  List<DetectedPattern> _detectTemporalPatterns(JournalEntry current, List<JournalEntry> history) {
    final patterns = <DetectedPattern>[];
    
    // Daily pattern detection
    final todayEntries = history.where((e) => 
        e.date.day == current.date.day && 
        e.date.month == current.date.month).toList();
    
    if (todayEntries.length > 2) {
      patterns.add(DetectedPattern(
        type: 'temporal',
        name: 'Daily Reflection Pattern',
        description: 'You tend to reflect multiple times on ${_getDayName(current.date.weekday)}s',
        confidence: 0.7,
        frequency: todayEntries.length,
        metadata: {'day_of_week': current.date.weekday},
      ));
    }
    
    return patterns;
  }

  List<DetectedPattern> _detectEmotionalPatterns(JournalEntry current, List<JournalEntry> history) {
    final patterns = <DetectedPattern>[];
    
    // Emotional consistency pattern
    final recentMoods = history.take(10).expand((e) => e.moods).toList();
    final currentMoods = current.moods;
    
    final commonMoods = currentMoods.where((mood) => recentMoods.contains(mood)).toList();
    
    if (commonMoods.isNotEmpty) {
      patterns.add(DetectedPattern(
        type: 'emotional',
        name: 'Emotional Consistency',
        description: 'You consistently experience ${commonMoods.join(", ")} emotions',
        confidence: commonMoods.length / currentMoods.length,
        frequency: commonMoods.length,
        metadata: {'common_moods': commonMoods},
      ));
    }
    
    return patterns;
  }

  List<DetectedPattern> _detectThemePatterns(JournalEntry current, List<JournalEntry> history) {
    final patterns = <DetectedPattern>[];
    
    // Theme consistency using keyword analysis
    final currentWords = current.content.toLowerCase().split(RegExp(r'\W+'));
    final themeWords = <String, int>{};
    
    for (final entry in history.take(20)) {
      final words = entry.content.toLowerCase().split(RegExp(r'\W+'));
      for (final word in words) {
        if (word.length > 4 && currentWords.contains(word)) {
          themeWords[word] = (themeWords[word] ?? 0) + 1;
        }
      }
    }
    
    final significantThemes = themeWords.entries
        .where((e) => e.value >= 3)
        .map((e) => e.key)
        .toList();
    
    if (significantThemes.isNotEmpty) {
      patterns.add(DetectedPattern(
        type: 'theme',
        name: 'Recurring Themes',
        description: 'You frequently discuss themes around ${significantThemes.take(3).join(", ")}',
        confidence: 0.8,
        frequency: significantThemes.length,
        metadata: {'themes': significantThemes},
      ));
    }
    
    return patterns;
  }

  List<DetectedPattern> _detectBehavioralPatterns(JournalEntry current, List<JournalEntry> history) {
    final patterns = <DetectedPattern>[];
    
    // Entry length pattern
    final avgLength = history.isNotEmpty 
        ? history.map((e) => e.content.length).reduce((a, b) => a + b) / history.length
        : 0;
    
    if ((current.content.length - avgLength).abs() / avgLength < 0.2) {
      patterns.add(DetectedPattern(
        type: 'behavioral',
        name: 'Consistent Entry Length',
        description: 'You maintain consistent entry lengths averaging ${avgLength.round()} characters',
        confidence: 0.6,
        frequency: 1,
        metadata: {'average_length': avgLength, 'current_length': current.content.length},
      ));
    }
    
    return patterns;
  }

  List<DetectedPattern> _detectCyclicalPatterns(JournalEntry current, List<JournalEntry> history) {
    final patterns = <DetectedPattern>[];
    
    // Weekly cyclical patterns
    final sameWeekdayEntries = history.where((e) => e.date.weekday == current.date.weekday).toList();
    
    if (sameWeekdayEntries.length >= 4) {
      patterns.add(DetectedPattern(
        type: 'cyclical',
        name: 'Weekly Reflection Cycle',
        description: 'You have a pattern of reflecting on ${_getDayName(current.date.weekday)}s',
        confidence: 0.7,
        frequency: sameWeekdayEntries.length,
        metadata: {'day_of_week': current.date.weekday, 'occurrences': sameWeekdayEntries.length},
      ));
    }
    
    return patterns;
  }

  // Helper methods for contextual analysis
  double _getContextualBoost(String content, int start, int end, String emotion) {
    final contextRange = 20; // Characters before and after
    final contextStart = (start - contextRange).clamp(0, content.length);
    final contextEnd = (end + contextRange).clamp(0, content.length);
    final context = content.substring(contextStart, contextEnd);
    
    // Boost for intensity words
    final intensityWords = ['very', 'extremely', 'really', 'so', 'quite', 'totally', 'absolutely'];
    for (final word in intensityWords) {
      if (context.contains(word)) return 0.2;
    }
    
    // Boost for negative modifiers
    final negativeModifiers = ['not', 'never', 'hardly', 'barely'];
    for (final word in negativeModifiers) {
      if (context.contains(word)) return -0.3; // Negative boost
    }
    
    return 0.0;
  }

  double _getIntensityMultiplier(String content, String keyword) {
    final intensityPattern = RegExp(r'\b(very|extremely|really|so|quite|totally|absolutely)\s+\w*' + RegExp.escape(keyword), caseSensitive: false);
    return intensityPattern.hasMatch(content) ? 1.5 : 1.0;
  }

  double _calculateEmotionConfidence(Map<String, double> emotions, int wordCount) {
    if (emotions.isEmpty) return 0.0;
    
    final totalScore = emotions.values.reduce((a, b) => a + b);
    final averageScore = totalScore / emotions.length;
    
    // Factor in word count - more words generally mean higher confidence
    final wordCountFactor = (wordCount / 100).clamp(0.1, 1.0);
    
    return (averageScore * wordCountFactor).clamp(0.0, 1.0);
  }

  double _calculateInsightConfidence(double templateScore, List<ContextualInsight> contextualInsights) {
    final baseConfidence = (templateScore / 10).clamp(0.0, 1.0); // Normalize template score
    final contextualBoost = contextualInsights.length * 0.1;
    
    return (baseConfidence + contextualBoost).clamp(0.0, 1.0);
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  // Persistence methods
  Future<void> _saveCachedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patternsJson = _emotionPatterns.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_emotionPatternsKey, jsonEncode(patternsJson));
    } catch (e) {
      if (kDebugMode) debugPrint('💾 Failed to save emotion patterns: $e');
    }
  }

  Future<void> _loadCachedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patternsJsonString = prefs.getString(_emotionPatternsKey);
      
      if (patternsJsonString != null) {
        final patternsJson = jsonDecode(patternsJsonString) as Map<String, dynamic>;
        _emotionPatterns.clear();
        patternsJson.forEach((key, value) {
          _emotionPatterns[key] = EmotionPattern.fromJson(value);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('💾 Failed to load emotion patterns: $e');
    }
  }

  Future<void> _saveContextHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _contextHistory.map((snapshot) => snapshot.toJson()).toList();
      await prefs.setString(_contextHistoryKey, jsonEncode(historyJson));
    } catch (e) {
      if (kDebugMode) debugPrint('💾 Failed to save context history: $e');
    }
  }

  Future<void> _loadContextHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJsonString = prefs.getString(_contextHistoryKey);
      
      if (historyJsonString != null) {
        final historyJson = jsonDecode(historyJsonString) as List<dynamic>;
        _contextHistory.clear();
        _contextHistory.addAll(historyJson.map((json) => ContextSnapshot.fromJson(json)));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('💾 Failed to load context history: $e');
    }
  }

  Future<void> _saveLearningData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_learningDataKey, jsonEncode(_learningData.toJson()));
    } catch (e) {
      if (kDebugMode) debugPrint('💾 Failed to save learning data: $e');
    }
  }

  Future<void> _loadLearningData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final learningJsonString = prefs.getString(_learningDataKey);
      
      if (learningJsonString != null) {
        final learningJson = jsonDecode(learningJsonString);
        _learningData.updateFromJson(learningJson);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('💾 Failed to load learning data: $e');
    }
  }

  Future<void> _loadUserPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patternsJsonString = prefs.getString(_userPatternsKey);
      
      if (patternsJsonString != null) {
        final patternsJson = jsonDecode(patternsJsonString) as Map<String, dynamic>;
        _userPatterns.clear();
        patternsJson.forEach((key, value) {
          _userPatterns[key] = UserPattern.fromJson(value);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('💾 Failed to load user patterns: $e');
    }
  }

  /// Clear all cached data (for testing)
  Future<void> clearAllData() async {
    _emotionPatterns.clear();
    _userPatterns.clear();
    _contextHistory.clear();
    _learningData.reset();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emotionPatternsKey);
    await prefs.remove(_userPatternsKey);
    await prefs.remove(_contextHistoryKey);
    await prefs.remove(_learningDataKey);
    
    if (kDebugMode) {
      debugPrint('🗑️ Cleared all response enhancer data');
    }
  }

  // Emotion keyword mapping for local detection
  static const Map<String, List<String>> _emotionKeywordMap = {
    'happy': ['happy', 'joy', 'joyful', 'cheerful', 'delighted', 'pleased', 'content', 'elated', 'ecstatic', 'blissful', 'upbeat', 'positive', 'great', 'wonderful', 'amazing', 'fantastic', 'excellent'],
    'sad': ['sad', 'sadness', 'depressed', 'down', 'melancholy', 'gloomy', 'blue', 'dejected', 'sorrowful', 'mournful', 'grief', 'heartbroken', 'disappointed', 'upset', 'hurt'],
    'angry': ['angry', 'anger', 'mad', 'furious', 'rage', 'irritated', 'annoyed', 'frustrated', 'livid', 'enraged', 'incensed', 'outraged', 'pissed', 'agitated'],
    'anxious': ['anxious', 'anxiety', 'worried', 'nervous', 'stressed', 'tense', 'uneasy', 'apprehensive', 'fearful', 'concerned', 'troubled', 'panicked', 'restless'],
    'excited': ['excited', 'enthusiasm', 'eager', 'thrilled', 'pumped', 'energetic', 'animated', 'exhilarated', 'passionate', 'motivated', 'inspired'],
    'grateful': ['grateful', 'thankful', 'appreciation', 'blessed', 'fortunate', 'appreciative', 'indebted', 'obliged'],
    'peaceful': ['peaceful', 'calm', 'serene', 'tranquil', 'relaxed', 'zen', 'composed', 'centered', 'balanced', 'harmonious'],
    'confident': ['confident', 'self-assured', 'certain', 'sure', 'determined', 'strong', 'capable', 'empowered', 'bold'],
    'lonely': ['lonely', 'alone', 'isolated', 'solitary', 'abandoned', 'disconnected', 'alienated', 'forsaken'],
    'hopeful': ['hopeful', 'optimistic', 'positive', 'encouraged', 'uplifting', 'promising', 'bright', 'looking forward'],
    'overwhelmed': ['overwhelmed', 'overloaded', 'swamped', 'buried', 'drowning', 'too much', 'can\'t handle'],
    'proud': ['proud', 'accomplished', 'achieved', 'successful', 'satisfied', 'fulfilled', 'victorious'],
    'confused': ['confused', 'bewildered', 'puzzled', 'perplexed', 'lost', 'uncertain', 'unclear', 'mixed up'],
    'love': ['love', 'adore', 'cherish', 'treasure', 'affection', 'devotion', 'care', 'fondness'],
    'fear': ['fear', 'afraid', 'scared', 'terrified', 'frightened', 'panic', 'dread', 'horror', 'phobia'],
  };

  static const List<String> _positiveEmotions = ['happy', 'excited', 'grateful', 'peaceful', 'confident', 'hopeful', 'proud', 'love'];
  static const List<String> _negativeEmotions = ['sad', 'angry', 'anxious', 'lonely', 'overwhelmed', 'confused', 'fear'];
}

/// Enhanced response containing both Haiku and local analysis
class EnhancedResponse {
  final Map<String, dynamic> originalHaikuAnalysis;
  final LocalEmotionAnalysis localEmotions;
  final List<DetectedPattern> detectedPatterns;
  final List<ContextualInsight> contextualInsights;
  final Map<String, dynamic> blendedAnalysis;
  final List<EnhancedInsight> enhancedInsights;
  final ConfidenceScores confidenceScores;
  final int processingTimeMs;
  final String enhancementVersion;
  final String? error;

  EnhancedResponse({
    required this.originalHaikuAnalysis,
    required this.localEmotions,
    required this.detectedPatterns,
    required this.contextualInsights,
    required this.blendedAnalysis,
    required this.enhancedInsights,
    required this.confidenceScores,
    required this.processingTimeMs,
    required this.enhancementVersion,
    this.error,
  });

  bool get hasError => error != null;
  bool get isHighConfidence => confidenceScores.overall > 0.7;
  
  Map<String, dynamic> toJson() => {
    'originalHaikuAnalysis': originalHaikuAnalysis,
    'localEmotions': localEmotions.toJson(),
    'detectedPatterns': detectedPatterns.map((p) => p.toJson()).toList(),
    'contextualInsights': contextualInsights.map((i) => i.toJson()).toList(),
    'blendedAnalysis': blendedAnalysis,
    'enhancedInsights': enhancedInsights.map((i) => i.toJson()).toList(),
    'confidenceScores': confidenceScores.toJson(),
    'processingTimeMs': processingTimeMs,
    'enhancementVersion': enhancementVersion,
    'error': error,
  };
}

/// Local emotion analysis results
class LocalEmotionAnalysis {
  final Map<String, double> detectedEmotions;
  final Map<String, List<String>> emotionKeywords;
  final List<String> dominantEmotions;
  final double sentiment;
  final double emotionalComplexity;
  final double confidenceScore;

  LocalEmotionAnalysis({
    this.detectedEmotions = const {},
    this.emotionKeywords = const {},
    this.dominantEmotions = const [],
    this.sentiment = 0.0,
    this.emotionalComplexity = 0.0,
    this.confidenceScore = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'detectedEmotions': detectedEmotions,
    'emotionKeywords': emotionKeywords,
    'dominantEmotions': dominantEmotions,
    'sentiment': sentiment,
    'emotionalComplexity': emotionalComplexity,
    'confidenceScore': confidenceScore,
  };
}

/// Detected pattern from user history
class DetectedPattern {
  final String type;
  final String name;
  final String description;
  final double confidence;
  final int frequency;
  final Map<String, dynamic> metadata;

  DetectedPattern({
    required this.type,
    required this.name,
    required this.description,
    required this.confidence,
    required this.frequency,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'description': description,
    'confidence': confidence,
    'frequency': frequency,
    'metadata': metadata,
  };

  factory DetectedPattern.fromJson(Map<String, dynamic> json) => DetectedPattern(
    type: json['type'],
    name: json['name'],
    description: json['description'],
    confidence: json['confidence']?.toDouble() ?? 0.0,
    frequency: json['frequency'] ?? 0,
    metadata: json['metadata'] ?? {},
  );
}

/// Contextual insight generated from local analysis
class ContextualInsight {
  final String type;
  final String title;
  final String content;
  final double confidence;
  final String source;

  ContextualInsight({
    required this.type,
    required this.title,
    required this.content,
    required this.confidence,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'content': content,
    'confidence': confidence,
    'source': source,
  };
}

/// Enhanced insight combining multiple analysis sources
class EnhancedInsight {
  final InsightCategory category;
  final String content;
  final double confidence;
  final InsightTemplate? template;
  final String source;
  final Map<String, dynamic> supportingData;

  EnhancedInsight({
    required this.category,
    required this.content,
    required this.confidence,
    this.template,
    required this.source,
    this.supportingData = const {},
  });

  Map<String, dynamic> toJson() => {
    'category': category.id,
    'content': content,
    'confidence': confidence,
    'templateId': template?.id,
    'source': source,
    'supportingData': supportingData,
  };
}

/// Confidence scores for different aspects of enhancement
class ConfidenceScores {
  final double overall;
  final double emotionDetection;
  final double patternMatching;
  final double contextualInsights;
  final double templateMatching;

  ConfidenceScores({
    this.overall = 0.0,
    this.emotionDetection = 0.0,
    this.patternMatching = 0.0,
    this.contextualInsights = 0.0,
    this.templateMatching = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'overall': overall,
    'emotionDetection': emotionDetection,
    'patternMatching': patternMatching,
    'contextualInsights': contextualInsights,
    'templateMatching': templateMatching,
  };
}

/// Emotion pattern for learning
class EmotionPattern {
  final String emotion;
  int frequency;
  List<String> keywords;
  DateTime lastSeen;

  EmotionPattern({
    required this.emotion,
    this.frequency = 1,
    this.keywords = const [],
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  void updateFrequency() {
    frequency++;
    lastSeen = DateTime.now();
  }

  void addKeywords(List<String> newKeywords) {
    final existingKeywords = Set<String>.from(keywords);
    existingKeywords.addAll(newKeywords);
    keywords = existingKeywords.toList();
  }

  Map<String, dynamic> toJson() => {
    'emotion': emotion,
    'frequency': frequency,
    'keywords': keywords,
    'lastSeen': lastSeen.toIso8601String(),
  };

  factory EmotionPattern.fromJson(Map<String, dynamic> json) => EmotionPattern(
    emotion: json['emotion'],
    frequency: json['frequency'] ?? 1,
    keywords: List<String>.from(json['keywords'] ?? []),
    lastSeen: DateTime.parse(json['lastSeen']),
  );
}

/// User pattern for behavioral analysis
class UserPattern {
  final String patternType;
  final String description;
  int frequency;
  double confidence;
  DateTime lastDetected;
  Map<String, dynamic> metadata;

  UserPattern({
    required this.patternType,
    required this.description,
    this.frequency = 1,
    this.confidence = 0.5,
    DateTime? lastDetected,
    this.metadata = const {},
  }) : lastDetected = lastDetected ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'patternType': patternType,
    'description': description,
    'frequency': frequency,
    'confidence': confidence,
    'lastDetected': lastDetected.toIso8601String(),
    'metadata': metadata,
  };

  factory UserPattern.fromJson(Map<String, dynamic> json) => UserPattern(
    patternType: json['patternType'],
    description: json['description'],
    frequency: json['frequency'] ?? 1,
    confidence: json['confidence']?.toDouble() ?? 0.5,
    lastDetected: DateTime.parse(json['lastDetected']),
    metadata: json['metadata'] ?? {},
  );
}

/// Context snapshot for historical analysis
class ContextSnapshot {
  final DateTime timestamp;
  final List<String> dominantEmotions;
  final double sentiment;
  final double emotionalComplexity;
  final int patternCount;
  final int contentLength;

  ContextSnapshot({
    required this.timestamp,
    required this.dominantEmotions,
    required this.sentiment,
    required this.emotionalComplexity,
    required this.patternCount,
    required this.contentLength,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'dominantEmotions': dominantEmotions,
    'sentiment': sentiment,
    'emotionalComplexity': emotionalComplexity,
    'patternCount': patternCount,
    'contentLength': contentLength,
  };

  factory ContextSnapshot.fromJson(Map<String, dynamic> json) => ContextSnapshot(
    timestamp: DateTime.parse(json['timestamp']),
    dominantEmotions: List<String>.from(json['dominantEmotions']),
    sentiment: json['sentiment']?.toDouble() ?? 0.0,
    emotionalComplexity: json['emotionalComplexity']?.toDouble() ?? 0.0,
    patternCount: json['patternCount'] ?? 0,
    contentLength: json['contentLength'] ?? 0,
  );
}

/// Local learning data
class LocalLearningData {
  int totalEntriesProcessed = 0;
  double averageEmotionalComplexity = 0.0;
  DateTime lastUpdated = DateTime.now();
  Map<String, int> emotionFrequency = {};

  void reset() {
    totalEntriesProcessed = 0;
    averageEmotionalComplexity = 0.0;
    lastUpdated = DateTime.now();
    emotionFrequency.clear();
  }

  Map<String, dynamic> toJson() => {
    'totalEntriesProcessed': totalEntriesProcessed,
    'averageEmotionalComplexity': averageEmotionalComplexity,
    'lastUpdated': lastUpdated.toIso8601String(),
    'emotionFrequency': emotionFrequency,
  };

  void updateFromJson(Map<String, dynamic> json) {
    totalEntriesProcessed = json['totalEntriesProcessed'] ?? 0;
    averageEmotionalComplexity = json['averageEmotionalComplexity']?.toDouble() ?? 0.0;
    lastUpdated = DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String());
    emotionFrequency = Map<String, int>.from(json['emotionFrequency'] ?? {});
  }
}