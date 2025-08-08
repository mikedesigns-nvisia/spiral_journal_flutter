import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/core.dart';
import '../screens/emotional_mirror_screen.dart';
import 'journal_service.dart';
import 'dart:math';

/// Service to manage daily personalized recommendations based on user mood and patterns
class DailyRecommendationService {
  static const String _lastRecommendationDateKey = 'last_recommendation_date';
  static const String _currentRecommendationKey = 'current_daily_recommendation';
  static const String _usedRecommendationsKey = 'used_recommendations';
  static const String _recommendationStreakKey = 'recommendation_streak';

  final JournalService _journalService;
  final Random _random = Random();

  DailyRecommendationService(this._journalService);

  /// Get today's personalized recommendation
  Future<EnhancedRecommendation?> getTodaysRecommendation() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    final lastDate = prefs.getString(_lastRecommendationDateKey);

    // If we already have a recommendation for today, return it
    if (lastDate == today) {
      final storedRecommendation = prefs.getString(_currentRecommendationKey);
      if (storedRecommendation != null) {
        try {
          return _deserializeRecommendation(storedRecommendation);
        } catch (e) {
          debugPrint('Error deserializing stored recommendation: $e');
        }
      }
    }

    // Generate new recommendation for today
    final newRecommendation = await _generateTodaysRecommendation();
    if (newRecommendation != null) {
      await _storeTodaysRecommendation(newRecommendation, today);
    }

