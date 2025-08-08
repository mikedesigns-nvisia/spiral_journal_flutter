import 'dart:async';
import 'dart:math' as math;
import '../models/core.dart';
import '../models/journal_entry.dart';

/// Types of personalized insights
enum CoreInsightType {
  growthPattern,
  journalingRecommendation,
  coreCorrelation,
  milestoneGuidance,
  strengthRecognition,
  improvementSuggestion,
  motivationalInsight,
  reflectionPrompt,
}

/// Data model for personalized core insights
class PersonalizedCoreInsight {
  final String id;
  final CoreInsightType type;
  final String coreId;
  final String coreName;
  final String title;
  final String description;
  final String actionableAdvice;
  final double relevanceScore; // 0.0 to 1.0
  final DateTime generatedAt;
  final List<String> supportingEvidence;
  final Map<String, dynamic> metadata;

  PersonalizedCoreInsight({
    required this.id,
    required this.type,
    required this.coreId,
    required this.coreName,
    required this.title,
    required this.description,
    required this.actionableAdvice,
    required this.relevanceScore,
    required this.generatedAt,
    this.supportingEvidence = const [],
    this.metadata = const {},
  });

  factory PersonalizedCoreInsight.fromJson(Map<String, dynamic> json) {
    return PersonalizedCoreInsight(
      id: json['id'],
      type: CoreInsightType.values.firstWhere(
        (e) => e.toString() == 'CoreInsightType.${json['type']}',
        orElse: () => CoreInsightType.growthPattern,
      ),
      coreId: json['coreId'],
      coreName: json['coreName'],
      title: json['title'],
      description: json['description'],
      actionableAdvice: json['actionableAdvice'],
      relevanceScore: json['relevanceScore'].toDouble(),
      generatedAt: DateTime.parse(json['generatedAt']),
      supportingEvidence: List<String>.from(json['supportingEvidence'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'coreId': coreId,
      'coreName': coreName,
      'title': title,
      'description': description,
      'actionableAdvice': actionableAdvice,
      'relevanceScore': relevanceScore,
      'generatedAt': generatedAt.toIso8601String(),
      'supportingEvidence': supportingEvidence,
      'metadata': metadata,
    };
  }
}

/// Service for generating personalized core insights based on journal patterns
class CoreInsightGenerator {
  static final CoreInsightGenerator _instance = CoreInsightGenerator._internal();
  factory CoreInsightGenerator() => _instance;
  CoreInsightGenerator._internal();

  final List<PersonalizedCoreInsight> _generatedInsights = [];
  final Map<String, DateTime> _lastInsightGeneration = {};

  /// Generate personalized insights for a core based on journal patterns
  Future<List<PersonalizedCoreInsight>> generateInsightsForCore({
    required EmotionalCore core,
    required List<JournalEntry> recentEntries,
    required List<JournalEntry> historicalEntries,
    int maxInsights = 3,
  }) async {
    final insights = <PersonalizedCoreInsight>[];
    
    // Analyze patterns
    final patterns = await _analyzeJournalPatterns(core, recentEntries, historicalEntries);
    
    // Generate different types of insights
    insights.addAll(await _generateGrowthPatternInsights(core, patterns));
    insights.addAll(await _generateJournalingRecommendations(core, patterns));
    insights.addAll(await _generateCorrelationInsights(core, patterns));
    insights.addAll(await _generateMilestoneGuidance(core, patterns));
    insights.addAll(await _generateStrengthRecognition(core, patterns));
    insights.addAll(await _generateImprovementSuggestions(core, patterns));
    insights.addAll(await _generateMotivationalInsights(core, patterns));
    insights.addAll(await _generateReflectionPrompts(core, patterns));
    
    // Sort by relevance and return top insights
    insights.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    final topInsights = insights.take(maxInsights).toList();
    
    // Store generated insights
    _generatedInsights.addAll(topInsights);
    _lastInsightGeneration[core.id] = DateTime.now();
    
    return topInsights;
  }

  /// Generate contextual prompts for journaling based on core trends
  Future<List<String>> generateJournalingPrompts({
    required EmotionalCore core,
    required List<JournalEntry> recentEntries,
    int maxPrompts = 5,
  }) async {
    final prompts = <String>[];
    
    // Analyze current core state
    final trend = core.trend;
    final level = core.currentLevel;
    final recentThemes = _extractRecentThemes(recentEntries);
    
    // Generate prompts based on core state
    if (trend == 'rising') {
      prompts.addAll(_generateRisingTrendPrompts(core, recentThemes));
    } else if (trend == 'declining') {
      prompts.addAll(_generateDecliningTrendPrompts(core, recentThemes));
    } else {
      prompts.addAll(_generateStableTrendPrompts(core, recentThemes));
    }
    
    // Add level-specific prompts
    if (level < 0.3) {
      prompts.addAll(_generateFoundationPrompts(core));
    } else if (level < 0.7) {
      prompts.addAll(_generateDevelopmentPrompts(core));
    } else {
      prompts.addAll(_generateMasteryPrompts(core));
    }
    
    // Add core-specific prompts
    prompts.addAll(_generateCoreSpecificPrompts(core));
    
    // Shuffle and return top prompts
    prompts.shuffle();
    return prompts.take(maxPrompts).toList();
  }

  /// Generate growth suggestions based on individual core patterns
  Future<List<String>> generateGrowthSuggestions({
    required EmotionalCore core,
    required List<JournalEntry> journalHistory,
    int maxSuggestions = 3,
  }) async {
    final suggestions = <String>[];
    
    // Analyze journal patterns
    final patterns = await _analyzeJournalPatterns(core, journalHistory.take(10).toList(), journalHistory);
    
    // Generate suggestions based on patterns
    if (patterns['consistentThemes']?.isNotEmpty == true) {
      suggestions.add(_generateConsistencyBasedSuggestion(core, patterns['consistentThemes']));
    }
    
    if (patterns['emotionalPatterns']?.isNotEmpty == true) {
      suggestions.add(_generateEmotionalPatternSuggestion(core, patterns['emotionalPatterns']));
    }
    
    if (patterns['writingFrequency'] != null) {
      suggestions.add(_generateFrequencyBasedSuggestion(core, patterns['writingFrequency']));
    }
    
    // Add core-specific growth suggestions
    suggestions.addAll(_generateCoreSpecificGrowthSuggestions(core));
    
    return suggestions.take(maxSuggestions).toList();
  }

  /// Get all generated insights for a core
  List<PersonalizedCoreInsight> getInsightsForCore(String coreId) {
    return _generatedInsights.where((insight) => insight.coreId == coreId).toList();
  }

  /// Get recent insights (last 7 days)
  List<PersonalizedCoreInsight> getRecentInsights() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _generatedInsights
        .where((insight) => insight.generatedAt.isAfter(cutoff))
        .toList();
  }

  /// Clear old insights to prevent memory buildup
  void clearOldInsights() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _generatedInsights.removeWhere((insight) => insight.generatedAt.isBefore(cutoff));
  }

