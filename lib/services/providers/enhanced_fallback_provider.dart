import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/journal_entry.dart';
import '../../models/core.dart';
import '../../models/core_resonance_data.dart';
import '../ai_service_interface.dart';
import '../ai_service_error_tracker.dart';

/// Enhanced Fallback Provider with sophisticated local emotional analysis
/// This provider delivers rich, meaningful insights without any API calls
class EnhancedFallbackProvider implements AIServiceInterface {
  final AIServiceConfig _config;
  
  // Emotional pattern recognition engine
  final _emotionalPatternEngine = EmotionalPatternEngine();
  
  // Temporal analysis engine
  final _temporalAnalysisEngine = TemporalAnalysisEngine();
  
  // Core resonance calculator
  final _coreResonanceCalculator = CoreResonanceCalculator();
  
  // Context analyzer
  final _contextAnalyzer = ContextAnalyzer();

  EnhancedFallbackProvider(this._config);

  @override
  AIProvider get provider => AIProvider.disabled;

  @override
  bool get isConfigured => true;

  @override
  bool get isEnabled => true;

  @override
  Future<void> setApiKey(String apiKey) async {
    // No API key needed
  }

  @override
  Future<void> testConnection() async {
    // Always passes
  }

  @override
  Future<Map<String, dynamic>> analyzeJournalEntry(JournalEntry entry) async {
    try {
      debugPrint('🧠 EnhancedFallbackProvider: Performing deep emotional analysis for entry ${entry.id}');
      
      // Simulate processing time for realism
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Perform multi-layered analysis
      final emotionalProfile = _emotionalPatternEngine.analyzeEmotionalProfile(entry);
      final temporalContext = await _temporalAnalysisEngine.analyzeTemporalContext(entry);
      final contextualInsights = _contextAnalyzer.extractContextualInsights(entry);
      final coreResonances = _coreResonanceCalculator.calculateResonances(
        entry, 
        emotionalProfile, 
        temporalContext,
        contextualInsights,
      );
      
      // Generate personalized insight
      final personalizedInsight = _generatePersonalizedInsight(
        entry,
        emotionalProfile,
        temporalContext,
        contextualInsights,
        coreResonances,
      );
      
      // Build comprehensive analysis result
      final result = {
        "primary_emotions": emotionalProfile.primaryEmotions,
        "emotional_intensity": emotionalProfile.intensity,
        "growth_indicators": _identifyGrowthIndicators(entry, contextualInsights),
        "core_updates": _generateCoreUpdates(coreResonances),
        "mind_reflection": {
          "title": _generateReflectionTitle(emotionalProfile, temporalContext),
          "summary": _generateReflectionSummary(entry, emotionalProfile, contextualInsights),
          "insights": _generateDeepInsights(entry, emotionalProfile, temporalContext, contextualInsights),
        },
        "emotional_patterns": _identifyEmotionalPatterns(entry, emotionalProfile, temporalContext),
        "entry_insight": personalizedInsight,
        "core_resonance": coreResonances.map((key, value) => MapEntry(key, value.toJson())),
        "temporal_insights": temporalContext.insights,
        "contextual_themes": contextualInsights.themes,
      };
      
      debugPrint('✅ EnhancedFallbackProvider: Deep analysis completed with ${(result["emotional_patterns"] as List?)?.length ?? 0} patterns identified');
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('❌ EnhancedFallbackProvider error: $e');
      AIServiceErrorTracker.logError(
        'analyzeJournalEntry',
        e,
        stackTrace: stackTrace,
        provider: 'EnhancedFallbackProvider',
      );
      return _getBasicAnalysis(entry);
    }
  }

  @override
  Future<String> generateMonthlyInsight(List<JournalEntry> entries) async {
    try {
      if (entries.isEmpty) {
        return "Start your emotional journey with daily reflections. Each entry helps you understand yourself better.";
      }
      
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Analyze monthly patterns
      final monthlyPatterns = _emotionalPatternEngine.analyzeMonthlyPatterns(entries);
      final emotionalJourney = _temporalAnalysisEngine.analyzeEmotionalJourney(entries);
      final growthMetrics = _calculateGrowthMetrics(entries);
      
      return _generateComprehensiveMonthlyInsight(
        entries,
        monthlyPatterns,
        emotionalJourney,
        growthMetrics,
      );
      
    } catch (e, stackTrace) {
      debugPrint('❌ EnhancedFallbackProvider monthly insight error: $e');
      AIServiceErrorTracker.logError(
        'generateMonthlyInsight',
        e,
        stackTrace: stackTrace,
        provider: 'EnhancedFallbackProvider',
      );
      return "Your journey of self-discovery continues with ${entries.length} meaningful reflections this month.";
    }
  }

