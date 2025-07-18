import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import 'ai_service_manager.dart';
import 'journal_service.dart';

/// Background AI processing service for non-blocking AI analysis operations.
/// 
/// This service handles AI analysis operations in the background to prevent
/// UI blocking and provide a smooth user experience. It includes:
/// - Queue-based processing with priority levels
/// - Batch processing for efficiency
/// - Progress tracking and callbacks
/// - Error handling and retry logic
/// - Resource management and throttling
/// 
/// ## Key Features
/// - **Non-blocking Processing**: All AI operations run in background
/// - **Priority Queue**: High-priority operations (user-initiated) process first
/// - **Batch Processing**: Multiple entries processed together for efficiency
/// - **Progress Callbacks**: Real-time progress updates for UI
/// - **Smart Throttling**: Prevents overwhelming the AI service
/// - **Error Recovery**: Automatic retry with exponential backoff
/// 
/// ## Usage Example
/// ```dart
/// final processor = BackgroundAIProcessor();
/// await processor.initialize();
/// 
/// // Queue single entry for analysis
/// processor.queueEntryAnalysis(
///   entry,
///   priority: ProcessingPriority.high,
///   onProgress: (progress) => debugPrint('Progress: $progress%'),
///   onComplete: (result) => debugPrint('Analysis complete'),
/// );
/// 
/// // Queue batch analysis
/// processor.queueBatchAnalysis(
///   entries,
///   onBatchProgress: (completed, total) => debugPrint('$completed/$total'),
/// );
/// ```
class BackgroundAIProcessor {
  static final BackgroundAIProcessor _instance = BackgroundAIProcessor._internal();
  factory BackgroundAIProcessor() => _instance;
  BackgroundAIProcessor._internal();

  // Configuration
  static const int _maxConcurrentOperations = 3;
  static const int _maxQueueSize = 100;
  static const Duration _processingInterval = Duration(milliseconds: 500);
  static const Duration _throttleDelay = Duration(milliseconds: 200);
  static const int _maxRetries = 3;

  // Processing queue
  final Queue<_ProcessingTask> _processingQueue = Queue<_ProcessingTask>();
  final Set<String> _processingEntries = <String>{};
  
  // State management
  bool _isProcessing = false;
  bool _isInitialized = false;
  Timer? _processingTimer;
  int _activeOperations = 0;
  
  // Dependencies
  AIServiceManager? _aiServiceManager;
  JournalService? _journalService;
  
  // Progress tracking
  final Map<String, double> _progressMap = <String, double>{};
  final StreamController<ProcessingProgress> _progressController = 
      StreamController<ProcessingProgress>.broadcast();
  
  // Performance metrics
  int _totalProcessed = 0;
  int _totalErrors = 0;
  int _totalRetries = 0;
  
  // Getters
  bool get isProcessing => _isProcessing;
  int get queueLength => _processingQueue.length;
  int get activeOperations => _activeOperations;
  Stream<ProcessingProgress> get progressStream => _progressController.stream;
  
  Map<String, dynamic> get performanceMetrics => {
    'totalProcessed': _totalProcessed,
    'totalErrors': _totalErrors,
    'totalRetries': _totalRetries,
    'queueLength': queueLength,
    'activeOperations': activeOperations,
    'successRate': _totalProcessed > 0 ? 
        (_totalProcessed - _totalErrors) / _totalProcessed : 0.0,
  };

  /// Initialize the background processor
  Future<void> initialize({
    AIServiceManager? aiServiceManager,
    JournalService? journalService,
  }) async {
    if (_isInitialized) return;
    
    _aiServiceManager = aiServiceManager ?? AIServiceManager();
    _journalService = journalService ?? JournalService();
    
    // Start processing timer
    _processingTimer = Timer.periodic(_processingInterval, (_) => _processQueue());
    
    _isInitialized = true;
    
    if (kDebugMode) {
      debugPrint('BackgroundAIProcessor initialized');
    }
  }