  // Private helper methods

  Future<Map<String, dynamic>> _analyzeJournalPatterns(
    EmotionalCore core,
    List<JournalEntry> recentEntries,
    List<JournalEntry> historicalEntries,
  ) async {
    final patterns = <String, dynamic>{};
    
    // Analyze themes
    patterns['consistentThemes'] = _findConsistentThemes(recentEntries);
    patterns['emergingThemes'] = _findEmergingThemes(recentEntries, historicalEntries);
    
    // Analyze emotional patterns
    patterns['emotionalPatterns'] = _analyzeEmotionalPatterns(recentEntries);
    patterns['moodCorrelations'] = _analyzeMoodCorrelations(recentEntries, core);
    
    // Analyze writing patterns
    patterns['writingFrequency'] = _analyzeWritingFrequency(recentEntries);
    patterns['writingLength'] = _analyzeWritingLength(recentEntries);
    
    // Analyze core-specific patterns
    patterns['coreImpactPatterns'] = _analyzeCoreImpactPatterns(recentEntries, core);
    
    return patterns;
  }

  Future<List<PersonalizedCoreInsight>> _generateGrowthPatternInsights(
    EmotionalCore core,
    Map<String, dynamic> patterns,
  ) async {
    final insights = <PersonalizedCoreInsight>[];
    
    final consistentThemes = patterns['consistentThemes'] as List<String>? ?? [];
    if (consistentThemes.isNotEmpty) {
      insights.add(PersonalizedCoreInsight(
        id: 'growth_pattern_${core.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreInsightType.growthPattern,
        coreId: core.id,
        coreName: core.name,
        title: 'Consistent Growth Pattern Detected',
        description: 'You consistently write about ${consistentThemes.first}, which strongly supports your ${core.name} development.',
        actionableAdvice: 'Continue exploring ${consistentThemes.first} in your journaling to maintain this positive growth trajectory.',
        relevanceScore: 0.8,
        generatedAt: DateTime.now(),
        supportingEvidence: consistentThemes,
      ));
    }
    
    return insights;
  }

