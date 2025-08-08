import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../design_system/heading_system.dart';
import '../design_system/component_library.dart';
import '../models/journal_entry.dart';

class EmotionalJourneyVisualization extends StatelessWidget {
  final List<JournalEntry> recentEntries;
  final List<String> dominantMoods;

  const EmotionalJourneyVisualization({
    super.key,
    required this.recentEntries,
    required this.dominantMoods,
  });

  @override
  Widget build(BuildContext context) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                'Your Emotional Journey',
                style: HeadingSystem.getHeadlineSmall(context),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          _buildTodaysJourney(context),
          SizedBox(height: DesignTokens.spaceXL),
          
          _buildWeeklyPatterns(context),
          SizedBox(height: DesignTokens.spaceL),
          
          _buildKeyInsights(context),
        ],
      ),
    );
  }

  Widget _buildTodaysJourney(BuildContext context) {
    final todaysEntries = _getTodaysEntries();
    final todaysMoods = _extractMoodsWithTimestamps(todaysEntries);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Journey',
          style: HeadingSystem.getTitleMedium(context),
        ),
        SizedBox(height: DesignTokens.spaceM),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: _generateMoodGradient(todaysMoods),
          ),
        ),
        if (todaysMoods.isNotEmpty) ...[
          SizedBox(height: DesignTokens.spaceS),
          Text(
            _generateJourneyInsight(todaysMoods),
            style: HeadingSystem.getBodySmall(context).copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklyPatterns(BuildContext context) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week\'s Patterns',
          style: HeadingSystem.getTitleMedium(context),
        ),
        SizedBox(height: DesignTokens.spaceM),
        ...List.generate(7, (index) {
          final dayEntries = _getEntriesForDay(index);
          final dayMoods = _extractMoodsWithTimestamps(dayEntries);
          
          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    weekDays[index],
                    style: HeadingSystem.getBodySmall(context),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: dayMoods.isEmpty 
                        ? LinearGradient(
                            colors: [
                              DesignTokens.getTextTertiary(context).withValues(alpha: 0.3),
                              DesignTokens.getTextTertiary(context).withValues(alpha: 0.3),
                            ]
                          )
                        : _generateMoodGradient(dayMoods),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildKeyInsights(BuildContext context) {
    final insights = _generatePatternInsights();
    
    if (insights.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: DesignTokens.iconSizeM,
              color: DesignTokens.getPrimaryColor(context),
            ),
            SizedBox(width: DesignTokens.spaceS),
            Text(
              'Key Insights',
              style: HeadingSystem.getTitleMedium(context),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spaceM),
        Container(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          decoration: BoxDecoration(
            color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Column(
            children: insights.map((insight) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: HeadingSystem.getBodySmall(context).copyWith(
                      color: DesignTokens.getPrimaryColor(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      insight,
                      style: HeadingSystem.getBodySmall(context),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  List<JournalEntry> _getTodaysEntries() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return recentEntries.where((entry) => 
      entry.date.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
      entry.date.isBefore(todayEnd)
    ).toList();
  }

  List<JournalEntry> _getEntriesForDay(int daysAgo) {
    final targetDate = DateTime.now().subtract(Duration(days: daysAgo));
    final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    return recentEntries.where((entry) => 
      entry.date.isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
      entry.date.isBefore(dayEnd)
    ).toList();
  }

  List<MoodTimestamp> _extractMoodsWithTimestamps(List<JournalEntry> entries) {
    final List<MoodTimestamp> moodTimestamps = [];
    
    for (final entry in entries) {
      for (final mood in entry.moods) {
        moodTimestamps.add(MoodTimestamp(
          mood: mood.toLowerCase(),
          timestamp: entry.date,
        ));
      }
    }
    
    moodTimestamps.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return moodTimestamps;
  }

  LinearGradient _generateMoodGradient(List<MoodTimestamp> moodTimestamps) {
    if (moodTimestamps.isEmpty) {
      return const LinearGradient(
        colors: [Color(0xFFE0E0E0), Color(0xFFE0E0E0)],
      );
    }

    // Group consecutive similar moods to avoid too many color transitions
    final List<Color> colors = [];
    final List<double> stops = [];
    
    // Take maximum 4 mood points for clean gradient
    final selectedMoods = _selectRepresentativeMoods(moodTimestamps, 4);
    
    for (int i = 0; i < selectedMoods.length; i++) {
      colors.add(_getMoodColor(selectedMoods[i].mood));
      stops.add(i / (selectedMoods.length - 1).clamp(1, double.infinity));
    }
    
    // Ensure we have at least 2 colors for gradient
    if (colors.length == 1) {
      colors.add(colors.first);
    }
    
    return LinearGradient(
      colors: colors,
      stops: stops.length > 1 ? stops : null,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  List<MoodTimestamp> _selectRepresentativeMoods(List<MoodTimestamp> all, int maxCount) {
    if (all.length <= maxCount) return all;
    
    final List<MoodTimestamp> selected = [];
    final step = (all.length - 1) / (maxCount - 1);
    
    for (int i = 0; i < maxCount; i++) {
      final index = (i * step).round().clamp(0, all.length - 1);
      selected.add(all[index]);
    }
    
    return selected;
  }

  Color _getMoodColor(String mood) {
    // Map moods to colors based on emotional psychology
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joyful':
      case 'elated':
        return const Color(0xFFFFD54F);
      case 'calm':
      case 'peaceful':
      case 'relaxed':
        return const Color(0xFF81C784);
      case 'anxious':
      case 'worried':
      case 'stressed':
        return const Color(0xFFFF8A65);
      case 'sad':
      case 'depressed':
      case 'down':
        return const Color(0xFF64B5F6);
      case 'angry':
      case 'frustrated':
      case 'irritated':
        return const Color(0xFFE57373);
      case 'excited':
      case 'energetic':
      case 'motivated':
        return const Color(0xFFFFB74D);
      case 'focused':
      case 'determined':
      case 'productive':
        return const Color(0xFF9575CD);
      case 'grateful':
      case 'content':
      case 'satisfied':
        return const Color(0xFF4DB6AC);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  String _generateJourneyInsight(List<MoodTimestamp> todaysMoods) {
    if (todaysMoods.isEmpty) return 'No entries today yet';
    if (todaysMoods.length == 1) return 'Single mood captured: ${todaysMoods.first.mood}';
    
    final firstMood = todaysMoods.first.mood;
    final lastMood = todaysMoods.last.mood;
    
    if (firstMood == lastMood) {
      return 'Consistent $firstMood mood throughout the day';
    }
    
    final timeSpan = _getTimeOfDay(todaysMoods.first.timestamp);
    final endTime = _getTimeOfDay(todaysMoods.last.timestamp);
    
    return 'Started $firstMood in the $timeSpan, ended $lastMood by $endTime';
  }

  String _getTimeOfDay(DateTime time) {
    final hour = time.hour;
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }

  List<String> _generatePatternInsights() {
    if (recentEntries.length < 3) return [];
    
    final insights = <String>[];
    
    // Time-based patterns
    final morningMoods = _getMoodsByTimeOfDay('morning');
    final eveningMoods = _getMoodsByTimeOfDay('evening');
    
    if (morningMoods.contains('anxious') && eveningMoods.contains('calm')) {
      insights.add('Your days often start anxious but end calm');
    } else if (morningMoods.contains('calm') && eveningMoods.contains('excited')) {
      insights.add('You tend to build energy throughout the day');
    }
    
    // Consistency patterns
    final moodFrequency = <String, int>{};
    for (final entry in recentEntries.take(7)) {
      for (final mood in entry.moods) {
        moodFrequency[mood.toLowerCase()] = (moodFrequency[mood.toLowerCase()] ?? 0) + 1;
      }
    }
    
    final mostFrequent = moodFrequency.entries
        .where((e) => e.value >= 3)
        .map((e) => e.key)
        .toList();
        
    if (mostFrequent.isNotEmpty) {
      insights.add('${mostFrequent.first} appears consistently this week');
    }
    
    // Weekly patterns
    final weekendMoods = _getWeekendsVsWeekdaysMoodDifference();
    if (weekendMoods.isNotEmpty) {
      insights.add(weekendMoods);
    }
    
    return insights.take(3).toList();
  }

  List<String> _getMoodsByTimeOfDay(String timeOfDay) {
    final moodsList = <String>[];
    
    for (final entry in recentEntries.take(7)) {
      final entryTimeOfDay = _getTimeOfDay(entry.date);
      if (entryTimeOfDay == timeOfDay) {
        moodsList.addAll(entry.moods.map((m) => m.toLowerCase()));
      }
    }
    
    return moodsList.toSet().toList();
  }

  String _getWeekendsVsWeekdaysMoodDifference() {
    final weekdayMoods = <String>[];
    final weekendMoods = <String>[];
    
    for (final entry in recentEntries.take(7)) {
      final isWeekend = entry.date.weekday == 6 || entry.date.weekday == 7;
      final moodList = entry.moods.map((m) => m.toLowerCase()).toList();
      
      if (isWeekend) {
        weekendMoods.addAll(moodList);
      } else {
        weekdayMoods.addAll(moodList);
      }
    }
    
    if (weekendMoods.contains('relaxed') && weekdayMoods.contains('stressed')) {
      return 'Weekends bring more relaxation than weekdays';
    } else if (weekendMoods.contains('excited') && !weekdayMoods.contains('excited')) {
      return 'Weekends spark more excitement';
    }
    
    return '';
  }
}

class MoodTimestamp {
  final String mood;
  final DateTime timestamp;
  
  MoodTimestamp({
    required this.mood,
    required this.timestamp,
  });
}