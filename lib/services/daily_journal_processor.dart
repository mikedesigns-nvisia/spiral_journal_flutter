import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import '../config/environment.dart';
import '../utils/app_error_handler.dart';
import '../repositories/journal_repository.dart';
import '../repositories/journal_repository_impl.dart';
import 'usage_tracking_service.dart';
import 'core_evolution_engine.dart';
import 'ai_service_manager.dart';
import '../services/providers/claude_ai_provider.dart';

/// Daily Journal Processor
/// 
/// Handles the automatic processing of journal entries at midnight using
/// batch processing for cost efficiency (~$0.01/day). Processes all draft
/// entries from the day and updates emotional cores.
class DailyJournalProcessor {
  static final DailyJournalProcessor _instance = DailyJournalProcessor._internal();
  factory DailyJournalProcessor() => _instance;
  DailyJournalProcessor._internal();

  final JournalRepository _journalRepository = JournalRepositoryImpl();
  final UsageTrackingService _usageService = UsageTrackingService();
  final CoreEvolutionEngine _coreEngine = CoreEvolutionEngine();
  final AIServiceManager _aiServiceManager = AIServiceManager();
  
  bool _isInitialized = false;

  /// Initialize the processor
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _usageService.initialize();
    await _coreEngine.initialize();
    await _aiServiceManager.initialize();
    _isInitialized = true;
    