  Future<List<PersonalizedCoreInsight>> _generateJournalingRecommendations(
    EmotionalCore core,
    Map<String, dynamic> patterns,
  ) async {
    final insights = <PersonalizedCoreInsight>[];
    
    final writingFrequency = patterns['writingFrequency'] as double? ?? 0.0;
    if (writingFrequency < 0.5) { // Less than every other day
      insights.add(PersonalizedCoreInsight(
        id: 'journaling_rec_${core.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreInsightType.journalingRecommendation,
        coreId: core.id,
        coreName: core.name,
        title: 'Increase Journaling Frequency',
        description: 'Your ${core.name} shows stronger growth when you journal more consistently.',
        actionableAdvice: 'Try journaling at least every other day to maximize your ${core.name} development.',
        relevanceScore: 0.7,
        generatedAt: DateTime.now(),
        metadata: {'currentFrequency': writingFrequency},
      ));
    }
    
    return insights;
  }

  Future<List<PersonalizedCoreInsight>> _generateCorrelationInsights(
    EmotionalCore core,
    Map<String, dynamic> patterns,
  ) async {
    final insights = <PersonalizedCoreInsight>[];
    
    final moodCorrelations = patterns['moodCorrelations'] as Map<String, double>? ?? {};
    final strongestMood = moodCorrelations.entries
        .where((entry) => entry.value > 0.6)
        .fold<MapEntry<String, double>?>(null, (prev, curr) => 
            prev == null || curr.value > prev.value ? curr : prev);
    
    if (strongestMood != null) {
      insights.add(PersonalizedCoreInsight(
        id: 'correlation_${core.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreInsightType.coreCorrelation,
        coreId: core.id,
        coreName: core.name,
        title: 'Strong Mood-Core Connection',
        description: 'Your ${core.name} grows significantly when you feel ${strongestMood.key}.',
        actionableAdvice: 'Pay attention to what makes you feel ${strongestMood.key} and incorporate more of those experiences into your life.',
        relevanceScore: 0.75,
        generatedAt: DateTime.now(),
        supportingEvidence: [strongestMood.key],
        metadata: {'correlationStrength': strongestMood.value},
      ));
    }
    
    return insights;
  }

  Future<List<PersonalizedCoreInsight>> _generateMilestoneGuidance(
    EmotionalCore core,
    Map<String, dynamic> patterns,
  ) async {
    final insights = <PersonalizedCoreInsight>[];
    
    final nextMilestone = core.milestones
        .where((m) => !m.isAchieved && m.threshold > core.currentLevel)
        .fold<CoreMilestone?>(null, (prev, curr) => 
            prev == null || curr.threshold < prev.threshold ? curr : prev);
    
    if (nextMilestone != null) {
      final progress = (core.currentLevel / nextMilestone.threshold * 100).toStringAsFixed(0);
      insights.add(PersonalizedCoreInsight(
        id: 'milestone_${core.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreInsightType.milestoneGuidance,
        coreId: core.id,
        coreName: core.name,
        title: 'Approaching Milestone',
        description: 'You\'re $progress% of the way to achieving "${nextMilestone.title}" in your ${core.name} journey.',
        actionableAdvice: 'Focus on ${nextMilestone.description.toLowerCase()} to reach this milestone faster.',
        relevanceScore: 0.85,
        generatedAt: DateTime.now(),
        metadata: {
          'milestoneId': nextMilestone.id,
          'progressPercentage': progress,
        },
      ));
    }
    
    return insights;
  }

  Future<List<PersonalizedCoreInsight>> _generateStrengthRecognition(
    EmotionalCore core,
    Map<String, dynamic> patterns,
  ) async {
    final insights = <PersonalizedCoreInsight>[];
    
    if (core.trend == 'rising' && core.currentLevel > 0.6) {
      insights.add(PersonalizedCoreInsight(
        id: 'strength_${core.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreInsightType.strengthRecognition,
        coreId: core.id,
        coreName: core.name,
        title: 'Strength Recognition',
        description: 'Your ${core.name} is a significant strength, showing consistent growth and high development.',
        actionableAdvice: 'Consider how you can leverage your strong ${core.name} to support other areas of growth.',
        relevanceScore: 0.9,
        generatedAt: DateTime.now(),
        metadata: {'currentLevel': core.currentLevel, 'trend': core.trend},
      ));
    }
    
    return insights;
  }

