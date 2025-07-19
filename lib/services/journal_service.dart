import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../constants/validation_constants.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import '../database/journal_dao.dart';
import '../database/core_dao.dart';
import 'ai_service_manager.dart';
import 'background_ai_processor.dart';

/// Central service for managing journal entries and emotional core operations.
/// 
/// This service provides a high-level interface for all journal-related operations,
/// coordinating between the database layer, AI analysis, and emotional core updates.
/// It handles transaction safety, error recovery, and provides both atomic and
/// fallback approaches for complex operations.
/// 
/// ## Key Features
/// - Atomic journal entry creation with core updates
/// - AI-powered emotional analysis with fallback to rule-based analysis
/// - Comprehensive search and filtering capabilities
/// - Monthly summary generation with insights
/// - Transaction safety for all database operations
/// 
/// ## Usage Example
/// ```dart
/// final journalService = JournalService();
/// await journalService.initialize();
/// 
/// // Create a new journal entry
/// final entryId = await journalService.createJournalEntry(
///   content: "Today was a great day...",
///   moods: ["happy", "grateful"],
/// );
/// 
/// // Get monthly summary
/// final summary = await journalService.generateMonthlySummary(2024, 12);
/// debugPrint(summary.insight);
/// ```
/// 
/// ## Architecture Notes
/// - Uses singleton pattern for consistent state management
/// - Coordinates between JournalDao, CoreDao, and AIServiceManager
/// - Implements graceful degradation when AI services are unavailable
/// - Provides both atomic and fallback transaction approaches
class JournalService {
  static final JournalService _instance = JournalService._internal();
  factory JournalService() => _instance;
  JournalService._internal();

  final JournalDao _journalDao = JournalDao();
  final CoreDao _coreDao = CoreDao();
  final AIServiceManager _aiManager = AIServiceManager();
  final BackgroundAIProcessor _aiProcessor = BackgroundAIProcessor();

  // Initialize the service (call this on app startup)
  Future<void> initialize() async {
    try {
      await _coreDao.initializeDefaultCores();
      await _aiProcessor.initialize(
        aiServiceManager: _aiManager,
        journalService: this,
      );
    } catch (e) {
      debugPrint('JournalService initialize error: $e');
      rethrow;
    }
  }

  // Journal Entry Operations with atomic transaction safety
  Future<String> createJournalEntry({
    required String content,
    required List<String> moods,
    EntryStatus status = EntryStatus.saved,
  }) async {
    try {
      final entry = JournalEntry.create(
        content: content,
        moods: moods,
      ).copyWith(status: status);
      
      try {
        // Calculate core updates first
        final coreUpdates = await _calculateCoreUpdates(entry);
        
        // Use atomic method to insert entry and update cores in single transaction
        final entryId = await _journalDao.insertJournalEntryWithCoreUpdates(entry, coreUpdates);
        
        return entryId;
      } catch (e) {
        // If atomic operation fails, try fallback approach
        final entryId = await _journalDao.insertJournalEntry(entry);
        
        // Update cores separately as fallback (with error handling)
        try {
          await _updateCoresFromEntry(entry);
        } catch (coreError) {
          // Log core update failure but don't fail the entire operation
          debugPrint('JournalService createJournalEntry fallback core update error: $coreError');
        }
        
        return entryId;
      }
    } catch (e) {
      debugPrint('JournalService createJournalEntry error: $e');
      rethrow;
    }
  }

  // Save draft entry (autosave functionality)
  Future<String> saveDraftEntry({
    required String content,
    required List<String> moods,
    String? existingEntryId,
  }) async {
    try {
      if (existingEntryId != null) {
        // Update existing draft
        final existingEntry = await getEntryById(existingEntryId);
        if (existingEntry != null && existingEntry.isEditable) {
          final updatedEntry = existingEntry.copyWith(
            content: content,
            moods: moods,
            status: EntryStatus.draft,
            updatedAt: DateTime.now(),
          );
          await updateEntry(updatedEntry);
          return existingEntryId;
        }
      }
      
      // Create new draft entry
      final entry = JournalEntry.create(
        content: content,
        moods: moods,
      ).copyWith(status: EntryStatus.draft);
      
      final entryId = await _journalDao.insertJournalEntry(entry);
      return entryId;
    } catch (e) {
      debugPrint('JournalService saveDraftEntry error: $e');
      rethrow;
    }
  }

  Future<List<JournalEntry>> getAllEntries() async {
    try {
      return await _journalDao.getAllJournalEntries();
    } catch (e) {
      debugPrint('JournalService getAllEntries error: $e');
      rethrow;
    }
  }

