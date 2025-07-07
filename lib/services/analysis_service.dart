import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import '../models/ai_analysis.dart';
import 'claude_ai_service.dart';
import 'firebase_service.dart';

/// Analysis service that orchestrates AI analysis and data persistence
class AnalysisService extends ChangeNotifier {
  final ClaudeAIService _claudeService;
  final FirebaseService _firebaseService;
  
  // Analysis state
  bool _isAnalyzing = false;
  String? _analysisError;
  AIAnalysis? _latestAnalysis;
  
  // Getters for state
  bool get isAnalyzing => _isAnalyzing;
  String? get analysisError => _analysisError;
  AIAnalysis? get latestAnalysis => _latestAnalysis;

  AnalysisService({
    required ClaudeAIService claudeService,
    required FirebaseService firebaseService,
  })  : _claudeService = claudeService,
        _firebaseService = firebaseService;

  /// Main orchestration method - analyzes entry and updates everything
  Future<AIAnalysis?> analyzeAndProcess(JournalEntry entry) async {
    if (!_firebaseService.isSignedIn) {
      throw AnalysisException('User must be authenticated to analyze entries');
    }

    _setAnalyzing(true);
    _clearError();

    try {
      // Step 1: Get current user context
      final userId = _firebaseService.currentUserId!;
      final currentCores = await _firebaseService.getCores();
      final recentPatterns = await _getRecentPatterns();

      // Step 2: Perform AI analysis with Claude
      final analysis = await _claudeService.analyzeJournalEntry(
        entry: entry,
        userId: userId,
        currentCores: currentCores,
        recentPatterns: recentPatterns,
      );

      // Step 3: Update cores based on AI insights
      final updatedCores = await _updateCoresWithAnalysis(
        currentCores, 
        analysis.coreEvolution,
      );

      // Step 4: Save everything to Firebase
      await Future.wait([
        _firebaseService.saveAIAnalysis(analysis),
        _firebaseService.updateCores(updatedCores),
        _firebaseService.logUserActivity('ai_analysis_completed'),
      ]);

      // Step 5: Update local state
      _latestAnalysis = analysis;
      
      _setAnalyzing(false);
      return analysis;

    } catch (e) {
      _setError('Analysis failed: ${e.toString()}');
      _setAnalyzing(false);
      return null;
    }
  }

  /// Get recent patterns for context in AI analysis
  Future<String> _getRecentPatterns() async {
    try {
      final recentAnalyses = await _firebaseService.getRecentAnalyses(limit: 5);
      
      if (recentAnalyses.isEmpty) return '';

      // Extract key patterns from recent analyses
      final patterns = <String>[];
      
      for (final analysis in recentAnalyses) {
        // Collect primary emotions
        patterns.addAll(analysis.emotionalAnalysis.primaryEmotions);
        
        // Collect thinking styles
        patterns.addAll(analysis.cognitivePatterns.thinkingStyles);
        
        // Add key insights
        if (analysis.personalizedInsights.patternRecognition.isNotEmpty) {
          patterns.add(analysis.personalizedInsights.patternRecognition);
        }
      }

      // Create context summary
      final emotionPatterns = patterns.where((p) => 
        ['happy', 'sad', 'anxious', 'excited', 'calm', 'stressed', 'grateful']
            .any((emotion) => p.toLowerCase().contains(emotion))).toList();
            
      final thinkingPatterns = patterns.where((p) => 
        ['analytical', 'creative', 'problem-solving', 'rumination']
            .any((thinking) => p.toLowerCase().contains(thinking))).toList();

      return '''
Recent emotional patterns: ${emotionPatterns.take(3).join(', ')}
Recent thinking patterns: ${thinkingPatterns.take(3).join(', ')}
''';
    } catch (e) {
      // If we can't get patterns, continue without them
      return '';
    }
  }

  /// Update cores based on AI analysis suggestions
  Future<Map<String, EmotionalCore>> _updateCoresWithAnalysis(
    Map<String, EmotionalCore> currentCores,
    CoreEvolution coreEvolution,
  ) async {
    final updatedCores = <String, EmotionalCore>{};

    for (final entry in currentCores.entries) {
      final coreId = entry.key;
      final currentCore = entry.value;
      
      // Get adjustment from AI analysis
      final adjustment = coreEvolution.adjustments[coreId];
      
      if (adjustment != null && adjustment.adjustment != 0) {
        // Apply adjustment with bounds checking
        final newPercentage = (currentCore.percentage + adjustment.adjustment)
            .clamp(0.0, 100.0);
            
        updatedCores[coreId] = EmotionalCore(
          id: currentCore.id,
          name: currentCore.name,
          description: currentCore.description,
          percentage: newPercentage,
          trend: currentCore.trend,
          color: currentCore.color,
          iconPath: currentCore.iconPath,
          insight: currentCore.insight,
          relatedCores: currentCore.relatedCores,
        );
      } else {
        // No change for this core
        updatedCores[coreId] = currentCore;
      }
    }

    return updatedCores;
  }

