import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import 'emotional_analyzer.dart';
import 'core_evolution_engine.dart';
import 'claude_ai_service.dart';

/// Service that orchestrates the complete journal analysis workflow.
/// 
/// This service combines AI analysis, emotional pattern recognition, and core evolution
/// to provide comprehensive insights about journal entries and personal growth.
class JournalAnalysisService {
  static final JournalAnalysisService _instance = JournalAnalysisService._internal();
  factory JournalAnalysisService() => _instance;
  JournalAnalysisService._internal();

  final EmotionalAnalyzer _analyzer = EmotionalAnalyzer();
  final CoreEvolutionEngine _engine = CoreEvolutionEngine();
  final ClaudeAIService _aiService = ClaudeAIService();

  /// Analyze a journal entry and update emotional cores
  Future<JournalAnalysisResult> analyzeJournalEntry(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
  ) async {
    try {
      // Check cache first
      final cachedAnalysis = _analyzer.getCachedAnalysisResult(entry.id);
      EmotionalAnalysisResult analysisResult;

      if (cachedAnalysis != null) {
        analysisResult = cachedAnalysis;
      } else {
        // Get AI analysis
        final aiResponse = await _aiService.analyzeJournalEntry(entry);
        
        // Process and cache the analysis
        analysisResult = _analyzer.processAndCacheAnalysis(aiResponse, entry);
      }

      // Update cores based on analysis
      final updatedCores = _engine.updateCoresWithAnalysis(currentCores, analysisResult, entry);

      // Calculate core progress
      final coreProgress = <String, CoreProgressResult>{};
      for (final core in updatedCores) {
        coreProgress[core.id] = _engine.calculateCoreProgress(core, [entry]);
      }

      // Generate insights and recommendations
      final insights = _generateInsights(analysisResult, updatedCores);
      final recommendations = _engine.generateGrowthRecommendations(updatedCores, [analysisResult]);

      return JournalAnalysisResult(
        entry: entry,
        emotionalAnalysis: analysisResult,
        updatedCores: updatedCores,
        coreProgress: coreProgress,
        insights: insights,
        recommendations: recommendations,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('JournalAnalysisService analyzeJournalEntry error: $e');
      
      // Return fallback result
      return JournalAnalysisResult(
        entry: entry,
        emotionalAnalysis: _analyzer.processAnalysis({}, entry),
        updatedCores: currentCores,
        coreProgress: {},
        insights: ['Thank you for taking time to reflect and journal.'],
        recommendations: ['Continue your journaling practice for personal growth.'],
        timestamp: DateTime.now(),
      );
    }
  }

  /// Analyze patterns across multiple journal entries
  Future<PatternAnalysisResult> analyzeJournalPatterns(
    List<JournalEntry> entries,
    List<EmotionalCore> currentCores,
  ) async {
    try {
      if (entries.isEmpty) {
        return PatternAnalysisResult(
          patterns: [],
          trends: {},
          coreSynergies: {},
          combinations: [],
          overallInsight: 'Start journaling to discover your emotional patterns.',
        );
      }

      // Identify emotional patterns
      final patterns = _analyzer.identifyPatterns(entries);

      // Analyze emotional trends
      final trends = _analyzer.analyzeEmotionalTrends(entries);

      // Calculate core synergies
      final synergies = _engine.calculateCoreSynergies(currentCores);

      // Generate core combinations
      final combinations = _engine.generateCoreCombinations(currentCores);

      // Generate overall insight
      final overallInsight = _generateOverallInsight(patterns, trends, currentCores);

      return PatternAnalysisResult(
        patterns: patterns,
        trends: trends,
        coreSynergies: synergies,
        combinations: combinations,
        overallInsight: overallInsight,
      );
    } catch (e) {
      debugPrint('JournalAnalysisService analyzeJournalPatterns error: $e');
      
      return PatternAnalysisResult(
        patterns: [],
        trends: {},
        coreSynergies: {},
        combinations: [],
        overallInsight: 'Continue journaling to develop deeper insights about your emotional patterns.',
      );
    }
  }

  /// Get initial emotional cores for new users
  List<EmotionalCore> getInitialCores() {
    return _engine.getInitialCores();
  }

  /// Clear analysis cache (useful for memory management)
  void clearCache() {
    _analyzer.clearCache();
  }

  // Private helper methods

  List<String> _generateInsights(
    EmotionalAnalysisResult analysis,
    List<EmotionalCore> cores,
  ) {
    final insights = <String>[];

    // Add personalized insight from AI
    if (analysis.personalizedInsight.isNotEmpty) {
      insights.add(analysis.personalizedInsight);
    }

    // Add core-specific insights
    final risingCores = cores.where((core) => core.trend == 'rising').toList();
    if (risingCores.isNotEmpty) {
      final coreNames = risingCores.map((core) => core.name).join(', ');
      insights.add('Your $coreNames ${risingCores.length == 1 ? 'is' : 'are'} growing stronger through your reflective practice.');
    }

    // Add pattern-based insights
    if (analysis.emotionalPatterns.isNotEmpty) {
      final growthPatterns = analysis.emotionalPatterns.where((p) => p.type == 'growth').toList();
      if (growthPatterns.isNotEmpty) {
        insights.add('You\'re showing positive growth patterns in ${growthPatterns.first.category.toLowerCase()}.');
      }
    }

    // Add sentiment insight
    if (analysis.overallSentiment > 0.3) {
      insights.add('Your positive emotional state is contributing to your overall well-being.');
    } else if (analysis.overallSentiment < -0.3) {
      insights.add('Remember that difficult emotions are temporary and part of your growth journey.');
    }

    return insights.take(3).toList(); // Limit to 3 insights
  }

  String _generateOverallInsight(
    List<EmotionalPattern> patterns,
    Map<String, dynamic> trends,
    List<EmotionalCore> cores,
  ) {
    try {
      final strongCores = cores.where((core) => core.percentage > 70.0).toList();
      final growingCores = cores.where((core) => core.trend == 'rising').toList();
      
      if (strongCores.length >= 3) {
        return 'You\'re showing strong emotional development across multiple areas. Your ${strongCores.map((c) => c.name).take(3).join(', ')} are particularly well-developed.';
      } else if (growingCores.length >= 2) {
        return 'You\'re in a positive growth phase with your ${growingCores.map((c) => c.name).take(2).join(' and ')} developing nicely.';
      } else if (patterns.any((p) => p.type == 'growth')) {
        return 'Your journaling practice is revealing positive growth patterns in your emotional development.';
      } else {
        return 'Your consistent journaling practice is building emotional awareness and supporting your personal growth journey.';
      }
    } catch (e) {
      return 'Your journaling practice is contributing to your emotional well-being and personal growth.';
    }
  }
}

/// Result of analyzing a single journal entry
class JournalAnalysisResult {
  final JournalEntry entry;
  final EmotionalAnalysisResult emotionalAnalysis;
  final List<EmotionalCore> updatedCores;
  final Map<String, CoreProgressResult> coreProgress;
  final List<String> insights;
  final List<String> recommendations;
  final DateTime timestamp;

  JournalAnalysisResult({
    required this.entry,
    required this.emotionalAnalysis,
    required this.updatedCores,
    required this.coreProgress,
    required this.insights,
    required this.recommendations,
    required this.timestamp,
  });
}

/// Result of analyzing patterns across multiple entries
class PatternAnalysisResult {
  final List<EmotionalPattern> patterns;
  final Map<String, dynamic> trends;
  final Map<String, double> coreSynergies;
  final List<CoreCombination> combinations;
  final String overallInsight;

  PatternAnalysisResult({
    required this.patterns,
    required this.trends,
    required this.coreSynergies,
    required this.combinations,
    required this.overallInsight,
  });
}