  Future<List<JournalEntry>> getEntriesByYear(int year) async {
    try {
      return await _journalDao.getJournalEntriesByYear(year);
    } catch (e) {
      debugPrint('JournalService getEntriesByYear error: $e');
      rethrow;
    }
  }

  Future<List<JournalEntry>> getEntriesByMonth(int year, int month) async {
    try {
      return await _journalDao.getJournalEntriesByMonth(year, month);
    } catch (e) {
      debugPrint('JournalService getEntriesByMonth error: $e');
      rethrow;
    }
  }

  Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      return await _journalDao.searchJournalEntries(query);
    } catch (e) {
      debugPrint('JournalService searchEntries error: $e');
      rethrow;
    }
  }

  Future<List<JournalEntry>> getEntriesByMood(String mood) async {
    try {
      return await _journalDao.getJournalEntriesByMood(mood);
    } catch (e) {
      debugPrint('JournalService getEntriesByMood error: $e');
      rethrow;
    }
  }

  Future<JournalEntry?> getEntryById(String id) async {
    try {
      return await _journalDao.getJournalEntryById(id);
    } catch (e) {
      debugPrint('JournalService getEntryById error: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    try {
      try {
        // Calculate core updates first
        final coreUpdates = await _calculateCoreUpdates(entry);
        
        // Use atomic method to update entry and cores in single transaction
        await _journalDao.updateJournalEntryWithCoreUpdates(entry, coreUpdates);
      } catch (e) {
        // If atomic operation fails, try fallback approach
        await _journalDao.updateJournalEntry(entry);
        
        // Update cores separately as fallback (with error handling)
        try {
          await _updateCoresFromEntry(entry);
        } catch (coreError) {
          // Log core update failure but don't fail the entire operation
          debugPrint('JournalService updateEntry fallback core update error: $coreError');
        }
      }
    } catch (e) {
      debugPrint('JournalService updateEntry error: $e');
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _journalDao.deleteJournalEntry(id);
    } catch (e) {
      debugPrint('JournalService deleteEntry error: $e');
      rethrow;
    }
  }

  // Emotional Core Operations
  Future<List<EmotionalCore>> getAllCores() async {
    try {
      return await _coreDao.getAllEmotionalCores();
    } catch (e) {
      debugPrint('JournalService getAllCores error: $e');
      rethrow;
    }
  }

  Future<List<EmotionalCore>> getTopCores(int limit) async {
    try {
      return await _coreDao.getTopCores(limit);
    } catch (e) {
      debugPrint('JournalService getTopCores error: $e');
      rethrow;
    }
  }

  Future<EmotionalCore?> getCoreById(String id) async {
    try {
      return await _coreDao.getEmotionalCoreById(id);
    } catch (e) {
      debugPrint('JournalService getCoreById error: $e');
      rethrow;
    }
  }

  Future<EmotionalCore?> getCoreByName(String name) async {
    try {
      return await _coreDao.getEmotionalCoreByName(name);
    } catch (e) {
      debugPrint('JournalService getCoreByName error: $e');
      rethrow;
    }
  }

  Future<List<EmotionalCore>> getCoresByTrend(String trend) async {
    try {
      return await _coreDao.getCoresByTrend(trend);
    } catch (e) {
      debugPrint('JournalService getCoresByTrend error: $e');
      rethrow;
    }
  }

  Future<void> updateCore(EmotionalCore core) async {
    try {
      await _coreDao.updateEmotionalCore(core);
    } catch (e) {
      debugPrint('JournalService updateCore error: $e');
      rethrow;
    }
  }

  // Statistics and Analytics
  Future<Map<String, int>> getMonthlyEntryCounts(int year) async {
    try {
      return await _journalDao.getMonthlyEntryCounts(year);
    } catch (e) {
      debugPrint('JournalService getMonthlyEntryCounts error: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getMoodFrequency() async {
    try {
      return await _journalDao.getMoodFrequency();
    } catch (e) {
      debugPrint('JournalService getMoodFrequency error: $e');
      rethrow;
    }
  }

  Future<List<String>> getAvailableYears() async {
    try {
      final entries = await getAllEntries();
      final years = entries.map((e) => e.date.year).toSet().toList();
      years.sort((a, b) => b.compareTo(a)); // Most recent first
      return years.map((y) => y.toString()).toList();
    } catch (e) {
      debugPrint('JournalService getAvailableYears error: $e');
      rethrow;
    }
  }

  Future<MonthlySummary> generateMonthlySummary(int year, int month) async {
    try {
      final entries = await getEntriesByMonth(year, month);
      final moodCounts = <String, int>{};
      
      // Count moods for the month
      for (final entry in entries) {
        for (final mood in entry.moods) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        }
      }

      // Get dominant moods (top 3)
      final sortedMoods = moodCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final dominantMoods = sortedMoods.take(AppConstants.topMoodsCount).map((e) => e.key).toList();

      // Generate emotional journey data (simplified for now)
      final journeyData = List.generate(AppConstants.journeyDataPoints, (index) => 
        (moodCounts.values.isNotEmpty ? 
          moodCounts.values.reduce((a, b) => a + b) / moodCounts.length : 0.0) + 
        (index * AppConstants.journeyDataVariation));

      // Generate insight based on data
      String insight = _generateMonthlyInsight(entries, dominantMoods);

      final months = ValidationConstants.monthNames;

      return MonthlySummary(
        id: '${year}_$month',
        month: months[month - 1],
        year: year,
        dominantMoods: dominantMoods,
        emotionalJourneyData: journeyData,
        insight: insight,
        entryCount: entries.length,
      );
    } catch (e) {
      debugPrint('JournalService generateMonthlySummary error: $e');
      rethrow;
    }
  }

  // Private helper methods
  Future<Map<String, double>> _calculateCoreUpdates(JournalEntry entry) async {
    try {
      // Get current cores
      final currentCores = await getAllCores();
      
      // Use AI service to calculate core updates
      final coreUpdates = await _aiManager.calculateCoreUpdates(entry, currentCores);
      
      return coreUpdates;
    } catch (e) {
      // Fallback to simple mood-based updates if AI service fails
      return await _calculateFallbackCoreUpdates(entry);
    }
  }

  // Fallback method for calculating core updates when AI service is unavailable
  Future<Map<String, double>> _calculateFallbackCoreUpdates(JournalEntry entry) async {
    final coreUpdates = <String, double>{};
    
    for (final mood in entry.moods) {
      final coreName = ValidationConstants.getPrimaryCoreForMood(mood);
      if (coreName != null) {
        final core = await getCoreByName(coreName);
        if (core != null) {
          final newPercentage = (core.percentage + AppConstants.corePercentageIncrement)
              .clamp(AppConstants.minCorePercentage, AppConstants.maxCorePercentage);
          coreUpdates[core.id] = newPercentage;
        }
      }
    }
    
    return coreUpdates;
  }

  Future<void> _updateCoresFromEntry(JournalEntry entry) async {
    try {
      // Get current cores
      final currentCores = await getAllCores();
      
      // Use AI service to calculate core updates
      final coreUpdates = await _aiManager.calculateCoreUpdates(entry, currentCores);
      
      // Apply updates to each core
      for (final update in coreUpdates.entries) {
        final coreId = update.key;
        final newPercentage = update.value;
        
        final core = currentCores.firstWhere((c) => c.id == coreId);
        final trend = _determineTrend(core.percentage, newPercentage);
        
        await _coreDao.updateCorePercentage(coreId, newPercentage, trend);
      }
    } catch (e) {
      // Fallback to simple mood-based updates if AI service fails
      await _fallbackCoreUpdate(entry);
    }
  }

  // Fallback method for core updates when AI service is unavailable
  Future<void> _fallbackCoreUpdate(JournalEntry entry) async {
    for (final mood in entry.moods) {
      final coreName = ValidationConstants.getPrimaryCoreForMood(mood);
      if (coreName != null) {
        final core = await getCoreByName(coreName);
        if (core != null) {
          final newPercentage = (core.percentage + AppConstants.corePercentageIncrement)
              .clamp(AppConstants.minCorePercentage, AppConstants.maxCorePercentage);
          final trend = _determineTrend(core.percentage, newPercentage);
          await _coreDao.updateCorePercentage(core.id, newPercentage, trend);
        }
      }
    }
  }

  // Determine trend based on percentage change
  String _determineTrend(double oldPercentage, double newPercentage) {
    final difference = newPercentage - oldPercentage;
    if (difference > AppConstants.trendChangeThreshold) return 'rising';
    if (difference < -AppConstants.trendChangeThreshold) return 'declining';
    return 'stable';
  }

  String _generateMonthlyInsight(List<JournalEntry> entries, List<String> dominantMoods) {
    if (entries.isEmpty) {
      return "No entries this month. Consider starting a regular journaling practice!";
    }

    if (entries.length == 1) {
      return "Great start! One entry is the beginning of a meaningful journey.";
    }

    final avgWordsPerEntry = entries.map((e) => e.content.split(' ').length)
        .reduce((a, b) => a + b) / entries.length;

    if (dominantMoods.isNotEmpty) {
      final topMood = dominantMoods.first;
      if (avgWordsPerEntry > AppConstants.minWordsForDetailedAnalysis) {
        return "You've been feeling mostly $topMood this month, with rich, detailed reflections averaging ${avgWordsPerEntry.round()} words per entry.";
      } else {
        return "Your $topMood mood dominated this month. Consider writing longer entries to deepen your self-reflection.";
      }
    }

    return "You maintained consistent journaling this month with ${entries.length} entries. Keep up the great work!";
  }

  // Background AI processing methods
  Future<void> queueEntryForAnalysis(JournalEntry entry, {
    ProcessingPriority priority = ProcessingPriority.normal,
  }) async {
    await _aiProcessor.queueEntryAnalysis(
      entry,
      priority: priority,
      onComplete: (result) async {
        // Update entry with analysis result
        await updateEntryWithAnalysis(entry.id, result);
      },
      onError: (error) {
        debugPrint('Background AI analysis failed for entry ${entry.id}: $error');
      },
    );
  }

  Future<void> queueBatchAnalysis(List<JournalEntry> entries) async {
    await _aiProcessor.queueBatchAnalysis(
      entries,
      onBatchComplete: (results) async {
        // Update entries with analysis results
        for (int i = 0; i < entries.length && i < results.length; i++) {
          if (!results[i].containsKey('error')) {
            await updateEntryWithAnalysis(entries[i].id, results[i]);
          }
        }
      },
    );
  }

  Future<void> updateEntryWithAnalysis(String entryId, Map<String, dynamic> analysis) async {
    try {
      final entry = await getEntryById(entryId);
      if (entry != null) {
        final emotionalAnalysis = EmotionalAnalysis(
          primaryEmotions: analysis['primary_emotions']?.cast<String>() ?? [],
          emotionalIntensity: (analysis['emotional_intensity'] ?? 0.0).toDouble(),
          keyThemes: analysis['growth_indicators']?.cast<String>() ?? [],
          personalizedInsight: analysis['insight']?.toString(),
          coreImpacts: Map<String, double>.from(analysis['core_impacts'] ?? {}),
          analyzedAt: DateTime.now(),
        );
        
        final updatedEntry = entry.copyWith(
          aiAnalysis: emotionalAnalysis,
          isAnalyzed: true,
          aiDetectedMoods: analysis['primary_emotions']?.cast<String>() ?? [],
          emotionalIntensity: analysis['emotional_intensity']?.toDouble(),
          keyThemes: analysis['growth_indicators']?.cast<String>() ?? [],
          personalizedInsight: analysis['insight']?.toString(),
        );
        
        await updateEntry(updatedEntry);
      }
    } catch (e) {
      debugPrint('JournalService updateEntryWithAnalysis error: $e');
    }
  }

  // Performance and resource management
  void pauseBackgroundProcessing() {
    _aiProcessor.pauseProcessing();
  }

  void resumeBackgroundProcessing() {
    _aiProcessor.resumeProcessing();
  }

  void clearProcessingQueue() {
    _aiProcessor.clearQueue();
  }

  Map<String, dynamic> getProcessingMetrics() {
    return _aiProcessor.performanceMetrics;
  }

  // Dispose method for cleanup
  Future<void> dispose() async {
    await _aiProcessor.dispose();
  }

  // Utility methods for UI
  List<String> get availableMoods => ValidationConstants.validMoods;

  List<String> get coreTypes => ValidationConstants.validCoreNames;

  // Phase 5: 24-Hour Entry Limit
  Future<bool> canCreateEntryToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final todaysEntries = await _journalDao.getJournalEntriesByDateRange(startOfDay, endOfDay);
      
      // Allow only one entry per day for API usage limits
      return todaysEntries.isEmpty;
    } catch (e) {
      debugPrint('JournalService canCreateEntryToday error: $e');
      // If there's an error checking, allow the entry (fail open)
      return true;
    }
  }

  Future<JournalEntry?> getTodaysEntry() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final todaysEntries = await _journalDao.getJournalEntriesByDateRange(startOfDay, endOfDay);
      
      return todaysEntries.isNotEmpty ? todaysEntries.first : null;
    } catch (e) {
      debugPrint('JournalService getTodaysEntry error: $e');
      return null;
    }
  }

  // Phase 4: Data Management - Clear all app data
  Future<bool> clearAllData() async {
    try {
      // Clear all journal entries
      await _journalDao.clearAllJournalEntries();
      
      // Reset all cores to default state
      await _coreDao.resetAllCores();
      
      // Clear any cached data
      clearProcessingQueue();
      
      debugPrint('JournalService: All data cleared successfully');
      return true;
    } catch (e) {
      debugPrint('JournalService clearAllData error: $e');
      return false;
    }
  }
}