  /// Quick emotional analysis without full processing (for real-time feedback)
  Future<EmotionalAnalysis?> quickEmotionalAnalysis(String text) async {
    if (text.length < 20) return null; // Too short for meaningful analysis

    try {
      _setAnalyzing(true);
      final analysis = await _claudeService.analyzeJournalEntry(
        entry: JournalEntry(
          id: 'temp',
          content: text,
          date: DateTime.now(),
          moods: [],
          dayOfWeek: DateTime.now().weekday.toString(),
        ),
        userId: _firebaseService.currentUserId ?? 'anonymous',
      );
      
      _setAnalyzing(false);
      return analysis.emotionalAnalysis;
    } catch (e) {
      _setAnalyzing(false);
      return null;
    }
  }

  /// Get insights for a specific journal entry
  Future<AIAnalysis?> getInsightsForEntry(String entryId) async {
    try {
      return await _firebaseService.getAIAnalysis(entryId);
    } catch (e) {
      _setError('Failed to get insights: ${e.toString()}');
      return null;
    }
  }

  /// Get trend analysis across multiple entries
  Future<TrendAnalysis> getTrendAnalysis({int days = 30}) async {
    try {
      final recentAnalyses = await _firebaseService.getRecentAnalyses(limit: days);
      
      if (recentAnalyses.isEmpty) {
        return TrendAnalysis.empty();
      }

      return _calculateTrends(recentAnalyses);
    } catch (e) {
      throw AnalysisException('Failed to calculate trends: $e');
    }
  }

  /// Calculate trends from recent analyses
  TrendAnalysis _calculateTrends(List<AIAnalysis> analyses) {
    // Group by emotion categories
    final emotionCounts = <String, int>{};
    final thinkingStyleCounts = <String, int>{};
    final resilienceScores = <double>[];
    final selfCompassionScores = <double>[];

    for (final analysis in analyses) {
      // Count emotions
      for (final emotion in analysis.emotionalAnalysis.primaryEmotions) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }

      // Count thinking styles  
      for (final style in analysis.cognitivePatterns.thinkingStyles) {
        thinkingStyleCounts[style] = (thinkingStyleCounts[style] ?? 0) + 1;
      }

      // Collect growth indicators
      resilienceScores.add(analysis.growthIndicators.resilienceScore);
      selfCompassionScores.add(analysis.growthIndicators.selfCompassionLevel);
    }

    // Calculate averages
    final avgResilience = resilienceScores.isEmpty 
        ? 0.0 
        : resilienceScores.reduce((a, b) => a + b) / resilienceScores.length;
        
    final avgSelfCompassion = selfCompassionScores.isEmpty 
        ? 0.0 
        : selfCompassionScores.reduce((a, b) => a + b) / selfCompassionScores.length;

    // Find most common patterns
    final topEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final topThinkingStyles = thinkingStyleCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return TrendAnalysis(
      topEmotions: topEmotions.take(3).map((e) => e.key).toList(),
      topThinkingStyles: topThinkingStyles.take(3).map((e) => e.key).toList(),
      averageResilience: avgResilience,
      averageSelfCompassion: avgSelfCompassion,
      totalEntries: analyses.length,
      dateRange: analyses.isEmpty 
          ? null 
          : DateRange(
              start: analyses.last.analyzedAt,
              end: analyses.first.analyzedAt,
            ),
    );
  }

  // State management methods
  void _setAnalyzing(bool analyzing) {
    _isAnalyzing = analyzing;
    notifyListeners();
  }

  void _setError(String error) {
    _analysisError = error;
    notifyListeners();
  }

  void _clearError() {
    _analysisError = null;
    notifyListeners();
  }

  /// Clear latest analysis
  void clearLatestAnalysis() {
    _latestAnalysis = null;
    notifyListeners();
  }
}

/// Trend analysis data structure
class TrendAnalysis {
  final List<String> topEmotions;
  final List<String> topThinkingStyles;
  final double averageResilience;
  final double averageSelfCompassion;
  final int totalEntries;
  final DateRange? dateRange;

  TrendAnalysis({
    required this.topEmotions,
    required this.topThinkingStyles,
    required this.averageResilience,
    required this.averageSelfCompassion,
    required this.totalEntries,
    this.dateRange,
  });

  factory TrendAnalysis.empty() {
    return TrendAnalysis(
      topEmotions: [],
      topThinkingStyles: [],
      averageResilience: 0.0,
      averageSelfCompassion: 0.0,
      totalEntries: 0,
    );
  }
}

/// Date range for trend analysis
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

/// Exception thrown when analysis operations fail
class AnalysisException implements Exception {
  final String message;
  
  AnalysisException(this.message);
  
  @override
  String toString() => 'AnalysisException: $message';
}
