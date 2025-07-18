import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/core.dart';
import '../models/journal_entry.dart';
import 'emotional_analyzer.dart';

/// Service for managing the complete emotional core library system.
/// 
/// This service handles all six personality cores, their progress tracking,
/// milestone management, and insight generation based on journal analysis patterns.
class CoreLibraryService {
  static final CoreLibraryService _instance = CoreLibraryService._internal();
  factory CoreLibraryService() => _instance;
  CoreLibraryService._internal();

  static const String _coresKey = 'emotional_cores';
  static const String _milestonesKey = 'core_milestones';
  static const String _insightsKey = 'core_insights';

  // Core configuration for all six personality cores
  static const Map<String, CoreConfig> _coreConfigs = {
    'optimism': CoreConfig(
      id: 'optimism',
      name: 'Optimism',
      description: 'Your ability to maintain hope and positive outlook',
      color: '#FF6B35',
      iconPath: 'assets/icons/optimism.png',
      baselineLevel: 0.7,
      maxDailyChange: 0.03,
      decayRate: 0.001,
    ),
    'resilience': CoreConfig(
      id: 'resilience',
      name: 'Resilience',
      description: 'Your capacity to bounce back from challenges',
      color: '#4ECDC4',
      iconPath: 'assets/icons/resilience.png',
      baselineLevel: 0.65,
      maxDailyChange: 0.025,
      decayRate: 0.0005,
    ),
    'self_awareness': CoreConfig(
      id: 'self_awareness',
      name: 'Self-Awareness',
      description: 'Your understanding of your emotions and thoughts',
      color: '#45B7D1',
      iconPath: 'assets/icons/self_awareness.png',
      baselineLevel: 0.75,
      maxDailyChange: 0.02,
      decayRate: 0.0002,
    ),
    'creativity': CoreConfig(
      id: 'creativity',
      name: 'Creativity',
      description: 'Your innovative thinking and creative expression',
      color: '#96CEB4',
      iconPath: 'assets/icons/creativity.png',
      baselineLevel: 0.6,
      maxDailyChange: 0.04,
      decayRate: 0.0015,
    ),
    'social_connection': CoreConfig(
      id: 'social_connection',
      name: 'Social Connection',
      description: 'Your relationships and empathy with others',
      color: '#FFEAA7',
      iconPath: 'assets/icons/social_connection.png',
      baselineLevel: 0.68,
      maxDailyChange: 0.035,
      decayRate: 0.0008,
    ),
    'growth_mindset': CoreConfig(
      id: 'growth_mindset',
      name: 'Growth Mindset',
      description: 'Your openness to learning and embracing challenges',
      color: '#DDA0DD',
      iconPath: 'assets/icons/growth_mindset.png',
      baselineLevel: 0.72,
      maxDailyChange: 0.028,
      decayRate: 0.0003,
    ),
  };

  /// Get all six emotional cores
  Future<List<EmotionalCore>> getAllCores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coresJson = prefs.getString(_coresKey);
      
      if (coresJson != null) {
        final coresList = jsonDecode(coresJson) as List;
        return coresList.map((json) => EmotionalCore.fromJson(json)).toList();
      }
      