  /// Queue a single entry for AI analysis
  Future<void> queueEntryAnalysis(
    JournalEntry entry, {
    ProcessingPriority priority = ProcessingPriority.normal,
    Function(double progress)? onProgress,
    Function(Map<String, dynamic> result)? onComplete,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      throw StateError('BackgroundAIProcessor not initialized');
    }
    
    // Check if already processing this entry
    if (_processingEntries.contains(entry.id)) {
      if (kDebugMode) {
        debugPrint('Entry ${entry.id} already in processing queue');
      }
      return;
    }
    
    // Check queue size limit
    if (_processingQueue.length >= _maxQueueSize) {
      // Remove oldest low-priority task
      _removeOldestLowPriorityTask();
    }
    
    final task = _ProcessingTask(
      id: entry.id,
      type: ProcessingType.singleEntry,
      priority: priority,
      entry: entry,
      onProgress: onProgress,
      onComplete: onComplete,
      onError: onError,
      createdAt: DateTime.now(),
    );
    
    _addTaskToQueue(task);
    _processingEntries.add(entry.id);
    
    if (kDebugMode) {
      debugPrint('Queued entry ${entry.id} for analysis (priority: ${priority.name})');
    }
  }

  /// Queue multiple entries for batch analysis
  Future<void> queueBatchAnalysis(
    List<JournalEntry> entries, {
    ProcessingPriority priority = ProcessingPriority.normal,
    Function(int completed, int total)? onBatchProgress,
    Function(List<Map<String, dynamic>> results)? onBatchComplete,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      throw StateError('BackgroundAIProcessor not initialized');
    }
    
    if (entries.isEmpty) return;
    
    // Filter out entries already being processed
    final filteredEntries = entries
        .where((entry) => !_processingEntries.contains(entry.id))
        .toList();
    
    if (filteredEntries.isEmpty) {
      if (kDebugMode) {
        debugPrint('All entries in batch are already being processed');
      }
      return;
    }
    
    final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
    
    final task = _ProcessingTask(
      id: batchId,
      type: ProcessingType.batch,
      priority: priority,
      entries: filteredEntries,
      onBatchProgress: onBatchProgress,
      onBatchComplete: onBatchComplete,
      onError: onError,
      createdAt: DateTime.now(),
    );
    
    _addTaskToQueue(task);
    
    // Mark all entries as being processed
    for (final entry in filteredEntries) {
      _processingEntries.add(entry.id);
    }
    
    if (kDebugMode) {
      debugPrint('Queued batch of ${filteredEntries.length} entries for analysis');
    }
  }

  /// Queue core updates for an entry
  Future<void> queueCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores, {
    ProcessingPriority priority = ProcessingPriority.normal,
    Function(List<EmotionalCore> updatedCores)? onComplete,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      throw StateError('BackgroundAIProcessor not initialized');
    }
    
    final taskId = 'cores_${entry.id}';
    
    final task = _ProcessingTask(
      id: taskId,
      type: ProcessingType.coreUpdates,
      priority: priority,
      entry: entry,
      cores: currentCores,
      onCoreUpdatesComplete: onComplete,
      onError: onError,
      createdAt: DateTime.now(),
    );
    
    _addTaskToQueue(task);
    
