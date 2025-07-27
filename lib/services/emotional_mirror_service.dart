import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import '../models/emotional_mirror_data.dart';
import '../repositories/journal_repository.dart';
import '../repositories/journal_repository_impl.dart';
import '../services/core_library_service.dart';
import '../services/emotional_analyzer.dart';

/// Service for providing emotional mirror data and insights
/// 
/// This service aggregates journal entries and AI analysis data to provide
/// comprehensive emotional insights, patterns, and trends for the emotional mirror screen.
class EmotionalMirrorService {
  static final EmotionalMirrorService _instance = EmotionalMirrorService._internal();
  factory EmotionalMirrorService() => _instance;
  EmotionalMirrorService._internal();

  final JournalRepository _journalRepository = JournalRepositoryImpl();
  final CoreLibraryService _coreLibraryService = CoreLibraryService();
  final EmotionalAnalyzer _emotionalAnalyzer = EmotionalAnalyzer();

  /// Get comprehensive emotional mirror data
  Future<EmotionalMirrorData> getEmotionalMirrorData({
    int daysBack = 30,
  }) async {
    try {
      // Get recent entries
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));
      final entries = await _journalRepository.getEntriesByDateRange(startDate, endDate);
      
      // Get analyzed entries only
      final analyzedEntries = entries.where((entry) => entry.isAnalyzed && entry.aiAnalysis != null).toList();
      
      // Get current cores
      final cores = await _coreLibraryService.getAllCores();
      
      // Calculate mood overview
      final moodOverview = _calculateMoodOverview(analyzedEntries);
      
      // Calculate emotional trends
      final trends = _calculateEmotionalTrends(analyzedEntries);
      
      // Get emotional patterns
      final patterns = _emotionalAnalyzer.identifyPatterns(entries);
      
      // Calculate emotional balance
      final balance = _calculateEmotionalBalance(analyzedEntries);
      
      // Generate insights
      final insights = _generateEmotionalInsights(analyzedEntries, cores, patterns);
      
      // Calculate self-awareness score
      final selfAwarenessScore = _calculateSelfAwarenessScore(analyzedEntries, cores);
      
