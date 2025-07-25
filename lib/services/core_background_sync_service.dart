import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/core.dart';
import 'core_library_service.dart';
import 'core_cache_manager.dart';

/// Background synchronization service for core updates with conflict resolution
class CoreBackgroundSyncService {
  static final CoreBackgroundSyncService _instance = CoreBackgroundSyncService._internal();
  factory CoreBackgroundSyncService() => _instance;
  CoreBackgroundSyncService._internal();

  final CoreLibraryService _coreLibraryService = CoreLibraryService();
  final CoreCacheManager _cacheManager = CoreCacheManager();

  // Sync configuration
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _maxBackoffDelay = Duration(minutes: 30);
  static const int _maxRetryAttempts = 5;
  static const int _maxQueueSize = 100;

  // Sync state
  Timer? _syncTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastSuccessfulSync;
  int _consecutiveFailures = 0;

  // Update queue for offline operations
  final List<QueuedUpdate> _updateQueue = [];
  final StreamController<SyncEvent> _syncEventController = StreamController<SyncEvent>.broadcast();

  // Conflict resolution
  final Map<String, List<EmotionalCore>> _conflictBuffer = {};

  /// Initialize the background sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _cacheManager.initialize();
      _startPeriodicSync();
      _isInitialized = true;
      
      debugPrint('CoreBackgroundSyncService: Initialized successfully');
      
      // Process any queued updates from previous session
      await _processQueuedUpdates();
      
