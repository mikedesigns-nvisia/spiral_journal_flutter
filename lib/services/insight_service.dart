import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import 'ai_service_manager.dart';

class InsightService {
  static final InsightService _instance = InsightService._internal();
  factory InsightService() => _instance;
  InsightService._internal();

  final AIServiceManager _aiManager = AIServiceManager();
  
  // Cache for the latest insights to power visualization components
  Map<String, dynamic>? _latestMindReflection;
  List<Map<String, dynamic>> _recentEmotionalPatterns = [];
  String? _latestEntryInsight;

  // Getters for visualization components
  Map<String, dynamic>? get latestMindReflection => _latestMindReflection;
  List<Map<String, dynamic>> get recentEmotionalPatterns => _recentEmotionalPatterns;
  String? get latestEntryInsight => _latestEntryInsight;

  /// Analyze a journal entry and extract insights for visualization components
  Future<Map<String, dynamic>> analyzeEntryForVisualization(JournalEntry entry) async {
    try {
      // Get AI analysis
      final analysis = await _aiManager.analyzeJournalEntry(entry);
      
      // Cache insights for visualization components
      _latestMindReflection = analysis['mind_reflection'];
      _latestEntryInsight = analysis['entry_insight'];
      
      // Add to recent emotional patterns (keep last 5)
      if (analysis['emotional_patterns'] != null) {
        final patterns = List<Map<String, dynamic>>.from(analysis['emotional_patterns']);
        _recentEmotionalPatterns.addAll(patterns);
        if (_recentEmotionalPatterns.length > 5) {
          _recentEmotionalPatterns = _recentEmotionalPatterns.take(5).toList();
        }
      }
      
      return analysis;
    } catch (error) {
      debugPrint('InsightService analyzeEntryForVisualization error: $error');
      // Return fallback insights if analysis fails
      return _generateFallbackInsights(entry);
    }
  }

  /// Generate monthly insights for the Emotional Mirror screen
  Future<Map<String, dynamic>> generateMonthlyMirrorInsights(List<JournalEntry> entries) async {
    if (entries.isEmpty) {
      return _getEmptyMonthInsights();
    }

    try {
      // Get AI-generated monthly insight
      final monthlyInsight = await _aiManager.generateMonthlyInsight(entries);
      
      // Analyze mood patterns for visualization
      final moodAnalysis = _analyzeMoodPatterns(entries);
      final emotionalBalance = _calculateEmotionalBalance(entries);
      final selfAwarenessScore = _calculateSelfAwarenessScore(entries);
      
      return {
        'monthly_insight': monthlyInsight,
        'mood_overview': moodAnalysis,
        'emotional_balance': emotionalBalance,
        'self_awareness_score': selfAwarenessScore,
        'entry_count': entries.length,
        'dominant_moods': moodAnalysis['dominant_moods'],
        'emotional_trajectory': moodAnalysis['trajectory'],
      };
    } catch (error) {
      debugPrint('InsightService generateMonthlyMirrorInsights error: $error');
      return _generateFallbackMonthlyInsights(entries);
    }
  }

  /// Get insights formatted for the Mind Reflection Card
  Map<String, dynamic> getMindReflectionData() {
    return _latestMindReflection ?? {
      'title': 'Emotional Pattern Analysis',
      'summary': 'Start journaling to see your emotional patterns and insights here.',
      'insights': ['Begin your journaling journey to unlock personalized insights'],
    };
  }

  /// Get data formatted for the Emotional Mirror screen
  Map<String, dynamic> getEmotionalMirrorData(List<JournalEntry> recentEntries) {
    if (recentEntries.isEmpty) {
      return _getEmptyMirrorData();
    }

    final moodAnalysis = _analyzeMoodPatterns(recentEntries);
    final emotionalBalance = _calculateEmotionalBalance(recentEntries);
    
    return {
      'mood_indicators': _getMoodIndicators(moodAnalysis),
      'emotional_balance': emotionalBalance,
      'balance_description': _getBalanceDescription(emotionalBalance),
      'self_awareness_score': _calculateSelfAwarenessScore(recentEntries),
      'recent_patterns': _recentEmotionalPatterns,
    };
  }

