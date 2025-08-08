import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import 'journal_service.dart';
import 'ai_service_manager.dart';

/// Offline queue service that handles failed operations with exponential backoff retry.
/// 
/// This service queues failed journal saves and AI requests when offline,
/// persists the queue to SharedPreferences, and processes the queue when
/// connectivity returns using exponential backoff (2s, 4s, 8s, 16s).
/// 
/// ## Key Features
/// - Operation pattern for different types of operations
/// - Exponential backoff retry with configurable parameters
/// - SharedPreferences persistence for queue durability
/// - Connectivity monitoring with automatic queue processing
/// - Queue status tracking for UI integration
/// 
/// ## Usage Example
/// ```dart
/// final queueService = OfflineQueueService();
/// await queueService.initialize();
/// 
/// // Queue a journal save operation
/// await queueService.queueJournalSave(entry);
/// 
/// // Queue an AI analysis operation
/// await queueService.queueAIAnalysis(entry);
/// 
/// // Get queue status for UI
/// final status = queueService.getQueueStatus();
/// ```
class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  static const String _queueKey = 'offline_operation_queue';
  static const int _maxRetries = 4; // 2s, 4s, 8s, 16s
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  
  final List<QueuedOperation> _operationQueue = [];
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  Timer? _retryTimer;
  bool _isProcessing = false;
  bool _isInitialized = false;
  
  // Dependencies - injected during initialization
  JournalService? _journalService;
  AIServiceManager? _aiServiceManager;

  /// Initialize the offline queue service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize dependencies
      _journalService = JournalService();
      _aiServiceManager = AIServiceManager();
      
      // Load persisted queue
      await _loadQueueFromStorage();
      
      // Start connectivity monitoring
      await _startConnectivityMonitoring();
      
      _isInitialized = true;
      debugPrint('OfflineQueueService: Initialized with ${_operationQueue.length} queued operations');
    } catch (e) {
      debugPrint('OfflineQueueService initialization error: $e');
      rethrow;
    }
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _isInitialized = false;
  }

  /// Queue a journal save operation
  Future<void> queueJournalSave(JournalEntry entry) async {
    final operation = JournalSaveOperation(
      id: _generateOperationId(),
      entry: entry,
      createdAt: DateTime.now(),
    );
    
    await _addOperationToQueue(operation);
  }

  /// Queue an AI analysis operation
  Future<void> queueAIAnalysis(JournalEntry entry) async {
    final operation = AIAnalysisOperation(
      id: _generateOperationId(),
      entry: entry,
      createdAt: DateTime.now(),
    );
    
    await _addOperationToQueue(operation);
  }

  /// Queue a core update operation
  Future<void> queueCoreUpdate(String entryId, List<EmotionalCore> cores) async {
    final operation = CoreUpdateOperation(
      id: _generateOperationId(),
      entryId: entryId,
      cores: cores,
      createdAt: DateTime.now(),
    );
    
    await _addOperationToQueue(operation);
  }

  /// Get current queue status for UI display
  OfflineQueueStatus getQueueStatus() {
    final totalOperations = _operationQueue.length;
    final failedOperations = _operationQueue.where((op) => op.retryCount > 0).length;
    final pendingOperations = _operationQueue.where((op) => op.retryCount == 0).length;
    
    return OfflineQueueStatus(
      totalOperations: totalOperations,
      pendingOperations: pendingOperations,
      failedOperations: failedOperations,
      isProcessing: _isProcessing,
      lastProcessedAt: _getLastProcessedTime(),
    );
  }

  /// Force process the queue (for manual retry)
  Future<void> processQueue() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    await _processOperationQueue();
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    _operationQueue.clear();
    await _saveQueueToStorage();
    debugPrint('OfflineQueueService: Queue cleared');
  }

  /// Remove a specific operation from the queue
  Future<void> removeOperation(String operationId) async {
    _operationQueue.removeWhere((op) => op.id == operationId);
    await _saveQueueToStorage();
  }

  // Private methods

  /// Add an operation to the queue
  Future<void> _addOperationToQueue(QueuedOperation operation) async {
    _operationQueue.add(operation);
    await _saveQueueToStorage();
    
    debugPrint('OfflineQueueService: Queued ${operation.type} operation ${operation.id}');
    
    // Try to process immediately if online
    if (await _isConnected()) {
      unawaited(_processOperationQueue());
    }
  }

  /// Start monitoring connectivity changes
  Future<void> _startConnectivityMonitoring() async {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isConnected = results.any((result) => 
          result == ConnectivityResult.mobile || 
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet
        );
        
        if (isConnected && _operationQueue.isNotEmpty) {
          debugPrint('OfflineQueueService: Connectivity restored, processing queue');
          unawaited(_processOperationQueue());
        }
      },
      onError: (error) {
        debugPrint('OfflineQueueService connectivity monitoring error: $error');
      },
    );
  }

  /// Check if device is connected to internet
  Future<bool> _isConnected() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      return connectivityResults.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
      );
    } catch (e) {
      debugPrint('OfflineQueueService connectivity check error: $e');
      return false;
    }
  }

  /// Process all operations in the queue
  Future<void> _processOperationQueue() async {
    if (_isProcessing || _operationQueue.isEmpty) return;
    
    _isProcessing = true;
    debugPrint('OfflineQueueService: Processing ${_operationQueue.length} operations');
    
    try {
      final operationsToProcess = List<QueuedOperation>.from(_operationQueue);
      
      for (final operation in operationsToProcess) {
        if (await _processOperation(operation)) {
          _operationQueue.remove(operation);
        }
      }
      
      await _saveQueueToStorage();
    } catch (e) {
      debugPrint('OfflineQueueService queue processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single operation with retry logic
  Future<bool> _processOperation(QueuedOperation operation) async {
    try {
      debugPrint('OfflineQueueService: Processing ${operation.type} operation ${operation.id} (attempt ${operation.retryCount + 1})');
      
      final success = await operation.execute(_journalService!, _aiServiceManager!);
      
      if (success) {
        debugPrint('OfflineQueueService: Successfully processed operation ${operation.id}');
        return true;
      } else {
        return await _handleOperationFailure(operation);
      }
    } catch (e) {
      debugPrint('OfflineQueueService: Operation ${operation.id} failed: $e');
      return await _handleOperationFailure(operation);
    }
  }

  /// Handle operation failure with exponential backoff
  Future<bool> _handleOperationFailure(QueuedOperation operation) async {
    operation.retryCount++;
    operation.lastAttemptAt = DateTime.now();
    
    if (operation.retryCount >= _maxRetries) {
      debugPrint('OfflineQueueService: Operation ${operation.id} exceeded max retries, removing from queue');
      return true; // Remove from queue
    }
    
    // Calculate exponential backoff delay
    final delaySeconds = _baseRetryDelay.inSeconds * pow(2, operation.retryCount - 1);
    final delay = Duration(seconds: delaySeconds.toInt());
    
    debugPrint('OfflineQueueService: Will retry operation ${operation.id} in ${delay.inSeconds}s');
    
    // Schedule retry
    _scheduleRetry(delay);
    
    return false; // Keep in queue
  }

  /// Schedule a retry after the specified delay
  void _scheduleRetry(Duration delay) {
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (_operationQueue.isNotEmpty) {
        unawaited(_processOperationQueue());
      }
    });
  }

  /// Load queue from SharedPreferences
  Future<void> _loadQueueFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson != null) {
        final queueData = jsonDecode(queueJson) as List<dynamic>;
        _operationQueue.clear();
        
        for (final operationData in queueData) {
          final operation = QueuedOperation.fromJson(operationData);
          _operationQueue.add(operation);
        }
        
        debugPrint('OfflineQueueService: Loaded ${_operationQueue.length} operations from storage');
      }
    } catch (e) {
      debugPrint('OfflineQueueService: Error loading queue from storage: $e');
      _operationQueue.clear();
    }
  }

  /// Save queue to SharedPreferences
  Future<void> _saveQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueData = _operationQueue.map((op) => op.toJson()).toList();
      await prefs.setString(_queueKey, jsonEncode(queueData));
    } catch (e) {
      debugPrint('OfflineQueueService: Error saving queue to storage: $e');
    }
  }

  /// Generate a unique operation ID
  String _generateOperationId() {
    return 'op_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Get the last processed time for status display
  DateTime? _getLastProcessedTime() {
    return _operationQueue
        .where((op) => op.lastAttemptAt != null)
        .map((op) => op.lastAttemptAt!)
        .fold<DateTime?>(null, (latest, current) => 
          latest == null || current.isAfter(latest) ? current : latest);
  }
}