  @override
  Future<Map<String, double>> calculateCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
  ) async {
    try {
      final analysis = await analyzeJournalEntry(entry);
      final coreUpdates = <String, double>{};
      
      final coreResonances = analysis['core_resonance'] as Map<String, dynamic>? ?? {};
      final coreAdjustments = analysis['core_updates'] as Map<String, dynamic>? ?? {};
      
      for (final core in currentCores) {
        double totalAdjustment = 0.0;
        
        // Base adjustment from core updates
        final baseAdjustment = (coreAdjustments[core.name] as num?)?.toDouble() ?? 0.0;
        totalAdjustment += baseAdjustment;
        
        // Resonance-based adjustment
        if (coreResonances.containsKey(core.id)) {
          final resonanceData = coreResonances[core.id] as Map<String, dynamic>;
          final resonanceStrength = (resonanceData['resonanceStrength'] as num?)?.toDouble() ?? 0.0;
          
          // Strong resonance provides additional boost
          if (resonanceStrength > 0.7) {
            totalAdjustment += 0.15;
          } else if (resonanceStrength > 0.5) {
            totalAdjustment += 0.1;
          }
        }
        
        // Apply adjustment with momentum
        if (totalAdjustment != 0.0) {
          final momentum = _calculateMomentum(core);
          final adjustedValue = totalAdjustment * momentum;
          final newPercentage = (core.percentage + adjustedValue).clamp(0.0, 100.0);
          coreUpdates[core.id] = newPercentage;
        }
      }
      
      return coreUpdates;
      
    } catch (e, stackTrace) {
      debugPrint('❌ EnhancedFallbackProvider calculateCoreUpdates error: $e');
      AIServiceErrorTracker.logError(
        'calculateCoreUpdates',
        e,
        stackTrace: stackTrace,
        provider: 'EnhancedFallbackProvider',
      );
      return {};
    }
  }

  // Helper methods for deep analysis
  
  String _generatePersonalizedInsight(
    JournalEntry entry,
    EmotionalProfile profile,
    TemporalContext temporal,
    ContextualInsights contextual,
    Map<String, CoreResonanceData> resonances,
  ) {
    // Find the strongest resonating core
    String? strongestCore;
    double maxResonance = 0.0;
    
    resonances.forEach((coreId, resonanceData) {
      if (resonanceData.resonanceStrength > maxResonance) {
        maxResonance = resonanceData.resonanceStrength;
        strongestCore = coreId;
      }
    });
    
    // Generate insight based on emotional complexity
    if (profile.emotionalComplexity > 0.7) {
      return "Your entry reveals a rich emotional landscape with ${profile.primaryEmotions.join(', ')} interweaving. "
             "This emotional complexity shows deep self-awareness and the ability to hold multiple feelings simultaneously.";
    }
    
    // Generate insight based on growth patterns
    if (contextual.hasGrowthIndicators) {
      return "Beautiful growth moment captured here. Your reflection on ${contextual.primaryTheme} "
             "demonstrates expanding ${strongestCore ?? 'emotional'} awareness. Keep nurturing this momentum.";
    }
    
    // Generate insight based on temporal patterns
    if (temporal.isBreakthrough) {
      return "This entry marks a significant shift in your emotional journey. "
             "The way you're processing ${profile.dominantEmotion} shows remarkable evolution from previous patterns.";
    }
    
    // Default personalized insight
    return "Your ${profile.dominantEmotion} mood today connects deeply with your ${strongestCore ?? 'inner'} core. "
           "This kind of honest reflection strengthens emotional resilience.";
  }

  List<String> _generateDeepInsights(
    JournalEntry entry,
    EmotionalProfile profile,
    TemporalContext temporal,
    ContextualInsights contextual,
  ) {
    final insights = <String>[];
    
    // Emotional depth insights
    if (profile.emotionalDepth > 0.6) {
      insights.add("Deep emotional processing evident - you're connecting with feelings at multiple levels");
    }
    
    // Pattern recognition insights
    if (temporal.hasRecurringPattern) {
      insights.add("Noticing a ${temporal.patternType} pattern emerging in your emotional landscape");
    }
    
    // Contextual insights
    if (contextual.hasLifeTransition) {
      insights.add("Life transition energy detected - your cores are adapting to new circumstances");
    }
    
    // Growth insights
    if (profile.growthOrientation > 0.5) {
      insights.add("Strong growth mindset activation - you're actively learning from experiences");
    }
    
    // Resilience insights
    if (contextual.hasChallenge && profile.resilienceIndicator > 0.4) {
      insights.add("Resilience building through challenge - transforming difficulty into strength");
    }
    
    // Ensure we always have at least one insight
    if (insights.isEmpty) {
      insights.add("Consistent self-reflection practice strengthening all emotional cores");
    }
    
    return insights.take(3).toList();
  }

  List<Map<String, dynamic>> _identifyEmotionalPatterns(
    JournalEntry entry,
    EmotionalProfile profile,
    TemporalContext temporal,
  ) {
    final patterns = <Map<String, dynamic>>[];
    
    // Emotional complexity pattern
    if (profile.emotionalComplexity > 0.6) {
      patterns.add({
        "category": "Emotional Intelligence",
        "title": "Nuanced Emotional Awareness",
        "description": "Recognizing and articulating multiple emotional states simultaneously",
        "type": "growth",
        "strength": profile.emotionalComplexity,
      });
    }
    
    // Temporal pattern
    if (temporal.hasRecurringPattern) {
      patterns.add({
        "category": "Temporal Patterns",
        "title": temporal.patternTitle,
        "description": temporal.patternDescription,
        "type": temporal.patternType,
        "strength": temporal.patternStrength,
      });
    }
    
    // Growth pattern
    if (profile.growthOrientation > 0.5) {
      patterns.add({
        "category": "Personal Development",
        "title": "Active Growth Mindset",
        "description": "Consistently viewing experiences through a lens of learning and development",
        "type": "growth",
        "strength": profile.growthOrientation,
      });
    }
    
    // Resilience pattern
    if (profile.resilienceIndicator > 0.4) {
      patterns.add({
        "category": "Emotional Resilience",
        "title": "Adaptive Coping",
        "description": "Developing healthy strategies for processing challenging emotions",
        "type": "resilience",
        "strength": profile.resilienceIndicator,
      });
    }
    
    return patterns.take(3).toList();
  }

  Map<String, dynamic> _generateCoreUpdates(Map<String, CoreResonanceData> resonances) {
    final updates = <String, dynamic>{};
    
    resonances.forEach((coreId, resonanceData) {
      // Convert core ID to display name
      final coreName = _getCoreDisplayName(coreId);
      
      // Calculate update based on resonance strength
      double update = 0.0;
      if (resonanceData.resonanceStrength > 0.8) {
        update = 0.3;
      } else if (resonanceData.resonanceStrength > 0.6) {
        update = 0.2;
      } else if (resonanceData.resonanceStrength > 0.4) {
        update = 0.1;
      } else if (resonanceData.resonanceStrength > 0.2) {
        update = 0.05;
      }
      
      updates[coreName] = update;
    });
    
    return updates;
  }

  String _getCoreDisplayName(String coreId) {
    final coreMap = {
      'optimism': 'Optimism',
      'resilience': 'Resilience',
      'self_awareness': 'Self-Awareness',
      'creativity': 'Creativity',
      'social_connection': 'Social Connection',
      'growth_mindset': 'Growth Mindset',
    };
    return coreMap[coreId] ?? coreId;
  }

  double _calculateMomentum(EmotionalCore core) {
    // Cores that are trending upward get momentum boost
    if (core.trend == 'rising') {
      return 1.2;
    } else if (core.trend == 'declining') {
      return 0.8;
    }
    return 1.0;
  }

  String _generateReflectionTitle(EmotionalProfile profile, TemporalContext temporal) {
    if (temporal.isBreakthrough) {
      return "Breakthrough Moment";
    } else if (profile.emotionalComplexity > 0.7) {
      return "Rich Emotional Tapestry";
    } else if (profile.growthOrientation > 0.6) {
      return "Growth in Motion";
    } else {
      return "Emotional Landscape";
    }
  }

  String _generateReflectionSummary(
    JournalEntry entry,
    EmotionalProfile profile,
    ContextualInsights contextual,
  ) {
    final emotion = profile.dominantEmotion;
    final theme = contextual.primaryTheme;
    
    return "Your $emotion state reveals deep engagement with $theme. "
           "This reflection strengthens your emotional intelligence and self-understanding.";
  }

  List<String> _identifyGrowthIndicators(JournalEntry entry, ContextualInsights contextual) {
    final indicators = <String>[];
    
    if (contextual.hasGrowthIndicators) {
      indicators.addAll(contextual.growthIndicators);
    }
    
    // Add default indicator if none found
    if (indicators.isEmpty) {
      indicators.add('self_reflection');
    }
    
    return indicators;
  }

  String _generateComprehensiveMonthlyInsight(
    List<JournalEntry> entries,
    MonthlyPatterns patterns,
    EmotionalJourney journey,
    GrowthMetrics metrics,
  ) {
    final buffer = StringBuffer();
    
    // Opening statement
    buffer.write("This month's ${entries.length} entries reveal ");
    
    // Dominant pattern
    if (patterns.dominantPattern != null) {
      buffer.write("a strong ${patterns.dominantPattern} pattern. ");
    } else {
      buffer.write("diverse emotional experiences. ");
    }
    
    // Journey highlight
    if (journey.hasTransformation) {
      buffer.write("You've navigated a significant transformation, ");
      buffer.write("moving from ${journey.startingPoint} to ${journey.currentPoint}. ");
    }
    
    // Growth metrics
    if (metrics.overallGrowth > 0.3) {
      buffer.write("Your emotional cores show ${(metrics.overallGrowth * 100).round()}% growth, ");
      buffer.write("particularly in ${metrics.strongestGrowthArea}. ");
    }
    
    // Closing encouragement
    buffer.write("Keep nurturing this beautiful journey of self-discovery.");
    
    return buffer.toString();
  }

  GrowthMetrics _calculateGrowthMetrics(List<JournalEntry> entries) {
    // Analyze entries for growth indicators
    double growthScore = 0.0;
    String strongestArea = "self-awareness";
    
    for (final entry in entries) {
      if (entry.content.toLowerCase().contains('learn')) growthScore += 0.1;
      if (entry.content.toLowerCase().contains('grow')) growthScore += 0.1;
      if (entry.content.toLowerCase().contains('better')) growthScore += 0.05;
    }
    
    return GrowthMetrics(
      overallGrowth: (growthScore / entries.length).clamp(0.0, 1.0),
      strongestGrowthArea: strongestArea,
    );
  }

  Map<String, dynamic> _getBasicAnalysis(JournalEntry entry) {
    return {
      "primary_emotions": entry.moods.isNotEmpty ? [entry.moods.first] : ["reflective"],
      "emotional_intensity": 0.5,
      "growth_indicators": ["self_reflection"],
      "core_updates": {
        'Self-Awareness': 0.1,
      },
      "mind_reflection": {
        "title": "Moment of Reflection",
        "summary": "Taking time to journal shows commitment to self-understanding.",
        "insights": ["Each entry deepens your emotional awareness"],
      },
      "emotional_patterns": [],
      "entry_insight": "Thank you for sharing this moment of your journey.",
    };
  }
}

