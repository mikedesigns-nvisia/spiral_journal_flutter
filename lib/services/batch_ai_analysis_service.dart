import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../services/ai_service_manager.dart';

/// Service for batched AI analysis of journal entries.
/// 
/// This service runs AI analysis in batches to:
/// - Reduce API costs by batching requests
/// - Improve performance by avoiding real-time processing
/// - Provide predictable timing for users
/// - Handle rate limits gracefully
class BatchAIAnalysisService {
  static final BatchAIAnalysisService _instance = BatchAIAnalysisService._internal();
  factory BatchAIAnalysisService() => _instance;
  BatchAIAnalysisService._internal();

  final JournalService _journalService = JournalService();
  final AIServiceManager _aiManager = AIServiceManager();
  
  Timer? _batchTimer;
  bool _isProcessing = false;
  
  // Batch configuration
  static const Duration _batchInterval = Duration(hours: 12); // Run every 12 hours
  static const int _maxBatchSize = 10; // Process up to 10 entries per batch
  static const String _lastBatchKey = 'last_batch_analysis_time';
  static const String _nextBatchKey = 'next_batch_analysis_time';

  /// Initialize the batch processing service
  Future<void> initialize() async {
    debugPrint('BatchAIAnalysisService: Initializing...');
    
    // Schedule the next batch run
    await _scheduleNextBatch();
    
    debugPrint('BatchAIAnalysisService: Initialized successfully');
  }

  /// Schedule the next batch processing run
  Future<void> _scheduleNextBatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBatchTime = prefs.getInt(_lastBatchKey);
      final now = DateTime.now();
      
      Duration delay;
      if (lastBatchTime == null) {
        // First time - run in 30 seconds for immediate feedback
        delay = const Duration(seconds: 30);
      } else {
        final lastBatch = DateTime.fromMillisecondsSinceEpoch(lastBatchTime);
        final nextBatch = lastBatch.add(_batchInterval);
        
        if (now.isAfter(nextBatch)) {
          // Overdue - run immediately
          delay = Duration.zero;
        } else {
          // Schedule for the next batch time
          delay = nextBatch.difference(now);
        }
      }
      
      // Store next batch time
      final nextBatchTime = now.add(delay);
      await prefs.setInt(_nextBatchKey, nextBatchTime.millisecondsSinceEpoch);
      
      // Cancel existing timer
      _batchTimer?.cancel();
      
      // Schedule new batch
      _batchTimer = Timer(delay, _runBatchAnalysis);
      