  Future<List<PersonalizedCoreInsight>> _generateImprovementSuggestions(
    EmotionalCore core,
    Map<String, dynamic> patterns,
  ) async {
    final insights = <PersonalizedCoreInsight>[];
    
    if (core.trend == 'declining' || core.currentLevel < 0.3) {
      insights.add(PersonalizedCoreInsight(
        id: 'improvement_${core.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreInsightType.improvementSuggestion,
        coreId: core.id,
        coreName: core.name,
        title: 'Growth Opportunity',
        description: 'Your ${core.name} has room for development and could benefit from focused attention.',
        actionableAdvice: _getCoreSpecificImprovementAdvice(core),
        relevanceScore: 0.8,
        generatedAt: DateTime.now(),
      ));
    }
    
    return insights;
  }

  Future<List<PersonalizedCoreInsight>> _generateMotivationalInsights(
    EmotionalCore core,
    Map<String, dynamic> patterns,
  ) async {
    final insights = <PersonalizedCoreInsight>[];
    
    final recentGrowth = core.currentLevel - core.previousLevel;
    if (recentGrowth > 0.1) {
      insights.add(PersonalizedCoreInsight(
        id: 'motivation_${core.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreInsightType.motivationalInsight,
        coreId: core.id,
        coreName: core.name,
        title: 'Celebrating Your Progress',
        description: 'You\'ve made remarkable progress in your ${core.name}, growing by ${(recentGrowth * 100).toStringAsFixed(0)}% recently.',
        actionableAdvice: 'Take a moment to acknowledge this growth and consider what specific actions contributed to this positive change.',
        relevanceScore: 0.85,
        generatedAt: DateTime.now(),
        metadata: {'recentGrowth': recentGrowth},
      ));
    }
    
    return insights;
  }

  Future<List<PersonalizedCoreInsight>> _generateReflectionPrompts(
    EmotionalCore core,
    Map<String, dynamic> patterns,
  ) async {
    final insights = <PersonalizedCoreInsight>[];
    
    final prompts = _getCoreSpecificReflectionPrompts(core);
    if (prompts.isNotEmpty) {
      insights.add(PersonalizedCoreInsight(
        id: 'reflection_${core.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: CoreInsightType.reflectionPrompt,
        coreId: core.id,
        coreName: core.name,
        title: 'Reflection Opportunity',
        description: 'Deepen your ${core.name} development with targeted reflection.',
        actionableAdvice: prompts.first,
        relevanceScore: 0.6,
        generatedAt: DateTime.now(),
        supportingEvidence: prompts,
      ));
    }
    
    return insights;
  }

  // Helper methods for pattern analysis