  // Private helper methods
  Map<String, dynamic> _analyzeMoodPatterns(List<JournalEntry> entries) {
    final moodCounts = <String, int>{};
    final moodsByDate = <DateTime, List<String>>{};
    
    for (final entry in entries) {
      moodsByDate[entry.date] = entry.moods;
      for (final mood in entry.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }
    
    // Get dominant moods (top 4 for visualization)
    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dominantMoods = sortedMoods.take(4).map((e) => e.key).toList();
    
    // Calculate emotional trajectory (simplified)
    final trajectory = _calculateEmotionalTrajectory(moodsByDate);
    
    return {
      'mood_counts': moodCounts,
      'dominant_moods': dominantMoods,
      'trajectory': trajectory,
      'total_entries': entries.length,
    };
  }

  Map<String, dynamic> _calculateEmotionalBalance(List<JournalEntry> entries) {
    final positiveWords = ['happy', 'joyful', 'excited', 'grateful', 'content', 'peaceful'];
    final neutralWords = ['reflective', 'thoughtful', 'calm', 'focused'];
    final challengingWords = ['sad', 'stressed', 'anxious', 'tired', 'unsure'];
    
    int positiveCount = 0;
    int neutralCount = 0;
    int challengingCount = 0;
    
    for (final entry in entries) {
      for (final mood in entry.moods) {
        final lowerMood = mood.toLowerCase();
        if (positiveWords.contains(lowerMood)) {
          positiveCount++;
        } else if (neutralWords.contains(lowerMood)) {
          neutralCount++;
        } else if (challengingWords.contains(lowerMood)) {
          challengingCount++;
        }
      }
    }
    
    final total = positiveCount + neutralCount + challengingCount;
    if (total == 0) return {'positive': 0.33, 'neutral': 0.33, 'challenging': 0.34};
    
    return {
      'positive': positiveCount / total,
      'neutral': neutralCount / total,
      'challenging': challengingCount / total,
    };
  }

  double _calculateSelfAwarenessScore(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0.0;
    
    double score = 0.0;
    final reflectiveWords = ['feel', 'think', 'realize', 'understand', 'learn', 'reflect'];
    
    for (final entry in entries) {
      final content = entry.content.toLowerCase();
      final wordCount = entry.content.split(' ').length;
      
      // Base score for journaling
      score += 1.0;
      
      // Bonus for reflective language
      for (final word in reflectiveWords) {
        if (content.contains(word)) {
          score += 0.5;
        }
      }
      
      // Bonus for detailed entries
      if (wordCount > 50) score += 0.5;
      if (wordCount > 100) score += 0.5;
      
      // Bonus for mood awareness
      if (entry.moods.length > 1) score += 0.3;
    }
    
    // Normalize to 0-100 scale
    final maxPossibleScore = entries.length * 3.0;
    return ((score / maxPossibleScore) * 100).clamp(0.0, 100.0);
  }

  List<double> _calculateEmotionalTrajectory(Map<DateTime, List<String>> moodsByDate) {
    if (moodsByDate.isEmpty) return [5.0, 5.0, 5.0, 5.0];
    
    final sortedDates = moodsByDate.keys.toList()..sort();
    final trajectory = <double>[];
    
    // Calculate emotional intensity for each entry
    for (final date in sortedDates) {
      final moods = moodsByDate[date]!;
      double intensity = 5.0; // Base neutral
      
      for (final mood in moods) {
        switch (mood.toLowerCase()) {
          case 'excited':
          case 'energetic':
          case 'joyful':
            intensity += 1.5;
            break;
          case 'happy':
          case 'grateful':
          case 'confident':
            intensity += 1.0;
            break;
          case 'content':
          case 'peaceful':
            intensity += 0.5;
            break;
          case 'sad':
          case 'stressed':
            intensity -= 1.0;
            break;
          case 'tired':
          case 'unsure':
            intensity -= 0.5;
            break;
        }
      }
      
      trajectory.add(intensity.clamp(1.0, 10.0));
    }
    
    // Return last 4 data points for visualization
    return trajectory.length >= 4 
        ? trajectory.sublist(trajectory.length - 4)
        : List.generate(4, (index) => trajectory.isNotEmpty ? trajectory.last : 5.0);
  }

  List<Map<String, dynamic>> _getMoodIndicators(Map<String, dynamic> moodAnalysis) {
    final dominantMoods = List<String>.from(moodAnalysis['dominant_moods'] ?? []);
    
    return dominantMoods.take(4).map((mood) {
      return {
        'label': _getMoodLabel(mood),
        'icon': _getMoodIcon(mood),
        'mood': mood,
      };
    }).toList();
  }

  String _getMoodLabel(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return 'Optimistic';
      case 'reflective': return 'Reflective';
      case 'grateful': return 'Grateful';
      case 'creative': return 'Creative';
      case 'energetic': return 'Energetic';
      case 'content': return 'Balanced';
      case 'peaceful': return 'Peaceful';
      default: return mood.substring(0, 1).toUpperCase() + mood.substring(1);
    }
  }