// Supporting classes for sophisticated analysis

class EmotionalPatternEngine {
  EmotionalProfile analyzeEmotionalProfile(JournalEntry entry) {
    final emotions = entry.moods;
    final content = entry.content.toLowerCase();
    
    // Calculate emotional complexity
    final uniqueEmotions = emotions.toSet().length;
    final emotionalComplexity = (uniqueEmotions / max(emotions.length, 1)).clamp(0.0, 1.0);
    
    // Analyze emotional depth
    final emotionalDepth = _calculateEmotionalDepth(content);
    
    // Identify dominant emotion
    final emotionFrequency = <String, int>{};
    for (final emotion in emotions) {
      emotionFrequency[emotion] = (emotionFrequency[emotion] ?? 0) + 1;
    }
    final dominantEmotion = emotionFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    // Calculate growth orientation
    final growthOrientation = _calculateGrowthOrientation(content);
    
    // Calculate resilience indicator
    final resilienceIndicator = _calculateResilienceIndicator(content, emotions);
    
    return EmotionalProfile(
      primaryEmotions: emotions.take(3).toList(),
      dominantEmotion: dominantEmotion,
      emotionalComplexity: emotionalComplexity,
      emotionalDepth: emotionalDepth,
      intensity: _calculateIntensity(content, emotions),
      growthOrientation: growthOrientation,
      resilienceIndicator: resilienceIndicator,
    );
  }
  