      debugPrint('BatchAIAnalysisService: Next batch scheduled for ${nextBatchTime.toLocal()}');
    } catch (e) {
      debugPrint('BatchAIAnalysisService: Error scheduling next batch: $e');
    }
  }

  /// Run batch analysis of pending entries
  Future<void> _runBatchAnalysis() async {
    if (_isProcessing) {
      debugPrint('BatchAIAnalysisService: Batch already in progress, skipping...');
      return;
    }

    _isProcessing = true;
    debugPrint('BatchAIAnalysisService: Starting batch analysis...');
    
    try {
      final startTime = DateTime.now();
      
      // Get unanalyzed entries
      final allEntries = await _journalService.getAllEntries();
      final unanalyzedEntries = allEntries
          .where((entry) => !entry.isAnalyzed)
          .take(_maxBatchSize)
          .toList();
      
      if (unanalyzedEntries.isEmpty) {
        debugPrint('BatchAIAnalysisService: No entries need analysis');
        await _updateLastBatchTime();
        await _scheduleNextBatch();
        return;
      }
      
      debugPrint('BatchAIAnalysisService: Analyzing ${unanalyzedEntries.length} entries...');
      
      int successCount = 0;
      int errorCount = 0;
      
      // Process each entry
      for (final entry in unanalyzedEntries) {
        try {
          await _analyzeEntry(entry);
          successCount++;
          debugPrint('BatchAIAnalysisService: Successfully analyzed entry ${entry.id}');
        } catch (e) {
          errorCount++;
          debugPrint('BatchAIAnalysisService: Failed to analyze entry ${entry.id}: $e');
        }
      }
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('BatchAIAnalysisService: Batch completed in ${duration.inSeconds}s');
      debugPrint('BatchAIAnalysisService: Success: $successCount, Errors: $errorCount');
      
      // Update batch time
      await _updateLastBatchTime();
      
    } catch (e) {
      debugPrint('BatchAIAnalysisService: Batch analysis failed: $e');
    } finally {
      _isProcessing = false;
      // Schedule next batch
      await _scheduleNextBatch();
    }
  }

  /// Analyze a single journal entry
  Future<void> _analyzeEntry(JournalEntry entry) async {
    if (entry.content.trim().isEmpty) {
      throw Exception('Cannot analyze entry with empty content');
    }
    
    if (entry.moods.isEmpty) {
      throw Exception('Cannot analyze entry with no moods selected');
    }
    
    debugPrint('BatchAIAnalysisService: Starting analysis for entry ${entry.id}');
    
    // Perform AI analysis
    final analysisResult = await _aiManager.performEmotionalAnalysis(entry);
    
    // Create EmotionalAnalysis object
    final emotionalAnalysis = EmotionalAnalysis(
      primaryEmotions: analysisResult.primaryEmotions,
      emotionalIntensity: analysisResult.emotionalIntensity,
      keyThemes: analysisResult.keyThemes,
      personalizedInsight: analysisResult.personalizedInsight,
      analyzedAt: DateTime.now(),
      growthIndicators: analysisResult.growthIndicators,
      coreAdjustments: {},
      mindReflection: null,
      emotionalPatterns: [],
      entryInsight: analysisResult.personalizedInsight,
    );

    // Update the entry with analysis results
    final updatedEntry = entry.copyWith(
      aiAnalysis: emotionalAnalysis,
      isAnalyzed: true,
      aiDetectedMoods: analysisResult.primaryEmotions,
      emotionalIntensity: analysisResult.emotionalIntensity,
      keyThemes: analysisResult.keyThemes,
      personalizedInsight: analysisResult.personalizedInsight,
    );

    // Save the updated entry
    await _journalService.updateEntry(updatedEntry);
    
    // Update today's analysis state if this is today's entry
    await _updateTodaysAnalysisState(updatedEntry);
  }

  /// Update today's analysis state for the emotional state widget
  Future<void> _updateTodaysAnalysisState(JournalEntry analyzedEntry) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final entryDate = DateTime(
        analyzedEntry.createdAt.year,
        analyzedEntry.createdAt.month,
        analyzedEntry.createdAt.day,
      );
      
      // Only update if this entry is from today
      if (entryDate.isAtSameMomentAs(today)) {
        final prefs = await SharedPreferences.getInstance();
        final todayKey = '${today.year}-${today.month}-${today.day}';
        
        // Mark that we have analyzed an entry today
        await prefs.setString('last_analysis_date', todayKey);
        
        debugPrint('BatchAIAnalysisService: Updated today\'s analysis state for entry ${analyzedEntry.id}');
      }
    } catch (e) {
      debugPrint('BatchAIAnalysisService: Error updating today\'s analysis state: $e');
    }
  }

  /// Update the last batch analysis time
  Future<void> _updateLastBatchTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBatchKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('BatchAIAnalysisService: Error updating last batch time: $e');
    }
  }

  /// Force run batch analysis immediately (for testing/manual trigger)
  Future<void> runBatchNow() async {
    debugPrint('BatchAIAnalysisService: Manual batch trigger requested');
    
    try {
      await _runBatchAnalysis();
      debugPrint('BatchAIAnalysisService: Manual batch trigger completed successfully');
    } catch (e) {
      debugPrint('BatchAIAnalysisService: Manual batch trigger failed: $e');
      rethrow; // Let the calling widget handle the error display
    }
  }

  /// Get batch analysis status
  Future<Map<String, dynamic>> getBatchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBatchTime = prefs.getInt(_lastBatchKey);
      final nextBatchTime = prefs.getInt(_nextBatchKey);
      
      // Get pending entries count
      final allEntries = await _journalService.getAllEntries();
      final pendingCount = allEntries.where((entry) => !entry.isAnalyzed).length;
      
      return {
        'isProcessing': _isProcessing,
        'lastBatchTime': lastBatchTime != null 
            ? DateTime.fromMillisecondsSinceEpoch(lastBatchTime) 
            : null,
        'nextBatchTime': nextBatchTime != null 
            ? DateTime.fromMillisecondsSinceEpoch(nextBatchTime) 
            : null,
        'pendingCount': pendingCount,
        'batchInterval': _batchInterval.inHours,
        'maxBatchSize': _maxBatchSize,
      };
    } catch (e) {
      debugPrint('BatchAIAnalysisService: Error getting batch status: $e');
      return {
        'error': e.toString(),
        'isProcessing': _isProcessing,
        'pendingCount': 0,
      };
    }
  }

  /// Get time until next batch in human readable format
  Future<String> getTimeUntilNextBatch() async {
    try {
      final status = await getBatchStatus();
      final nextBatchTime = status['nextBatchTime'] as DateTime?;
      
      if (nextBatchTime == null) return 'Unknown';
      
      final now = DateTime.now();
      if (now.isAfter(nextBatchTime)) {
        return 'Processing...';
      }
      
      final difference = nextBatchTime.difference(now);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ${difference.inHours % 24}h';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes % 60}m';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Soon';
      }
    } catch (e) {
      debugPrint('BatchAIAnalysisService: Error calculating time until next batch: $e');
      return 'Unknown';
    }
  }

  /// Dispose of the service
  void dispose() {
    _batchTimer?.cancel();
    debugPrint('BatchAIAnalysisService: Disposed');
  }
}