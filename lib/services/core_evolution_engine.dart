import 'package:flutter/foundation.dart';
import '../models/core.dart';
import '../models/journal_entry.dart';
import '../models/resonance_depth.dart';
import '../models/core_resonance_data.dart';
import 'emotional_analyzer.dart';

/// Engine for evolving personality cores through resonance depth transitions.
/// 
/// This service calculates resonance depths, manages transitions between depth stages,
/// and provides insights about personality development based on journal analysis.
class CoreEvolutionEngine {
  static final CoreEvolutionEngine _instance = CoreEvolutionEngine._internal();
  factory CoreEvolutionEngine() => _instance;
  CoreEvolutionEngine._internal();

  bool _isInitialized = false;

  /// Initialize the core evolution engine
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('CoreEvolutionEngine: Initializing resonance depth system...');
      _isInitialized = true;
      debugPrint('CoreEvolutionEngine: Initialized successfully');
    } catch (e) {
      debugPrint('CoreEvolutionEngine: Initialization failed: $e');
      rethrow;
    }
  }

  // Core configuration for resonance depth system
  static const Map<String, CoreConfig> _coreConfigs = {
    'optimism': CoreConfig(
      id: 'optimism',
      name: 'Optimism',
      description: 'Your ability to maintain hope and positive outlook',
      color: 'FF6B35',
      iconPath: 'assets/icons/optimism.png',
    ),
    'resilience': CoreConfig(
      id: 'resilience',
      name: 'Resilience',
      description: 'Your capacity to bounce back from challenges',
      color: '4ECDC4',
      iconPath: 'assets/icons/resilience.png',
    ),
    'self_awareness': CoreConfig(
      id: 'self_awareness',
      name: 'Self-Awareness',
      description: 'Your understanding of your emotions and thoughts',
      color: '45B7D1',
      iconPath: 'assets/icons/self_awareness.png',
    ),
    'creativity': CoreConfig(
      id: 'creativity',
      name: 'Creativity',
      description: 'Your innovative thinking and creative expression',
      color: '96CEB4',
      iconPath: 'assets/icons/creativity.png',
    ),
    'social_connection': CoreConfig(
      id: 'social_connection',
      name: 'Social Connection',
      description: 'Your relationships and empathy with others',
      color: 'FFEAA7',
      iconPath: 'assets/icons/social_connection.png',
    ),
    'growth_mindset': CoreConfig(
      id: 'growth_mindset',
      name: 'Growth Mindset',
      description: 'Your openness to learning and embracing challenges',
      color: 'DDA0DD',
      iconPath: 'assets/icons/growth_mindset.png',
    ),
  };

  /// Process resonance analysis and return core updates
  Future<List<CoreUpdate>> processResonanceAnalysis(
    List<EmotionalCore> currentCores,
    Map<String, CoreResonanceData> coreResonance,
    JournalEntry entry,
  ) async {
    final updates = <CoreUpdate>[];
    
    for (final core in currentCores) {
      final resonanceData = coreResonance[core.id];
      if (resonanceData == null) {
        // No resonance detected for this core - just increment entry counter
        updates.add(CoreUpdate(
          core: core.copyWith(
            entriesAtCurrentDepth: core.entriesAtCurrentDepth + 1,
          ),
          transitionOccurred: false,
        ));
        continue;
      }
      
      // Always increment entry counter
      final newEntriesCount = core.entriesAtCurrentDepth + 1;
      
      // Determine if transition should occur
      final suggestedDepth = ResonanceDepth.values.firstWhere(
        (d) => d.name.toLowerCase() == resonanceData.depthIndicator.toLowerCase(),
        orElse: () => core.resonanceDepth,
      );
      
      final shouldTransition = _evaluateTransition(
        current: core.resonanceDepth,
        suggested: suggestedDepth,
        entriesAtDepth: newEntriesCount,
        resonanceStrength: resonanceData.resonanceStrength,
      );
      
      if (shouldTransition) {
        // Calculate new level at midpoint of new depth
        final newLevel = (suggestedDepth.minLevel + suggestedDepth.maxLevel) / 2;
        
        updates.add(CoreUpdate(
          core: core.copyWith(
            currentLevel: newLevel,
            previousLevel: core.currentLevel,
            lastTransitionDate: DateTime.now(),
            entriesAtCurrentDepth: 0, // Reset counter
            trend: _calculateTrend(core.resonanceDepth, suggestedDepth),
            transitionSignals: resonanceData.transitionSignals,
            supportingEvidence: resonanceData.supportingEvidence,
            lastUpdated: DateTime.now(),
          ),
          transitionOccurred: true,
          fromDepth: core.resonanceDepth,
          toDepth: suggestedDepth,
          entryId: entry.id,
          reason: 'Resonance analysis indicates transition to ${suggestedDepth.displayName}',
        ));
      } else {
        // Just update signals and evidence
        updates.add(CoreUpdate(
          core: core.copyWith(
            entriesAtCurrentDepth: newEntriesCount,
            transitionSignals: resonanceData.transitionSignals,
            supportingEvidence: resonanceData.supportingEvidence,
            lastUpdated: DateTime.now(),
          ),
          transitionOccurred: false,
        ));
      }
    }
    
    return updates;
  }
  
  /// Evaluate whether a transition should occur
  bool _evaluateTransition({
    required ResonanceDepth current,
    required ResonanceDepth suggested,
    required int entriesAtDepth,
    required double resonanceStrength,
  }) {
    // No transition if same depth
    if (current == suggested) return false;
    
    // Minimum entries at current depth before allowing transition
    final minEntries = _getMinimumEntriesForDepth(current);
    if (entriesAtDepth < minEntries) return false;
    
    // Only move one stage at a time
    final currentIndex = ResonanceDepth.values.indexOf(current);
    final suggestedIndex = ResonanceDepth.values.indexOf(suggested);
    if ((suggestedIndex - currentIndex).abs() > 1) return false;
    
    // Require strong resonance for upward movement
    if (suggestedIndex > currentIndex) {
      return resonanceStrength > _getUpwardTransitionThreshold(current);
    }
    
    // Allow downward movement with moderate resonance (life circumstances)
    return resonanceStrength > _getDownwardTransitionThreshold(current);
  }
  
  /// Get minimum entries required at each depth before transition
  int _getMinimumEntriesForDepth(ResonanceDepth depth) {
    switch (depth) {
      case ResonanceDepth.dormant:
        return 3;
      case ResonanceDepth.emerging:
        return 5;
      case ResonanceDepth.developing:
        return 7;
      case ResonanceDepth.deepening:
        return 10;
      case ResonanceDepth.integrated:
        return 15;
      case ResonanceDepth.transcendent:
        return 20;
    }
  }
  
  /// Get resonance strength threshold for upward transitions
  double _getUpwardTransitionThreshold(ResonanceDepth current) {
    switch (current) {
      case ResonanceDepth.dormant:
        return 0.6; // Easier to emerge from dormancy
      case ResonanceDepth.emerging:
        return 0.7; // Moderate requirement to develop
      case ResonanceDepth.developing:
        return 0.75; // Higher bar for deepening
      case ResonanceDepth.deepening:
        return 0.8; // Strong requirement for integration
      case ResonanceDepth.integrated:
        return 0.85; // Very strong requirement for transcendence
      case ResonanceDepth.transcendent:
        return 1.0; // Already at highest level
    }
  }
  
  /// Get resonance strength threshold for downward transitions
  double _getDownwardTransitionThreshold(ResonanceDepth current) {
    // More lenient thresholds for downward movement (life happens)
    switch (current) {
      case ResonanceDepth.dormant:
        return 1.0; // Can't go lower
      case ResonanceDepth.emerging:
        return 0.4;
      case ResonanceDepth.developing:
        return 0.5;
      case ResonanceDepth.deepening:
        return 0.55;
      case ResonanceDepth.integrated:
        return 0.6;
      case ResonanceDepth.transcendent:
        return 0.65;
    }
  }
  
  /// Calculate trend based on depth transition
  String _calculateTrend(ResonanceDepth from, ResonanceDepth to) {
    final fromIndex = ResonanceDepth.values.indexOf(from);
    final toIndex = ResonanceDepth.values.indexOf(to);
    
    if (toIndex > fromIndex) return 'rising';
    if (toIndex < fromIndex) return 'declining';
    return 'stable';
  }

  /// Get initial emotional cores for new users (all start at dormant)
  List<EmotionalCore> getInitialCores() {
    final now = DateTime.now();
    return _coreConfigs.values.map((config) {
      return EmotionalCore(
        id: config.id,
        name: config.name,
        description: config.description,
        currentLevel: 0.05, // Start in dormant range
        previousLevel: 0.05,
        lastUpdated: now,
        trend: 'stable',
        color: config.color,
        iconPath: config.iconPath,
        insight: 'Your journey with ${config.name.toLowerCase()} is just beginning',
        relatedCores: _getRelatedCores(config.id),
      );
    }).toList();
  }
  
  /// Get related cores for synergy calculations
  List<String> _getRelatedCores(String coreId) {
    switch (coreId) {
      case 'optimism':
        return ['resilience', 'growth_mindset'];
      case 'resilience':
        return ['optimism', 'self_awareness'];
      case 'self_awareness':
        return ['resilience', 'growth_mindset'];
      case 'creativity':
        return ['growth_mindset', 'self_awareness'];
      case 'social_connection':
        return ['optimism', 'self_awareness'];
      case 'growth_mindset':
        return ['optimism', 'creativity', 'self_awareness'];
      default:
        return [];
    }
  }

  /// Generate growth recommendations based on current resonance depths
  List<String> generateGrowthRecommendations(
    List<EmotionalCore> cores,
    List<EmotionalAnalysisResult> recentAnalyses,
  ) {
    final recommendations = <String>[];
    
    // Find cores ready for transition
    final transitioningCores = cores.where((core) => core.isTransitioning).toList();
    if (transitioningCores.isNotEmpty) {
      final coreNames = transitioningCores.map((c) => c.name).join(', ');
      recommendations.add('Your $coreNames ${transitioningCores.length == 1 ? 'is' : 'are'} showing signs of growth. Continue your reflective practice to support this development.');
    }
    
    // Find dormant cores that could be activated
    final dormantCores = cores.where((core) => core.resonanceDepth == ResonanceDepth.dormant).toList();
    if (dormantCores.isNotEmpty && recommendations.length < 3) {
      final dormantCore = dormantCores.first;
      recommendations.add('Consider exploring your ${dormantCore.name.toLowerCase()} through specific activities or reflections.');
    }
    
    // Add depth-specific recommendations
    for (final core in cores.take(2)) {
      if (recommendations.length >= 3) break;
      
      final depthRecommendation = _getDepthSpecificRecommendation(core);
      if (depthRecommendation != null) {
        recommendations.add(depthRecommendation);
      }
    }
    
    return recommendations.take(3).toList();
  }
  
  String? _getDepthSpecificRecommendation(EmotionalCore core) {
    switch (core.resonanceDepth) {
      case ResonanceDepth.dormant:
        return 'Try activities that engage your ${core.name.toLowerCase()} to help it emerge.';
      case ResonanceDepth.emerging:
        return 'Your ${core.name.toLowerCase()} is awakening. Regular practice will help it develop.';
      case ResonanceDepth.developing:
        return 'Your ${core.name.toLowerCase()} is growing stronger. Stay consistent with supportive practices.';
      case ResonanceDepth.deepening:
        return 'Your ${core.name.toLowerCase()} is becoming more integrated. Look for ways to apply it in new situations.';
      case ResonanceDepth.integrated:
        return 'Your ${core.name.toLowerCase()} is well-established. Consider how you might share this strength with others.';
      case ResonanceDepth.transcendent:
        return 'Your ${core.name.toLowerCase()} flows naturally through all you do. You\'re an inspiration to others in this area.';
    }
  }

  /// Calculate core synergies based on resonance depths
  Map<String, double> calculateCoreSynergies(List<EmotionalCore> cores) {
    final synergies = <String, double>{};
    
    for (final core in cores) {
      final relatedCoreIds = _getRelatedCores(core.id);
      final relatedCores = cores.where((c) => relatedCoreIds.contains(c.id)).toList();
      
      if (relatedCores.isNotEmpty) {
        // Calculate synergy based on how close the related cores are in depth
        double synergy = 0.0;
        for (final relatedCore in relatedCores) {
          final depthDifference = (ResonanceDepth.values.indexOf(core.resonanceDepth) - 
                                 ResonanceDepth.values.indexOf(relatedCore.resonanceDepth)).abs();
          synergy += (5 - depthDifference) / 5.0; // Closer depths = higher synergy
        }
        synergies[core.id] = (synergy / relatedCores.length).clamp(0.0, 1.0);
      }
    }
    
    return synergies;
  }

  /// Generate core combinations based on resonance synergies
  List<CoreCombination> generateCoreCombinations(List<EmotionalCore> cores) {
    final combinations = <CoreCombination>[];
    
    // Find cores at similar depths for potential combinations
    final groupedByDepth = <ResonanceDepth, List<EmotionalCore>>{};
    for (final core in cores) {
      groupedByDepth.putIfAbsent(core.resonanceDepth, () => []).add(core);
    }
    
    for (final depth in groupedByDepth.keys) {
      final coresAtDepth = groupedByDepth[depth]!;
      if (coresAtDepth.length >= 2 && depth.index >= 2) { // Only for developing+ cores
        combinations.add(CoreCombination(
          name: '${depth.displayName} Synergy',
          coreIds: coresAtDepth.map((c) => c.id).toList(),
          description: 'Your ${coresAtDepth.map((c) => c.name).join(', ')} are all at ${depth.displayName} level',
          benefit: 'This balanced development creates strong foundation for continued growth',
        ));
      }
    }
    
    return combinations;
  }

  /// Calculate core progress with milestones and insights
  CoreProgressResult calculateCoreProgress(
    EmotionalCore core,
    List<JournalEntry> recentEntries,
  ) {
    final currentDepth = core.resonanceDepth;
    final milestones = _getMilestonesForDepth(currentDepth);
    final achievedMilestones = _getAchievedMilestones(core, currentDepth);
    final nextMilestone = _getNextMilestone(milestones, achievedMilestones);
    final progressVelocity = _calculateProgressVelocity(core, recentEntries);
    final estimatedTime = _estimateTimeToNextMilestone(core, progressVelocity);

    return CoreProgressResult(
      core: core,
      milestones: milestones,
      achievedMilestones: achievedMilestones,
      nextMilestone: nextMilestone,
      progressVelocity: progressVelocity,
      estimatedTimeToNextMilestone: estimatedTime,
    );
  }

  /// Get milestones for a specific resonance depth
  List<String> _getMilestonesForDepth(ResonanceDepth depth) {
    switch (depth) {
      case ResonanceDepth.dormant:
        return ['Show initial awareness', 'Recognize patterns', 'Begin exploration'];
      case ResonanceDepth.emerging:
        return ['Consistent practice', 'Growing confidence', 'Regular application'];
      case ResonanceDepth.developing:
        return ['Deeper understanding', 'Increased frequency', 'Natural integration'];
      case ResonanceDepth.deepening:
        return ['Automatic responses', 'Teaching others', 'Complex situations'];
      case ResonanceDepth.integrated:
        return ['Effortless expression', 'Leadership role', 'Inspiring others'];
      case ResonanceDepth.transcendent:
        return ['Master level', 'Transformative impact', 'Wisdom sharing'];
    }
  }

  /// Get achieved milestones based on core's current state
  List<String> _getAchievedMilestones(EmotionalCore core, ResonanceDepth depth) {
    final achieved = <String>[];
    final depthIndex = ResonanceDepth.values.indexOf(depth);
    
    // Mark milestones from previous depths as achieved
    for (int i = 0; i < depthIndex; i++) {
      achieved.addAll(_getMilestonesForDepth(ResonanceDepth.values[i]));
    }
    
    // Add some milestones from current depth based on progress
    final currentMilestones = _getMilestonesForDepth(depth);
    final progressInDepth = (core.currentLevel - depth.minLevel) / (depth.maxLevel - depth.minLevel);
    final achievedCount = (currentMilestones.length * progressInDepth).floor();
    
    achieved.addAll(currentMilestones.take(achievedCount));
    
    return achieved;
  }

  /// Get the next milestone to work on
  String? _getNextMilestone(List<String> allMilestones, List<String> achieved) {
    for (final milestone in allMilestones) {
      if (!achieved.contains(milestone)) {
        return milestone;
      }
    }
    return null;
  }

  /// Calculate progress velocity based on recent activity
  double _calculateProgressVelocity(EmotionalCore core, List<JournalEntry> recentEntries) {
    if (recentEntries.isEmpty) return 0.0;
    
    // Simple velocity calculation based on recent changes and entry frequency
    final daysSinceLastUpdate = DateTime.now().difference(core.lastUpdated).inDays;
    final entriesPerDay = recentEntries.length / (daysSinceLastUpdate > 0 ? daysSinceLastUpdate : 1);
    
    return (entriesPerDay * 0.1).clamp(0.0, 1.0);
  }

  /// Estimate time to next milestone
  Duration? _estimateTimeToNextMilestone(EmotionalCore core, double velocity) {
    if (velocity <= 0.0) return null;
    
    // Rough estimation based on current progress and velocity
    final daysEstimate = (30 / velocity).ceil(); // Base estimate of 30 days, adjusted by velocity
    return Duration(days: daysEstimate);
  }

  /// Update cores with analysis results
  List<EmotionalCore> updateCoresWithAnalysis(
    List<EmotionalCore> currentCores,
    dynamic analysisResult, // Can be EmotionalAnalysisResult or Map<String, dynamic>
    dynamic entry, // Can be JournalEntry or other entry type
  ) {
    try {
      // Extract core resonance data from analysis result
      Map<String, dynamic> coreResonance = {};
      
      if (analysisResult is Map<String, dynamic>) {
        coreResonance = Map<String, dynamic>.from(analysisResult['coreResonance'] ?? {});
      } else if (analysisResult != null && analysisResult.toString().contains('coreResonance')) {
        // Try to extract from object properties if available
        try {
          final resonanceData = (analysisResult as dynamic).coreResonance;
          if (resonanceData is Map) {
            coreResonance = Map<String, dynamic>.from(resonanceData);
          }
        } catch (e) {
          debugPrint('CoreEvolutionEngine: Could not extract coreResonance: $e');
        }
      }
      
      final updatedCores = <EmotionalCore>[];
      
      for (final core in currentCores) {
        final resonanceData = coreResonance[core.id];
        
        if (resonanceData == null) {
          // No resonance data for this core, return unchanged
          updatedCores.add(core);
          continue;
        }
        
        // Extract resonance information
        double resonanceStrength = 0.0;
        String depthIndicator = core.resonanceDepth.name;
        List<String> transitionSignals = [];
        String? supportingEvidence;
        
        if (resonanceData is Map<String, dynamic>) {
          resonanceStrength = (resonanceData['resonanceStrength'] ?? 0.0).toDouble();
          depthIndicator = resonanceData['depthIndicator'] ?? core.resonanceDepth.name;
          transitionSignals = List<String>.from(resonanceData['transitionSignals'] ?? []);
          supportingEvidence = resonanceData['supportingEvidence'];
        }
        
        // Calculate level adjustment based on resonance strength
        final levelAdjustment = resonanceStrength * 0.05; // Small incremental changes
        final newLevel = (core.currentLevel + levelAdjustment).clamp(0.0, 1.0);
        
        // Determine trend
        String trend = core.trend;
        if (newLevel > core.currentLevel) {
          trend = 'rising';
        } else if (newLevel < core.currentLevel) {
          trend = 'declining';
        } else {
          trend = 'stable';
        }
        
        // Update the core
        updatedCores.add(core.copyWith(
          currentLevel: newLevel,
          previousLevel: core.currentLevel,
          lastUpdated: DateTime.now(),
          trend: trend,
          transitionSignals: transitionSignals,
          supportingEvidence: supportingEvidence,
          entriesAtCurrentDepth: core.entriesAtCurrentDepth + 1,
        ));
      }
      
      return updatedCores;
    } catch (e) {
      debugPrint('CoreEvolutionEngine updateCoresWithAnalysis error: $e');
      return currentCores; // Return unchanged cores on error
    }
  }

  /// Generate insight for a specific core based on recent analyses
  String generateCoreInsight(
    EmotionalCore core,
    List<dynamic> recentAnalyses, // List<EmotionalAnalysisResult> or similar
  ) {
    try {
      final depth = core.resonanceDepth;
      final trend = core.trend;
      final name = core.name.toLowerCase();
      
      // Base insight based on current depth and trend
      String baseInsight = _getDepthInsight(core, depth);
      
      // Add trend-specific information
      String trendInsight = '';
      switch (trend) {
        case 'rising':
          trendInsight = 'Your $name is growing stronger and showing signs of positive development.';
          break;
        case 'declining':
          trendInsight = 'Your $name may need more attention to maintain its current level.';
          break;
        case 'stable':
          trendInsight = 'Your $name is maintaining steady progress at its current level.';
          break;
      }
      
      // Add transition insight if applicable
      String transitionInsight = '';
      if (core.isTransitioning) {
        transitionInsight = ' You\'re currently in a transitional phase, which is an excellent opportunity for growth.';
      }
      
      // Combine insights
      final insight = '$baseInsight $trendInsight$transitionInsight';
      
      return insight.trim();
    } catch (e) {
      debugPrint('CoreEvolutionEngine generateCoreInsight error: $e');
      return 'Your ${core.name.toLowerCase()} continues to develop through your reflective practice.';
    }
  }
  
  /// Get depth-specific insight
  String _getDepthInsight(EmotionalCore core, ResonanceDepth depth) {
    final name = core.name.toLowerCase();
    
    switch (depth) {
      case ResonanceDepth.dormant:
        return 'Your $name is ready to emerge with focused attention and practice.';
      case ResonanceDepth.emerging:
        return 'Your $name is beginning to show itself more consistently in your experiences.';
      case ResonanceDepth.developing:
        return 'Your $name is actively developing and becoming more integrated into your daily life.';
      case ResonanceDepth.deepening:
        return 'Your $name is reaching deeper levels of integration and natural expression.';
      case ResonanceDepth.integrated:
        return 'Your $name flows naturally through your experiences and interactions.';
      case ResonanceDepth.transcendent:
        return 'Your $name has become a source of wisdom and inspiration, both for yourself and others.';
    }
  }

  /// Update cores from analysis data (different from updateCoresWithAnalysis)
  Future<void> updateCoresFromAnalysis(Map<String, dynamic> analysisData) async {
    try {
      debugPrint('CoreEvolutionEngine: Processing core updates from analysis data');
      
      // This method processes aggregated analysis data to update cores
      // The actual core updates would typically be handled by a core service
      // For now, we'll just log the received data
      
      for (final entry in analysisData.entries) {
        final coreId = entry.key;
        final updateData = entry.value;
        
        debugPrint('CoreEvolutionEngine: Core update for $coreId: $updateData');
        
        // In a full implementation, this would:
        // 1. Load the current core data
        // 2. Apply the updates based on the analysis
        // 3. Save the updated core data
        // 4. Trigger any necessary events or notifications
      }
    } catch (e) {
      debugPrint('CoreEvolutionEngine updateCoresFromAnalysis error: $e');
    }
  }
}

/// Configuration for each emotional core
class CoreConfig {
  final String id;
  final String name;
  final String description;
  final String color;
  final String iconPath;

  const CoreConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.iconPath,
  });
}

/// Result of a core update operation
class CoreUpdate {
  final EmotionalCore core;
  final bool transitionOccurred;
  final ResonanceDepth? fromDepth;
  final ResonanceDepth? toDepth;
  final String? entryId;
  final String? reason;

  const CoreUpdate({
    required this.core,
    required this.transitionOccurred,
    this.fromDepth,
    this.toDepth,
    this.entryId,
    this.reason,
  });
}

/// Result of core progress calculation
class CoreProgressResult {
  final EmotionalCore core;
  final List<String> milestones;
  final List<String> achievedMilestones;
  final String? nextMilestone;
  final double progressVelocity;
  final Duration? estimatedTimeToNextMilestone;

  const CoreProgressResult({
    required this.core,
    required this.milestones,
    required this.achievedMilestones,
    this.nextMilestone,
    required this.progressVelocity,
    this.estimatedTimeToNextMilestone,
  });
}