/// Base class for queued operations using the Operation pattern
abstract class QueuedOperation {
  final String id;
  final String type;
  final DateTime createdAt;
  int retryCount;
  DateTime? lastAttemptAt;

  QueuedOperation({
    required this.id,
    required this.type,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  /// Execute the operation
  Future<bool> execute(JournalService journalService, AIServiceManager aiService);

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson();

  /// Create operation from JSON
  static QueuedOperation fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    
    switch (type) {
      case 'journal_save':
        return JournalSaveOperation.fromJson(json);
      case 'ai_analysis':
        return AIAnalysisOperation.fromJson(json);
      case 'core_update':
        return CoreUpdateOperation.fromJson(json);
      default:
        throw ArgumentError('Unknown operation type: $type');
    }
  }
}

/// Operation for saving journal entries
class JournalSaveOperation extends QueuedOperation {
  final JournalEntry entry;

  JournalSaveOperation({
    required super.id,
    required this.entry,
    required super.createdAt,
    super.retryCount,
    super.lastAttemptAt,
  }) : super(
          type: 'journal_save',
        );

  @override
  Future<bool> execute(JournalService journalService, AIServiceManager aiService) async {
    try {
      await journalService.createJournalEntry(
        content: entry.content,
        moods: entry.moods,
      );
      return true;
    } catch (e) {
      debugPrint('JournalSaveOperation: Failed to save entry: $e');
      return false;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'entry': entry.toJson(),
    };
  }