  List<String> _findConsistentThemes(List<JournalEntry> entries) {
    final themeCount = <String, int>{};
    
    for (final entry in entries) {
      for (final theme in entry.keyThemes) {
        themeCount[theme] = (themeCount[theme] ?? 0) + 1;
      }
    }
    
    final threshold = math.max(1, entries.length ~/ 3);
    return themeCount.entries
        .where((entry) => entry.value >= threshold)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> _findEmergingThemes(List<JournalEntry> recent, List<JournalEntry> historical) {
    final recentThemes = _extractRecentThemes(recent);
    final historicalThemes = _extractRecentThemes(historical);
    
    return recentThemes
        .where((theme) => !historicalThemes.contains(theme))
        .toList();
  }

  List<String> _extractRecentThemes(List<JournalEntry> entries) {
    final themes = <String>{};
    for (final entry in entries) {
      themes.addAll(entry.keyThemes);
    }
    return themes.toList();
  }

  Map<String, double> _analyzeEmotionalPatterns(List<JournalEntry> entries) {
    final emotionCount = <String, int>{};
    
    for (final entry in entries) {
      for (final mood in entry.moods) {
        emotionCount[mood] = (emotionCount[mood] ?? 0) + 1;
      }
    }
    
    final total = entries.length;
    return emotionCount.map((emotion, count) => 
        MapEntry(emotion, count / total));
  }

  Map<String, double> _analyzeMoodCorrelations(List<JournalEntry> entries, EmotionalCore core) {
    final correlations = <String, double>{};
    
    for (final entry in entries) {
      final coreImpact = entry.aiAnalysis?.coreImpacts[core.id] ?? 0.0;
      
      for (final mood in entry.moods) {
        correlations[mood] = (correlations[mood] ?? 0.0) + coreImpact;
      }
    }
    
    // Normalize correlations
    final maxCorrelation = correlations.values.fold(0.0, math.max);
    if (maxCorrelation > 0) {
      correlations.updateAll((mood, correlation) => correlation / maxCorrelation);
    }
    
    return correlations;
  }

  double _analyzeWritingFrequency(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0.0;
    
    final days = DateTime.now().difference(entries.last.date).inDays + 1;
    return entries.length / days;
  }

  double _analyzeWritingLength(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0.0;
    
    final totalLength = entries.fold(0, (sum, entry) => sum + entry.content.length);
    return totalLength / entries.length;
  }

  Map<String, double> _analyzeCoreImpactPatterns(List<JournalEntry> entries, EmotionalCore core) {
    final impacts = entries
        .map((entry) => entry.aiAnalysis?.coreImpacts[core.id] ?? 0.0)
        .where((impact) => impact != 0.0)
        .toList();
    
    if (impacts.isEmpty) return {};
    
    final avgImpact = impacts.fold(0.0, (sum, impact) => sum + impact) / impacts.length;
    final maxImpact = impacts.fold(0.0, math.max);
    final minImpact = impacts.fold(0.0, math.min);
    
    return {
      'averageImpact': avgImpact,
      'maxImpact': maxImpact,
      'minImpact': minImpact,
      'consistency': 1.0 - (maxImpact - minImpact).abs(),
    };
  }

  // Core-specific helper methods

  List<String> _generateRisingTrendPrompts(EmotionalCore core, List<String> themes) {
    final corePrompts = _getCoreSpecificPrompts(core);
    return [
      'What specific actions have contributed to your recent growth in ${core.name}?',
      'How can you build on your current momentum in ${core.name}?',
      ...corePrompts.take(3),
    ];
  }

  List<String> _generateDecliningTrendPrompts(EmotionalCore core, List<String> themes) {
    return [
      'What challenges are you facing in your ${core.name} development?',
      'What support or resources might help you strengthen your ${core.name}?',
      'When did you last feel strong in your ${core.name}? What was different then?',
    ];
  }

  List<String> _generateStableTrendPrompts(EmotionalCore core, List<String> themes) {
    return [
      'What would it look like to take your ${core.name} to the next level?',
      'How does your ${core.name} show up in your daily life?',
      'What new aspects of ${core.name} would you like to explore?',
    ];
  }

  List<String> _generateFoundationPrompts(EmotionalCore core) {
    return [
      'What does ${core.name} mean to you personally?',
      'When have you felt most connected to your ${core.name}?',
      'What small step could you take today to nurture your ${core.name}?',
    ];
  }

  List<String> _generateDevelopmentPrompts(EmotionalCore core) {
    return [
      'How has your understanding of ${core.name} evolved recently?',
      'What patterns do you notice in your ${core.name} development?',
      'How does your ${core.name} influence other areas of your life?',
    ];
  }

  List<String> _generateMasteryPrompts(EmotionalCore core) {
    return [
      'How can you use your strong ${core.name} to help others?',
      'What wisdom have you gained through developing your ${core.name}?',
      'How might you continue to refine and deepen your ${core.name}?',
    ];
  }

  List<String> _generateCoreSpecificPrompts(EmotionalCore core) {
    return _getCoreSpecificPrompts(core);
  }

  List<String> _getCoreSpecificPrompts(EmotionalCore core) {
    switch (core.name.toLowerCase()) {
      case 'optimism':
        return [
          'What positive possibilities do you see in your current situation?',
          'How do you maintain hope during challenging times?',
          'What are you most grateful for today?',
        ];
      case 'resilience':
        return [
          'How have you bounced back from recent setbacks?',
          'What inner strengths help you persevere?',
          'What have you learned from overcoming past challenges?',
        ];
      case 'self-awareness':
        return [
          'What patterns in your thoughts and behaviors have you noticed lately?',
          'How do your emotions guide your decisions?',
          'What aspects of yourself are you still discovering?',
        ];
      case 'creativity':
        return [
          'What new ideas or solutions have emerged for you recently?',
          'How do you nurture your creative spirit?',
          'What would you create if there were no limitations?',
        ];
      case 'social connection':
        return [
          'How have your relationships enriched your life lately?',
          'What do you value most in your connections with others?',
          'How do you show care and support to those around you?',
        ];
      case 'growth mindset':
        return [
          'What new skills or knowledge are you excited to develop?',
          'How do you view challenges as opportunities?',
          'What would you attempt if you knew you couldn\'t fail?',
        ];
      default:
        return [
          'How has your ${core.name} influenced your recent experiences?',
          'What would strengthening your ${core.name} look like?',
          'How do you recognize ${core.name} in your daily life?',
        ];
    }
  }

  String _getCoreSpecificImprovementAdvice(EmotionalCore core) {
    switch (core.name.toLowerCase()) {
      case 'optimism':
        return 'Practice gratitude daily and focus on identifying positive aspects in challenging situations.';
      case 'resilience':
        return 'Build your support network and develop healthy coping strategies for stress.';
      case 'self-awareness':
        return 'Spend time in reflection and consider keeping a daily mindfulness practice.';
      case 'creativity':
        return 'Set aside regular time for creative exploration without judgment or pressure.';
      case 'social connection':
        return 'Reach out to friends and family, and consider joining communities aligned with your interests.';
      case 'growth mindset':
        return 'Embrace challenges as learning opportunities and celebrate progress over perfection.';
      default:
        return 'Focus on small, consistent actions that align with developing your ${core.name}.';
    }
  }

  List<String> _getCoreSpecificReflectionPrompts(EmotionalCore core) {
    return _getCoreSpecificPrompts(core);
  }

  String _generateConsistencyBasedSuggestion(EmotionalCore core, List<String> themes) {
    return 'Continue exploring ${themes.first} in your journaling, as it consistently supports your ${core.name} growth.';
  }

  String _generateEmotionalPatternSuggestion(EmotionalCore core, Map<String, double> patterns) {
    final dominantEmotion = patterns.entries
        .fold<MapEntry<String, double>?>(null, (prev, curr) => 
            prev == null || curr.value > prev.value ? curr : prev);
    
    if (dominantEmotion != null) {
      return 'Your ${core.name} responds well to ${dominantEmotion.key} emotions. Consider what activities or thoughts cultivate this feeling.';
    }
    
    return 'Pay attention to the emotional states that support your ${core.name} development.';
  }

  String _generateFrequencyBasedSuggestion(EmotionalCore core, double frequency) {
    if (frequency < 0.3) {
      return 'Increase your journaling frequency to accelerate your ${core.name} development.';
    } else if (frequency > 0.8) {
      return 'Your consistent journaling is excellent for ${core.name} growth. Consider deepening your reflections.';
    } else {
      return 'Your journaling frequency supports steady ${core.name} development.';
    }
  }

  List<String> _generateCoreSpecificGrowthSuggestions(EmotionalCore core) {
    switch (core.name.toLowerCase()) {
      case 'optimism':
        return [
          'Practice reframing negative thoughts into learning opportunities',
          'Keep a daily gratitude journal to strengthen positive thinking patterns',
          'Surround yourself with positive influences and uplifting content',
        ];
      case 'resilience':
        return [
          'Develop a toolkit of healthy coping strategies for stress',
          'Build and maintain strong support relationships',
          'Practice mindfulness to stay grounded during challenges',
        ];
      case 'self-awareness':
        return [
          'Regular meditation or mindfulness practice to increase self-observation',
          'Ask for feedback from trusted friends about your blind spots',
          'Journal about your emotional patterns and triggers',
        ];
      case 'creativity':
        return [
          'Set aside dedicated time for creative exploration without goals',
          'Try new creative mediums or approaches regularly',
          'Connect with other creative individuals for inspiration',
        ];
      case 'social connection':
        return [
          'Schedule regular check-ins with friends and family',
          'Practice active listening in your conversations',
          'Join communities or groups aligned with your interests',
        ];
      case 'growth mindset':
        return [
          'Embrace challenges as opportunities to learn and grow',
          'Focus on effort and process rather than just outcomes',
          'Learn from setbacks by asking "What can this teach me?"',
        ];
      default:
        return [
          'Set specific, achievable goals for developing your ${core.name}',
          'Track your progress and celebrate small wins',
          'Seek resources and learning opportunities related to ${core.name}',
        ];
    }
  }
}