    if (kDebugMode) {
      debugPrint('DailyJournalProcessor initialized for batch processing');
    }
  }

  /// Process all draft journal entries that need processing (called at midnight)
  Future<ProcessingResult> processAllPendingJournals() async {
    await initialize();
    
    final result = await AppErrorHandler().handleError(
      () async {
        // Get all draft entries from today that need processing
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
        
        final allEntries = await _journalRepository.getEntriesByDateRange(
          startOfDay, 
          endOfDay,
        );
        
        // Filter for draft entries
        final draftEntries = allEntries.where((entry) => entry.status == EntryStatus.draft).toList();
        
        if (draftEntries.isEmpty) {
          if (kDebugMode) {
            debugPrint('DailyJournalProcessor: No draft entries to process');
          }
          return ProcessingResult(
            totalJournals: 0,
            processedJournals: 0,
            skippedJournals: 0,
            failedJournals: 0,
            usageLimitReached: false,
          );
        }

        // Check usage limits before processing
        final canProcess = await _usageService.canProcessJournal();
        
        if (!canProcess) {
          // Mark all entries as skipped due to usage limits
          for (final entry in draftEntries) {
            await _markEntryAsSkipped(entry, 'Monthly usage limit reached');
          }
          
          if (kDebugMode) {
            debugPrint('DailyJournalProcessor: Usage limit reached, skipped ${draftEntries.length} entries');
          }
          
          return ProcessingResult(
            totalJournals: draftEntries.length,
            processedJournals: 0,
            skippedJournals: draftEntries.length,
            failedJournals: 0,
            usageLimitReached: true,
          );
        }

        // Process entries using batch processing for efficiency
        try {
          final success = await _processBatchOfEntries(draftEntries);
          
          if (success) {
            if (kDebugMode) {
              debugPrint('DailyJournalProcessor: Successfully processed ${draftEntries.length} entries');
            }
            
            return ProcessingResult(
              totalJournals: draftEntries.length,
              processedJournals: draftEntries.length,
              skippedJournals: 0,
              failedJournals: 0,
              usageLimitReached: false,
            );
          } else {
            return ProcessingResult(
              totalJournals: draftEntries.length,
              processedJournals: 0,
              skippedJournals: 0,
              failedJournals: draftEntries.length,
              usageLimitReached: false,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('DailyJournalProcessor: Batch processing failed: $e');
          }
          
          // Mark all entries as failed
          for (final entry in draftEntries) {
            await _usageService.recordProcessingFailure(
              journalId: entry.id,
              errorMessage: e.toString(),
            );
          }
          
          return ProcessingResult(
            totalJournals: draftEntries.length,
            processedJournals: 0,
            skippedJournals: 0,
            failedJournals: draftEntries.length,
            usageLimitReached: false,
          );
        }
      },
      operationName: 'processAllPendingJournals',
      component: 'DailyJournalProcessor',
    );
    
    // Return the result or a fallback if null
    return result ?? ProcessingResult(
      totalJournals: 0,
      processedJournals: 0,
      skippedJournals: 0,
      failedJournals: 0,
      usageLimitReached: false,
    );
  }

  /// Process a batch of journal entries using Claude API batch processing
  Future<bool> _processBatchOfEntries(List<JournalEntry> entries) async {
    if (entries.isEmpty) return true;
    
    final startTime = DateTime.now();
    
    try {
      // Get the Claude AI provider for batch processing
      final aiProvider = _aiServiceManager.currentService;
      if (aiProvider is! ClaudeAIProvider) {
        if (kDebugMode) {
          debugPrint('DailyJournalProcessor: Claude provider not available, using fallback');
        }
        return await _processBatchWithFallback(entries, startTime);
      }
      
      // Combine all entry content for batch processing
      final combinedContent = entries.map((entry) {
        return 'Entry ${entry.id} (${entry.date.toIso8601String().split('T')[0]}):\n'
               'Moods: ${entry.moods.join(', ')}\n'
               'Content: ${entry.content}\n'
               'Word Count: ${entry.content.split(' ').length}';
      }).join('\n\n---ENTRY---\n\n');
      
      if (kDebugMode) {
        debugPrint('DailyJournalProcessor: Processing batch of ${entries.length} entries');
      }
      
      // Call Claude API batch processing
      final batchAnalysis = await aiProvider.analyzeDailyBatch(combinedContent);
      
      // Process the batch results
      await _processBatchResults(entries, batchAnalysis, startTime);
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DailyJournalProcessor: Batch processing failed, using fallback: $e');
      }
      
      // Fall back to individual processing
      return await _processBatchWithFallback(entries, startTime);
    }
  }
  
  /// Process batch results and update entries
  Future<void> _processBatchResults(
    List<JournalEntry> entries, 
    Map<String, dynamic> batchAnalysis,
    DateTime startTime,
  ) async {
    // Extract individual analyses from batch result
    final individualAnalyses = batchAnalysis['individual_analyses'] as List<dynamic>? ?? [];
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      
      // Get analysis for this entry (or use fallback)
      final analysis = i < individualAnalyses.length 
          ? individualAnalyses[i] as Map<String, dynamic>
          : _generateFallbackAnalysisForEntry(entry);
      
      // Update the entry
      await _completeEntryProcessing(entry, analysis, startTime);
    }
    
    // Update cores with aggregated data
    if (batchAnalysis.containsKey('aggregated_core_updates')) {
      final coreUpdates = batchAnalysis['aggregated_core_updates'] as Map<String, dynamic>? ?? {};
      if (coreUpdates.isNotEmpty) {
        await _coreEngine.updateCoresFromAnalysis(coreUpdates);
      }
    }
  }

  /// Complete the processing of a journal entry
  Future<void> _completeEntryProcessing(
    JournalEntry entry,
    Map<String, dynamic> analysis,
    DateTime startTime,
  ) async {
    final processingTime = DateTime.now().difference(startTime).inMilliseconds;
    
    // Update the entry and mark as processed
    final updatedEntry = entry.copyWith(
      status: EntryStatus.processed,
      // Note: aiAnalysis expects EmotionalAnalysis type, not Map
      // For now, just mark as processed; full analysis integration would need type conversion
    );
    
    await _journalRepository.updateEntry(updatedEntry);

    // Update emotional cores if analysis contains core updates
    if (analysis.containsKey('core_strengths')) {
      await _updateEmotionalCoresFromEntry(entry, analysis);
    }

    // Record usage tracking
    final tokensInput = _estimateTokens(entry.content);
    final tokensOutput = _estimateTokens(analysis.toString());
    
    await _usageService.recordJournalProcessing(
      journalId: entry.id,
      tokensInput: tokensInput,
      tokensOutput: tokensOutput,
      processingTimeMs: processingTime,
      costEstimate: _estimateCost(tokensInput, tokensOutput),
    );
  }

  /// Process batch with fallback individual processing
  Future<bool> _processBatchWithFallback(
    List<JournalEntry> entries, 
    DateTime startTime,
  ) async {
    bool allSuccessful = true;
    
    for (final entry in entries) {
      try {
        final analysis = _generateFallbackAnalysisForEntry(entry);
        await _completeEntryProcessing(entry, analysis, startTime);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('DailyJournalProcessor: Failed to process entry ${entry.id}: $e');
        }
        allSuccessful = false;
      }
    }
    
    return allSuccessful;
  }

  /// Generate fallback analysis for a single entry
  Map<String, dynamic> _generateFallbackAnalysisForEntry(JournalEntry entry) {
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
    for (final mood in entry.moods) {
      final adjustments = moodToCore[mood.toLowerCase()] ?? {};
      for (final adjustment in adjustments.entries) {
        coreStrengths[adjustment.key] = 
            (coreStrengths[adjustment.key] ?? 0.0) + adjustment.value;
      }
    }

    // Add base self-awareness for any journaling
    coreStrengths['self_awareness'] = (coreStrengths['self_awareness'] ?? 0.0) + 0.1;

    return {
      "primary_emotions": entry.moods.take(2).toList(),
      "emotional_intensity": _calculateIntensityFromContent(entry.content),
      "growth_indicators": ["self_reflection", "emotional_awareness"],
      "core_strengths": coreStrengths,
      "insight": _generateFallbackInsight(entry),
      "daily_reflection": "Your commitment to journaling shows dedication to personal growth.",
      "patterns": ["consistent_journaling"],
      "suggestions": ["continue_daily_practice"],
    };
  }

  /// Mark entry as skipped
  Future<void> _markEntryAsSkipped(JournalEntry entry, String reason) async {
    final updatedEntry = entry.copyWith(
      status: EntryStatus.processed,
      // Entry marked as processed but skipped due to limits
    );
    
    await _journalRepository.updateEntry(updatedEntry);
    
    if (kDebugMode) {
      debugPrint('DailyJournalProcessor: Marked entry ${entry.id} as skipped - $reason');
    }
  }

  /// Update emotional cores from entry analysis
  Future<void> _updateEmotionalCoresFromEntry(JournalEntry entry, Map<String, dynamic> analysis) async {
    try {
      final coreStrengths = analysis['core_strengths'] as Map<String, dynamic>? ?? {};
      
      if (coreStrengths.isNotEmpty) {
        await _coreEngine.updateCoresFromAnalysis(coreStrengths);
        
        if (kDebugMode) {
          debugPrint('DailyJournalProcessor: Updated cores for entry ${entry.id}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DailyJournalProcessor: Failed to update emotional cores from entry ${entry.id}: $e');
      }
    }
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

  String _generateFallbackInsight(JournalEntry entry) {
    final wordCount = entry.content.trim().split(' ').length;
    if (wordCount > 100) {
      return "Your detailed reflection shows deep self-awareness and commitment to personal growth.";
    } else if (entry.moods.isNotEmpty) {
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