  MonthlyPatterns analyzeMonthlyPatterns(List<JournalEntry> entries) {
    // Analyze patterns across the month
    final moodFrequency = <String, int>{};
    final dayPatterns = <String, int>{};
    
    for (final entry in entries) {
      for (final mood in entry.moods) {
        moodFrequency[mood] = (moodFrequency[mood] ?? 0) + 1;
      }
      dayPatterns[entry.dayOfWeek] = (dayPatterns[entry.dayOfWeek] ?? 0) + 1;
    }
    
    // Find dominant pattern
    String? dominantPattern;
    if (moodFrequency.isNotEmpty) {
      final topMood = moodFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      dominantPattern = topMood;
    }
    
    return MonthlyPatterns(
      dominantPattern: dominantPattern,
      moodDistribution: moodFrequency,
      temporalPatterns: dayPatterns,
    );
  }
  
  double _calculateEmotionalDepth(String content) {
    final depthIndicators = [
      'feel', 'feeling', 'emotion', 'sense', 'experience',
      'realize', 'understand', 'discover', 'notice', 'aware',
      'deep', 'profound', 'intense', 'powerful', 'overwhelming'
    ];
    
    int depthScore = 0;
    for (final indicator in depthIndicators) {
      if (content.contains(indicator)) depthScore++;
    }
    
    return (depthScore / depthIndicators.length).clamp(0.0, 1.0);
  }
  
