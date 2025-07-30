import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';
import 'haiku_prompt_optimizer.dart';

/// Batch processor for cost-efficient journal analysis
/// 
/// This service implements intelligent batching to minimize API costs:
/// - Queues entries throughout the day
/// - Processes up to 10 entries in single API call at midnight
/// - Handles partial failures gracefully
/// - Implements exponential backoff retry logic
/// - Persists queue across app restarts
class HaikuBatchProcessor {
  static final HaikuBatchProcessor _instance = HaikuBatchProcessor._internal();
  factory HaikuBatchProcessor() => _instance;
  HaikuBatchProcessor._internal();

  final HaikuPromptOptimizer _optimizer = HaikuPromptOptimizer();
  
  // Queue management
  final List<BatchQueueItem> _pendingQueue = [];
  final List<BatchQueueItem> _processingQueue = [];
  final List<BatchResult> _completedBatches = [];
  
  // Scheduler
  Timer? _midnightScheduler;
  Timer? _retryTimer;
  
  // Configuration
  static const int maxBatchSize = 10;
  static const int maxRetryAttempts = 3;
  static const Duration retryBaseDelay = Duration(minutes: 5);
  static const String queueStorageKey = 'haiku_batch_queue';
  static const String resultsStorageKey = 'haiku_batch_results';
  
  // State
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  /// Initialize the batch processor
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadPersistedQueue();
    await _loadPersistedResults();
    _scheduleMidnightProcessing();
    _isInitialized = true;
    
