import 'package:flutter/foundation.dart';
import '../models/core.dart';
import '../models/journal_entry.dart';
import 'emotional_analyzer.dart';

/// Engine for evolving personality cores based on emotional analysis and journal patterns.
/// 
/// This service calculates core progress, manages milestones, and provides insights
/// about personality development based on journal analysis results.
class CoreEvolutionEngine {
  static final CoreEvolutionEngine _instance = CoreEvolutionEngine._internal();
  factory CoreEvolutionEngine() => _instance;
  CoreEvolutionEngine._internal();

  bool _isInitialized = false;

  /// Initialize the core evolution engine
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize any database connections or services needed
      debugPrint('CoreEvolutionEngine: Initializing...');
      
      // Set up core database tables if needed
      // Initialize core configurations
      // Load user's current cores from database
      
      _isInitialized = true;
      debugPrint('CoreEvolutionEngine: Initialized successfully');
    } catch (e) {
      debugPrint('CoreEvolutionEngine: Initialization failed: $e');
      rethrow;
    }
  }

  // Core configuration
  static const Map<String, CoreConfig> _coreConfigs = {
    'optimism': CoreConfig(
      id: 'optimism',
      name: 'Optimism',
      description: 'Your ability to maintain hope and positive outlook',
      color: '#FF6B35',
      iconPath: 'assets/icons/optimism.png',
      baselinePercentage: 70.0,
      maxDailyChange: 3.0,
      decayRate: 0.1,
    ),
    'resilience': CoreConfig(
      id: 'resilience',
      name: 'Resilience',
      description: 'Your capacity to bounce back from challenges',
      color: '#4ECDC4',
      iconPath: 'assets/icons/resilience.png',
      baselinePercentage: 65.0,
      maxDailyChange: 2.5,
      decayRate: 0.05,
    ),
    'self_awareness': CoreConfig(
      id: 'self_awareness',
      name: 'Self-Awareness',
      description: 'Your understanding of your emotions and thoughts',
      color: '#45B7D1',
      iconPath: 'assets/icons/self_awareness.png',
      baselinePercentage: 75.0,
      maxDailyChange: 2.0,
      decayRate: 0.02,
    ),
    'creativity': CoreConfig(
      id: 'creativity',
      name: 'Creativity',
      description: 'Your innovative thinking and creative expression',
      color: '#96CEB4',
      iconPath: 'assets/icons/creativity.png',
      baselinePercentage: 60.0,
      maxDailyChange: 4.0,
      decayRate: 0.15,
    ),
    'social_connection': CoreConfig(
      id: 'social_connection',
      name: 'Social Connection',
      description: 'Your relationships and empathy with others',
      color: '#FFEAA7',
      iconPath: 'assets/icons/social_connection.png',
      baselinePercentage: 68.0,
      maxDailyChange: 3.5,
      decayRate: 0.08,
    ),
    'growth_mindset': CoreConfig(
      id: 'growth_mindset',
      name: 'Growth Mindset',
      description: 'Your openness to learning and embracing challenges',
      color: '#DDA0DD',
      iconPath: 'assets/icons/growth_mindset.png',
      baselinePercentage: 72.0,
      maxDailyChange: 2.8,
      decayRate: 0.03,
    ),
  };

  /// Calculate core updates based on emotional analysis
  Map<String, double> calculateCoreUpdates(
    List<EmotionalCore> currentCores,
    EmotionalAnalysisResult analysis,
    JournalEntry entry,
  ) {
    try {
      final updates = <String, double>{};
      
      for (final core in currentCores) {
        final coreId = _getCoreIdFromName(core.name);
        final config = _coreConfigs[coreId];
        
        if (config != null) {
          final newPercentage = _calculateNewCorePercentage(
            core,
            config,
            analysis,
            entry,
          );
          
          if ((newPercentage - core.percentage).abs() > 0.01) {
            updates[core.id] = newPercentage;
          }
        }
      }
      
      return updates;
    } catch (e) {
      debugPrint('CoreEvolutionEngine calculateCoreUpdates error: $e');
      return {};
    }
  }

  /// Update cores with milestone tracking and trend analysis
  List<EmotionalCore> updateCoresWithAnalysis(
    List<EmotionalCore> currentCores,
    EmotionalAnalysisResult analysis,
    JournalEntry entry,
  ) {
    try {
      final updates = calculateCoreUpdates(currentCores, analysis, entry);
      final updatedCores = <EmotionalCore>[];
      
      for (final core in currentCores) {
        if (updates.containsKey(core.id)) {
          final newPercentage = updates[core.id]!;
          final trend = _calculateTrend(core.percentage, newPercentage);
          final insight = _generateCoreInsight(core, analysis, trend);
          final relatedCores = _getRelatedCores(core.name);
          
          updatedCores.add(EmotionalCore(
            id: core.id,
            name: core.name,
            description: core.description,
            currentLevel: newPercentage / 100.0,
            previousLevel: core.percentage / 100.0,
            lastUpdated: DateTime.now(),
            trend: trend,
            color: core.color,
            iconPath: core.iconPath,
            insight: insight,
            relatedCores: relatedCores,
          ));
        } else {
          // Keep existing core unchanged
          updatedCores.add(core);
        }
      }
      
      return updatedCores;
    } catch (e) {
      debugPrint('CoreEvolutionEngine updateCoresWithAnalysis error: $e');
      return currentCores;
    }
  }

  /// Calculate core progress and milestones
  CoreProgressResult calculateCoreProgress(
    EmotionalCore core,
    List<JournalEntry> recentEntries,
  ) {
    try {
      final milestones = _generateCoreMilestones(core);
      final achievedMilestones = milestones
          .where((m) => core.percentage >= m.threshold)
          .toList();
      
      final progressVelocity = _calculateProgressVelocity(core, recentEntries);
      final nextMilestone = milestones
          .where((m) => core.percentage < m.threshold)
          .fold<CoreMilestone?>(null, (prev, curr) => 
              prev == null || curr.threshold < prev.threshold ? curr : prev);
      
      return CoreProgressResult(
        core: core,
        milestones: milestones,
        achievedMilestones: achievedMilestones,
        nextMilestone: nextMilestone,
        progressVelocity: progressVelocity,
        estimatedTimeToNextMilestone: _estimateTimeToMilestone(
          core.percentage,
          nextMilestone?.threshold ?? 100.0,
          progressVelocity,
        ),
      );
    } catch (e) {
      debugPrint('CoreEvolutionEngine calculateCoreProgress error: $e');
      return CoreProgressResult(
        core: core,
        milestones: [],
        achievedMilestones: [],
        nextMilestone: null,
        progressVelocity: 0.0,
        estimatedTimeToNextMilestone: null,
      );
    }
  }

  /// Generate personalized core insights based on recent patterns
  String generateCoreInsight(
    EmotionalCore core,
    List<EmotionalAnalysisResult> recentAnalyses,
  ) {
    try {
      final coreId = _getCoreIdFromName(core.name);
      final config = _coreConfigs[coreId];
      
      if (config == null) {
        return 'Your ${core.name} continues to develop through self-reflection.';
      }
      
      // Analyze recent trends
      final recentImpacts = recentAnalyses
          .map((analysis) => analysis.coreImpacts[core.name] ?? 0.0)
          .where((impact) => impact != 0.0)
          .toList();
      
      if (recentImpacts.isEmpty) {
        return _getDefaultCoreInsight(core.name);
      }
      
      final avgImpact = recentImpacts.reduce((a, b) => a + b) / recentImpacts.length;
      final isGrowing = avgImpact > 0.05;
      final isStable = avgImpact.abs() <= 0.05;
      
      return _generatePersonalizedInsight(core.name, isGrowing, isStable, core.percentage);
    } catch (e) {
      debugPrint('CoreEvolutionEngine generateCoreInsight error: $e');
      return 'Your ${core.name} continues to develop through self-reflection.';
    }
  }

  /// Update cores from analysis results (called by DailyJournalProcessor)
  Future<void> updateCoresFromAnalysis(Map<String, dynamic> coreStrengths) async {
    try {
      if (coreStrengths.isEmpty) {
        debugPrint('CoreEvolutionEngine: No core strengths to update');
        return;
      }

      // This would typically update the cores in the database
      // For now, we'll just log the updates
      debugPrint('CoreEvolutionEngine: Updating cores with analysis:');
      
      for (final entry in coreStrengths.entries) {
        final coreId = entry.key;
        final increment = entry.value as double;
        
        debugPrint('  $coreId: ${increment > 0 ? '+' : ''}${increment.toStringAsFixed(2)}');
        
        // Here you would:
        // 1. Get current core from database
        // 2. Apply the increment (with daily limits)
        // 3. Update core in database
        // 4. Trigger milestone checks
        // 5. Update core trends
      }
      
      debugPrint('CoreEvolutionEngine: Core updates completed');
    } catch (e) {
      debugPrint('CoreEvolutionEngine updateCoresFromAnalysis error: $e');
    }
  }

  /// Get initial core set for new users
  List<EmotionalCore> getInitialCores() {
    return _coreConfigs.values.map((config) => EmotionalCore(
      id: config.id,
      name: config.name,
      description: config.description,
      currentLevel: config.baselinePercentage / 100.0,
      previousLevel: config.baselinePercentage / 100.0,
      lastUpdated: DateTime.now(),
      trend: 'stable',
      color: config.color,
      iconPath: config.iconPath,
      insight: _getDefaultCoreInsight(config.name),
      relatedCores: _getRelatedCores(config.name),
    )).toList();
  }

  /// Calculate core synergy effects between related cores
  Map<String, double> calculateCoreSynergies(List<EmotionalCore> cores) {
    try {
      final synergies = <String, double>{};
      
      for (final core in cores) {
        double synergyBonus = 0.0;
        
        // Check related cores for synergy effects
        for (final relatedCoreId in core.relatedCores) {
          final relatedCore = cores.firstWhere(
            (c) => c.id == relatedCoreId,
            orElse: () => cores.firstWhere(
              (c) => _getCoreIdFromName(c.name) == relatedCoreId,
              orElse: () => cores.first, // Fallback
            ),
          );
          
          // Calculate synergy based on related core strength
          if (relatedCore.percentage > 70.0) {
            synergyBonus += 0.1; // 10% bonus for strong related cores
          } else if (relatedCore.percentage > 50.0) {
            synergyBonus += 0.05; // 5% bonus for moderate related cores
          }
        }
        
        synergies[core.id] = synergyBonus.clamp(0.0, 0.3); // Max 30% synergy bonus
      }
      
      return synergies;
    } catch (e) {
      debugPrint('CoreEvolutionEngine calculateCoreSynergies error: $e');
      return {};
    }
  }

  /// Generate core combination recommendations
  List<CoreCombination> generateCoreCombinations(List<EmotionalCore> cores) {
    try {
      final combinations = <CoreCombination>[];
      
      // Find strong core pairs
      final strongCores = cores.where((core) => core.percentage > 70.0).toList();
      
      if (strongCores.length >= 2) {
        // Optimism + Resilience combination
        final optimism = cores.firstWhere(
          (core) => core.name == 'Optimism',
          orElse: () => cores.first,
        );
        final resilience = cores.firstWhere(
          (core) => core.name == 'Resilience',
          orElse: () => cores.first,
        );
        
        if (optimism.percentage > 65.0 && resilience.percentage > 65.0) {
          combinations.add(CoreCombination(
            name: 'Unshakeable Spirit',
            coreIds: [optimism.id, resilience.id],
            description: 'Your optimism and resilience create an unshakeable foundation for facing life\'s challenges.',
            benefit: 'Enhanced emotional stability and faster recovery from setbacks.',
          ));
        }
        
        // Self-Awareness + Growth Mindset combination
        final selfAwareness = cores.firstWhere(
          (core) => core.name == 'Self-Awareness',
          orElse: () => cores.first,
        );
        final growthMindset = cores.firstWhere(
          (core) => core.name == 'Growth Mindset',
          orElse: () => cores.first,
        );
        
        if (selfAwareness.percentage > 70.0 && growthMindset.percentage > 70.0) {
          combinations.add(CoreCombination(
            name: 'Conscious Evolution',
            coreIds: [selfAwareness.id, growthMindset.id],
            description: 'Your self-awareness combined with growth mindset creates powerful personal development.',
            benefit: 'Accelerated learning and more intentional personal growth.',
          ));
        }
        
        // Creativity + Social Connection combination
        final creativity = cores.firstWhere(
          (core) => core.name == 'Creativity',
          orElse: () => cores.first,
        );
        final socialConnection = cores.firstWhere(
          (core) => core.name == 'Social Connection',
          orElse: () => cores.first,
        );
        
        if (creativity.percentage > 65.0 && socialConnection.percentage > 65.0) {
          combinations.add(CoreCombination(
            name: 'Inspiring Connector',
            coreIds: [creativity.id, socialConnection.id],
            description: 'Your creativity and social connection inspire and uplift others around you.',
            benefit: 'Enhanced ability to build meaningful relationships through creative expression.',
          ));
        }
      }
      
      return combinations;
    } catch (e) {
      debugPrint('CoreEvolutionEngine generateCoreCombinations error: $e');
      return [];
    }
  }

  /// Calculate milestone achievements and progress
  List<CoreMilestone> calculateMilestoneAchievements(
    EmotionalCore core,
    List<JournalEntry> historicalEntries,
  ) {
    try {
      final milestones = _generateCoreMilestones(core);
      final achievedMilestones = <CoreMilestone>[];
      
      for (final milestone in milestones) {
        if (core.percentage >= milestone.threshold) {
          // Estimate achievement date based on historical data
          DateTime? achievedDate;
          if (historicalEntries.isNotEmpty) {
            // Find approximate date when this threshold was reached
            final sortedEntries = historicalEntries
              ..sort((a, b) => a.date.compareTo(b.date));
            
            // Simple estimation - in a real implementation, this would track historical percentages
            final progressRate = core.percentage / sortedEntries.length;
            final entriesNeeded = (milestone.threshold / progressRate).ceil();
            
            if (entriesNeeded < sortedEntries.length) {
              achievedDate = sortedEntries[entriesNeeded].date;
            } else {
              achievedDate = sortedEntries.last.date;
            }
          }
          
          achievedMilestones.add(CoreMilestone(
            id: milestone.id,
            title: milestone.title,
            description: milestone.description,
            threshold: milestone.threshold,
            isAchieved: true,
            achievedAt: achievedDate ?? DateTime.now(),
          ));
        }
      }
      
      return achievedMilestones;
    } catch (e) {
      debugPrint('CoreEvolutionEngine calculateMilestoneAchievements error: $e');
      return [];
    }
  }

  /// Generate growth recommendations based on core analysis
  List<String> generateGrowthRecommendations(
    List<EmotionalCore> cores,
    List<EmotionalAnalysisResult> recentAnalyses,
  ) {
    try {
      final recommendations = <String>[];
      
      // Find cores that need attention (below 50%)
      final weakCores = cores.where((core) => core.percentage < 50.0).toList();
      
      for (final core in weakCores) {
        final recommendation = _getCoreGrowthRecommendation(core.name, core.percentage);
        if (recommendation.isNotEmpty) {
          recommendations.add(recommendation);
        }
      }
      
      // Find cores with declining trends
      final decliningCores = cores.where((core) => core.trend == 'declining').toList();
      
      for (final core in decliningCores) {
        final recommendation = _getDeclineRecoveryRecommendation(core.name);
        if (recommendation.isNotEmpty) {
          recommendations.add(recommendation);
        }
      }
      
      // Add general growth recommendations based on recent patterns
      if (recentAnalyses.isNotEmpty) {
        final commonThemes = _findCommonThemes(recentAnalyses);
        for (final theme in commonThemes) {
          final recommendation = _getThemeBasedRecommendation(theme);
          if (recommendation.isNotEmpty) {
            recommendations.add(recommendation);
          }
        }
      }
      
      return recommendations.take(5).toList(); // Limit to 5 recommendations
    } catch (e) {
      debugPrint('CoreEvolutionEngine generateGrowthRecommendations error: $e');
      return [];
    }
  }

  // Private methods

  double _calculateNewCorePercentage(
    EmotionalCore core,
    CoreConfig config,
    EmotionalAnalysisResult analysis,
    JournalEntry entry,
  ) {
    double impact = 0.0;
    
    // Get direct impact from analysis
    final directImpact = analysis.coreImpacts[core.name] ?? 0.0;
    impact += directImpact * 10; // Scale up the impact
    
    // Add pattern-based impacts
    impact += _calculatePatternImpact(core.name, analysis, entry);
    
    // Add theme-based impacts
    impact += _calculateThemeImpact(core.name, analysis.keyThemes);
    
    // Add emotion-based impacts
    impact += _calculateEmotionImpact(core.name, analysis.primaryEmotions);
    
    // Apply daily change limits
    impact = impact.clamp(-config.maxDailyChange, config.maxDailyChange);
    
    // Calculate new percentage
    final newPercentage = (core.percentage + impact).clamp(0.0, 100.0);
    
    // Apply natural decay towards baseline if no significant impact
    if (impact.abs() < 0.1) {
      final decayAmount = (config.baselinePercentage - core.percentage) * config.decayRate;
      return (core.percentage + decayAmount).clamp(0.0, 100.0);
    }
    
    return newPercentage;
  }

  double _calculatePatternImpact(
    String coreName,
    EmotionalAnalysisResult analysis,
    JournalEntry entry,
  ) {
    double impact = 0.0;
    
    for (final pattern in analysis.emotionalPatterns) {
      switch (coreName) {
        case 'Optimism':
          if (pattern.type == 'growth' && pattern.category.contains('Positive')) {
            impact += 0.5;
          }
          break;
        case 'Resilience':
          if (pattern.description.toLowerCase().contains('challenge') ||
              pattern.description.toLowerCase().contains('overcome')) {
            impact += 0.8;
          }
          break;
        case 'Self-Awareness':
          if (pattern.category.contains('Reflection') || 
              pattern.type == 'awareness') {
            impact += 0.6;
          }
          break;
        case 'Creativity':
          if (pattern.description.toLowerCase().contains('creative') ||
              pattern.description.toLowerCase().contains('innovative')) {
            impact += 0.7;
          }
          break;
        case 'Social Connection':
          if (pattern.description.toLowerCase().contains('social') ||
              pattern.description.toLowerCase().contains('relationship')) {
            impact += 0.6;
          }
          break;
        case 'Growth Mindset':
          if (pattern.type == 'growth' || 
              pattern.description.toLowerCase().contains('learning')) {
            impact += 0.5;
          }
          break;
      }
    }
    
    return impact;
  }

  double _calculateThemeImpact(String coreName, List<String> themes) {
    double impact = 0.0;
    
    final coreThemes = {
      'Optimism': ['gratitude', 'hope', 'positive', 'joy', 'happiness'],
      'Resilience': ['challenge', 'overcome', 'strength', 'perseverance', 'recovery'],
      'Self-Awareness': ['reflection', 'understanding', 'awareness', 'mindfulness', 'insight'],
      'Creativity': ['creative', 'innovation', 'imagination', 'artistic', 'original'],
      'Social Connection': ['relationship', 'friendship', 'community', 'empathy', 'connection'],
      'Growth Mindset': ['learning', 'development', 'improvement', 'progress', 'growth'],
    };
    
    final relevantThemes = coreThemes[coreName] ?? [];
    
    for (final theme in themes) {
      for (final relevantTheme in relevantThemes) {
        if (theme.toLowerCase().contains(relevantTheme)) {
          impact += 0.3;
          break;
        }
      }
    }
    
    return impact.clamp(0.0, 2.0);
  }

  double _calculateEmotionImpact(String coreName, List<String> emotions) {
    double impact = 0.0;
    
    final coreEmotions = {
      'Optimism': ['happy', 'joyful', 'excited', 'hopeful', 'grateful'],
      'Resilience': ['determined', 'strong', 'confident', 'brave', 'persistent'],
      'Self-Awareness': ['reflective', 'thoughtful', 'aware', 'mindful', 'introspective'],
      'Creativity': ['inspired', 'imaginative', 'innovative', 'artistic', 'original'],
      'Social Connection': ['loving', 'connected', 'empathetic', 'caring', 'social'],
      'Growth Mindset': ['curious', 'motivated', 'ambitious', 'learning', 'developing'],
    };
    
    final relevantEmotions = coreEmotions[coreName] ?? [];
    
    for (final emotion in emotions) {
      if (relevantEmotions.contains(emotion.toLowerCase())) {
        impact += 0.4;
      }
    }
    
    return impact.clamp(0.0, 1.5);
  }

  String _calculateTrend(double oldPercentage, double newPercentage) {
    final change = newPercentage - oldPercentage;
    
    if (change > 0.5) return 'rising';
    if (change < -0.5) return 'declining';
    return 'stable';
  }

  String _generateCoreInsight(
    EmotionalCore core,
    EmotionalAnalysisResult analysis,
    String trend,
  ) {
    final coreName = core.name;
    
    switch (trend) {
      case 'rising':
        return _getGrowthInsight(coreName, analysis);
      case 'declining':
        return _getDeclineInsight(coreName);
      default:
        return _getStableInsight(coreName);
    }
  }

  String _getGrowthInsight(String coreName, EmotionalAnalysisResult analysis) {
    final insights = {
      'Optimism': 'Your positive outlook is strengthening through mindful reflection and gratitude practices.',
      'Resilience': 'You\'re building emotional strength by facing challenges with courage and determination.',
      'Self-Awareness': 'Your understanding of your emotions deepens with each thoughtful journal entry.',
      'Creativity': 'Your innovative thinking flourishes as you explore new perspectives and ideas.',
      'Social Connection': 'Your empathy and relationship skills grow through conscious reflection on connections.',
      'Growth Mindset': 'Your openness to learning expands as you embrace challenges and new experiences.',
    };
    
    return insights[coreName] ?? 'Your $coreName continues to develop through consistent self-reflection.';
  }

  String _getDeclineInsight(String coreName) {
    final insights = {
      'Optimism': 'Consider focusing on gratitude and positive aspects of your experiences to rebuild optimism.',
      'Resilience': 'Remember that setbacks are temporary. Your strength will return through self-compassion.',
      'Self-Awareness': 'Take time for deeper reflection to reconnect with your inner wisdom and understanding.',
      'Creativity': 'Explore new activities or perspectives to reignite your creative spark and imagination.',
      'Social Connection': 'Reach out to others and practice empathy to strengthen your social bonds.',
      'Growth Mindset': 'Embrace challenges as learning opportunities to rediscover your growth potential.',
    };
    
    return insights[coreName] ?? 'Your $coreName may benefit from focused attention and gentle self-care.';
  }

  String _getStableInsight(String coreName) {
    final insights = {
      'Optimism': 'Your positive outlook remains steady, providing a solid foundation for well-being.',
      'Resilience': 'Your emotional strength is consistent, ready to support you through any challenges.',
      'Self-Awareness': 'Your self-understanding maintains a healthy balance, supporting continued growth.',
      'Creativity': 'Your creative energy flows steadily, ready to be channeled into meaningful expression.',
      'Social Connection': 'Your relationship skills remain strong, fostering meaningful connections.',
      'Growth Mindset': 'Your learning orientation stays consistent, supporting continuous development.',
    };
    
    return insights[coreName] ?? 'Your $coreName maintains a healthy balance, supporting your overall well-being.';
  }

  List<CoreMilestone> _generateCoreMilestones(EmotionalCore core) {
    return [
      CoreMilestone(
        id: '${core.id}_milestone_1',
        title: 'Foundation',
        description: 'Building the foundation of ${core.name}',
        threshold: 25.0,
        isAchieved: core.percentage >= 25.0,
        achievedAt: core.percentage >= 25.0 ? DateTime.now() : null,
      ),
      CoreMilestone(
        id: '${core.id}_milestone_2',
        title: 'Development',
        description: 'Developing strong ${core.name} skills',
        threshold: 50.0,
        isAchieved: core.percentage >= 50.0,
        achievedAt: core.percentage >= 50.0 ? DateTime.now() : null,
      ),
      CoreMilestone(
        id: '${core.id}_milestone_3',
        title: 'Proficiency',
        description: 'Achieving proficiency in ${core.name}',
        threshold: 75.0,
        isAchieved: core.percentage >= 75.0,
        achievedAt: core.percentage >= 75.0 ? DateTime.now() : null,
      ),
      CoreMilestone(
        id: '${core.id}_milestone_4',
        title: 'Mastery',
        description: 'Mastering the art of ${core.name}',
        threshold: 90.0,
        isAchieved: core.percentage >= 90.0,
        achievedAt: core.percentage >= 90.0 ? DateTime.now() : null,
      ),
    ];
  }

  double _calculateProgressVelocity(EmotionalCore core, List<JournalEntry> recentEntries) {
    // Simplified velocity calculation - in a real implementation,
    // this would track historical percentage changes
    return 0.5; // Default velocity
  }

  Duration? _estimateTimeToMilestone(
    double currentPercentage,
    double targetPercentage,
    double velocity,
  ) {
    if (velocity <= 0) return null;
    
    final remainingProgress = targetPercentage - currentPercentage;
    final daysToMilestone = (remainingProgress / velocity).ceil();
    
    return Duration(days: daysToMilestone);
  }

  String _getCoreIdFromName(String name) {
    return name.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  List<String> _getRelatedCores(String coreName) {
    final relationships = {
      'Optimism': ['resilience', 'growth_mindset'],
      'Resilience': ['optimism', 'self_awareness'],
      'Self-Awareness': ['resilience', 'growth_mindset'],
      'Creativity': ['growth_mindset', 'social_connection'],
      'Social Connection': ['creativity', 'self_awareness'],
      'Growth Mindset': ['optimism', 'self_awareness'],
    };
    
    final coreId = _getCoreIdFromName(coreName);
    return relationships[coreId] ?? [];
  }

  String _getDefaultCoreInsight(String coreName) {
    final insights = {
      'Optimism': 'Your positive outlook supports your overall well-being and resilience.',
      'Resilience': 'Your ability to bounce back from challenges is a key strength.',
      'Self-Awareness': 'Your understanding of yourself deepens through regular reflection.',
      'Creativity': 'Your creative thinking adds richness to your problem-solving abilities.',
      'Social Connection': 'Your relationships and empathy enhance your life experience.',
      'Growth Mindset': 'Your openness to learning fuels continuous personal development.',
    };
    
    return insights[coreName] ?? 'Your $coreName contributes to your personal growth journey.';
  }

  String _generatePersonalizedInsight(
    String coreName,
    bool isGrowing,
    bool isStable,
    double percentage,
  ) {
    if (isGrowing) {
      return _getGrowthInsight(coreName, EmotionalAnalysisResult(
        primaryEmotions: [],
        emotionalIntensity: 0,
        keyThemes: [],
        overallSentiment: 0,
        personalizedInsight: '',
        coreImpacts: {},
        emotionalPatterns: [],
        growthIndicators: [],
        validationScore: 0,
      ));
    } else if (isStable) {
      return _getStableInsight(coreName);
    } else {
      return _getDeclineInsight(coreName);
    }
  }

  // Helper methods for growth recommendations

  String _getCoreGrowthRecommendation(String coreName, double percentage) {
    final recommendations = {
      'Optimism': 'Try practicing daily gratitude by writing down three things you\'re thankful for each day.',
      'Resilience': 'Focus on reframing challenges as opportunities for growth and learning.',
      'Self-Awareness': 'Spend more time reflecting on your emotions and what triggers them.',
      'Creativity': 'Explore new creative outlets like drawing, writing, or brainstorming sessions.',
      'Social Connection': 'Reach out to friends or family members you haven\'t spoken to recently.',
      'Growth Mindset': 'Embrace learning opportunities and view mistakes as stepping stones to improvement.',
    };
    
    return recommendations[coreName] ?? 'Focus on developing your $coreName through consistent practice.';
  }

  String _getDeclineRecoveryRecommendation(String coreName) {
    final recommendations = {
      'Optimism': 'When feeling down, try to identify one small positive aspect of your day.',
      'Resilience': 'Remember past challenges you\'ve overcome and draw strength from those experiences.',
      'Self-Awareness': 'Take a few minutes each day for mindful self-reflection without judgment.',
      'Creativity': 'Try a new creative activity or approach a familiar task in a different way.',
      'Social Connection': 'Consider reaching out to someone who makes you feel understood and supported.',
      'Growth Mindset': 'Remind yourself that abilities can be developed through dedication and hard work.',
    };
    
    return recommendations[coreName] ?? 'Be patient with yourself as your $coreName recovers and grows.';
  }

  List<String> _findCommonThemes(List<EmotionalAnalysisResult> analyses) {
    final themeFrequency = <String, int>{};
    
    for (final analysis in analyses) {
      for (final theme in analysis.keyThemes) {
        themeFrequency[theme] = (themeFrequency[theme] ?? 0) + 1;
      }
    }
    
    // Return themes that appear in at least 30% of analyses
    final threshold = (analyses.length * 0.3).ceil();
    return themeFrequency.entries
        .where((entry) => entry.value >= threshold)
        .map((entry) => entry.key)
        .toList();
  }

  String _getThemeBasedRecommendation(String theme) {
    final recommendations = {
      'gratitude': 'Continue your gratitude practice - it\'s having a positive impact on your well-being.',
      'challenge': 'You\'re handling challenges well. Remember to celebrate your resilience.',
      'growth': 'Your focus on growth is admirable. Keep embracing new learning opportunities.',
      'reflection': 'Your self-reflection practice is deepening your self-awareness beautifully.',
      'creativity': 'Your creative expressions are flourishing. Consider exploring new creative outlets.',
      'connection': 'Your focus on relationships is strengthening your social bonds.',
      'learning': 'Your commitment to learning is expanding your growth mindset.',
      'mindfulness': 'Your mindfulness practice is enhancing your emotional awareness.',
    };
    
    return recommendations[theme.toLowerCase()] ?? 'Your focus on $theme is contributing to your personal growth.';
  }
}

/// Configuration for a personality core
class CoreConfig {
  final String id;
  final String name;
  final String description;
  final String color;
  final String iconPath;
  final double baselinePercentage;
  final double maxDailyChange;
  final double decayRate;

  const CoreConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.iconPath,
    required this.baselinePercentage,
    required this.maxDailyChange,
    required this.decayRate,
  });
}

/// Milestone for core development
class CoreMilestone {
  final String id;
  final String title;
  final String description;
  final double threshold;
  final bool isAchieved;
  final DateTime? achievedAt;

  CoreMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.threshold,
    required this.isAchieved,
    this.achievedAt,
  });
}

/// Result of core progress calculation
class CoreProgressResult {
  final EmotionalCore core;
  final List<CoreMilestone> milestones;
  final List<CoreMilestone> achievedMilestones;
  final CoreMilestone? nextMilestone;
  final double progressVelocity;
  final Duration? estimatedTimeToNextMilestone;

  CoreProgressResult({
    required this.core,
    required this.milestones,
    required this.achievedMilestones,
    this.nextMilestone,
    required this.progressVelocity,
    this.estimatedTimeToNextMilestone,
  });
}