    if (kDebugMode) {
      debugPrint('Queued core updates for entry ${entry.id}');
    }
  }

  /// Cancel processing for a specific entry
  void cancelEntryProcessing(String entryId) {
    // Remove from queue
    _processingQueue.removeWhere((task) => 
        task.entry?.id == entryId || task.id == entryId);
    
    // Remove from processing set
    _processingEntries.remove(entryId);
    
    if (kDebugMode) {
      debugPrint('Cancelled processing for entry $entryId');
    }
  }

  /// Clear all queued tasks
  void clearQueue() {
    _processingQueue.clear();
    _processingEntries.clear();
    _progressMap.clear();
    
    if (kDebugMode) {
      debugPrint('Processing queue cleared');
    }
  }

  /// Pause processing
  void pauseProcessing() {
    _isProcessing = false;
    if (kDebugMode) {
      debugPrint('Processing paused');
    }
  }

  /// Resume processing
  void resumeProcessing() {
    _isProcessing = true;
    if (kDebugMode) {
      debugPrint('Processing resumed');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    _processingTimer?.cancel();
    _isProcessing = false;
    
    // Wait for active operations to complete
    while (_activeOperations > 0) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    clearQueue();
    await _progressController.close();
    
    _isInitialized = false;
    
    if (kDebugMode) {
      debugPrint('BackgroundAIProcessor disposed');
    }
  }

  // Private methods

  void _addTaskToQueue(_ProcessingTask task) {
    // Insert based on priority
    if (task.priority == ProcessingPriority.high) {
      // Add high priority tasks to the front
      final highPriorityTasks = <_ProcessingTask>[];
      final otherTasks = <_ProcessingTask>[];
      
      while (_processingQueue.isNotEmpty) {
        final existingTask = _processingQueue.removeFirst();
        if (existingTask.priority == ProcessingPriority.high) {
          highPriorityTasks.add(existingTask);
        } else {
          otherTasks.add(existingTask);
        }
      }
      
      // Re-add in order: existing high priority, new task, others
      for (final t in highPriorityTasks) {
        _processingQueue.add(t);
      }
      _processingQueue.add(task);
      for (final t in otherTasks) {
        _processingQueue.add(t);
      }
    } else {
      _processingQueue.add(task);
    }
  }

  void _removeOldestLowPriorityTask() {
    // Find and remove the oldest low-priority task
    _ProcessingTask? oldestLowPriority;
    
    for (final task in _processingQueue) {
      if (task.priority == ProcessingPriority.low) {
        if (oldestLowPriority == null || 
            task.createdAt.isBefore(oldestLowPriority.createdAt)) {
          oldestLowPriority = task;
        }
      }
    }
    
    if (oldestLowPriority != null) {
      _processingQueue.remove(oldestLowPriority);
      if (oldestLowPriority.entry != null) {
        _processingEntries.remove(oldestLowPriority.entry!.id);
      }
    }
  }

  Future<void> _processQueue() async {
    if (!_isProcessing || 
        _processingQueue.isEmpty || 
        _activeOperations >= _maxConcurrentOperations) {
      return;
    }
    
    final task = _processingQueue.removeFirst();
    _activeOperations++;
    
    // Process task in background
    _processTask(task).then((_) {
      _activeOperations--;
    }).catchError((error) {
      _activeOperations--;
      if (kDebugMode) {
        debugPrint('Error processing task ${task.id}: $error');
      }
    });
  }

  Future<void> _processTask(_ProcessingTask task) async {
    try {
      switch (task.type) {
        case ProcessingType.singleEntry:
          await _processSingleEntry(task);
          break;
        case ProcessingType.batch:
          await _processBatch(task);
          break;
        case ProcessingType.coreUpdates:
          await _processCoreUpdates(task);
          break;
      }
      
      _totalProcessed++;
    } catch (error) {
      _totalErrors++;
      
      // Retry logic
      if (task.retryCount < _maxRetries) {
        task.retryCount++;
        _totalRetries++;
        
        // Exponential backoff
        final delay = Duration(
          milliseconds: 1000 * (1 << (task.retryCount - 1))
        );
        
        Timer(delay, () {
          _addTaskToQueue(task);
        });
        
        if (kDebugMode) {
          debugPrint('Retrying task ${task.id} (attempt ${task.retryCount})');
        }
      } else {
        // Max retries reached, call error callback
        task.onError?.call(error.toString());
        
        // Remove from processing set
        if (task.entry != null) {
          _processingEntries.remove(task.entry!.id);
        }
        if (task.entries != null) {
          for (final entry in task.entries!) {
            _processingEntries.remove(entry.id);
          }
        }
      }
    }
  }

  Future<void> _processSingleEntry(_ProcessingTask task) async {
    if (task.entry == null || _aiServiceManager == null) return;
    
    final entry = task.entry!;
    
    // Update progress
    task.onProgress?.call(0.0);
    _updateProgress(task.id, 0.0);
    
    // Throttle to prevent overwhelming the AI service
    await Future.delayed(_throttleDelay);
    
    // Perform AI analysis
    task.onProgress?.call(50.0);
    _updateProgress(task.id, 50.0);
    
    final result = await _aiServiceManager!.analyzeJournalEntry(entry);
    
    task.onProgress?.call(100.0);
    _updateProgress(task.id, 100.0);
    
    // Update entry with analysis if journal service is available
    if (_journalService != null) {
      await _journalService!.updateEntryWithAnalysis(entry.id, result);
    }
    
    // Call completion callback
    task.onComplete?.call(result);
    
    // Remove from processing set
    _processingEntries.remove(entry.id);
    _progressMap.remove(task.id);
  }

  Future<void> _processBatch(_ProcessingTask task) async {
    if (task.entries == null || _aiServiceManager == null) return;
    
    final entries = task.entries!;
    final results = <Map<String, dynamic>>[];
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      
      // Update batch progress
      final progress = (i / entries.length) * 100;
      task.onBatchProgress?.call(i, entries.length);
      _updateProgress(task.id, progress);
      
      try {
        // Throttle between entries
        if (i > 0) {
          await Future.delayed(_throttleDelay);
        }
        
        final result = await _aiServiceManager!.analyzeJournalEntry(entry);
        results.add(result);
        
        // Update entry with analysis
        if (_journalService != null) {
          await _journalService!.updateEntryWithAnalysis(entry.id, result);
        }
        
        // Remove from processing set
        _processingEntries.remove(entry.id);
        
      } catch (error) {
        // Continue with other entries even if one fails
        results.add({'error': error.toString()});
        _processingEntries.remove(entry.id);
      }
    }
    
    // Final progress update
    task.onBatchProgress?.call(entries.length, entries.length);
    _updateProgress(task.id, 100.0);
    
    // Call completion callback
    task.onBatchComplete?.call(results);
    
    _progressMap.remove(task.id);
  }

  Future<void> _processCoreUpdates(_ProcessingTask task) async {
    if (task.entry == null || task.cores == null || _aiServiceManager == null) {
      return;
    }
    
    final entry = task.entry!;
    final currentCores = task.cores!;
    
    try {
      final updatedCores = await _aiServiceManager!.updateEmotionalCores(
        currentCores,
        entry,
      );
      
      task.onCoreUpdatesComplete?.call(updatedCores);
    } catch (error) {
      task.onError?.call(error.toString());
    }
  }

  void _updateProgress(String taskId, double progress) {
    _progressMap[taskId] = progress;
    
    _progressController.add(ProcessingProgress(
      taskId: taskId,
      progress: progress,
      timestamp: DateTime.now(),
    ));
  }
}

