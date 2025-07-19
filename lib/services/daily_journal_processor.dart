import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_journal.dart';
import '../models/core.dart';
import '../config/environment.dart';
import '../utils/app_error_handler.dart';
import 'daily_journal_service.dart';
import 'usage_tracking_service.dart';
import 'core_evolution_engine.dart';

/// Daily Journal Processor
/// 
/// Handles the automatic processing of daily journals at midnight using
/// the built-in Claude API key. Integrates with usage tracking and
/// enforces monthly limits.
class DailyJournalProcessor {
  static final DailyJournalProcessor _instance = DailyJournalProcessor._internal();
  factory DailyJournalProcessor() => _instance;
  DailyJournalProcessor._internal();

  final DailyJournalService _journalService = DailyJournalService();
  final UsageTrackingService _usageService = UsageTrackingService();
  final CoreEvolutionEngine _coreEngine = CoreEvolutionEngine();
  
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  bool _isInitialized = false;

  /// Initialize the processor
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _journalService.initialize();
    await _usageService.initialize();
    await _coreEngine.initialize();
    _isInitialized = true;
  }

  /// Process all journals that need processing
  Future<ProcessingResult> processAllPendingJournals() async {
    await initialize();
    
    return await AppErrorHandler().handleError(
      () async {
        final pendingJournals = await _journalService.getJournalsNeedingProcessing();
        
        if (pendingJournals.isEmpty) {
          return ProcessingResult(
            totalJournals: 0,
            processedJournals: 0,
            skippedJournals: 0,
            failedJournals: 0,
            usageLimitReached: false,
          );
        }

        int processed = 0;
        int skipped = 0;
        int failed = 0;
        bool usageLimitReached = false;

        for (final journal in pendingJournals) {
          // Check usage limits before processing each journal
          final canProcess = await _usageService.canProcessJournal();
          
          if (!canProcess) {
            // Mark remaining journals as skipped due to usage limits
            await _markJournalAsSkipped(journal, 'Monthly usage limit reached');
            skipped++;
            usageLimitReached = true;
            continue;
          }

          try {
            final success = await _processSingleJournal(journal);
            if (success) {
              processed++;
            } else {
              failed++;
            }
          } catch (e) {
            await _usageService.recordProcessingFailure(
              journalId: journal.id,
              errorMessage: e.toString(),
            );
            failed++;
          }
        }

        return ProcessingResult(
          totalJournals: pendingJournals.length,
          processedJournals: processed,
          skippedJournals: skipped,
          failedJournals: failed,
          usageLimitReached: usageLimitReached,
        );
      },
      operationName: 'processAllPendingJournals',
      component: 'DailyJournalProcessor',
    );
  }

  /// Process a single journal
  Future<bool> _processSingleJournal(DailyJournal journal) async {
    if (!journal.hasContent) {
      // Skip empty journals
      await _markJournalAsSkipped(journal, 'No content to process');
      return true;
    }

    final startTime = DateTime.now();
    
    try {
      // Check if we have a built-in API key
      if (!EnvironmentConfig.hasBuiltInApiKey) {
        // Use fallback processing
        final analysis = await _generateFallbackAnalysis(journal);
        await _completeProcessing(journal, analysis, startTime);
        return true;
      }

      // Use real Claude API
      final analysis = await _callClaudeAPI(journal);
      await _completeProcessing(journal, analysis, startTime);
      return true;
      
    } catch (e) {
      // Fall back to local analysis on API errors
      try {
        final fallbackAnalysis = await _generateFallbackAnalysis(journal);
        await _completeProcessing(journal, fallbackAnalysis, startTime);
        return true;
      } catch (fallbackError) {
        await AppErrorHandler().logError(
          'Failed to process journal with fallback',
          error: fallbackError,
          component: 'DailyJournalProcessor',
          context: {'journalId': journal.id},
        );
        return false;
      }
    }
  }

  /// Complete the processing of a journal
  Future<void> _completeProcessing(
    DailyJournal journal,
    Map<String, dynamic> analysis,
    DateTime startTime,
  ) async {
    final processingTime = DateTime.now().difference(startTime).inMilliseconds;
    
    // Mark journal as processed
    await _journalService.markJournalAsProcessed(
      journalId: journal.id,
      aiAnalysis: analysis,
    );

    // Update emotional cores if analysis contains core updates
    if (analysis.containsKey('core_strengths')) {
      await _updateEmotionalCores(journal, analysis);
    }

    // Record usage tracking
    final tokensInput = _estimateTokens(journal.content);
    final tokensOutput = _estimateTokens(analysis.toString());
    
    await _usageService.recordJournalProcessing(
      journalId: journal.id,
      tokensInput: tokensInput,
      tokensOutput: tokensOutput,
      processingTimeMs: processingTime,
      costEstimate: _estimateCost(tokensInput, tokensOutput),
    );
  }

  /// Call Claude API for journal analysis
  Future<Map<String, dynamic>> _callClaudeAPI(DailyJournal journal) async {
    final prompt = _buildAnalysisPrompt(journal);
    
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': EnvironmentConfig.claudeApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307', // Using Haiku for cost efficiency
        'max_tokens': 1000,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final responseText = data['content'][0]['text'];
      return _parseAnalysisResponse(responseText);
    } else {
      throw Exception('Claude API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Build analysis prompt for daily journal
  String _buildAnalysisPrompt(DailyJournal journal) {
    return '''
Analyze this daily journal entry for emotional intelligence insights:

Date: ${journal.formattedDate}
Moods: ${journal.moods.join(', ')}
Content: "${journal.content}"
Word Count: ${journal.wordCount}

Please provide a JSON response with the following structure:
{
  "primary_emotions": ["emotion1", "emotion2"],
  "emotional_intensity": 7.5,
  "growth_indicators": ["indicator1", "indicator2"],
  "core_strengths": {
    "optimism": 0.2,
    "resilience": 0.1,
    "self_awareness": 0.3,
    "creativity": 0.0,
    "social_connection": 0.1,
    "growth_mindset": 0.2
  },
  "insight": "Brief encouraging insight about the entry",
  "daily_reflection": "A personalized reflection on their day",
  "patterns": ["pattern1", "pattern2"],
  "suggestions": ["suggestion1", "suggestion2"]
}

Focus on:
1. Emotional patterns and self-awareness throughout the day
2. Growth mindset indicators and learning moments
3. Resilience and coping mechanisms used
4. Creative expression and problem-solving
5. Social connections and relationships mentioned
6. Overall emotional trajectory of the day

Provide core_strengths as small incremental values (-0.5 to +0.5) representing how this day's reflection should adjust each emotional core percentage.

Keep insights warm, encouraging, and focused on growth and self-compassion.
''';
  }

  /// Parse Claude API response
  Map<String, dynamic> _parseAnalysisResponse(String response) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
      
      // If no JSON found, return default structure
      return _getDefaultAnalysis();
    } catch (e) {
      return _getDefaultAnalysis();
    }
  }

  /// Generate fallback analysis when API is unavailable
  Future<Map<String, dynamic>> _generateFallbackAnalysis(DailyJournal journal) async {
    final moodToCore = {
      'happy': {'optimism': 0.2, 'self_awareness': 0.1},
      'content': {'self_awareness': 0.2, 'optimism': 0.1},
      'energetic': {'creativity': 0.2, 'growth_mindset': 0.1},
      'grateful': {'optimism': 0.3, 'social_connection': 0.1},
      'confident': {'resilience': 0.2, 'growth_mindset': 0.1},
      'peaceful': {'self_awareness': 0.2, 'resilience': 0.1},
      'excited': {'creativity': 0.1, 'growth_mindset': 0.2},
      'motivated': {'growth_mindset': 0.3, 'resilience': 0.1},
      'creative': {'creativity': 0.3, 'self_awareness': 0.1},
      'social': {'social_connection': 0.3, 'optimism': 0.1},
      'reflective': {'self_awareness': 0.3, 'growth_mindset': 0.1},
      'anxious': {'self_awareness': 0.1, 'resilience': -0.1},
      'sad': {'self_awareness': 0.2, 'resilience': 0.1},
      'frustrated': {'resilience': 0.1, 'growth_mindset': 0.1},
    };

    final coreStrengths = <String, double>{
      'optimism': 0.0,
      'resilience': 0.0,
      'self_awareness': 0.0,
      'creativity': 0.0,
      'social_connection': 0.0,
      'growth_mindset': 0.0,
    };

    // Apply mood-based adjustments
    for (final mood in journal.moods) {
      final adjustments = moodToCore[mood.toLowerCase()] ?? {};
      for (final adjustment in adjustments.entries) {
        coreStrengths[adjustment.key] = 
            (coreStrengths[adjustment.key] ?? 0.0) + adjustment.value;
      }
    }

    // Add base self-awareness for any journaling
    coreStrengths['self_awareness'] = (coreStrengths['self_awareness'] ?? 0.0) + 0.1;

    return {
      "primary_emotions": journal.moods.take(2).toList(),
      "emotional_intensity": _calculateIntensityFromContent(journal.content),
      "growth_indicators": ["self_reflection", "emotional_awareness"],
      "core_strengths": coreStrengths,
      "insight": _generateFallbackInsight(journal),
      "daily_reflection": "Your commitment to daily reflection shows dedication to personal growth.",
      "patterns": ["consistent_journaling"],
      "suggestions": ["continue_daily_practice"],
    };
  }

  /// Update emotional cores based on analysis
  Future<void> _updateEmotionalCores(DailyJournal journal, Map<String, dynamic> analysis) async {
    try {
      final coreStrengths = analysis['core_strengths'] as Map<String, dynamic>? ?? {};
      
      if (coreStrengths.isNotEmpty) {
        await _coreEngine.updateCoresFromAnalysis(coreStrengths);
      }
    } catch (e) {
      await AppErrorHandler().logError(
        'Failed to update emotional cores',
        error: e,
        component: 'DailyJournalProcessor',
        context: {'journalId': journal.id},
      );
    }
  }

  /// Mark journal as skipped
  Future<void> _markJournalAsSkipped(DailyJournal journal, String reason) async {
    final analysis = {
      'skipped': true,
      'reason': reason,
      'processed_at': DateTime.now().toIso8601String(),
    };

    await _journalService.markJournalAsProcessed(
      journalId: journal.id,
      aiAnalysis: analysis,
    );
  }

  /// Helper methods

  Map<String, dynamic> _getDefaultAnalysis() {
    return {
      "primary_emotions": ["neutral"],
      "emotional_intensity": 5.0,
      "growth_indicators": ["self_reflection"],
      "core_strengths": {
        "optimism": 0.0,
        "resilience": 0.0,
        "self_awareness": 0.1,
        "creativity": 0.0,
        "social_connection": 0.0,
        "growth_mindset": 0.0
      },
      "insight": "Thank you for taking time to reflect and journal.",
      "daily_reflection": "Your journaling practice supports your emotional well-being.",
      "patterns": ["self_reflection"],
      "suggestions": ["continue_journaling"]
    };
  }

  double _calculateIntensityFromContent(String content) {
    // Simple heuristic based on content length and emotional words
    final wordCount = content.split(' ').length;
    final emotionalWords = [
      'amazing', 'terrible', 'wonderful', 'awful', 'fantastic', 'horrible',
      'love', 'hate', 'excited', 'devastated', 'thrilled', 'crushed'
    ];
    
    int emotionalWordCount = 0;
    for (final word in emotionalWords) {
      emotionalWordCount += word.allMatches(content.toLowerCase()).length;
    }
    
    double intensity = 5.0; // Base neutral intensity
    intensity += (wordCount / 50).clamp(0, 2); // Length factor
    intensity += (emotionalWordCount * 0.5).clamp(0, 3); // Emotional word factor
    
    return intensity.clamp(1.0, 10.0);
  }

  String _generateFallbackInsight(DailyJournal journal) {
    if (journal.wordCount > 100) {
      return "Your detailed reflection shows deep self-awareness and commitment to personal growth.";
    } else if (journal.moods.isNotEmpty) {
      return "Acknowledging your emotions is an important step in emotional intelligence.";
    } else {
      return "Every moment of reflection contributes to your personal development journey.";
    }
  }

  int _estimateTokens(String text) {
    // Rough estimation: ~4 characters per token
    return (text.length / 4).ceil();
  }

  double _estimateCost(int tokensInput, int tokensOutput) {
    // Claude 3 Haiku pricing (approximate)
    const inputCostPer1M = 0.25;
    const outputCostPer1M = 1.25;
    
    final inputCost = (tokensInput / 1000000) * inputCostPer1M;
    final outputCost = (tokensOutput / 1000000) * outputCostPer1M;
    
    return inputCost + outputCost;
  }
}

/// Result of processing operation
class ProcessingResult {
  final int totalJournals;
  final int processedJournals;
  final int skippedJournals;
  final int failedJournals;
  final bool usageLimitReached;

  ProcessingResult({
    required this.totalJournals,
    required this.processedJournals,
    required this.skippedJournals,
    required this.failedJournals,
    required this.usageLimitReached,
  });

  bool get hasProcessedAny => processedJournals > 0;
  bool get hasFailures => failedJournals > 0;
  bool get allSuccessful => failedJournals == 0 && totalJournals > 0;
  
  double get successRate {
    if (totalJournals == 0) return 1.0;
    return processedJournals / totalJournals;
  }

  @override
  String toString() {
    return 'ProcessingResult(total: $totalJournals, processed: $processedJournals, skipped: $skippedJournals, failed: $failedJournals, limitReached: $usageLimitReached)';
  }
}