      return EmotionalMirrorData(
        moodOverview: moodOverview,
        emotionalTrends: trends,
        emotionalPatterns: patterns,
        emotionalBalance: balance,
        insights: insights,
        selfAwarenessScore: selfAwarenessScore,
        totalEntries: entries.length,
        analyzedEntries: analyzedEntries.length,
        dateRange: DateRange(startDate, endDate),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('EmotionalMirrorService getEmotionalMirrorData error: $e');
      return _createFallbackMirrorData();
    }
  }

  /// Get mood distribution data for charts
  Future<MoodDistribution> getMoodDistribution({
    int daysBack = 30,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));
      final entries = await _journalRepository.getEntriesByDateRange(startDate, endDate);
      
      // Count manual moods
      final manualMoodCounts = <String, int>{};
      // Count AI-detected moods
      final aiMoodCounts = <String, int>{};
      
      for (final entry in entries) {
        // Count manual moods
        for (final mood in entry.moods) {
          manualMoodCounts[mood] = (manualMoodCounts[mood] ?? 0) + 1;
        }
        
        // Count AI-detected moods
        if (entry.aiAnalysis != null) {
          for (final emotion in entry.aiAnalysis!.primaryEmotions) {
            aiMoodCounts[emotion] = (aiMoodCounts[emotion] ?? 0) + 1;
          }
        }
      }
      
      return MoodDistribution(
        manualMoods: manualMoodCounts,
        aiDetectedMoods: aiMoodCounts,
        totalEntries: entries.length,
        dateRange: DateRange(startDate, endDate),
      );
    } catch (e) {
      debugPrint('EmotionalMirrorService getMoodDistribution error: $e');
      return MoodDistribution(
        manualMoods: {},
        aiDetectedMoods: {},
        totalEntries: 0,
        dateRange: DateRange(DateTime.now().subtract(Duration(days: daysBack)), DateTime.now()),
      );
    }
  }

  /// Get emotional intensity trends over time
  Future<List<EmotionalTrendPoint>> getEmotionalIntensityTrend({
    int daysBack = 30,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));
      final entries = await _journalRepository.getEntriesByDateRange(startDate, endDate);
      
      // Group entries by day and calculate average intensity
      final dailyIntensities = <DateTime, List<double>>{};
      
      for (final entry in entries) {
        final dayKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
        
        double intensity = 0.5; // Default neutral intensity
        
        if (entry.aiAnalysis != null) {
          intensity = entry.aiAnalysis!.emotionalIntensity;
        } else if (entry.emotionalIntensity != null) {
          intensity = entry.emotionalIntensity!;
        }
        
        dailyIntensities[dayKey] ??= [];
        dailyIntensities[dayKey]!.add(intensity);
      }
      
      // Calculate trend points
      final trendPoints = <EmotionalTrendPoint>[];
      final sortedDays = dailyIntensities.keys.toList()..sort();
      
      for (final day in sortedDays) {
        final intensities = dailyIntensities[day]!;
        final avgIntensity = intensities.reduce((a, b) => a + b) / intensities.length;
        
        trendPoints.add(EmotionalTrendPoint(
          date: day,
          intensity: avgIntensity,
          entryCount: intensities.length,
        ));
      }
      
      return trendPoints;
    } catch (e) {
      debugPrint('EmotionalMirrorService getEmotionalIntensityTrend error: $e');
      return [];
    }
  }

  /// Get sentiment trends over time
  Future<List<SentimentTrendPoint>> getSentimentTrend({
    int daysBack = 30,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));
      final entries = await _journalRepository.getEntriesByDateRange(startDate, endDate);
      
      // Group entries by day and calculate sentiment
      final dailySentiments = <DateTime, List<double>>{};
      
      for (final entry in entries) {
        final dayKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
        
        double sentiment = 0.0; // Default neutral sentiment
        
        if (entry.aiAnalysis != null) {
          // Use AI analysis if available
          sentiment = _calculateSentimentFromEmotions(entry.aiAnalysis!.primaryEmotions);
        } else {
          // Calculate from manual moods
          sentiment = _calculateSentimentFromMoods(entry.moods);
        }
        
        dailySentiments[dayKey] ??= [];
        dailySentiments[dayKey]!.add(sentiment);
      }
      
      // Calculate trend points
      final trendPoints = <SentimentTrendPoint>[];
      final sortedDays = dailySentiments.keys.toList()..sort();
      
      for (final day in sortedDays) {
        final sentiments = dailySentiments[day]!;
        final avgSentiment = sentiments.reduce((a, b) => a + b) / sentiments.length;
        
        trendPoints.add(SentimentTrendPoint(
          date: day,
          sentiment: avgSentiment,
          entryCount: sentiments.length,
        ));
      }
      
      return trendPoints;
    } catch (e) {
      debugPrint('EmotionalMirrorService getSentimentTrend error: $e');
      return [];
    }
  }

  /// Get pattern recognition data showing emotional journey
  Future<EmotionalJourneyData> getEmotionalJourney({
    int daysBack = 90,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));
      final entries = await _journalRepository.getEntriesByDateRange(startDate, endDate);
      
      // Analyze patterns over time
      final patterns = _emotionalAnalyzer.identifyPatterns(entries);
      
      // Get emotional trends
      final trends = _emotionalAnalyzer.analyzeEmotionalTrends(entries);
      
      // Calculate journey milestones
      final milestones = _calculateJourneyMilestones(entries);
      
      // Get core evolution over time
      final cores = await _coreLibraryService.getAllCores();
      final coreEvolution = _calculateCoreEvolution(entries, cores);
      
      return EmotionalJourneyData(
        patterns: patterns,
        trends: trends,
        milestones: milestones,
        coreEvolution: coreEvolution,
        totalEntries: entries.length,
        dateRange: DateRange(startDate, endDate),
      );
    } catch (e) {
      debugPrint('EmotionalMirrorService getEmotionalJourney error: $e');
      return EmotionalJourneyData(
        patterns: [],
        trends: {},
        milestones: [],
        coreEvolution: {},
        totalEntries: 0,
        dateRange: DateRange(DateTime.now().subtract(Duration(days: daysBack)), DateTime.now()),
      );
    }
  }

  // Private helper methods

  MoodOverview _calculateMoodOverview(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return MoodOverview(
        dominantMoods: ['neutral'],
        moodBalance: 0.0,
        emotionalVariety: 0.0,
        description: 'Start journaling to discover your emotional patterns.',
      );
    }

    // Collect all emotions from AI analysis
    final allEmotions = <String>[];
    double totalIntensity = 0.0;
    int intensityCount = 0;

    for (final entry in entries) {
      if (entry.aiAnalysis != null) {
        allEmotions.addAll(entry.aiAnalysis!.primaryEmotions);
        totalIntensity += entry.aiAnalysis!.emotionalIntensity;
        intensityCount++;
      }
    }

    // Calculate dominant moods
    final emotionCounts = <String, int>{};
    for (final emotion in allEmotions) {
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }

    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final dominantMoods = sortedEmotions.take(4).map((e) => e.key).toList();
    
    // Calculate mood balance (sentiment)
    final moodBalance = _calculateSentimentFromEmotions(allEmotions);
    
    // Calculate emotional variety
    final uniqueEmotions = emotionCounts.keys.length;
    final emotionalVariety = (uniqueEmotions / 10.0).clamp(0.0, 1.0); // Normalize to 0-1

    // Generate description
    final avgIntensity = intensityCount > 0 ? totalIntensity / intensityCount : 0.5;
    final description = _generateMoodDescription(dominantMoods, moodBalance, avgIntensity);

    return MoodOverview(
      dominantMoods: dominantMoods.isNotEmpty ? dominantMoods : ['neutral'],
      moodBalance: moodBalance,
      emotionalVariety: emotionalVariety,
      description: description,
    );
  }

  Map<String, dynamic> _calculateEmotionalTrends(List<JournalEntry> entries) {
    return _emotionalAnalyzer.analyzeEmotionalTrends(entries);
  }

  EmotionalBalance _calculateEmotionalBalance(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return EmotionalBalance(
        positiveRatio: 0.5,
        negativeRatio: 0.5,
        neutralRatio: 0.0,
        overallBalance: 0.0,
        balanceDescription: 'Start journaling to understand your emotional balance.',
      );
    }

    int positiveCount = 0;
    int negativeCount = 0;
    int neutralCount = 0;

    for (final entry in entries) {
      if (entry.aiAnalysis != null) {
        final sentiment = _calculateSentimentFromEmotions(entry.aiAnalysis!.primaryEmotions);
        if (sentiment > 0.1) {
          positiveCount++;
        } else if (sentiment < -0.1) {
          negativeCount++;
        } else {
          neutralCount++;
        }
      }
    }

    final total = entries.length;
    final positiveRatio = positiveCount / total;
    final negativeRatio = negativeCount / total;
    final neutralRatio = neutralCount / total;
    final overallBalance = (positiveCount - negativeCount) / total;

    final balanceDescription = _generateBalanceDescription(positiveRatio, negativeRatio, overallBalance);

    return EmotionalBalance(
      positiveRatio: positiveRatio,
      negativeRatio: negativeRatio,
      neutralRatio: neutralRatio,
      overallBalance: overallBalance,
      balanceDescription: balanceDescription,
    );
  }

  List<String> _generateEmotionalInsights(
    List<JournalEntry> entries,
    List<EmotionalCore> cores,
    List<EmotionalPattern> patterns,
  ) {
    final insights = <String>[];

    if (entries.isEmpty) {
      insights.add('Start journaling to discover insights about your emotional patterns.');
      return insights;
    }

    // Create a set to track unique insights and avoid duplicates
    final uniqueInsights = <String>{};
    
    // Analyze recent AI insights with deduplication
    final recentInsights = entries
        .where((entry) => entry.aiAnalysis?.personalizedInsight != null)
        .map((entry) => entry.aiAnalysis!.personalizedInsight!)
        .where((insight) => insight.trim().isNotEmpty)
        .toList();
    
    // Add diverse AI insights by checking for similarity
    for (final insight in recentInsights) {
      if (_isInsightUnique(insight, uniqueInsights) && uniqueInsights.length < 2) {
        uniqueInsights.add(insight);
      }
    }
    
    // Generate trend-based insights
    final trendInsight = _generateTrendInsight(entries);
    if (trendInsight.isNotEmpty && _isInsightUnique(trendInsight, uniqueInsights)) {
      uniqueInsights.add(trendInsight);
    }
    
    // Add core-based insights with variety
    final coreInsight = _generateCoreInsight(cores);
    if (coreInsight.isNotEmpty && _isInsightUnique(coreInsight, uniqueInsights)) {
      uniqueInsights.add(coreInsight);
    }
    
    // Add pattern-based insights
    final patternInsight = _generatePatternInsight(patterns, entries);
    if (patternInsight.isNotEmpty && _isInsightUnique(patternInsight, uniqueInsights)) {
      uniqueInsights.add(patternInsight);
    }
    
    // Add emotional balance insight if we need more variety
    if (uniqueInsights.length < 3) {
      final balanceInsight = _generateBalanceInsight(entries);
      if (_isInsightUnique(balanceInsight, uniqueInsights)) {
        uniqueInsights.add(balanceInsight);
      }
    }
    
    // Ensure we have at least 2 insights
    if (uniqueInsights.length < 2) {
      uniqueInsights.add('Your emotional self-awareness continues to develop through consistent journaling practice.');
    }
    
    return uniqueInsights.take(4).toList();
  }

  /// Check if an insight is sufficiently unique compared to existing insights
  bool _isInsightUnique(String newInsight, Set<String> existingInsights) {
    if (existingInsights.isEmpty) return true;
    
    final newWords = newInsight.toLowerCase().split(RegExp(r'\W+'));
    
    for (final existing in existingInsights) {
      final existingWords = existing.toLowerCase().split(RegExp(r'\W+'));
      
      // Calculate word overlap
      final commonWords = newWords.where((word) => 
        existingWords.contains(word) && word.length > 3).length;
      
      // If more than 40% of significant words overlap, consider it similar
      final overlapRatio = commonWords / (newWords.where((w) => w.length > 3).length);
      if (overlapRatio > 0.4) {
        return false;
      }
    }
    
    return true;
  }

  /// Generate trend-based insight
  String _generateTrendInsight(List<JournalEntry> entries) {
    if (entries.length < 3) return '';
    
    // Analyze emotional intensity trends
    final recentEntries = entries.take(7).toList();
    final intensities = recentEntries
        .where((e) => e.aiAnalysis?.emotionalIntensity != null)
        .map((e) => e.aiAnalysis!.emotionalIntensity)
        .toList();
    
    if (intensities.length >= 3) {
      final avgEarly = intensities.take(intensities.length ~/ 2).fold(0.0, (a, b) => a + b) / (intensities.length ~/ 2);
      final avgRecent = intensities.skip(intensities.length ~/ 2).fold(0.0, (a, b) => a + b) / (intensities.length - intensities.length ~/ 2);
      
      if (avgRecent > avgEarly + 0.1) {
        return 'Your emotional intensity has been increasing recently, suggesting deeper engagement with your feelings.';
      } else if (avgEarly > avgRecent + 0.1) {
        return 'You\'ve been experiencing more balanced emotional states lately, indicating growing emotional regulation.';
      }
    }
    
    // Analyze consistency patterns
    final journalingFreq = entries.length / 30.0; // entries per day over 30 days
    if (journalingFreq > 0.8) {
      return 'Your consistent journaling practice demonstrates strong commitment to emotional self-discovery.';
    } else if (journalingFreq > 0.5) {
      return 'Regular journaling sessions are building your emotional vocabulary and self-awareness.';
    }
    
    return '';
  }

  /// Generate core-based insight with variety
  String _generateCoreInsight(List<EmotionalCore> cores) {
    if (cores.isEmpty) return '';
    
    // Sort cores by percentage to find patterns
    final sortedCores = cores.toList()..sort((a, b) => b.percentage.compareTo(a.percentage));
    
    final strongCores = sortedCores.where((core) => core.percentage > 70.0).toList();
    final growingCores = sortedCores.where((core) => 
      core.currentLevel > core.previousLevel && core.percentage > 50.0).toList();
    
    if (strongCores.isNotEmpty) {
      final topCore = strongCores.first;
      final coreInsights = [
        'Your ${topCore.name} core shows exceptional development, reflecting consistent growth in this area.',
        '${topCore.name} emerges as a dominant strength, influencing your emotional responses and decisions.',
        'Strong ${topCore.name} patterns suggest this quality is becoming integral to your personality.',
        'Your well-developed ${topCore.name} core provides a stable foundation for emotional well-being.',
      ];
      final hash = topCore.name.hashCode.abs();
      return coreInsights[hash % coreInsights.length];
    }
    
    if (growingCores.isNotEmpty) {
      final growingCore = growingCores.first;
      return 'Your ${growingCore.name} core is actively developing, showing promising upward trends.';
    }
    
    if (sortedCores.isNotEmpty) {
      return 'Your personality cores show unique patterns that reflect your individual emotional journey.';
    }
    
    return '';
  }

  /// Generate pattern-based insight
  String _generatePatternInsight(List<EmotionalPattern> patterns, List<JournalEntry> entries) {
    if (patterns.isEmpty) return '';
    
    final growthPatterns = patterns.where((p) => p.type == 'growth').toList();
    final challengePatterns = patterns.where((p) => p.type == 'challenge').toList();
    
    if (growthPatterns.isNotEmpty) {
      // Vary the growth pattern insight
      final pattern = growthPatterns.first;
      if (pattern.confidence > 0.7) {
        return 'Strong ${pattern.title.toLowerCase()} patterns indicate significant emotional development.';
      } else {
        return 'Emerging ${pattern.title.toLowerCase()} trends suggest new areas of personal growth.';
      }
    }
    
    if (challengePatterns.isNotEmpty && entries.length > 5) {
      return 'Recognizing challenging patterns is the first step toward emotional resilience and growth.';
    }
    
    return '';
  }

  /// Generate emotional balance insight
  String _generateBalanceInsight(List<JournalEntry> entries) {
    final positiveEmotions = ['happy', 'grateful', 'excited', 'calm', 'content', 'joyful'];
    final challengingEmotions = ['sad', 'anxious', 'stressed', 'frustrated', 'worried'];
    
    int positiveCount = 0;
    int challengingCount = 0;
    
    for (final entry in entries) {
      if (entry.aiAnalysis?.primaryEmotions.isNotEmpty == true) {
        for (final emotion in entry.aiAnalysis!.primaryEmotions) {
          if (positiveEmotions.contains(emotion.toLowerCase())) {
            positiveCount++;
          } else if (challengingEmotions.contains(emotion.toLowerCase())) {
            challengingCount++;
          }
        }
      }
    }
    
    final total = positiveCount + challengingCount;
    if (total == 0) return 'Your emotional journey is just beginning - each entry adds valuable insight.';
    
    final positiveRatio = positiveCount / total;
    
    if (positiveRatio > 0.7) {
      return 'Your emotional landscape shows predominantly positive patterns, reflecting inner contentment.';
    } else if (positiveRatio < 0.3) {
      return 'Processing challenging emotions demonstrates emotional courage and commitment to growth.';
    } else {
      return 'Your emotional balance reflects the natural complexity of human experience and growth.';
    }
  }

  double _calculateSelfAwarenessScore(List<JournalEntry> entries, List<EmotionalCore> cores) {
    if (entries.isEmpty) return 0.3;

    double score = 0.0;

    // Base score from journaling consistency
    score += (entries.length / 30.0).clamp(0.0, 0.3); // Up to 30% for consistency

    // Score from AI analysis usage
    final analyzedCount = entries.where((entry) => entry.isAnalyzed).length;
    score += (analyzedCount / entries.length) * 0.3; // Up to 30% for AI analysis

    // Score from emotional variety
    final allEmotions = <String>{};
    for (final entry in entries) {
      if (entry.aiAnalysis != null) {
        allEmotions.addAll(entry.aiAnalysis!.primaryEmotions);
      }
    }
    score += (allEmotions.length / 15.0).clamp(0.0, 0.2); // Up to 20% for emotional variety

    // Score from core development
    final avgCorePercentage = cores.isNotEmpty 
        ? cores.map((core) => core.percentage).reduce((a, b) => a + b) / cores.length / 100.0
        : 0.0;
    score += avgCorePercentage * 0.2; // Up to 20% for core development

    return score.clamp(0.0, 1.0);
  }

  double _calculateSentimentFromEmotions(List<String> emotions) {
    final positiveEmotions = ['happy', 'joyful', 'excited', 'grateful', 'content', 'peaceful', 'love', 'joy', 'optimistic', 'confident'];
    final negativeEmotions = ['sad', 'angry', 'frustrated', 'anxious', 'worried', 'fear', 'disappointment', 'stress', 'overwhelmed'];

    double sentiment = 0.0;
    for (final emotion in emotions) {
      if (positiveEmotions.contains(emotion.toLowerCase())) {
        sentiment += 0.3;
      } else if (negativeEmotions.contains(emotion.toLowerCase())) {
        sentiment -= 0.3;
      }
    }

    return sentiment.clamp(-1.0, 1.0);
  }

  double _calculateSentimentFromMoods(List<String> moods) {
    return _calculateSentimentFromEmotions(moods);
  }

  String _generateMoodDescription(List<String> dominantMoods, double balance, double intensity) {
    if (dominantMoods.isEmpty) {
      return 'Your emotional patterns are developing as you continue journaling.';
    }

    final moodText = dominantMoods.take(2).join(' and ');
    
    if (balance > 0.3) {
      return 'Your emotions show a healthy balance with $moodText being prominent, reflecting a positive mindset.';
    } else if (balance < -0.3) {
      return 'You\'ve been experiencing $moodText frequently. Remember that difficult emotions are part of growth.';
    } else {
      return 'Your emotions show a balanced mix with $moodText being most common, indicating emotional stability.';
    }
  }

  String _generateBalanceDescription(double positive, double negative, double balance) {
    if (balance > 0.3) {
      return 'Your emotional state leans positive, with ${(positive * 100).round()}% of entries showing positive emotions.';
    } else if (balance < -0.3) {
      return 'You\'ve been processing some challenging emotions. This reflection is valuable for growth.';
    } else {
      return 'Your emotions show a healthy balance between positive and challenging experiences.';
    }
  }

  List<JourneyMilestone> _calculateJourneyMilestones(List<JournalEntry> entries) {
    final milestones = <JourneyMilestone>[];

    if (entries.isEmpty) return milestones;

    // First entry milestone
    final firstEntry = entries.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
    milestones.add(JourneyMilestone(
      title: 'Started Your Journey',
      description: 'You began your journaling practice',
      date: firstEntry.date,
      type: 'start',
    ));

    // Entry count milestones
    if (entries.length >= 10) {
      milestones.add(JourneyMilestone(
        title: '10 Entries Milestone',
        description: 'Consistent journaling practice established',
        date: entries[9].date,
        type: 'consistency',
      ));
    }

    if (entries.length >= 30) {
      milestones.add(JourneyMilestone(
        title: '30 Entries Milestone',
        description: 'Strong commitment to self-reflection',
        date: entries[29].date,
        type: 'consistency',
      ));
    }

    // AI analysis milestone
    final firstAnalyzed = entries.where((entry) => entry.isAnalyzed).toList();
    if (firstAnalyzed.isNotEmpty) {
      milestones.add(JourneyMilestone(
        title: 'First AI Analysis',
        description: 'Started receiving personalized insights',
        date: firstAnalyzed.first.date,
        type: 'growth',
      ));
    }

    return milestones..sort((a, b) => a.date.compareTo(b.date));
  }

  Map<String, List<CoreEvolutionPoint>> _calculateCoreEvolution(List<JournalEntry> entries, List<EmotionalCore> cores) {
    final evolution = <String, List<CoreEvolutionPoint>>{};

    for (final core in cores) {
      evolution[core.name] = [
        CoreEvolutionPoint(
          date: DateTime.now().subtract(Duration(days: 30)),
          percentage: (core.percentage * 0.8).clamp(0.0, 100.0), // Simulate past value
        ),
        CoreEvolutionPoint(
          date: DateTime.now(),
          percentage: core.percentage,
        ),
      ];
    }

    return evolution;
  }

  EmotionalMirrorData _createFallbackMirrorData() {
    return EmotionalMirrorData(
      moodOverview: MoodOverview(
        dominantMoods: ['neutral'],
        moodBalance: 0.0,
        emotionalVariety: 0.0,
        description: 'Start journaling to discover your emotional patterns.',
      ),
      emotionalTrends: {},
      emotionalPatterns: [],
      emotionalBalance: EmotionalBalance(
        positiveRatio: 0.5,
        negativeRatio: 0.5,
        neutralRatio: 0.0,
        overallBalance: 0.0,
        balanceDescription: 'Start journaling to understand your emotional balance.',
      ),
      insights: ['Welcome to your emotional mirror. Start journaling to see your patterns unfold.'],
      selfAwarenessScore: 0.3,
      totalEntries: 0,
      analyzedEntries: 0,
      dateRange: DateRange(DateTime.now().subtract(Duration(days: 30)), DateTime.now()),
      lastUpdated: DateTime.now(),
    );
  }
}