    return newRecommendation;
  }

  /// Generate a new recommendation based on current mood and patterns
  Future<EnhancedRecommendation?> _generateTodaysRecommendation() async {
    try {
      // Get recent journal entries to understand current mood/patterns
      final recentEntries = await _journalService.getRecentEntries(7); // Last week
      final currentMoodState = await _analyzeMoodState(recentEntries);
      
      // Generate all possible recommendations
      final allRecommendations = _generateAllRecommendations();
      
      // Filter recommendations based on mood and avoid recently used ones
      final suitableRecommendations = await _filterRecommendationsByMood(
        allRecommendations, 
        currentMoodState
      );

      if (suitableRecommendations.isEmpty) {
        return _getFallbackRecommendation();
      }

      // Select recommendation with some randomness but weighted by suitability
      return _selectWeightedRecommendation(suitableRecommendations).recommendation;
    } catch (e) {
      debugPrint('Error generating daily recommendation: $e');
      return _getFallbackRecommendation();
    }
  }

  /// Analyze current mood state from recent entries
  Future<MoodState> _analyzeMoodState(List<dynamic> recentEntries) async {
    if (recentEntries.isEmpty) {
      return MoodState.neutral;
    }

    // Analyze mood patterns from recent entries
    var positiveCount = 0;
    var negativeCount = 0;
    var stressCount = 0;
    var energyLevel = 0.5;

    for (final entry in recentEntries) {
      final moods = entry.moods as List<String>? ?? [];
      
      for (final mood in moods) {
        switch (mood.toLowerCase()) {
          case 'happy':
          case 'joyful':
          case 'excited':
          case 'grateful':
          case 'content':
          case 'optimistic':
            positiveCount++;
            energyLevel += 0.1;
            break;
          case 'sad':
          case 'anxious':
          case 'worried':
          case 'frustrated':
          case 'overwhelmed':
          case 'lonely':
            negativeCount++;
            energyLevel -= 0.1;
            break;
          case 'stressed':
          case 'pressure':
          case 'tension':
            stressCount++;
            break;
        }
      }
    }

    energyLevel = energyLevel.clamp(0.0, 1.0);

    // Determine primary mood state
    if (stressCount > recentEntries.length * 0.4) {
      return MoodState.stressed;
    } else if (negativeCount > positiveCount * 1.5) {
      return MoodState.challenging;
    } else if (positiveCount > negativeCount * 1.5) {
      return MoodState.positive;
    } else if (energyLevel < 0.3) {
      return MoodState.lowEnergy;
    } else if (energyLevel > 0.7) {
      return MoodState.highEnergy;
    } else {
      return MoodState.neutral;
    }
  }

  /// Filter recommendations based on current mood state
  Future<List<WeightedRecommendation>> _filterRecommendationsByMood(
    List<EnhancedRecommendation> allRecommendations,
    MoodState moodState
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final usedRecommendations = prefs.getStringList(_usedRecommendationsKey) ?? [];
    
    final weightedRecommendations = <WeightedRecommendation>[];

    for (final recommendation in allRecommendations) {
      // Skip recently used recommendations
      if (usedRecommendations.contains(recommendation.title)) {
        continue;
      }

      double weight = _calculateMoodWeight(recommendation, moodState);
      
      if (weight > 0) {
        weightedRecommendations.add(WeightedRecommendation(
          recommendation: recommendation,
          weight: weight,
        ));
      }
    }

    // Sort by weight (highest first)
    weightedRecommendations.sort((a, b) => b.weight.compareTo(a.weight));
    
    return weightedRecommendations;
  }

  /// Calculate how well a recommendation matches the current mood
  double _calculateMoodWeight(EnhancedRecommendation recommendation, MoodState moodState) {
    double baseWeight = 1.0;

    switch (moodState) {
      case MoodState.stressed:
        if (recommendation.category == RecommendationCategory.wellbeing) baseWeight += 0.8;
        if (recommendation.title.toLowerCase().contains('stress')) baseWeight += 1.0;
        if (recommendation.title.toLowerCase().contains('mindful')) baseWeight += 0.7;
        if (recommendation.title.toLowerCase().contains('balance')) baseWeight += 0.6;
        break;

      case MoodState.challenging:
        if (recommendation.priority == RecommendationPriority.high) baseWeight += 0.5;
        if (recommendation.category == RecommendationCategory.wellbeing) baseWeight += 0.7;
        if (recommendation.title.toLowerCase().contains('resilience')) baseWeight += 1.0;
        if (recommendation.title.toLowerCase().contains('support')) baseWeight += 0.8;
        break;

      case MoodState.lowEnergy:
        if (recommendation.title.toLowerCase().contains('energy')) baseWeight += 1.0;
        if (recommendation.title.toLowerCase().contains('sleep')) baseWeight += 0.9;
        if (recommendation.title.toLowerCase().contains('self-care')) baseWeight += 0.8;
        if (recommendation.title.toLowerCase().contains('gentle')) baseWeight += 0.6;
        break;

      case MoodState.positive:
        if (recommendation.category == RecommendationCategory.growth) baseWeight += 0.8;
        if (recommendation.title.toLowerCase().contains('creative')) baseWeight += 0.7;
        if (recommendation.title.toLowerCase().contains('goal')) baseWeight += 0.6;
        break;

      case MoodState.highEnergy:
        if (recommendation.title.toLowerCase().contains('challenge')) baseWeight += 0.8;
        if (recommendation.title.toLowerCase().contains('goal')) baseWeight += 0.7;
        if (recommendation.title.toLowerCase().contains('creative')) baseWeight += 0.6;
        if (recommendation.category == RecommendationCategory.skill_building) baseWeight += 0.5;
        break;

      case MoodState.neutral:
        // Neutral mood - slight preference for growth and exploration
        if (recommendation.category == RecommendationCategory.growth) baseWeight += 0.3;
        if (recommendation.priority == RecommendationPriority.medium) baseWeight += 0.2;
        break;
    }

    // Add some randomness to prevent predictability
    baseWeight += (_random.nextDouble() - 0.5) * 0.3;

    return baseWeight.clamp(0.0, 3.0);
  }

  /// Select a recommendation using weighted randomness
  WeightedRecommendation _selectWeightedRecommendation(List<WeightedRecommendation> weightedRecommendations) {
    // Take top 5 recommendations and select randomly from them
    final topRecommendations = weightedRecommendations.take(5).toList();
    
    final totalWeight = topRecommendations.fold(0.0, (sum, wr) => sum + wr.weight);
    final randomValue = _random.nextDouble() * totalWeight;
    
    double currentWeight = 0.0;
    for (final weightedRec in topRecommendations) {
      currentWeight += weightedRec.weight;
      if (randomValue <= currentWeight) {
        return weightedRec;
      }
    }
    
    return topRecommendations.first; // Fallback
  }

  /// Store today's recommendation
  Future<void> _storeTodaysRecommendation(EnhancedRecommendation recommendation, String date) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_lastRecommendationDateKey, date);
    await prefs.setString(_currentRecommendationKey, _serializeRecommendation(recommendation));
    
    // Track used recommendations to avoid repetition
    final usedRecommendations = prefs.getStringList(_usedRecommendationsKey) ?? [];
    usedRecommendations.add(recommendation.title);
    
    // Keep only last 30 used recommendations to allow cycling
    if (usedRecommendations.length > 30) {
      usedRecommendations.removeAt(0);
    }
    
    await prefs.setStringList(_usedRecommendationsKey, usedRecommendations);
    
    // Update streak
    await _updateRecommendationStreak();
  }

  /// Update recommendation viewing streak
  Future<void> _updateRecommendationStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final currentStreak = prefs.getInt(_recommendationStreakKey) ?? 0;
    await prefs.setInt(_recommendationStreakKey, currentStreak + 1);
  }

  /// Get current recommendation streak
  Future<int> getRecommendationStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_recommendationStreakKey) ?? 0;
  }

  /// Mark recommendation as completed/acted upon
  Future<void> markRecommendationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('completed_recommendation_$today', 'true');
  }

  /// Check if today's recommendation was completed
  Future<bool> isTodaysRecommendationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    return prefs.getString('completed_recommendation_$today') == 'true';
  }

  /// Generate all possible recommendations
  List<EnhancedRecommendation> _generateAllRecommendations() {
    final recommendations = <EnhancedRecommendation>[];

    // Add all the creative recommendations
    _addCreativityRecommendations(recommendations);
    _addSocialConnectionRecommendations(recommendations);
    _addPhysicalWellbeingRecommendations(recommendations);
    _addMindfulnessRecommendations(recommendations);
    _addGoalSettingRecommendations(recommendations);
    _addStressManagementRecommendations(recommendations);
    _addRelationshipRecommendations(recommendations);
    _addProductivityRecommendations(recommendations);
    _addSelfCareRecommendations(recommendations);
    _addLearningRecommendations(recommendations);
    _addMotivationalRecommendations(recommendations);
    _addReflectionRecommendations(recommendations);

    return recommendations;
  }

  /// Add all recommendation types (copied from emotional_mirror_screen)
  void _addCreativityRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.addAll([
      EnhancedRecommendation(
        title: 'Express Through Art',
        description: 'Channel your emotions into creative expression. Art can help process complex feelings and unlock new insights.',
        category: RecommendationCategory.growth,
        priority: RecommendationPriority.medium,
        icon: Icons.palette_rounded,
        basedOn: 'Emotional complexity analysis',
        expectedBenefit: 'Enhanced emotional processing and creative fulfillment',
        coreImpacts: {'creativity': 0.4, 'emotional_processing': 0.3},
        timeCommitment: '20-30 minutes',
        actionSteps: [
          'Try drawing your current emotional state',
          'Write poetry about your feelings',
          'Create a mood board with colors and images',
        ],
      ),
      EnhancedRecommendation(
        title: 'Creative Problem Solving',
        description: 'Approach current challenges from new angles using creative thinking techniques.',
        category: RecommendationCategory.skill_building,
        priority: RecommendationPriority.medium,
        icon: Icons.lightbulb_rounded,
        basedOn: 'Challenge identification in recent entries',
        expectedBenefit: 'Innovative solutions and enhanced adaptability',
        coreImpacts: {'problem_solving': 0.4, 'adaptability': 0.3},
        timeCommitment: '15-25 minutes',
        actionSteps: [
          'Brainstorm without judgment for 10 minutes',
          'Ask "What would someone I admire do?"',
          'Consider the opposite of your first solution',
        ],
      ),
    ]);
  }

  void _addSocialConnectionRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.addAll([
      EnhancedRecommendation(
        title: 'Strengthen Relationships',
        description: 'Invest in meaningful connections with others. Quality relationships are fundamental to emotional wellbeing.',
        category: RecommendationCategory.wellbeing,
        priority: RecommendationPriority.high,
        icon: Icons.people_rounded,
        basedOn: 'Social connection pattern analysis',
        expectedBenefit: 'Improved support system and emotional fulfillment',
        coreImpacts: {'social_connection': 0.4, 'emotional_support': 0.3},
        timeCommitment: '30-60 minutes',
        actionSteps: [
          'Reach out to someone you care about',
          'Schedule quality time with loved ones',
          'Practice active listening in conversations',
        ],
      ),
      EnhancedRecommendation(
        title: 'Practice Empathy',
        description: 'Develop deeper understanding of others\' perspectives. Empathy enriches relationships and self-awareness.',
        category: RecommendationCategory.growth,
        priority: RecommendationPriority.medium,
        icon: Icons.favorite_rounded,
        basedOn: 'Relationship dynamics in journal entries',
        expectedBenefit: 'Enhanced emotional intelligence and connection',
        coreImpacts: {'empathy': 0.4, 'social_skills': 0.3},
        timeCommitment: '10-15 minutes daily',
        actionSteps: [
          'Try to see situations from others\' viewpoints',
          'Ask curious questions instead of making assumptions',
          'Reflect on how your actions affect others',
        ],
      ),
    ]);
  }

  void _addPhysicalWellbeingRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.addAll([
      EnhancedRecommendation(
        title: 'Mind-Body Connection',
        description: 'Physical activity can significantly impact emotional wellbeing. Movement helps process stress and boost mood.',
        category: RecommendationCategory.wellbeing,
        priority: RecommendationPriority.high,
        icon: Icons.directions_run_rounded,
        basedOn: 'Stress and energy level patterns',
        expectedBenefit: 'Improved mood, energy, and stress resilience',
        coreImpacts: {'physical_wellness': 0.4, 'stress_management': 0.3},
        timeCommitment: '20-30 minutes',
        actionSteps: [
          'Take a mindful walk in nature',
          'Try gentle stretching or yoga',
          'Dance to your favorite music',
        ],
      ),
      EnhancedRecommendation(
        title: 'Optimize Sleep Patterns',
        description: 'Quality sleep is crucial for emotional regulation and mental clarity. Improve your sleep hygiene.',
        category: RecommendationCategory.wellbeing,
        priority: RecommendationPriority.medium,
        icon: Icons.bedtime_rounded,
        basedOn: 'Energy and mood consistency analysis',
        expectedBenefit: 'Better emotional regulation and mental clarity',
        coreImpacts: {'sleep_quality': 0.4, 'emotional_stability': 0.3},
        timeCommitment: 'Ongoing habit',
        actionSteps: [
          'Create a consistent bedtime routine',
          'Limit screen time before bed',
          'Keep your bedroom cool and dark',
        ],
      ),
    ]);
  }

  void _addMindfulnessRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.add(EnhancedRecommendation(
      title: 'Present Moment Awareness',
      description: 'Cultivate mindfulness to reduce anxiety and increase appreciation for life\'s moments.',
      category: RecommendationCategory.skill_building,
      priority: RecommendationPriority.medium,
      icon: Icons.self_improvement_rounded,
      basedOn: 'Anxiety and worry pattern detection',
      expectedBenefit: 'Reduced anxiety and increased life satisfaction',
      coreImpacts: {'mindfulness': 0.4, 'anxiety_management': 0.3},
      timeCommitment: '5-15 minutes daily',
      actionSteps: [
        'Practice 5-minute breathing meditation',
        'Notice 5 things you can see, 4 you can hear, 3 you can touch',
        'Eat one meal mindfully each day',
      ],
    ));
  }

  void _addGoalSettingRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.add(EnhancedRecommendation(
      title: 'Set Meaningful Goals',
      description: 'Align your actions with your values by setting purposeful goals that inspire growth.',
      category: RecommendationCategory.growth,
      priority: RecommendationPriority.medium,
      icon: Icons.flag_rounded,
      basedOn: 'Purpose and direction themes in entries',
      expectedBenefit: 'Increased motivation and sense of purpose',
      coreImpacts: {'goal_achievement': 0.4, 'life_purpose': 0.3},
      timeCommitment: '20-30 minutes',
      actionSteps: [
        'Identify 3 areas for personal growth',
        'Set SMART goals with specific deadlines',
        'Break large goals into small daily actions',
      ],
    ));
  }

  void _addStressManagementRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.add(EnhancedRecommendation(
      title: 'Develop Stress Resilience',
      description: 'Build tools to handle life\'s challenges with greater ease and bounce back from setbacks.',
      category: RecommendationCategory.skill_building,
      priority: RecommendationPriority.high,
      icon: Icons.shield_rounded,
      basedOn: 'Stress response patterns in entries',
      expectedBenefit: 'Improved stress tolerance and emotional stability',
      coreImpacts: {'stress_resilience': 0.4, 'coping_skills': 0.3},
      timeCommitment: '10-20 minutes daily',
      actionSteps: [
        'Practice progressive muscle relaxation',
        'Use the "STOP" technique when overwhelmed',
        'Develop a personal stress-relief toolkit',
      ],
    ));
  }

  void _addRelationshipRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.add(EnhancedRecommendation(
      title: 'Improve Communication Skills',
      description: 'Enhance your ability to express needs, set boundaries, and resolve conflicts constructively.',
      category: RecommendationCategory.skill_building,
      priority: RecommendationPriority.medium,
      icon: Icons.forum_rounded,
      basedOn: 'Relationship challenges in journal entries',
      expectedBenefit: 'Stronger relationships and reduced interpersonal stress',
      coreImpacts: {'communication': 0.4, 'relationship_quality': 0.3},
      timeCommitment: '15-20 minutes practice',
      actionSteps: [
        'Practice "I" statements instead of "you" statements',
        'Ask for clarification before reacting',
        'Express appreciation daily to loved ones',
      ],
    ));
  }

  void _addProductivityRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.add(EnhancedRecommendation(
      title: 'Optimize Daily Routines',
      description: 'Create structure that supports both productivity and wellbeing through intentional daily practices.',
      category: RecommendationCategory.skill_building,
      priority: RecommendationPriority.low,
      icon: Icons.schedule_rounded,
      basedOn: 'Time management themes in entries',
      expectedBenefit: 'Increased efficiency and reduced overwhelm',
      coreImpacts: {'productivity': 0.3, 'time_management': 0.4},
      timeCommitment: 'Ongoing habit building',
      actionSteps: [
        'Plan your top 3 priorities each morning',
        'Use time-blocking for important tasks',
        'Build in regular breaks throughout your day',
      ],
    ));
  }

  void _addSelfCareRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.add(EnhancedRecommendation(
      title: 'Prioritize Self-Care',
      description: 'Make time for activities that nourish your mind, body, and spirit. Self-care isn\'t selfish—it\'s essential.',
      category: RecommendationCategory.wellbeing,
      priority: RecommendationPriority.medium,
      icon: Icons.spa_rounded,
      basedOn: 'Burnout and exhaustion indicators',
      expectedBenefit: 'Renewed energy and emotional resilience',
      coreImpacts: {'self_care': 0.4, 'energy_levels': 0.3},
      timeCommitment: '20-60 minutes',
      actionSteps: [
        'Schedule regular "me time" in your calendar',
        'Try a new hobby or return to an old one',
        'Create a relaxing evening ritual',
      ],
    ));
  }

  void _addLearningRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.addAll([
      EnhancedRecommendation(
        title: 'Cultivate Growth Mindset',
        description: 'Embrace challenges as opportunities to learn and grow. Develop resilience through continuous learning.',
        category: RecommendationCategory.growth,
        priority: RecommendationPriority.medium,
        icon: Icons.school_rounded,
        basedOn: 'Learning and challenge themes',
        expectedBenefit: 'Increased adaptability and confidence',
        coreImpacts: {'growth_mindset': 0.4, 'learning_agility': 0.3},
        timeCommitment: '15-30 minutes daily',
        actionSteps: [
          'Learn something new for 15 minutes daily',
          'Reframe failures as learning opportunities',
          'Seek feedback and act on it constructively',
        ],
      ),
      EnhancedRecommendation(
        title: 'Practice Gratitude',
        description: 'Regular gratitude practice can shift your perspective and increase overall life satisfaction.',
        category: RecommendationCategory.wellbeing,
        priority: RecommendationPriority.low,
        icon: Icons.favorite_border_rounded,
        basedOn: 'Emotional tone analysis',
        expectedBenefit: 'Improved mood and life satisfaction',
        coreImpacts: {'gratitude': 0.3, 'positive_outlook': 0.4},
        timeCommitment: '5-10 minutes daily',
        actionSteps: [
          'Write down 3 things you\'re grateful for daily',
          'Share appreciation with others regularly',
          'Notice and savor positive moments',
        ],
      ),
    ]);
  }

  void _addMotivationalRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.addAll([
      EnhancedRecommendation(
        title: 'Celebrate Small Wins',
        description: 'Acknowledge your progress and achievements, no matter how small. Recognition builds momentum.',
        category: RecommendationCategory.growth,
        priority: RecommendationPriority.medium,
        icon: Icons.celebration_rounded,
        basedOn: 'Achievement and progress patterns',
        expectedBenefit: 'Increased motivation and self-confidence',
        coreImpacts: {'self_confidence': 0.4, 'motivation': 0.3},
        timeCommitment: '5-10 minutes',
        actionSteps: [
          'Write down 3 things you accomplished today',
          'Share a recent win with someone you trust',
          'Reward yourself for completing goals',
        ],
      ),
      EnhancedRecommendation(
        title: 'Embrace New Experiences',
        description: 'Step out of your comfort zone with small adventures. New experiences fuel personal growth.',
        category: RecommendationCategory.growth,
        priority: RecommendationPriority.medium,
        icon: Icons.explore_rounded,
        basedOn: 'Routine and comfort zone patterns',
        expectedBenefit: 'Expanded perspective and increased confidence',
        coreImpacts: {'adaptability': 0.4, 'self_discovery': 0.3},
        timeCommitment: '30-60 minutes',
        actionSteps: [
          'Try a new restaurant or cuisine',
          'Take a different route to a familiar place',
          'Start a conversation with someone new',
        ],
      ),
    ]);
  }

  void _addReflectionRecommendations(List<EnhancedRecommendation> recommendations) {
    recommendations.addAll([
      EnhancedRecommendation(
        title: 'Values Alignment Check',
        description: 'Regularly assess whether your actions align with your core values and make adjustments as needed.',
        category: RecommendationCategory.growth,
        priority: RecommendationPriority.medium,
        icon: Icons.compass_calibration_rounded,
        basedOn: 'Value-based decision making patterns',
        expectedBenefit: 'Greater authenticity and life satisfaction',
        coreImpacts: {'value_alignment': 0.4, 'authenticity': 0.3},
        timeCommitment: '15-20 minutes',
        actionSteps: [
          'List your top 5 core values',
          'Evaluate recent decisions against these values',
          'Plan one action that better aligns with your values',
        ],
      ),
      EnhancedRecommendation(
        title: 'Future Self Visioning',
        description: 'Connect with your future self to gain clarity on your path and make decisions that serve your long-term growth.',
        category: RecommendationCategory.growth,
        priority: RecommendationPriority.low,
        icon: Icons.auto_awesome_rounded,
        basedOn: 'Future-focused thinking patterns',
        expectedBenefit: 'Clearer direction and purposeful decision-making',
        coreImpacts: {'future_planning': 0.4, 'purpose_clarity': 0.3},
        timeCommitment: '20-25 minutes',
        actionSteps: [
          'Write a letter to yourself one year from now',
          'Visualize your ideal day 5 years from now',
          'Identify one step you can take today toward that vision',
        ],
      ),
    ]);
  }

  /// Fallback recommendation when no suitable ones found
  EnhancedRecommendation _getFallbackRecommendation() {
    return EnhancedRecommendation(
      title: 'Moment of Reflection',
      description: 'Take a few minutes to check in with yourself and appreciate this moment.',
      category: RecommendationCategory.wellbeing,
      priority: RecommendationPriority.low,
      icon: Icons.self_improvement_rounded,
      basedOn: 'Daily mindfulness practice',
      expectedBenefit: 'Increased self-awareness and presence',
      coreImpacts: {'mindfulness': 0.3, 'self_awareness': 0.2},
      timeCommitment: '3-5 minutes',
      actionSteps: [
        'Take 3 deep breaths',
        'Notice how you\'re feeling right now',
        'Appreciate one thing about this moment',
      ],
    );
  }

  /// Serialize recommendation for storage
  String _serializeRecommendation(EnhancedRecommendation recommendation) {
    // Simple serialization - in production you might want to use JSON
    return [
      recommendation.title,
      recommendation.description,
      recommendation.category.toString(),
      recommendation.priority.toString(),
      recommendation.basedOn,
      recommendation.expectedBenefit,
      recommendation.timeCommitment,
      recommendation.actionSteps.join('|'),
    ].join(':::');
  }

  /// Deserialize recommendation from storage
  EnhancedRecommendation _deserializeRecommendation(String serialized) {
    final parts = serialized.split(':::');
    if (parts.length < 8) throw FormatException('Invalid serialized recommendation');
    
    return EnhancedRecommendation(
      title: parts[0],
      description: parts[1],
      category: RecommendationCategory.values.firstWhere(
        (c) => c.toString() == parts[2],
        orElse: () => RecommendationCategory.growth,
      ),
      priority: RecommendationPriority.values.firstWhere(
        (p) => p.toString() == parts[3],
        orElse: () => RecommendationPriority.medium,
      ),
      icon: Icons.lightbulb_rounded, // Default icon
      basedOn: parts[4],
      expectedBenefit: parts[5],
      coreImpacts: {}, // Not stored for simplicity
      timeCommitment: parts[6],
      actionSteps: parts[7].split('|'),
    );
  }
}

/// Enum for different mood states
enum MoodState {
  positive,
  neutral,
  challenging,
  stressed,
  lowEnergy,
  highEnergy,
}

/// Helper class for weighted recommendation selection
class WeightedRecommendation {
  final EnhancedRecommendation recommendation;
  final double weight;

  WeightedRecommendation({
    required this.recommendation,
    required this.weight,
  });
}