  double _calculateGrowthOrientation(String content) {
    final growthWords = [
      'learn', 'grow', 'improve', 'better', 'develop',
      'progress', 'evolve', 'transform', 'change', 'adapt',
      'goal', 'aspire', 'strive', 'work on', 'practice'
    ];
    
    int growthScore = 0;
    for (final word in growthWords) {
      if (content.contains(word)) growthScore++;
    }
    
    return (growthScore / growthWords.length * 2).clamp(0.0, 1.0);
  }
  
  double _calculateResilienceIndicator(String content, List<String> moods) {
    final resilienceWords = [
      'overcome', 'strong', 'cope', 'handle', 'manage',
      'persist', 'continue', 'survive', 'endure', 'bounce back',
      'challenge', 'difficult', 'hard', 'tough', 'struggle'
    ];
    
    int resilienceScore = 0;
    for (final word in resilienceWords) {
      if (content.contains(word)) resilienceScore++;
    }
    
    // Boost score if challenging moods are paired with positive ones
    final challengingMoods = ['stressed', 'anxious', 'sad', 'frustrated'];
    final positiveMoods = ['hopeful', 'determined', 'grateful', 'peaceful'];
    
    bool hasChallenge = moods.any((m) => challengingMoods.contains(m.toLowerCase()));
    bool hasPositive = moods.any((m) => positiveMoods.contains(m.toLowerCase()));
    
    if (hasChallenge && hasPositive) {
      resilienceScore += 3;
    }
    
    return (resilienceScore / (resilienceWords.length + 3)).clamp(0.0, 1.0);
  }
  
  double _calculateIntensity(String content, List<String> moods) {
    // Base intensity on mood count and content length
    double intensity = 0.5;
    
    // More moods = higher intensity
    intensity += moods.length * 0.1;
    
    // Longer content = higher intensity
    final wordCount = content.split(' ').length;
    if (wordCount > 100) intensity += 0.2;
    if (wordCount > 200) intensity += 0.1;
    
    // Intensity words
    final intensityWords = ['very', 'extremely', 'really', 'so ', '!', 'overwhelming', 'intense'];
    for (final word in intensityWords) {
      if (content.contains(word)) intensity += 0.05;
    }
    
    return intensity.clamp(0.0, 1.0);
  }
}

class TemporalAnalysisEngine {
  Future<TemporalContext> analyzeTemporalContext(JournalEntry entry) async {
    // Analyze time-based patterns
    final hour = entry.date.hour;
    final dayOfWeek = entry.date.weekday;
    
    // Time of day insights
    String timeContext = '';
    if (hour < 6) {
      timeContext = 'late night reflection';
    } else if (hour < 12) {
      timeContext = 'morning clarity';
    } else if (hour < 17) {
      timeContext = 'afternoon processing';
    } else if (hour < 21) {
      timeContext = 'evening contemplation';
    } else {
      timeContext = 'nighttime introspection';
    }
    
    // Detect breakthroughs (simplified for local processing)
    final isBreakthrough = entry.content.length > 200 && 
                          entry.moods.length > 2;
    
    return TemporalContext(
      timeOfDay: timeContext,
      isBreakthrough: isBreakthrough,
      hasRecurringPattern: false, // Would need historical data
      patternType: 'growth',
      patternTitle: 'Consistent Reflection',
      patternDescription: 'Regular journaling practice',
      patternStrength: 0.5,
      insights: ["Your $timeContext brings valuable self-awareness"],
    );
  }
  
  EmotionalJourney analyzeEmotionalJourney(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return EmotionalJourney(
        hasTransformation: false,
        startingPoint: '',
        currentPoint: '',
      );
    }
    
    // Compare first and last entries
    final firstMoods = entries.first.moods;
    final lastMoods = entries.last.moods;
    
    final hasTransformation = firstMoods.toSet().difference(lastMoods.toSet()).isNotEmpty;
    