    if (kDebugMode) {
      debugPrint('🔄 HaikuBatchProcessor initialized - Queue: ${_pendingQueue.length} items');
    }
  }

  /// Add journal entry to processing queue
  Future<void> queueEntry(JournalEntry entry, {int priority = 0}) async {
    if (!_isInitialized) await initialize();
    
    final queueItem = BatchQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entry: entry,
      queuedAt: DateTime.now(),
      priority: priority,
      retryCount: 0,
    );
    
    _pendingQueue.add(queueItem);
    _pendingQueue.sort((a, b) => b.priority.compareTo(a.priority)); // Higher priority first
    
    await _persistQueue();
    
    if (kDebugMode) {
      debugPrint('📝 Queued entry ${entry.id} - Queue size: ${_pendingQueue.length}');
    }
    
    // Process immediately if queue is full or in debug mode for testing
    if (_pendingQueue.length >= maxBatchSize || (kDebugMode && _pendingQueue.length >= 3)) {
      await _processBatch();
    }
  }

  /// Get current queue status
  BatchQueueStatus getQueueStatus() {
    return BatchQueueStatus(
      pendingCount: _pendingQueue.length,
      processingCount: _processingQueue.length,
      completedBatchesCount: _completedBatches.length,
      nextProcessingTime: _getNextMidnight(),
      isProcessing: _isProcessing,
    );
  }

  /// Force process current queue (for testing or manual trigger)
  Future<List<BatchResult>> forceProcessQueue() async {
    if (!_isInitialized) await initialize();
    return await _processBatch();
  }

  /// Get completed batch results
  List<BatchResult> getCompletedResults({int? lastN}) {
    final results = List<BatchResult>.from(_completedBatches);
    results.sort((a, b) => b.processedAt.compareTo(a.processedAt));
    
    if (lastN != null && lastN > 0) {
      return results.take(lastN).toList();
    }
    
    return results;
  }

  /// Schedule midnight processing
  void _scheduleMidnightProcessing() {
    _midnightScheduler?.cancel();
    
    final now = DateTime.now();
    final nextMidnight = _getNextMidnight();
    final timeUntilMidnight = nextMidnight.difference(now);
    
    _midnightScheduler = Timer(timeUntilMidnight, () {
      _processBatch();
      _scheduleMidnightProcessing(); // Reschedule for next day
    });
    
    if (kDebugMode) {
      debugPrint('⏰ Scheduled midnight processing in ${timeUntilMidnight.inHours}h ${timeUntilMidnight.inMinutes % 60}m');
    }
  }

  /// Process current batch
  Future<List<BatchResult>> _processBatch() async {
    if (_isProcessing || _pendingQueue.isEmpty) {
      return [];
    }
    
    _isProcessing = true;
    final results = <BatchResult>[];
    
    try {
      // Split queue into batches of maxBatchSize
      while (_pendingQueue.isNotEmpty) {
        final batchItems = _pendingQueue.take(maxBatchSize).toList();
        _pendingQueue.removeRange(0, batchItems.length.clamp(0, _pendingQueue.length));
        _processingQueue.addAll(batchItems);
        
        final batchResult = await _processSingleBatch(batchItems);
        results.add(batchResult);
        
        // Remove successfully processed items
        _processingQueue.removeWhere((item) => 
            batchResult.itemResults.any((result) => result.queueItemId == item.id && result.success));
        
        // Re-queue failed items for retry
        final failedItems = _processingQueue.where((item) => 
            batchResult.itemResults.any((result) => result.queueItemId == item.id && !result.success));
        
        for (final failedItem in failedItems) {
          if (failedItem.retryCount < maxRetryAttempts) {
            failedItem.retryCount++;
            _pendingQueue.add(failedItem);
          } else {
            if (kDebugMode) {
              debugPrint('❌ Dropping item ${failedItem.id} after ${maxRetryAttempts} failed attempts');
            }
          }
        }
        
        _processingQueue.clear();
      }
      
      _completedBatches.addAll(results);
      await _persistQueue();
      await _persistResults();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Batch processing error: $e');
      }
      
      // Re-queue processing items back to pending
      _pendingQueue.addAll(_processingQueue);
      _processingQueue.clear();
      
      // Schedule retry
      _scheduleRetry();
    } finally {
      _isProcessing = false;
    }
    
    return results;
  }

  /// Process a single batch of entries
  Future<BatchResult> _processSingleBatch(List<BatchQueueItem> batchItems) async {
    final batchId = DateTime.now().millisecondsSinceEpoch.toString();
    final startTime = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('🔄 Processing batch $batchId with ${batchItems.length} items');
    }
    
    try {
      // Create batch prompt
      final entries = batchItems.map((item) => item.entry).toList();
      final batchPrompt = _createBatchPrompt(entries);
      final systemPrompt = _optimizer.createHaikuSystemPrompt();
      
      // Select optimal model (use Haiku for batches to maximize cost savings)
      final modelConfig = _optimizer.createOptimizedRequestConfig(
        'claude-3-haiku-20240307',
        systemPrompt,
        batchPrompt,
      );
      
      // Simulate API call (replace with actual API implementation)
      final apiResponse = await _callBatchAPI(modelConfig);
      
      // Parse response
      final analyses = _parseBatchResponse(apiResponse, batchItems);
      
      // Create item results
      final itemResults = <BatchItemResult>[];
      for (int i = 0; i < batchItems.length; i++) {
        final item = batchItems[i];
        final analysis = i < analyses.length ? analyses[i] : null;
        
        itemResults.add(BatchItemResult(
          queueItemId: item.id,
          entryId: item.entry.id,
          success: analysis != null,
          analysis: analysis,
          error: analysis == null ? 'Analysis not found in response' : null,
          processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ));
      }
      
      final result = BatchResult(
        batchId: batchId,
        processedAt: DateTime.now(),
        itemCount: batchItems.length,
        successCount: itemResults.where((r) => r.success).length,
        failureCount: itemResults.where((r) => !r.success).length,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        itemResults: itemResults,
        totalCost: _estimateBatchCost(entries),
      );
      
      if (kDebugMode) {
        debugPrint('✅ Batch $batchId completed - Success: ${result.successCount}/${result.itemCount}');
      }
      
      return result;
      
    } catch (e) {
      final result = BatchResult(
        batchId: batchId,
        processedAt: DateTime.now(),
        itemCount: batchItems.length,
        successCount: 0,
        failureCount: batchItems.length,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        itemResults: batchItems.map((item) => BatchItemResult(
          queueItemId: item.id,
          entryId: item.entry.id,
          success: false,
          analysis: null,
          error: e.toString(),
          processingTimeMs: 0,
        )).toList(),
        totalCost: 0.0,
        error: e.toString(),
      );
      
      if (kDebugMode) {
        debugPrint('❌ Batch $batchId failed: $e');
      }
      
      return result;
    }
  }

  /// Create optimized batch prompt
  String _createBatchPrompt(List<JournalEntry> entries) {
    final batchData = entries.map((entry) => {
      'id': entry.id,
      'content': _compressContent(entry.content, maxLength: 200),
      'moods': entry.moods.take(3).join(','),
      'date': _formatDateCompact(entry.date),
    }).toList();

    return '''Batch analysis for ${entries.length} journal entries:

${batchData.asMap().entries.map((e) => 
    '${e.key + 1}. ID:"${e.value['id']}" "${e.value['content']}" [${e.value['moods']}] (${e.value['date']})'
).join('\n')}

Return JSON array with exactly ${entries.length} analyses in same order:
[
  {
    "id": "entry_id",
    "emotions": ["str"],
    "intensity": 0.0-1.0,
    "themes": ["str"],
    "sentiment": -1.0-1.0,
    "insight": "str",
    "cores": {
      "optimism": -1.0-1.0,
      "resilience": -1.0-1.0,
      "self_awareness": -1.0-1.0,
      "creativity": -1.0-1.0,
      "social_connection": -1.0-1.0,
      "growth_mindset": -1.0-1.0
    },
    "patterns": ["str"],
    "growth": ["str"]
  }
]

Limits: 3 emotions, 3 themes, 3 patterns, 3 growth items per entry. Insight max 80 chars.''';
  }

  /// Simulate API call (replace with actual implementation)
  Future<Map<String, dynamic>> _callBatchAPI(Map<String, dynamic> config) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 2));
    
    // Simulate API response structure
    return {
      'usage': {
        'input_tokens': 800,
        'output_tokens': 600,
      },
      'content': [
        {
          'text': jsonEncode([
            // Mock response for testing
            {
              "id": "test_entry_1",
              "emotions": ["hopeful", "reflective"],
              "intensity": 0.7,
              "themes": ["growth", "relationships"],
              "sentiment": 0.6,
              "insight": "Processing complex emotions around personal growth",
              "cores": {
                "optimism": 0.5,
                "resilience": 0.8,
                "self_awareness": 0.9,
                "creativity": 0.6,
                "social_connection": 0.7,
                "growth_mindset": 0.8
              },
              "patterns": ["self-reflection", "future-planning"],
              "growth": ["emotional awareness", "relationship skills"]
            }
          ])
        }
      ]
    };
  }

  /// Parse batch API response
  List<Map<String, dynamic>> _parseBatchResponse(
    Map<String, dynamic> response,
    List<BatchQueueItem> batchItems,
  ) {
    try {
      final content = response['content'] as List?;
      if (content == null || content.isEmpty) {
        throw Exception('No content in response');
      }
      
      final textContent = content.first['text'] as String?;
      if (textContent == null) {
        throw Exception('No text content in response');
      }
      
      final analyses = jsonDecode(textContent) as List;
      
      // Track token usage
      final usage = response['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        final inputTokens = usage['input_tokens'] as int? ?? 0;
        final outputTokens = usage['output_tokens'] as int? ?? 0;
        _optimizer.trackUsage('claude-3-haiku-20240307', inputTokens, outputTokens);
      }
      
      return analyses.cast<Map<String, dynamic>>();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔍 Batch response parsing error: $e');
      }
      return [];
    }
  }

  /// Schedule retry with exponential backoff
  void _scheduleRetry() {
    _retryTimer?.cancel();
    
    final retryDelay = Duration(
      milliseconds: (retryBaseDelay.inMilliseconds * 
        (1 << (_processingQueue.isNotEmpty ? _processingQueue.first.retryCount : 0))).clamp(
          retryBaseDelay.inMilliseconds,
          Duration(hours: 2).inMilliseconds,
        ),
    );
    
    _retryTimer = Timer(retryDelay, () {
      if (_pendingQueue.isNotEmpty) {
        _processBatch();
      }
    });
    
    if (kDebugMode) {
      debugPrint('⏱️ Retry scheduled in ${retryDelay.inMinutes} minutes');
    }
  }

  /// Estimate batch processing cost
  double _estimateBatchCost(List<JournalEntry> entries) {
    final totalContentLength = entries.fold<int>(0, (sum, entry) => sum + entry.content.length);
    final estimatedInputTokens = (totalContentLength / 4).round() + 500; // +500 for batch prompt overhead
    final estimatedOutputTokens = entries.length * 150; // ~150 tokens per analysis
    
    return (estimatedInputTokens * 0.25 / 1000000) + 
           (estimatedOutputTokens * 1.25 / 1000000);
  }

  /// Compress content for batch processing
  String _compressContent(String content, {int maxLength = 200}) {
    if (content.length <= maxLength) return content;
    
    final compressed = content
        .replaceAll(RegExp(r'\b(really|very|quite|just|actually|basically|literally)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    if (compressed.length <= maxLength) return compressed;
    
    final truncated = compressed.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');
    
    if (lastSpace > maxLength * 0.8) {
      return truncated.substring(0, lastSpace) + '...';
    }
    
    return '$truncated...';
  }

  /// Format date in compact form for batch processing
  String _formatDateCompact(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '${diff}d';
    if (diff < 30) return '${(diff / 7).round()}w';
    return '${date.month}/${date.day}';
  }

  /// Get next midnight
  DateTime _getNextMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    return midnight;
  }

  /// Persist queue to storage
  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _pendingQueue.map((item) => item.toJson()).toList();
      await prefs.setString(queueStorageKey, jsonEncode(queueJson));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💾 Queue persistence error: $e');
      }
    }
  }

  /// Load persisted queue from storage
  Future<void> _loadPersistedQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJsonString = prefs.getString(queueStorageKey);
      
      if (queueJsonString != null) {
        final queueJson = jsonDecode(queueJsonString) as List;
        _pendingQueue.clear();
        _pendingQueue.addAll(
          queueJson.map((json) => BatchQueueItem.fromJson(json)).toList(),
        );
        
        if (kDebugMode) {
          debugPrint('💾 Loaded ${_pendingQueue.length} items from persisted queue');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💾 Queue loading error: $e');
      }
    }
  }

  /// Persist results to storage
  Future<void> _persistResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsJson = _completedBatches.take(50).map((result) => result.toJson()).toList(); // Keep last 50 results
      await prefs.setString(resultsStorageKey, jsonEncode(resultsJson));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💾 Results persistence error: $e');
      }
    }
  }

  /// Load persisted results from storage
  Future<void> _loadPersistedResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsJsonString = prefs.getString(resultsStorageKey);
      
      if (resultsJsonString != null) {
        final resultsJson = jsonDecode(resultsJsonString) as List;
        _completedBatches.clear();
        _completedBatches.addAll(
          resultsJson.map((json) => BatchResult.fromJson(json)).toList(),
        );
        
        if (kDebugMode) {
          debugPrint('💾 Loaded ${_completedBatches.length} batch results from storage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💾 Results loading error: $e');
      }
    }
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    _pendingQueue.clear();
    _processingQueue.clear();
    _completedBatches.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(queueStorageKey);
    await prefs.remove(resultsStorageKey);
    
    if (kDebugMode) {
      debugPrint('🗑️ Cleared all batch processor data');
    }
  }

  /// Dispose resources
  void dispose() {
    _midnightScheduler?.cancel();
    _retryTimer?.cancel();
  }
}