  String _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return 'sunny';
      case 'reflective': return 'self_improvement';
      case 'grateful': return 'favorite';
      case 'creative': return 'palette';
      case 'energetic': return 'bolt';
      case 'content': return 'balance';
      case 'peaceful': return 'spa';
      default: return 'psychology';
    }
  }

  String _getBalanceDescription(Map<String, dynamic> balance) {
    final positive = balance['positive'] as double;
    final challenging = balance['challenging'] as double;
    
    if (positive > 0.6) {
      return 'Your emotions show a predominantly positive outlook with strong optimism and life satisfaction.';
    } else if (challenging > 0.4) {
      return 'You\'re navigating some challenges while maintaining emotional awareness and growth.';
    } else {
      return 'Your emotions show a healthy balance between optimism and reflection, with mindful awareness.';
    }
  }

  // Fallback methods
  Map<String, dynamic> _generateFallbackInsights(JournalEntry entry) {
    return {
      'mind_reflection': {
        'title': 'Emotional Pattern Analysis',
        'summary': 'Your journaling practice shows commitment to self-reflection and growth.',
        'insights': ['Self-awareness developing through regular journaling'],
      },
      'emotional_patterns': [
        {
          'category': 'Growth',
          'title': 'Consistent Self-Reflection',
          'description': 'Regular journaling is building emotional intelligence',
          'type': 'growth'
        }
      ],
      'entry_insight': 'Thank you for taking time to reflect and journal.',
    };
  }

  Map<String, dynamic> _generateFallbackMonthlyInsights(List<JournalEntry> entries) {
    return {
      'monthly_insight': 'Your journaling practice this month shows consistent emotional awareness.',
      'mood_overview': _analyzeMoodPatterns(entries),
      'emotional_balance': _calculateEmotionalBalance(entries),
      'self_awareness_score': _calculateSelfAwarenessScore(entries),
      'entry_count': entries.length,
    };
  }

  Map<String, dynamic> _getEmptyMonthInsights() {
    return {
      'monthly_insight': 'No entries this month. Start journaling to track your emotional journey!',
      'mood_overview': {'dominant_moods': [], 'trajectory': [5.0, 5.0, 5.0, 5.0]},
      'emotional_balance': {'positive': 0.33, 'neutral': 0.33, 'challenging': 0.34},
      'self_awareness_score': 0.0,
      'entry_count': 0,
    };
  }

  Map<String, dynamic> _getEmptyMirrorData() {
    return {
      'mood_indicators': [
        {'label': 'Curious', 'icon': 'search', 'mood': 'curious'},
        {'label': 'Reflective', 'icon': 'self_improvement', 'mood': 'reflective'},
        {'label': 'Balanced', 'icon': 'balance', 'mood': 'balanced'},
        {'label': 'Growing', 'icon': 'trending_up', 'mood': 'growing'},
      ],
      'emotional_balance': {'positive': 0.33, 'neutral': 0.33, 'challenging': 0.34},
      'balance_description': 'Start journaling to see your emotional patterns and balance.',
      'self_awareness_score': 0.0,
      'recent_patterns': [],
    };
  }
}