      _broadcastSyncEvent(SyncEvent(
        type: SyncEventType.initialized,
        timestamp: DateTime.now(),
        data: {'queueSize': _updateQueue.length},
      ));
    } catch (e) {
      debugPrint('CoreBackgroundSyncService: Initialization failed: $e');
      _broadcastSyncEvent(SyncEvent(
        type: SyncEventType.error,
        timestamp: DateTime.now(),
        error: e.toString(),
      ));
    }
  }

  /// Get sync event stream
  Stream<SyncEvent> get syncEventStream => _syncEventController.stream;

  /// Queue an update for background synchronization
  Future<void> queueUpdate(QueuedUpdate update) async {
    try {
      // Check queue size limit
      if (_updateQueue.length >= _maxQueueSize) {
        // Remove oldest updates to make room
        _updateQueue.removeRange(0, _updateQueue.length - _maxQueueSize + 1);
        debugPrint('CoreBackgroundSyncService: Queue size limit reached, removed old updates');
      }

      _updateQueue.add(update);
      
      debugPrint('CoreBackgroundSyncService: Queued update for core ${update.coreId}');
      
      _broadcastSyncEvent(SyncEvent(
        type: SyncEventType.updateQueued,
        timestamp: DateTime.now(),
        data: {
          'coreId': update.coreId,
          'queueSize': _updateQueue.length,
        },
      ));

      // Try to process immediately if online
      if (!_isSyncing) {
        await _processQueuedUpdates();
      }
    } catch (e) {
      debugPrint('CoreBackgroundSyncService: Error queuing update: $e');
    }
  }

  /// Force a sync operation
  Future<bool> forceSync() async {
    if (_isSyncing) {
      debugPrint('CoreBackgroundSyncService: Sync already in progress');
      return false;
    }

    return await _performSync(isManual: true);
  }

  /// Check if sync is currently active
  bool get isSyncing => _isSyncing;

  /// Get last successful sync time
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;

  /// Get current queue size
  int get queueSize => _updateQueue.length;

  /// Get sync statistics
  SyncStatistics getSyncStatistics() {
    return SyncStatistics(
      lastSuccessfulSync: _lastSuccessfulSync,
      consecutiveFailures: _consecutiveFailures,
      queueSize: _updateQueue.length,
      isActive: _isSyncing,
      nextSyncEstimate: _getNextSyncEstimate(),
    );
  }

  // Private methods

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    
    final interval = _calculateSyncInterval();
    _syncTimer = Timer.periodic(interval, (_) async {
      if (!_isSyncing) {
        await _performSync();
      }
    });
    
    debugPrint('CoreBackgroundSyncService: Started periodic sync with ${interval.inMinutes}min interval');
  }

  Duration _calculateSyncInterval() {
    // Use exponential backoff for failed syncs
    if (_consecutiveFailures > 0) {
      final backoffMultiplier = min(pow(2, _consecutiveFailures), 16).toInt();
      final backoffInterval = Duration(minutes: _syncInterval.inMinutes * backoffMultiplier);
      return backoffInterval.compareTo(_maxBackoffDelay) > 0 ? _maxBackoffDelay : backoffInterval;
    }
    
    return _syncInterval;
  }

  DateTime _getNextSyncEstimate() {
    final interval = _calculateSyncInterval();
    final lastAttempt = _lastSuccessfulSync ?? DateTime.now();
    return lastAttempt.add(interval);
  }

  Future<bool> _performSync({bool isManual = false}) async {
    if (_isSyncing) return false;

    _isSyncing = true;
    
    try {
      debugPrint('CoreBackgroundSyncService: Starting sync (manual: $isManual)');
      
      _broadcastSyncEvent(SyncEvent(
        type: SyncEventType.syncStarted,
        timestamp: DateTime.now(),
        data: {'isManual': isManual, 'queueSize': _updateQueue.length},
      ));

      // Process queued updates first
      await _processQueuedUpdates();

      // Check for remote updates
      final hasRemoteUpdates = await _coreLibraryService.hasUpdates();
      if (hasRemoteUpdates) {
        await _syncRemoteUpdates();
      }

      // Resolve any conflicts
      await _resolveConflicts();

      _lastSuccessfulSync = DateTime.now();
      _consecutiveFailures = 0;
      
      // Restart timer with normal interval
      if (!isManual) {
        _startPeriodicSync();
      }

      debugPrint('CoreBackgroundSyncService: Sync completed successfully');
      
      _broadcastSyncEvent(SyncEvent(
        type: SyncEventType.syncCompleted,
        timestamp: DateTime.now(),
        data: {'duration': DateTime.now().difference(_lastSuccessfulSync!).inMilliseconds},
      ));

      return true;
    } catch (e) {
      _consecutiveFailures++;
      
      debugPrint('CoreBackgroundSyncService: Sync failed (attempt $_consecutiveFailures): $e');
      
      _broadcastSyncEvent(SyncEvent(
        type: SyncEventType.syncFailed,
        timestamp: DateTime.now(),
        error: e.toString(),
        data: {'consecutiveFailures': _consecutiveFailures},
      ));

      // Restart timer with backoff
      _startPeriodicSync();
      
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processQueuedUpdates() async {
    if (_updateQueue.isEmpty) return;

    final updates = List<QueuedUpdate>.from(_updateQueue);
    _updateQueue.clear();

    debugPrint('CoreBackgroundSyncService: Processing ${updates.length} queued updates');

    for (final update in updates) {
      try {
        await _processUpdate(update);
      } catch (e) {
        debugPrint('CoreBackgroundSyncService: Failed to process update for ${update.coreId}: $e');
        
        // Re-queue failed updates with retry limit
        if (update.retryCount < _maxRetryAttempts) {
          final retriedUpdate = update.copyWith(
            retryCount: update.retryCount + 1,
            lastAttempt: DateTime.now(),
          );
          _updateQueue.add(retriedUpdate);
        } else {
          debugPrint('CoreBackgroundSyncService: Max retries exceeded for update ${update.id}');
          
          _broadcastSyncEvent(SyncEvent(
            type: SyncEventType.updateFailed,
            timestamp: DateTime.now(),
            error: 'Max retries exceeded',
            data: {'updateId': update.id, 'coreId': update.coreId},
          ));
        }
      }
    }
  }

  Future<void> _processUpdate(QueuedUpdate update) async {
    switch (update.type) {
      case UpdateType.coreUpdate:
        await _coreLibraryService.updateCore(update.core!);
        break;
      case UpdateType.batchUpdate:
        if (update.cores != null) {
          for (final core in update.cores!) {
            await _coreLibraryService.updateCore(core);
          }
        }
        break;
      case UpdateType.contextUpdate:
        // Handle context updates if needed
        break;
    }

    debugPrint('CoreBackgroundSyncService: Successfully processed ${update.type} for ${update.coreId}');
  }

  Future<void> _syncRemoteUpdates() async {
    try {
      final remoteCores = await _coreLibraryService.getAllCores();
      
      // Update cache with fresh data
      for (final core in remoteCores) {
        await _cacheManager.cacheCore(core);
      }
      
      debugPrint('CoreBackgroundSyncService: Synced ${remoteCores.length} remote updates');
    } catch (e) {
      debugPrint('CoreBackgroundSyncService: Failed to sync remote updates: $e');
      rethrow;
    }
  }

  Future<void> _resolveConflicts() async {
    if (_conflictBuffer.isEmpty) return;

    debugPrint('CoreBackgroundSyncService: Resolving ${_conflictBuffer.length} conflicts');

    for (final entry in _conflictBuffer.entries) {
      final coreId = entry.key;
      final conflictingCores = entry.value;
      
      try {
        final resolvedCore = await _resolveConflict(coreId, conflictingCores);
        if (resolvedCore != null) {
          await _coreLibraryService.updateCore(resolvedCore);
          await _cacheManager.cacheCore(resolvedCore);
          
          debugPrint('CoreBackgroundSyncService: Resolved conflict for core $coreId');
        }
      } catch (e) {
        debugPrint('CoreBackgroundSyncService: Failed to resolve conflict for core $coreId: $e');
      }
    }
    
    _conflictBuffer.clear();
  }

  Future<EmotionalCore?> _resolveConflict(String coreId, List<EmotionalCore> conflictingCores) async {
    if (conflictingCores.isEmpty) return null;
    if (conflictingCores.length == 1) return conflictingCores.first;

    // Conflict resolution strategy: Latest timestamp wins
    conflictingCores.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    final latestCore = conflictingCores.first;

    // Merge insights from all versions
    final allInsights = <CoreInsight>[];
    for (final core in conflictingCores) {
      allInsights.addAll(core.recentInsights);
    }
    
    // Remove duplicates and sort by relevance
    final uniqueInsights = <String, CoreInsight>{};
    for (final insight in allInsights) {
      final existing = uniqueInsights[insight.id];
      if (existing == null || insight.relevanceScore > existing.relevanceScore) {
        uniqueInsights[insight.id] = insight;
      }
    }
    
    final mergedInsights = uniqueInsights.values.toList()
      ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return latestCore.copyWith(
      recentInsights: mergedInsights.take(5).toList(),
    );
  }

  void _broadcastSyncEvent(SyncEvent event) {
    _syncEventController.add(event);
  }

  /// Add a conflict to the buffer for resolution
  void addConflict(String coreId, List<EmotionalCore> conflictingCores) {
    _conflictBuffer[coreId] = conflictingCores;
    
    _broadcastSyncEvent(SyncEvent(
      type: SyncEventType.conflictDetected,
      timestamp: DateTime.now(),
      data: {
        'coreId': coreId,
        'conflictCount': conflictingCores.length,
      },
    ));
  }

  /// Stop the background sync service
  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isInitialized = false;
    
    debugPrint('CoreBackgroundSyncService: Stopped');
  }

  /// Dispose resources
  void dispose() {
    stop();
    _syncEventController.close();
  }
}