/// Processing task priority levels
enum ProcessingPriority {
  low,
  normal,
  high,
}

/// Processing task types
enum ProcessingType {
  singleEntry,
  batch,
  coreUpdates,
}

/// Processing progress information
class ProcessingProgress {
  final String taskId;
  final double progress;
  final DateTime timestamp;
  
  ProcessingProgress({
    required this.taskId,
    required this.progress,
    required this.timestamp,
  });
}

/// Internal processing task representation
class _ProcessingTask {
  final String id;
  final ProcessingType type;
  final ProcessingPriority priority;
  final DateTime createdAt;
  
  // Task data
  final JournalEntry? entry;
  final List<JournalEntry>? entries;
  final List<EmotionalCore>? cores;
  
  // Callbacks
  final Function(double progress)? onProgress;
  final Function(Map<String, dynamic> result)? onComplete;
  final Function(int completed, int total)? onBatchProgress;
  final Function(List<Map<String, dynamic>> results)? onBatchComplete;
  final Function(List<EmotionalCore> updatedCores)? onCoreUpdatesComplete;
  final Function(String error)? onError;
  
  // Retry tracking
  int retryCount = 0;
  
  _ProcessingTask({
    required this.id,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.entry,
    this.entries,
    this.cores,
    this.onProgress,
    this.onComplete,
    this.onBatchProgress,
    this.onBatchComplete,
    this.onCoreUpdatesComplete,
    this.onError,
  });
}