/// Queue item for batch processing
class BatchQueueItem {
  final String id;
  final JournalEntry entry;
  final DateTime queuedAt;
  final int priority;
  int retryCount;

  BatchQueueItem({
    required this.id,
    required this.entry,
    required this.queuedAt,
    this.priority = 0,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'entry': {
      'id': entry.id,
      'content': entry.content,
      'date': entry.date.toIso8601String(),
      'moods': entry.moods,
    },
    'queuedAt': queuedAt.toIso8601String(),
    'priority': priority,
    'retryCount': retryCount,
  };

  factory BatchQueueItem.fromJson(Map<String, dynamic> json) {
    final entryJson = json['entry'] as Map<String, dynamic>;
    return BatchQueueItem(
      id: json['id'],
      entry: JournalEntry(
        id: entryJson['id'],
        userId: 'test_user',
        content: entryJson['content'],
        date: DateTime.parse(entryJson['date']),
        moods: List<String>.from(entryJson['moods'] ?? []),
        dayOfWeek: _getDayOfWeek(DateTime.parse(entryJson['date']).weekday),
        createdAt: DateTime.parse(entryJson['date']),
        updatedAt: DateTime.parse(entryJson['date']),
      ),
      queuedAt: DateTime.parse(json['queuedAt']),
      priority: json['priority'] ?? 0,
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// Result of batch processing
class BatchResult {
  final String batchId;
  final DateTime processedAt;
  final int itemCount;
  final int successCount;
  final int failureCount;
  final int processingTimeMs;
  final List<BatchItemResult> itemResults;
  final double totalCost;
  final String? error;

  BatchResult({
    required this.batchId,
    required this.processedAt,
    required this.itemCount,
    required this.successCount,
    required this.failureCount,
    required this.processingTimeMs,
    required this.itemResults,
    required this.totalCost,
    this.error,
  });

  bool get isSuccess => error == null && failureCount == 0;
  double get successRate => itemCount > 0 ? successCount / itemCount : 0.0;

  Map<String, dynamic> toJson() => {
    'batchId': batchId,
    'processedAt': processedAt.toIso8601String(),
    'itemCount': itemCount,
    'successCount': successCount,
    'failureCount': failureCount,
    'processingTimeMs': processingTimeMs,
    'itemResults': itemResults.map((r) => r.toJson()).toList(),
    'totalCost': totalCost,
    'error': error,
  };

  factory BatchResult.fromJson(Map<String, dynamic> json) => BatchResult(
    batchId: json['batchId'],
    processedAt: DateTime.parse(json['processedAt']),
    itemCount: json['itemCount'],
    successCount: json['successCount'],
    failureCount: json['failureCount'],
    processingTimeMs: json['processingTimeMs'],
    itemResults: (json['itemResults'] as List).map((r) => BatchItemResult.fromJson(r)).toList(),
    totalCost: json['totalCost']?.toDouble() ?? 0.0,
    error: json['error'],
  );
}

/// Result of individual item processing within a batch
class BatchItemResult {
  final String queueItemId;
  final String entryId;
  final bool success;
  final Map<String, dynamic>? analysis;
  final String? error;
  final int processingTimeMs;

  BatchItemResult({
    required this.queueItemId,
    required this.entryId,
    required this.success,
    this.analysis,
    this.error,
    required this.processingTimeMs,
  });

  Map<String, dynamic> toJson() => {
    'queueItemId': queueItemId,
    'entryId': entryId,
    'success': success,
    'analysis': analysis,
    'error': error,
    'processingTimeMs': processingTimeMs,
  };

  factory BatchItemResult.fromJson(Map<String, dynamic> json) => BatchItemResult(
    queueItemId: json['queueItemId'],
    entryId: json['entryId'],
    success: json['success'],
    analysis: json['analysis'],
    error: json['error'],
    processingTimeMs: json['processingTimeMs'],
  );
}

/// Current queue status
class BatchQueueStatus {
  final int pendingCount;
  final int processingCount;
  final int completedBatchesCount;
  final DateTime nextProcessingTime;
  final bool isProcessing;

  BatchQueueStatus({
    required this.pendingCount,
    required this.processingCount,
    required this.completedBatchesCount,
    required this.nextProcessingTime,
    required this.isProcessing,
  });

  Duration get timeUntilNextProcessing => nextProcessingTime.difference(DateTime.now());
  
  @override
  String toString() {
    return 'BatchQueueStatus(pending: $pendingCount, processing: $processingCount, '
           'completed: $completedBatchesCount, next: ${timeUntilNextProcessing.inHours}h, '
           'isProcessing: $isProcessing)';
  }
}

String _getDayOfWeek(int weekday) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return days[weekday - 1];
}