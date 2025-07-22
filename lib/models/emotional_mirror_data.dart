import 'package:spiral_journal/models/core.dart';

/// Data models for emotional mirror functionality

class EmotionalMirrorData {
  final MoodOverview moodOverview;
  final Map<String, dynamic> emotionalTrends;
  final List<EmotionalPattern> emotionalPatterns;
  final EmotionalBalance emotionalBalance;
  final List<String> insights;
  final double selfAwarenessScore;
  final int totalEntries;
  final int analyzedEntries;
  final DateRange dateRange;
  final DateTime lastUpdated;

  EmotionalMirrorData({
    required this.moodOverview,
    required this.emotionalTrends,
    required this.emotionalPatterns,
    required this.emotionalBalance,
    required this.insights,
    required this.selfAwarenessScore,
    required this.totalEntries,
    required this.analyzedEntries,
    required this.dateRange,
    required this.lastUpdated,
  });
}

class MoodOverview {
  final List<String> dominantMoods;
  final double moodBalance; // -1 to 1
  final double emotionalVariety; // 0 to 1
  final String description;

  MoodOverview({
    required this.dominantMoods,
    required this.moodBalance,
    required this.emotionalVariety,
    required this.description,
  });
}

class EmotionalBalance {
  final double positiveRatio;
  final double negativeRatio;
  final double neutralRatio;
  final double overallBalance;
  final String balanceDescription;

  EmotionalBalance({
    required this.positiveRatio,
    required this.negativeRatio,
    required this.neutralRatio,
    required this.overallBalance,
    required this.balanceDescription,
  });
}

class MoodDistribution {
  final Map<String, int> manualMoods;
  final Map<String, int> aiDetectedMoods;
  final int totalEntries;
  final DateRange dateRange;

  MoodDistribution({
    required this.manualMoods,
    required this.aiDetectedMoods,
    required this.totalEntries,
    required this.dateRange,
  });
}

class EmotionalTrendPoint {
  final DateTime date;
  final double intensity;
  final int entryCount;

  EmotionalTrendPoint({
    required this.date,
    required this.intensity,
    required this.entryCount,
  });
}

class SentimentTrendPoint {
  final DateTime date;
  final double sentiment;
  final int entryCount;

  SentimentTrendPoint({
    required this.date,
    required this.sentiment,
    required this.entryCount,
  });
}

class EmotionalJourneyData {
  final List<EmotionalPattern> patterns;
  final Map<String, dynamic> trends;
  final List<JourneyMilestone> milestones;
  final Map<String, List<CoreEvolutionPoint>> coreEvolution;
  final int totalEntries;
  final DateRange dateRange;

  EmotionalJourneyData({
    required this.patterns,
    required this.trends,
    required this.milestones,
    required this.coreEvolution,
    required this.totalEntries,
    required this.dateRange,
  });
}

class JourneyMilestone {
  final String title;
  final String description;
  final DateTime date;
  final String type; // 'start', 'consistency', 'growth', 'achievement'

  JourneyMilestone({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });
}

class CoreEvolutionPoint {
  final DateTime date;
  final double percentage;

  CoreEvolutionPoint({
    required this.date,
    required this.percentage,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  int get daysDifference => end.difference(start).inDays;
}