    return EmotionalJourney(
      hasTransformation: hasTransformation,
      startingPoint: firstMoods.isNotEmpty ? firstMoods.first : 'neutral',
      currentPoint: lastMoods.isNotEmpty ? lastMoods.first : 'reflective',
    );
  }
}

class CoreResonanceCalculator {
  Map<String, CoreResonanceData> calculateResonances(
    JournalEntry entry,
    EmotionalProfile profile,
    TemporalContext temporal,
    ContextualInsights contextual,
  ) {
    final resonances = <String, CoreResonanceData>{};
    
    // Calculate resonance for each core based on entry content
    resonances['optimism'] = _calculateOptimismResonance(entry, profile, contextual);
    resonances['resilience'] = _calculateResilienceResonance(entry, profile, contextual);
    resonances['self_awareness'] = _calculateSelfAwarenessResonance(entry, profile, contextual);
    resonances['creativity'] = _calculateCreativityResonance(entry, profile, contextual);
    resonances['social_connection'] = _calculateSocialConnectionResonance(entry, profile, contextual);
    resonances['growth_mindset'] = _calculateGrowthMindsetResonance(entry, profile, contextual);
    
    return resonances;
  }
  
  CoreResonanceData _calculateOptimismResonance(
    JournalEntry entry,
    EmotionalProfile profile,
    ContextualInsights contextual,
  ) {
    double strength = 0.0;
    final signals = <String>[];
    
    // Mood-based resonance
    final optimisticMoods = ['happy', 'excited', 'grateful', 'hopeful', 'content'];
    for (final mood in entry.moods) {
      if (optimisticMoods.contains(mood.toLowerCase())) {
        strength += 0.2;
        signals.add('$mood mood detected');
      }
    }
    
    // Content-based resonance
    final content = entry.content.toLowerCase();
    final optimismWords = ['hope', 'bright', 'positive', 'good', 'better', 'grateful', 'thankful', 'blessed'];
    for (final word in optimismWords) {
      if (content.contains(word)) {
        strength += 0.1;
      }
    }
    
    // Context boost
    if (contextual.hasPositiveOutlook) {
      strength += 0.2;
      signals.add('Positive future orientation');
    }
    
    strength = strength.clamp(0.0, 1.0);
    
    return CoreResonanceData(
      resonanceStrength: strength,
      depthIndicator: _getDepthIndicator(strength),
      transitionSignals: signals.take(3).toList(),
      supportingEvidence: strength > 0.5 
          ? 'Your entry radiates hope and positive energy'
          : 'Gentle optimistic threads weaving through your reflection',
    );
  }
  
  CoreResonanceData _calculateResilienceResonance(
    JournalEntry entry,
    EmotionalProfile profile,
    ContextualInsights contextual,
  ) {
    double strength = 0.0;
    final signals = <String>[];
    
    // Check for resilience indicators
    if (profile.resilienceIndicator > 0.4) {
      strength += profile.resilienceIndicator;
      signals.add('Resilience patterns identified');
    }
    
    // Challenge + coping combination
    if (contextual.hasChallenge) {
      strength += 0.3;
      signals.add('Navigating challenges');
      
      if (contextual.hasCopingStrategy) {
        strength += 0.2;
        signals.add('Active coping strategies');
      }
    }
    
    // Recovery patterns
    final content = entry.content.toLowerCase();
    if (content.contains('bounce back') || content.contains('recover') || content.contains('stronger')) {
      strength += 0.2;
      signals.add('Recovery mindset active');
    }
    
    strength = strength.clamp(0.0, 1.0);
    
    return CoreResonanceData(
      resonanceStrength: strength,
      depthIndicator: _getDepthIndicator(strength),
      transitionSignals: signals.take(3).toList(),
      supportingEvidence: strength > 0.5
          ? 'Transforming challenges into growth opportunities'
          : 'Building resilience through experience',
    );
  }
  
  CoreResonanceData _calculateSelfAwarenessResonance(
    JournalEntry entry,
    EmotionalProfile profile,
    ContextualInsights contextual,
  ) {
    double strength = 0.3; // Base strength for journaling itself
    final signals = <String>['Active self-reflection'];
    
    // Emotional depth bonus
    strength += profile.emotionalDepth * 0.3;
    if (profile.emotionalDepth > 0.5) {
      signals.add('Deep emotional exploration');
    }
    
    // Multiple emotions = higher awareness
    if (entry.moods.length > 2) {
      strength += 0.2;
      signals.add('Nuanced emotional recognition');
    }
    
    // Insight language
    final content = entry.content.toLowerCase();
    final awarenessWords = ['realize', 'understand', 'notice', 'aware', 'discover', 'insight', 'pattern'];
    int awarenessCount = 0;
    for (final word in awarenessWords) {
      if (content.contains(word)) awarenessCount++;
    }
    strength += (awarenessCount * 0.1).clamp(0.0, 0.3);
    
    strength = strength.clamp(0.0, 1.0);
    
    return CoreResonanceData(
      resonanceStrength: strength,
      depthIndicator: _getDepthIndicator(strength),
      transitionSignals: signals.take(3).toList(),
      supportingEvidence: 'Your reflective practice deepens self-understanding',
    );
  }
  