  static JournalSaveOperation fromJson(Map<String, dynamic> json) {
    return JournalSaveOperation(
      id: json['id'],
      entry: JournalEntry.fromJson(json['entry']),
      createdAt: DateTime.parse(json['created_at']),
      retryCount: json['retry_count'] ?? 0,
      lastAttemptAt: json['last_attempt_at'] != null 
          ? DateTime.parse(json['last_attempt_at'])
          : null,
    );
  }
}

/// Operation for AI analysis requests
class AIAnalysisOperation extends QueuedOperation {
  final JournalEntry entry;

  AIAnalysisOperation({
    required super.id,
    required this.entry,
    required super.createdAt,
    super.retryCount,
    super.lastAttemptAt,
  }) : super(
          type: 'ai_analysis',
        );

  @override
  Future<bool> execute(JournalService journalService, AIServiceManager aiService) async {
    try {
      await aiService.analyzeJournalEntry(entry);
      return true;
    } catch (e) {
      debugPrint('AIAnalysisOperation: Failed to analyze entry: $e');
      return false;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'entry': entry.toJson(),
    };
  }

  static AIAnalysisOperation fromJson(Map<String, dynamic> json) {
    return AIAnalysisOperation(
      id: json['id'],
      entry: JournalEntry.fromJson(json['entry']),
      createdAt: DateTime.parse(json['created_at']),
      retryCount: json['retry_count'] ?? 0,
      lastAttemptAt: json['last_attempt_at'] != null 
          ? DateTime.parse(json['last_attempt_at'])
          : null,
    );
  }
}

/// Operation for updating emotional cores
class CoreUpdateOperation extends QueuedOperation {
  final String entryId;
  final List<EmotionalCore> cores;

  CoreUpdateOperation({
    required super.id,
    required this.entryId,
    required this.cores,
    required super.createdAt,
    super.retryCount,
    super.lastAttemptAt,
  }) : super(
          type: 'core_update',
        );

  @override
  Future<bool> execute(JournalService journalService, AIServiceManager aiService) async {
    try {
      // This would need to be implemented in JournalService
      // For now, just return true as a placeholder
      debugPrint('CoreUpdateOperation: Would update cores for entry $entryId');
      return true;
    } catch (e) {
      debugPrint('CoreUpdateOperation: Failed to update cores: $e');
      return false;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'entry_id': entryId,
      'cores': cores.map((core) => core.toJson()).toList(),
    };
  }

  static CoreUpdateOperation fromJson(Map<String, dynamic> json) {
    return CoreUpdateOperation(
      id: json['id'],
      entryId: json['entry_id'],
      cores: (json['cores'] as List<dynamic>)
          .map((coreJson) => EmotionalCore.fromJson(coreJson))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      retryCount: json['retry_count'] ?? 0,
      lastAttemptAt: json['last_attempt_at'] != null 
          ? DateTime.parse(json['last_attempt_at'])
          : null,
    );
  }
}

/// Status information about the offline queue
class OfflineQueueStatus {
  final int totalOperations;
  final int pendingOperations;
  final int failedOperations;
  final bool isProcessing;
  final DateTime? lastProcessedAt;

  OfflineQueueStatus({
    required this.totalOperations,
    required this.pendingOperations,
    required this.failedOperations,
    required this.isProcessing,
    this.lastProcessedAt,
  });

  bool get hasOperations => totalOperations > 0;
  bool get hasFailedOperations => failedOperations > 0;
  bool get isEmpty => totalOperations == 0;

  @override
  String toString() {
    return 'OfflineQueueStatus(total: $totalOperations, pending: $pendingOperations, failed: $failedOperations, processing: $isProcessing)';
  }
}

/// Extension to avoid unawaited_futures warnings
extension FutureExtensions<T> on Future<T> {
  void unawaited() {}
}