/// Queued update for offline operations
class QueuedUpdate {
  final String id;
  final String coreId;
  final UpdateType type;
  final EmotionalCore? core;
  final List<EmotionalCore>? cores;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? lastAttempt;
  final int retryCount;

  QueuedUpdate({
    required this.id,
    required this.coreId,
    required this.type,
    this.core,
    this.cores,
    this.metadata,
    DateTime? createdAt,
    this.lastAttempt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  QueuedUpdate copyWith({
    String? id,
    String? coreId,
    UpdateType? type,
    EmotionalCore? core,
    List<EmotionalCore>? cores,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastAttempt,
    int? retryCount,
  }) {
    return QueuedUpdate(
      id: id ?? this.id,
      coreId: coreId ?? this.coreId,
      type: type ?? this.type,
      core: core ?? this.core,
      cores: cores ?? this.cores,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Types of updates that can be queued
enum UpdateType {
  coreUpdate,
  batchUpdate,
  contextUpdate,
}

/// Sync event types
enum SyncEventType {
  initialized,
  syncStarted,
  syncCompleted,
  syncFailed,
  updateQueued,
  updateFailed,
  conflictDetected,
  conflictResolved,
  error,
}

/// Sync event model
class SyncEvent {
  final SyncEventType type;
  final DateTime timestamp;
  final String? error;
  final Map<String, dynamic> data;

  SyncEvent({
    required this.type,
    required this.timestamp,
    this.error,
    this.data = const {},
  });
}

/// Sync statistics
class SyncStatistics {
  final DateTime? lastSuccessfulSync;
  final int consecutiveFailures;
  final int queueSize;
  final bool isActive;
  final DateTime nextSyncEstimate;

  SyncStatistics({
    this.lastSuccessfulSync,
    required this.consecutiveFailures,
    required this.queueSize,
    required this.isActive,
    required this.nextSyncEstimate,
  });
}