  CoreResonanceData _calculateCreativityResonance(
    JournalEntry entry,
    EmotionalProfile profile,
    ContextualInsights contextual,
  ) {
    double strength = 0.0;
    final signals = <String>[];
    
    // Creative moods
    final creativeMoods = ['creative', 'inspired', 'playful', 'curious', 'imaginative'];
    for (final mood in entry.moods) {
      if (creativeMoods.contains(mood.toLowerCase())) {
        strength += 0.3;
        signals.add('Creative energy present');
      }
    }
    
    // Creative content
    final content = entry.content.toLowerCase();
    final creativeWords = ['create', 'imagine', 'idea', 'design', 'art', 'music', 'write', 'build', 'invent'];
    for (final word in creativeWords) {
      if (content.contains(word)) {
        strength += 0.15;
      }
    }
    
    // Metaphorical language (simplified check)
    if (content.contains(' like ') || content.contains(' as if ')) {
      strength += 0.1;
      signals.add('Metaphorical thinking');
    }
    
    strength = strength.clamp(0.0, 1.0);
    
    return CoreResonanceData(
      resonanceStrength: strength,
      depthIndicator: _getDepthIndicator(strength),
      transitionSignals: signals.take(3).toList(),
      supportingEvidence: strength > 0.3
          ? 'Creative impulses flowing through your expression'
          : 'Creative potential quietly present',
    );
  }
  
  CoreResonanceData _calculateSocialConnectionResonance(
    JournalEntry entry,
    EmotionalProfile profile,
    ContextualInsights contextual,
  ) {
    double strength = 0.0;
    final signals = <String>[];
    
    // Social moods
    final socialMoods = ['social', 'connected', 'loved', 'grateful', 'appreciated'];
    for (final mood in entry.moods) {
      if (socialMoods.contains(mood.toLowerCase())) {
        strength += 0.25;
        signals.add('Social fulfillment');
      }
    }
    
    // Relationship content
    final content = entry.content.toLowerCase();
    final socialWords = ['friend', 'family', 'partner', 'colleague', 'community', 'together', 'share', 'connect', 'relationship', 'love', 'support'];
    int socialCount = 0;
    for (final word in socialWords) {
      if (content.contains(word)) {
        socialCount++;
      }
    }
    strength += (socialCount * 0.1).clamp(0.0, 0.5);
    
    if (socialCount > 2) {
      signals.add('Rich social reflections');
    }
    
    strength = strength.clamp(0.0, 1.0);
    
    return CoreResonanceData(
      resonanceStrength: strength,
      depthIndicator: _getDepthIndicator(strength),
      transitionSignals: signals.take(3).toList(),
      supportingEvidence: strength > 0.4
          ? 'Meaningful connections enriching your journey'
          : 'Social awareness gently present',
    );
  }
  
  CoreResonanceData _calculateGrowthMindsetResonance(
    JournalEntry entry,
    EmotionalProfile profile,
    ContextualInsights contextual,
  ) {
    double strength = 0.0;
    final signals = <String>[];
    
    // Growth orientation from profile
    strength += profile.growthOrientation * 0.5;
    if (profile.growthOrientation > 0.5) {
      signals.add('Strong growth orientation');
    }
    
    // Learning indicators
    if (contextual.hasLearningMoment) {
      strength += 0.3;
      signals.add('Active learning captured');
    }
    
    // Future-focused content
    final content = entry.content.toLowerCase();
    if (content.contains('will') || content.contains('going to') || content.contains('plan')) {
      strength += 0.1;
      signals.add('Future-focused thinking');
    }
    
    // Goal-oriented language
    if (content.contains('goal') || content.contains('improve') || content.contains('better')) {
      strength += 0.15;
    }
    
    strength = strength.clamp(0.0, 1.0);
    
    return CoreResonanceData(
      resonanceStrength: strength,
      depthIndicator: _getDepthIndicator(strength),
      transitionSignals: signals.take(3).toList(),
      supportingEvidence: 'Your growth mindset transforms experiences into wisdom',
    );
  }
  