      // Return initial cores if none exist
      return _createInitialCores();
    } catch (e) {
      debugPrint('CoreLibraryService getAllCores error: $e');
      return _createInitialCores();
    }
  }

  /// Get a specific core by ID
  Future<EmotionalCore?> getCoreById(String coreId) async {
    try {
      final cores = await getAllCores();
      return cores.firstWhere(
        (core) => core.id == coreId,
        orElse: () => cores.first,
      );
    } catch (e) {
      debugPrint('CoreLibraryService getCoreById error: $e');
      return null;
    }
  }

  /// Update core progress based on journal analysis
  Future<void> updateCoreProgress(String coreId, double newLevel) async {
    try {
      final cores = await getAllCores();
      final updatedCores = cores.map((core) {
        if (core.id == coreId) {
          final config = _coreConfigs[coreId];
          double adjustedNewLevel = newLevel;
          
          // Apply daily change limits if config exists
          if (config != null) {
            final change = newLevel - core.currentLevel;
            final limitedChange = change.clamp(-config.maxDailyChange, config.maxDailyChange);
            adjustedNewLevel = core.currentLevel + limitedChange;
          }
          
          adjustedNewLevel = adjustedNewLevel.clamp(0.0, 1.0);
          final trend = _calculateTrend(core.currentLevel, adjustedNewLevel);
          final updatedMilestones = _updateMilestones(core.milestones, adjustedNewLevel);
          
          return core.copyWith(
            previousLevel: core.currentLevel,
            currentLevel: adjustedNewLevel,
            lastUpdated: DateTime.now(),
            trend: trend,
            milestones: updatedMilestones,
          );
        }
        return core;
      }).toList();
      
      await _saveCores(updatedCores);
    } catch (e) {
      debugPrint('CoreLibraryService updateCoreProgress error: $e');
    }
  }

  /// Get milestones for a specific core
  Future<List<CoreMilestone>> getCoreMilestones(String coreId) async {
    try {
      final core = await getCoreById(coreId);
      return core?.milestones ?? [];
    } catch (e) {
      debugPrint('CoreLibraryService getCoreMilestones error: $e');
      return [];
    }
  }

  /// Generate core insight based on recent patterns
  Future<CoreInsight> generateCoreInsight(String coreId) async {
    try {
      final core = await getCoreById(coreId);
      if (core == null) {
        throw Exception('Core not found: $coreId');
      }

      final config = _coreConfigs[coreId];
      if (config == null) {
        throw Exception('Core config not found: $coreId');
      }

      final insight = _generateInsightForCore(core, config);
      
      // Save the insight
      await _saveInsight(insight);
      
      return insight;
    } catch (e) {
      debugPrint('CoreLibraryService generateCoreInsight error: $e');
      return CoreInsight(
        id: '${coreId}_insight_${DateTime.now().millisecondsSinceEpoch}',
        coreId: coreId,
        title: 'Growth Continues',
        description: 'Your core continues to develop through self-reflection.',
        type: 'growth',
        createdAt: DateTime.now(),
        relevanceScore: 0.5,
      );
    }
  }

  /// Update all cores based on journal analysis
  Future<List<EmotionalCore>> updateCoresWithJournalAnalysis(
    List<JournalEntry> recentEntries,
    EmotionalAnalysisResult? analysis,
  ) async {
    try {
      final cores = await getAllCores();
      final updatedCores = <EmotionalCore>[];

      for (final core in cores) {
        final config = _coreConfigs[core.id];
        if (config == null) {
          updatedCores.add(core);
          continue;
        }

        double impact = 0.0;
        
        // Calculate impact from analysis if available
        if (analysis != null) {
          impact += _calculateAnalysisImpact(core, analysis);
        }
        
        // Calculate impact from journal patterns
        impact += _calculateJournalPatternImpact(core, recentEntries);
        
        // Apply daily change limits
        impact = impact.clamp(-config.maxDailyChange, config.maxDailyChange);
        
        // Calculate new level
        double newLevel = core.currentLevel + impact;
        
        // Apply natural decay towards baseline if no significant impact
        if (impact.abs() < 0.001) {
          final decayAmount = (config.baselineLevel - core.currentLevel) * config.decayRate;
          newLevel = core.currentLevel + decayAmount;
        }
        
        newLevel = newLevel.clamp(0.0, 1.0);
        
        // Update core if there's a meaningful change
        if ((newLevel - core.currentLevel).abs() > 0.001) {
          final trend = _calculateTrend(core.currentLevel, newLevel);
          final updatedMilestones = _updateMilestones(core.milestones, newLevel);
          final newInsight = await _generateRecentInsight(core, analysis);
          
          final updatedCore = core.copyWith(
            previousLevel: core.currentLevel,
            currentLevel: newLevel,
            lastUpdated: DateTime.now(),
            trend: trend,
            milestones: updatedMilestones,
            recentInsights: [newInsight, ...core.recentInsights.take(4)].toList(),
          );
          
          updatedCores.add(updatedCore);
        } else {
          updatedCores.add(core);
        }
      }
      
      await _saveCores(updatedCores);
      return updatedCores;
    } catch (e) {
      debugPrint('CoreLibraryService updateCoresWithJournalAnalysis error: $e');
      return await getAllCores();
    }
  }

  /// Get core combinations and synergies
  Future<List<CoreCombination>> getCoreCombinations() async {
    try {
      final cores = await getAllCores();
      return _generateCoreCombinations(cores);
    } catch (e) {
      debugPrint('CoreLibraryService getCoreCombinations error: $e');
      return [];
    }
  }

  /// Get growth recommendations based on core analysis
  Future<List<String>> getGrowthRecommendations() async {
    try {
      final cores = await getAllCores();
      return _generateGrowthRecommendations(cores);
    } catch (e) {
      debugPrint('CoreLibraryService getGrowthRecommendations error: $e');
      return [];
    }
  }

  /// Update a specific core
  Future<void> updateCore(EmotionalCore core) async {
    try {
      final cores = await getAllCores();
      final updatedCores = cores.map((existingCore) {
        return existingCore.id == core.id ? core : existingCore;
      }).toList();
      
      await _saveCores(updatedCores);
    } catch (e) {
      debugPrint('CoreLibraryService updateCore error: $e');
    }
  }

  /// Reset all cores to initial state
  Future<void> resetCores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_coresKey);
      await prefs.remove(_milestonesKey);
      await prefs.remove(_insightsKey);
    } catch (e) {
      debugPrint('CoreLibraryService resetCores error: $e');
    }
  }

  // Private methods

  List<EmotionalCore> _createInitialCores() {
    return _coreConfigs.values.map((config) {
      final milestones = _createInitialMilestones(config.id);
      
      return EmotionalCore(
        id: config.id,
        name: config.name,
        description: config.description,
        currentLevel: config.baselineLevel,
        previousLevel: config.baselineLevel,
        lastUpdated: DateTime.now(),
        trend: 'stable',
        color: config.color,
        iconPath: config.iconPath,
        insight: _getDefaultInsight(config.name),
        relatedCores: _getRelatedCores(config.id),
        milestones: milestones,
        recentInsights: [],
      );
    }).toList();
  }

  List<CoreMilestone> _createInitialMilestones(String coreId) {
    return [
      CoreMilestone(
        id: '${coreId}_foundation',
        title: 'Foundation',
        description: 'Building the foundation of your core',
        threshold: 0.25,
        isAchieved: false,
      ),
      CoreMilestone(
        id: '${coreId}_development',
        title: 'Development',
        description: 'Developing strong core skills',
        threshold: 0.5,
        isAchieved: false,
      ),
      CoreMilestone(
        id: '${coreId}_proficiency',
        title: 'Proficiency',
        description: 'Achieving proficiency in your core',
        threshold: 0.75,
        isAchieved: false,
      ),
      CoreMilestone(
        id: '${coreId}_mastery',
        title: 'Mastery',
        description: 'Mastering your core strength',
        threshold: 0.9,
        isAchieved: false,
      ),
    ];
  }

  List<CoreMilestone> _updateMilestones(List<CoreMilestone> milestones, double currentLevel) {
    return milestones.map((milestone) {
      if (!milestone.isAchieved && currentLevel >= milestone.threshold) {
        return milestone.copyWith(
          isAchieved: true,
          achievedAt: DateTime.now(),
        );
      }
      return milestone;
    }).toList();
  }

  String _calculateTrend(double oldLevel, double newLevel) {
    final change = newLevel - oldLevel;
    if (change > 0.005) return 'rising';
    if (change < -0.005) return 'declining';
    return 'stable';
  }

  double _calculateAnalysisImpact(EmotionalCore core, EmotionalAnalysisResult analysis) {
    double impact = 0.0;
    
    // Direct impact from analysis
    final directImpact = analysis.coreImpacts[core.name] ?? 0.0;
    impact += directImpact;
    
    // Theme-based impact
    impact += _calculateThemeImpact(core.id, analysis.keyThemes);
    
    // Emotion-based impact
    impact += _calculateEmotionImpact(core.id, analysis.primaryEmotions);
    
    return impact;
  }

  double _calculateJournalPatternImpact(EmotionalCore core, List<JournalEntry> entries) {
    if (entries.isEmpty) return 0.0;
    
    double impact = 0.0;
    final recentEntries = entries.take(5).toList();
    
    // Analyze content patterns
    for (final entry in recentEntries) {
      impact += _analyzeContentForCore(core.id, entry.content);
    }
    
    return impact / recentEntries.length;
  }

  double _calculateThemeImpact(String coreId, List<String> themes) {
    final coreThemes = {
      'optimism': ['gratitude', 'hope', 'positive', 'joy', 'happiness'],
      'resilience': ['challenge', 'overcome', 'strength', 'perseverance', 'recovery'],
      'self_awareness': ['reflection', 'understanding', 'awareness', 'mindfulness', 'insight'],
      'creativity': ['creative', 'innovation', 'imagination', 'artistic', 'original'],
      'social_connection': ['relationship', 'friendship', 'community', 'empathy', 'connection'],
      'growth_mindset': ['learning', 'development', 'improvement', 'progress', 'growth'],
    };
    
    final relevantThemes = coreThemes[coreId] ?? [];
    double impact = 0.0;
    
    for (final theme in themes) {
      for (final relevantTheme in relevantThemes) {
        if (theme.toLowerCase().contains(relevantTheme)) {
          impact += 0.003;
          break;
        }
      }
    }
    
    return impact.clamp(0.0, 0.02);
  }

  double _calculateEmotionImpact(String coreId, List<String> emotions) {
    final coreEmotions = {
      'optimism': ['happy', 'joyful', 'excited', 'hopeful', 'grateful'],
      'resilience': ['determined', 'strong', 'confident', 'brave', 'persistent'],
      'self_awareness': ['reflective', 'thoughtful', 'aware', 'mindful', 'introspective'],
      'creativity': ['inspired', 'imaginative', 'innovative', 'artistic', 'original'],
      'social_connection': ['loving', 'connected', 'empathetic', 'caring', 'social'],
      'growth_mindset': ['curious', 'motivated', 'ambitious', 'learning', 'developing'],
    };
    
    final relevantEmotions = coreEmotions[coreId] ?? [];
    double impact = 0.0;
    
    for (final emotion in emotions) {
      if (relevantEmotions.contains(emotion.toLowerCase())) {
        impact += 0.004;
      }
    }
    
    return impact.clamp(0.0, 0.015);
  }

  double _analyzeContentForCore(String coreId, String content) {
    final contentLower = content.toLowerCase();
    final coreKeywords = {
      'optimism': ['grateful', 'thankful', 'positive', 'hope', 'bright', 'good'],
      'resilience': ['challenge', 'difficult', 'overcome', 'strong', 'push through'],
      'self_awareness': ['feel', 'realize', 'understand', 'notice', 'aware'],
      'creativity': ['create', 'imagine', 'idea', 'design', 'art', 'innovative'],
      'social_connection': ['friend', 'family', 'connect', 'relationship', 'together'],
      'growth_mindset': ['learn', 'grow', 'improve', 'develop', 'better', 'progress'],
    };
    
    final keywords = coreKeywords[coreId] ?? [];
    double impact = 0.0;
    
    for (final keyword in keywords) {
      if (contentLower.contains(keyword)) {
        impact += 0.001;
      }
    }
    
    return impact.clamp(0.0, 0.005);
  }

  CoreInsight _generateInsightForCore(EmotionalCore core, CoreConfig config) {
    final insights = _getCoreInsights(core.id, core.trend, core.currentLevel);
    final random = Random();
    final selectedInsight = insights[random.nextInt(insights.length)];
    
    return CoreInsight(
      id: '${core.id}_insight_${DateTime.now().millisecondsSinceEpoch}',
      coreId: core.id,
      title: selectedInsight['title']!,
      description: selectedInsight['description']!,
      type: selectedInsight['type']!,
      createdAt: DateTime.now(),
      relevanceScore: _calculateRelevanceScore(core, selectedInsight['type']!),
    );
  }

  Future<CoreInsight> _generateRecentInsight(EmotionalCore core, EmotionalAnalysisResult? analysis) async {
    String title = 'Growth Continues';
    String description = 'Your ${core.name} continues to develop.';
    String type = 'growth';
    
    if (core.trend == 'rising') {
      title = '${core.name} Rising';
      description = 'Your ${core.name} is showing positive growth through your recent reflections.';
      type = 'growth';
    } else if (core.trend == 'declining') {
      title = 'Gentle Reminder';
      description = 'Your ${core.name} could benefit from some focused attention and self-care.';
      type = 'recommendation';
    }
    
    return CoreInsight(
      id: '${core.id}_recent_${DateTime.now().millisecondsSinceEpoch}',
      coreId: core.id,
      title: title,
      description: description,
      type: type,
      createdAt: DateTime.now(),
      relevanceScore: 0.8,
    );
  }

  double _calculateRelevanceScore(EmotionalCore core, String insightType) {
    double score = 0.5;
    
    if (insightType == 'growth' && core.trend == 'rising') score += 0.3;
    if (insightType == 'recommendation' && core.currentLevel < 0.5) score += 0.2;
    if (insightType == 'milestone' && core.milestones.any((m) => m.isAchieved)) score += 0.2;
    
    return score.clamp(0.0, 1.0);
  }

  List<Map<String, String>> _getCoreInsights(String coreId, String trend, double level) {
    final baseInsights = {
      'optimism': [
        {'title': 'Bright Outlook', 'description': 'Your positive perspective brightens your daily experiences.', 'type': 'growth'},
        {'title': 'Hope Flourishes', 'description': 'Your ability to see possibilities continues to strengthen.', 'type': 'pattern'},
        {'title': 'Gratitude Practice', 'description': 'Consider keeping a daily gratitude journal to nurture optimism.', 'type': 'recommendation'},
      ],
      'resilience': [
        {'title': 'Inner Strength', 'description': 'Your capacity to handle challenges grows with each experience.', 'type': 'growth'},
        {'title': 'Bounce Back', 'description': 'You\'re developing a remarkable ability to recover from setbacks.', 'type': 'pattern'},
        {'title': 'Challenge Reframe', 'description': 'Try viewing obstacles as opportunities for growth.', 'type': 'recommendation'},
      ],
      'self_awareness': [
        {'title': 'Deep Understanding', 'description': 'Your self-knowledge deepens through mindful reflection.', 'type': 'growth'},
        {'title': 'Emotional Clarity', 'description': 'You\'re becoming more attuned to your emotional patterns.', 'type': 'pattern'},
        {'title': 'Mindful Moments', 'description': 'Take regular pauses to check in with your feelings.', 'type': 'recommendation'},
      ],
      'creativity': [
        {'title': 'Creative Flow', 'description': 'Your innovative thinking brings fresh perspectives to challenges.', 'type': 'growth'},
        {'title': 'Imaginative Spark', 'description': 'Your creative energy manifests in unique ways.', 'type': 'pattern'},
        {'title': 'Creative Exploration', 'description': 'Try a new creative activity to spark inspiration.', 'type': 'recommendation'},
      ],
      'social_connection': [
        {'title': 'Heart Connections', 'description': 'Your empathy and understanding deepen your relationships.', 'type': 'growth'},
        {'title': 'Community Builder', 'description': 'You naturally create bonds and foster connection.', 'type': 'pattern'},
        {'title': 'Reach Out', 'description': 'Consider connecting with someone you haven\'t spoken to recently.', 'type': 'recommendation'},
      ],
      'growth_mindset': [
        {'title': 'Learning Journey', 'description': 'Your openness to growth creates endless possibilities.', 'type': 'growth'},
        {'title': 'Embrace Challenges', 'description': 'You\'re learning to see difficulties as learning opportunities.', 'type': 'pattern'},
        {'title': 'Skill Building', 'description': 'Consider learning something new that excites you.', 'type': 'recommendation'},
      ],
    };
    
    return baseInsights[coreId] ?? [
      {'title': 'Personal Growth', 'description': 'Your core continues to develop through self-reflection.', 'type': 'growth'}
    ];
  }

  List<CoreCombination> _generateCoreCombinations(List<EmotionalCore> cores) {
    final combinations = <CoreCombination>[];
    
    // Find strong cores (above 0.7)
    final strongCores = cores.where((core) => core.currentLevel > 0.7).toList();
    
    if (strongCores.length >= 2) {
      // Optimism + Resilience
      final optimism = cores.firstWhere((c) => c.id == 'optimism', orElse: () => cores.first);
      final resilience = cores.firstWhere((c) => c.id == 'resilience', orElse: () => cores.first);
      
      if (optimism.currentLevel > 0.65 && resilience.currentLevel > 0.65) {
        combinations.add(CoreCombination(
          name: 'Unshakeable Spirit',
          coreIds: [optimism.id, resilience.id],
          description: 'Your optimism and resilience create an unshakeable foundation.',
          benefit: 'Enhanced emotional stability and faster recovery from setbacks.',
        ));
      }
      
      // Self-Awareness + Growth Mindset
      final selfAwareness = cores.firstWhere((c) => c.id == 'self_awareness', orElse: () => cores.first);
      final growthMindset = cores.firstWhere((c) => c.id == 'growth_mindset', orElse: () => cores.first);
      
      if (selfAwareness.currentLevel > 0.7 && growthMindset.currentLevel > 0.7) {
        combinations.add(CoreCombination(
          name: 'Conscious Evolution',
          coreIds: [selfAwareness.id, growthMindset.id],
          description: 'Self-awareness combined with growth mindset creates powerful development.',
          benefit: 'Accelerated learning and more intentional personal growth.',
        ));
      }
    }
    
    return combinations;
  }

  List<String> _generateGrowthRecommendations(List<EmotionalCore> cores) {
    final recommendations = <String>[];
    
    // Find cores that need attention
    final weakCores = cores.where((core) => core.currentLevel < 0.5).toList();
    final decliningCores = cores.where((core) => core.trend == 'declining').toList();
    
    for (final core in weakCores.take(2)) {
      recommendations.add(_getCoreRecommendation(core.id));
    }
    
    for (final core in decliningCores.take(1)) {
      recommendations.add(_getDeclineRecommendation(core.id));
    }
    
    return recommendations.take(3).toList();
  }

  String _getCoreRecommendation(String coreId) {
    final recommendations = {
      'optimism': 'Practice daily gratitude by writing down three things you\'re thankful for.',
      'resilience': 'Reframe challenges as opportunities for growth and learning.',
      'self_awareness': 'Spend time reflecting on your emotions and their triggers.',
      'creativity': 'Explore new creative outlets or approach familiar tasks differently.',
      'social_connection': 'Reach out to friends or family you haven\'t connected with recently.',
      'growth_mindset': 'Embrace learning opportunities and view mistakes as stepping stones.',
    };
    
    return recommendations[coreId] ?? 'Focus on developing this core through consistent practice.';
  }

  String _getDeclineRecommendation(String coreId) {
    final recommendations = {
      'optimism': 'When feeling down, try to identify one small positive aspect of your day.',
      'resilience': 'Remember past challenges you\'ve overcome and draw strength from those experiences.',
      'self_awareness': 'Take a few minutes each day for mindful self-reflection without judgment.',
      'creativity': 'Try a new creative activity or approach a familiar task in a different way.',
      'social_connection': 'Consider reaching out to someone who makes you feel understood.',
      'growth_mindset': 'Remind yourself that abilities develop through dedication and practice.',
    };
    
    return recommendations[coreId] ?? 'Be patient as this core recovers and grows.';
  }

  List<String> _getRelatedCores(String coreId) {
    final relationships = {
      'optimism': ['resilience', 'growth_mindset'],
      'resilience': ['optimism', 'self_awareness'],
      'self_awareness': ['resilience', 'growth_mindset'],
      'creativity': ['growth_mindset', 'social_connection'],
      'social_connection': ['creativity', 'self_awareness'],
      'growth_mindset': ['optimism', 'self_awareness'],
    };
    
    return relationships[coreId] ?? [];
  }

  String _getDefaultInsight(String coreName) {
    final insights = {
      'Optimism': 'Your positive outlook supports your overall well-being.',
      'Resilience': 'Your ability to bounce back from challenges is a key strength.',
      'Self-Awareness': 'Your understanding of yourself deepens through reflection.',
      'Creativity': 'Your creative thinking adds richness to your experiences.',
      'Social Connection': 'Your relationships enhance your life journey.',
      'Growth Mindset': 'Your openness to learning fuels continuous development.',
    };
    
    return insights[coreName] ?? 'Your core contributes to your personal growth.';
  }

  Future<void> _saveCores(List<EmotionalCore> cores) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coresJson = jsonEncode(cores.map((core) => core.toJson()).toList());
      await prefs.setString(_coresKey, coresJson);
    } catch (e) {
      debugPrint('CoreLibraryService _saveCores error: $e');
    }
  }

  Future<void> _saveInsight(CoreInsight insight) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingInsights = prefs.getStringList(_insightsKey) ?? [];
      existingInsights.add(jsonEncode(insight.toJson()));
      
      // Keep only the most recent 50 insights
      if (existingInsights.length > 50) {
        existingInsights.removeRange(0, existingInsights.length - 50);
      }
      
      await prefs.setStringList(_insightsKey, existingInsights);
    } catch (e) {
      debugPrint('CoreLibraryService _saveInsight error: $e');
    }
  }
}

/// Configuration class for core settings
class CoreConfig {
  final String id;
  final String name;
  final String description;
  final String color;
  final String iconPath;
  final double baselineLevel;
  final double maxDailyChange;
  final double decayRate;

  const CoreConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.iconPath,
    required this.baselineLevel,
    required this.maxDailyChange,
    required this.decayRate,
  });
}