  String _getDepthIndicator(double strength) {
    if (strength > 0.8) return 'profound';
    if (strength > 0.6) return 'deep';
    if (strength > 0.4) return 'developing';
    if (strength > 0.2) return 'emerging';
    return 'surface';
  }
}

class ContextAnalyzer {
  ContextualInsights extractContextualInsights(JournalEntry entry) {
    final content = entry.content.toLowerCase();
    final themes = <String>[];
    final growthIndicators = <String>[];
    
    // Life domains
    if (content.contains('work') || content.contains('job') || content.contains('career')) {
      themes.add('career');
    }
    if (content.contains('family') || content.contains('home')) {
      themes.add('family');
    }
    if (content.contains('health') || content.contains('exercise') || content.contains('sleep')) {
      themes.add('health');
    }
    if (content.contains('friend') || content.contains('social')) {
      themes.add('relationships');
    }
    
    // Growth indicators
    if (content.contains('learn')) {
      growthIndicators.add('learning_orientation');
    }
    if (content.contains('challenge') && (content.contains('overcome') || content.contains('face'))) {
      growthIndicators.add('challenge_navigation');
    }
    if (content.contains('grateful') || content.contains('thankful')) {
      growthIndicators.add('gratitude_practice');
    }
    if (content.contains('goal') || content.contains('plan')) {
      growthIndicators.add('goal_setting');
    }
    
    // Default theme
    if (themes.isEmpty) {
      themes.add('personal growth');
    }
    
    return ContextualInsights(
      themes: themes,
      primaryTheme: themes.first,
      hasChallenge: content.contains('difficult') || content.contains('hard') || content.contains('struggle'),
      hasGrowthIndicators: growthIndicators.isNotEmpty,
      growthIndicators: growthIndicators,
      hasPositiveOutlook: content.contains('hope') || content.contains('better') || content.contains('improve'),
      hasLifeTransition: content.contains('change') || content.contains('new') || content.contains('transition'),
      hasCopingStrategy: content.contains('cope') || content.contains('manage') || content.contains('handle'),
      hasLearningMoment: content.contains('learn') || content.contains('realize') || content.contains('understand'),
    );
  }
}

// Data classes
class EmotionalProfile {
  final List<String> primaryEmotions;
  final String dominantEmotion;
  final double emotionalComplexity;
  final double emotionalDepth;
  final double intensity;
  final double growthOrientation;
  final double resilienceIndicator;
  
  EmotionalProfile({
    required this.primaryEmotions,
    required this.dominantEmotion,
    required this.emotionalComplexity,
    required this.emotionalDepth,
    required this.intensity,
    required this.growthOrientation,
    required this.resilienceIndicator,
  });
}

class TemporalContext {
  final String timeOfDay;
  final bool isBreakthrough;
  final bool hasRecurringPattern;
  final String patternType;
  final String patternTitle;
  final String patternDescription;
  final double patternStrength;
  final List<String> insights;
  
  TemporalContext({
    required this.timeOfDay,
    required this.isBreakthrough,
    required this.hasRecurringPattern,
    required this.patternType,
    required this.patternTitle,
    required this.patternDescription,
    required this.patternStrength,
    required this.insights,
  });
}

class ContextualInsights {
  final List<String> themes;
  final String primaryTheme;
  final bool hasChallenge;
  final bool hasGrowthIndicators;
  final List<String> growthIndicators;
  final bool hasPositiveOutlook;
  final bool hasLifeTransition;
  final bool hasCopingStrategy;
  final bool hasLearningMoment;
  
  ContextualInsights({
    required this.themes,
    required this.primaryTheme,
    required this.hasChallenge,
    required this.hasGrowthIndicators,
    required this.growthIndicators,
    required this.hasPositiveOutlook,
    required this.hasLifeTransition,
    required this.hasCopingStrategy,
    required this.hasLearningMoment,
  });
}

class MonthlyPatterns {
  final String? dominantPattern;
  final Map<String, int> moodDistribution;
  final Map<String, int> temporalPatterns;
  
  MonthlyPatterns({
    required this.dominantPattern,
    required this.moodDistribution,
    required this.temporalPatterns,
  });
}

class EmotionalJourney {
  final bool hasTransformation;
  final String startingPoint;
  final String currentPoint;
  
  EmotionalJourney({
    required this.hasTransformation,
    required this.startingPoint,
    required this.currentPoint,
  });
}

class GrowthMetrics {
  final double overallGrowth;
  final String strongestGrowthArea;
  
  GrowthMetrics({
    required this.overallGrowth,
    required this.strongestGrowthArea,
  });
}