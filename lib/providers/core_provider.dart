import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/core.dart';
import '../models/core_error.dart';
import '../models/journal_entry.dart';
import '../services/core_library_service.dart';
import '../services/core_cache_manager.dart';
import '../services/core_background_sync_service.dart';
import '../services/core_memory_optimizer.dart';
import '../services/core_error_handler.dart';
import '../services/core_offline_support_service.dart';

class CoreProvider with ChangeNotifier {
  final CoreLibraryService _coreLibraryService = CoreLibraryService();
  final CoreCacheManager _cacheManager = CoreCacheManager();
  final CoreBackgroundSyncService _backgroundSyncService = CoreBackgroundSyncService();
  final CoreMemoryOptimizer _memoryOptimizer = CoreMemoryOptimizer();
  final CoreErrorHandler _errorHandler = CoreErrorHandler();
  final CoreOfflineSupportService _offlineService = CoreOfflineSupportService();
  
  // Enhanced state management
  List<EmotionalCore> _allCores = [];
  List<EmotionalCore> _topCores = [];
  final Map<String, CoreDetailContext> _coreContexts = {};
  CoreNavigationState _navigationState = CoreNavigationState.initial();
  bool _isLoading = false;
  CoreError? _error;
  
  // Real-time synchronization
  StreamController<CoreUpdateEvent>? _updateController;
  StreamSubscription? _coreUpdateSubscription;
  StreamSubscription? _syncEventSubscription;
  Timer? _syncTimer;
  
  // Performance optimization with intelligent caching and memory management
  final Map<String, List<String>> _preloadedCoreIds = {};
  bool _cacheInitialized = false;
  bool _syncInitialized = false;
  bool _memoryOptimizerInitialized = false;
  
  // Widget rebuild optimization
  DateTime? _lastNotifyTime;
  static const Duration _notifyThrottleInterval = Duration(milliseconds: 50);

  // Enhanced getters with memory optimization
  List<EmotionalCore> get allCores => _memoryOptimizerInitialized 
      ? _memoryOptimizer.optimizeCoreList(_allCores)
      : _allCores;
  
  List<EmotionalCore> get topCores => _memoryOptimizerInitialized 
      ? _memoryOptimizer.optimizeCoreList(_topCores, maxItems: 5)
      : _topCores;
  
  Map<String, CoreDetailContext> get coreContexts => _coreContexts;
  CoreNavigationState get navigationState => _navigationState;
  bool get isLoading => _isLoading;
  CoreError? get error => _error;
  
  // Note: Raw getters removed as they weren't being used
  // They could be added back if needed for internal operations that require unoptimized data
  
  // Real-time update stream
  Stream<CoreUpdateEvent> get coreUpdateStream => 
      _updateController?.stream ?? const Stream.empty();

  // Get cores by trend
  List<EmotionalCore> getCoresByTrend(String trend) {
    return _allCores.where((core) => core.trend == trend).toList();
  }

  // Get rising cores
  List<EmotionalCore> get risingCores => getCoresByTrend('rising');

  // Get declining cores  
  List<EmotionalCore> get decliningCores => getCoresByTrend('declining');

  // Get stable cores
  List<EmotionalCore> get stableCores => getCoresByTrend('stable');

  // Enhanced initialization with cache, background sync, memory optimization, and offline support
  Future<void> initialize() async {
    await _initializeMemoryOptimizer();
    await _initializeCache();
    await _initializeOfflineSupport();
    await _initializeBackgroundSync();
    _initializeUpdateStream();
    await loadAllCores();
    await loadTopCores();
    _startPeriodicSync();
  }
  
  // Initialize cache manager
  Future<void> _initializeCache() async {
    try {
      await _cacheManager.initialize();
      _cacheInitialized = true;
      debugPrint('CoreProvider: Cache manager initialized successfully');
    } catch (e) {
      debugPrint('CoreProvider: Cache initialization failed: $e');
      _cacheInitialized = false;
    }
  }
  
  // Initialize memory optimizer
  Future<void> _initializeMemoryOptimizer() async {
    try {
      await _memoryOptimizer.initialize();
      _memoryOptimizerInitialized = true;
      debugPrint('CoreProvider: Memory optimizer initialized successfully');
    } catch (e) {
      debugPrint('CoreProvider: Memory optimizer initialization failed: $e');
      _memoryOptimizerInitialized = false;
    }
  }
  
  // Initialize offline support service
  Future<void> _initializeOfflineSupport() async {
    try {
      await _offlineService.initialize();
      
      // Listen to connectivity changes
      _offlineService.connectivityStream.listen((isConnected) {
        _handleConnectivityChange(isConnected);
      });
      
      // Listen to offline mode changes
      _offlineService.offlineModeStream.listen((isOfflineMode) {
        _handleOfflineModeChange(isOfflineMode);
      });
      
      debugPrint('CoreProvider: Offline support initialized successfully');
    } catch (e) {
      debugPrint('CoreProvider: Offline support initialization failed: $e');
      // Continue without offline support if initialization fails
    }
  }
  
  // Initialize background sync service
  Future<void> _initializeBackgroundSync() async {
    try {
      await _backgroundSyncService.initialize();
      _syncInitialized = true;
      
      // Listen to sync events with memory tracking
      _syncEventSubscription = _backgroundSyncService.syncEventStream.listen(
        _handleSyncEvent,
        onError: (error) {
          debugPrint('CoreProvider: Sync event stream error: $error');
        },
      );
      
      // Register subscription for memory tracking
      if (_memoryOptimizerInitialized) {
        _memoryOptimizer.registerSubscription(_syncEventSubscription!, 'sync_events');
      }
      
      debugPrint('CoreProvider: Background sync service initialized successfully');
    } catch (e) {
      debugPrint('CoreProvider: Background sync initialization failed: $e');
      _syncInitialized = false;
    }
  }
  
  // Initialize real-time update stream
  void _initializeUpdateStream() {
    _updateController = StreamController<CoreUpdateEvent>.broadcast();
    
    // Listen to our own updates for internal synchronization and cache invalidation
    _coreUpdateSubscription = _updateController!.stream.listen(
      _handleCoreUpdateEvent,
      onError: (error) async {
        await _setError(CoreError.fromException(
          Exception('Update stream error: $error'),
          type: CoreErrorType.syncFailure,
          context: {
            'operation': 'coreUpdateStream',
            'streamActive': _updateController != null,
          },
        ));
      },
    );
    
    // Register subscription for memory tracking
    if (_memoryOptimizerInitialized) {
      _memoryOptimizer.registerSubscription(_coreUpdateSubscription!, 'core_updates');
    }
  }
  
  // Start periodic background sync
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _backgroundSync();
    });
    
    // Register timer for memory tracking
    if (_memoryOptimizerInitialized) {
      _memoryOptimizer.registerTimer(_syncTimer!, 'periodic_sync');
    }
  }

  // Enhanced core loading with intelligent caching and offline support
  Future<void> loadAllCores({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Check if we're operating offline
      if (isOperatingOffline && !forceRefresh) {
        final cachedCores = await _offlineService.getCachedCores();
        if (cachedCores != null && cachedCores.isNotEmpty) {
          _allCores = cachedCores;
          await _updateCoreContexts(cachedCores);
          _setLoading(false);
          notifyListeners();
          
          debugPrint('CoreProvider: Loaded ${cachedCores.length} cores from offline cache');
          return;
        } else {
          // No offline data available
          throw CoreError(
            type: CoreErrorType.networkError,
            message: 'No internet connection and no offline data available',
            isRecoverable: true,
            context: {
              'operation': 'loadAllCores',
              'isOffline': true,
              'forceRefresh': forceRefresh,
            },
          );
        }
      }
      
      // Try to load from cache first if not forcing refresh
      if (!forceRefresh && _cacheInitialized) {
        final cachedCores = await _loadCoresFromCache();
        if (cachedCores != null && cachedCores.isNotEmpty) {
          _allCores = cachedCores;
          await _updateCoreContexts(cachedCores);
          _setLoading(false);
          notifyListeners();
          
          // Load fresh data in background if connected
          if (isConnected) {
            _loadFreshCoresInBackground();
          }
          return;
        }
      }
      
      // Load fresh data from service
      final cores = await _coreLibraryService.getAllCores();
      _allCores = cores;
      
      // Cache the loaded cores
      if (_cacheInitialized) {
        await _cacheCores(cores);
      }
      
      // Update core contexts
      await _updateCoreContexts(cores);
      
      // Broadcast update event
      _broadcastUpdateEvent(CoreUpdateEvent(
        coreId: 'all',
        type: CoreUpdateEventType.batchUpdate,
        data: {'coreCount': cores.length},
        timestamp: DateTime.now(),
        updateSource: 'core_provider',
      ));
      
      notifyListeners();
    } catch (e) {
      await _setError(CoreError.fromException(
        e is Exception ? e : Exception(e.toString()),
        type: CoreErrorType.dataLoadFailure,
        context: {
          'operation': 'loadAllCores',
          'forceRefresh': forceRefresh,
          'cacheInitialized': _cacheInitialized,
        },
      ));
    } finally {
      _setLoading(false);
    }
  }

  // Enhanced top cores loading with smart caching
  Future<void> loadTopCores({int limit = 3, bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Load fresh data if needed
      if (_allCores.isEmpty || forceRefresh) {
        await loadAllCores(forceRefresh: forceRefresh);
      }
      
      // Sort by current level and recent activity
      final sortedCores = List<EmotionalCore>.from(_allCores);
      sortedCores.sort((a, b) {
        // Primary sort: current level
        final levelComparison = b.currentLevel.compareTo(a.currentLevel);
        if (levelComparison != 0) return levelComparison;
        
        // Secondary sort: recent activity (last updated)
        return b.lastUpdated.compareTo(a.lastUpdated);
      });
      
      _topCores = sortedCores.take(limit).toList();
      
      notifyListeners();
    } catch (e) {
      _setError(CoreError.fromException(
        e is Exception ? e : Exception(e.toString()),
        type: CoreErrorType.dataLoadFailure,
      ));
    } finally {
      _setLoading(false);
    }
  }


  // Enhanced core update with context and real-time sync
  Future<bool> updateCore(EmotionalCore core, {JournalEntry? relatedEntry}) async {
    try {
      _setLoading(true);
      _clearError();
      
      final previousCore = getCoreById(core.id);
      
      // Handle update based on connectivity status
      if (isOperatingOffline) {
        // Queue update for when connectivity is restored
        await _offlineService.queueOperation(OfflineOperation(
          id: '${core.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: OfflineOperationType.coreUpdate,
          data: {
            'coreId': core.id,
            'core': core.toJson(),
            'hasRelatedEntry': relatedEntry != null,
            'relatedEntryId': relatedEntry?.id,
          },
          timestamp: DateTime.now(),
        ));
        
        debugPrint('CoreProvider: Queued core update for offline processing');
      } else {
        // Queue update for background sync if available, otherwise update immediately
        if (_syncInitialized) {
          final queuedUpdate = QueuedUpdate(
            id: '${core.id}_${DateTime.now().millisecondsSinceEpoch}',
            coreId: core.id,
            type: UpdateType.coreUpdate,
            core: core,
            metadata: {
              'hasRelatedEntry': relatedEntry != null,
              'relatedEntryId': relatedEntry?.id,
            },
          );
          
          await _backgroundSyncService.queueUpdate(queuedUpdate);
        } else {
          // Fallback to direct update
          await _coreLibraryService.updateCore(core);
        }
      }
      
      // Update local lists
      _updateCoreInLists(core);
      
      // Update core context
      await _updateSingleCoreContext(core, relatedEntry);
      
      // Broadcast update events
      await _broadcastCoreUpdateEvents(core, previousCore, relatedEntry);
      
      // Invalidate related caches
      if (_cacheInitialized) {
        await _cacheManager.invalidateCore(core.id);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(CoreError.fromException(
        e is Exception ? e : Exception(e.toString()),
        type: CoreErrorType.persistenceError,
        coreId: core.id,
      ));
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Context-aware core update for journal-related changes
  Future<bool> updateCoreWithContext(
    String coreId, 
    JournalEntry? relatedEntry, {
    Map<String, dynamic>? additionalData,
  }) async {
    final core = getCoreById(coreId);
    if (core == null) {
      _setError(CoreError(
        type: CoreErrorType.dataLoadFailure,
        message: 'Core not found: $coreId',
        coreId: coreId,
      ));
      return false;
    }
    
    return await updateCore(core, relatedEntry: relatedEntry);
  }
  
  // Batch update processing for performance
  Future<bool> batchUpdateCores(
    List<EmotionalCore> cores, {
    JournalEntry? relatedEntry,
    String? updateSource,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final updateEvents = <CoreUpdateEvent>[];
      final updatedCores = <EmotionalCore>[];
      
      // Queue batch update for background sync if available
      if (_syncInitialized) {
        final queuedUpdate = QueuedUpdate(
          id: 'batch_${DateTime.now().millisecondsSinceEpoch}',
          coreId: 'batch',
          type: UpdateType.batchUpdate,
          cores: cores,
          metadata: {
            'hasRelatedEntry': relatedEntry != null,
            'relatedEntryId': relatedEntry?.id,
            'updateSource': updateSource ?? 'batch_update',
          },
        );
        
        await _backgroundSyncService.queueUpdate(queuedUpdate);
      }
      
      // Process all updates locally
      for (final core in cores) {
        final previousCore = getCoreById(core.id);
        
        // Update core in service if not using background sync
        if (!_syncInitialized) {
          await _coreLibraryService.updateCore(core);
        }
        
        // Update local lists
        _updateCoreInLists(core);
        
        // Update core context
        await _updateSingleCoreContext(core, relatedEntry);
        
        // Collect update events for batch broadcast
        if (previousCore != null) {
          final events = await _createUpdateEvents(core, previousCore, relatedEntry);
          updateEvents.addAll(events);
        }
        
        updatedCores.add(core);
      }
      
      // Broadcast batch update event
      _broadcastUpdateEvent(CoreUpdateEvent(
        coreId: 'batch',
        type: CoreUpdateEventType.batchUpdate,
        data: {
          'updatedCoreIds': cores.map((c) => c.id).toList(),
          'updateCount': cores.length,
          'updateSource': updateSource ?? 'batch_update',
        },
        timestamp: DateTime.now(),
        relatedJournalEntryId: relatedEntry?.id,
        updateSource: updateSource ?? 'batch_update',
      ));
      
      // Broadcast individual events
      for (final event in updateEvents) {
        _broadcastUpdateEvent(event);
      }
      
      // Invalidate caches
      if (_cacheInitialized) {
        for (final core in cores) {
          await _cacheManager.invalidateCore(core.id);
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(CoreError.fromException(
        e is Exception ? e : Exception(e.toString()),
        type: CoreErrorType.persistenceError,
      ));
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Conflict resolution for simultaneous core updates
  Future<void> resolveCoreConflicts(List<EmotionalCore> conflictingCores) async {
    try {
      final resolvedCores = <EmotionalCore>[];
      
      for (final core in conflictingCores) {
        // Get the latest version from storage
        final latestCore = await _coreLibraryService.getCoreById(core.id);
        if (latestCore != null) {
          // Use timestamp-based resolution - latest update wins
          if (core.lastUpdated.isAfter(latestCore.lastUpdated)) {
            resolvedCores.add(core);
          } else {
            resolvedCores.add(latestCore);
          }
        } else {
          resolvedCores.add(core);
        }
      }
      
      // Update with resolved cores
      await batchUpdateCores(
        resolvedCores,
        updateSource: 'conflict_resolution',
      );
      
      // Broadcast conflict resolution event
      _broadcastUpdateEvent(CoreUpdateEvent(
        coreId: 'conflict_resolution',
        type: CoreUpdateEventType.batchUpdate,
        data: {
          'resolvedCoreIds': resolvedCores.map((c) => c.id).toList(),
          'conflictCount': conflictingCores.length,
        },
        timestamp: DateTime.now(),
        updateSource: 'conflict_resolution',
      ));
      
    } catch (e) {
      _setError(CoreError.fromException(
        e is Exception ? e : Exception(e.toString()),
        type: CoreErrorType.syncFailure,
      ));
    }
  }

  // Get core by name
  EmotionalCore? getCoreByName(String name) {
    try {
      return _allCores.firstWhere(
        (core) => core.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get core by ID
  EmotionalCore? getCoreById(String id) {
    try {
      return _allCores.firstWhere((core) => core.id == id);
    } catch (e) {
      return null;
    }
  }

  // Context-aware navigation methods
  Future<void> navigateToCore(String coreId, {CoreNavigationContext? context}) async {
    try {
      final core = getCoreById(coreId);
      if (core == null) {
        _setError(CoreError(
          type: CoreErrorType.navigationError,
          message: 'Cannot navigate to core: Core not found',
          coreId: coreId,
        ));
        return;
      }
      
      // Update navigation state
      _navigationState = _navigationState.copyWith(
        currentCoreId: coreId,
        currentContext: context,
        navigationHistory: [..._navigationState.navigationHistory, coreId],
        lastNavigation: DateTime.now(),
      );
      
      // Preload core details for better performance
      await preloadCoreDetails([coreId]);
      
      // Broadcast navigation event
      _broadcastUpdateEvent(CoreUpdateEvent(
        coreId: coreId,
        type: CoreUpdateEventType.analysisCompleted,
        data: {
          'action': 'navigation',
          'context': context?.toJson(),
        },
        timestamp: DateTime.now(),
        relatedJournalEntryId: context?.relatedJournalEntryId,
        updateSource: 'navigation',
      ));
      
      notifyListeners();
    } catch (e) {
      _setError(CoreError.fromException(
        e is Exception ? e : Exception(e.toString()),
        type: CoreErrorType.navigationError,
        coreId: coreId,
      ));
    }
  }
  
  // Performance optimization: preload core details
  Future<void> preloadCoreDetails(List<String> coreIds) async {
    try {
      for (final coreId in coreIds) {
        if (!_coreContexts.containsKey(coreId)) {
          final core = getCoreById(coreId);
          if (core != null) {
            await _loadCoreContext(core);
          }
        }
      }
      
      // Track preloaded cores for cache management
      final timestamp = DateTime.now().toIso8601String();
      _preloadedCoreIds[timestamp] = coreIds;
      
      // Clean up old preload records
      _cleanupPreloadCache();
      
    } catch (e) {
      // Preloading failures shouldn't block the main flow
      debugPrint('Preload failed for cores $coreIds: $e');
    }
  }
  
  // Enhanced refresh with selective updates
  Future<void> refresh({bool forceRefresh = false}) async {
    await loadAllCores(forceRefresh: forceRefresh);
    await loadTopCores(forceRefresh: forceRefresh);
  }

  // Override notifyListeners with throttling for performance
  @override
  void notifyListeners() {
    if (_memoryOptimizerInitialized && 
        _memoryOptimizer.shouldThrottleRebuild('core_provider')) {
      return; // Skip this notification to prevent excessive rebuilds
    }
    
    final now = DateTime.now();
    if (_lastNotifyTime != null && 
        now.difference(_lastNotifyTime!) < _notifyThrottleInterval) {
      return; // Throttle notifications
    }
    
    _lastNotifyTime = now;
    super.notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _setError(CoreError error) async {
    _error = error;
    
    // Handle error through centralized error handler
    await _errorHandler.handleError(error);
    
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get error stream for UI components to listen to
  Stream<CoreError> get errorStream => _errorHandler.errorStream;

  /// Execute a recovery action for the current error
  Future<bool> executeRecoveryAction(CoreErrorRecoveryAction action) async {
    if (_error == null) return false;
    
    final success = await _errorHandler.executeRecoveryAction(_error!, action);
    
    if (success) {
      clearError();
      
      // Trigger appropriate refresh based on the action
      switch (action) {
        case CoreErrorRecoveryAction.refreshData:
        case CoreErrorRecoveryAction.retry:
          await refresh(forceRefresh: true);
          break;
        case CoreErrorRecoveryAction.clearCache:
          await clearCache();
          await refresh(forceRefresh: true);
          break;
        case CoreErrorRecoveryAction.forceSync:
          await forceSync();
          break;
        default:
          break;
      }
    }
    
    return success;
  }

  /// Get error statistics for debugging
  Map<String, dynamic> getErrorStatistics() {
    return _errorHandler.getErrorStatistics();
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(bool isConnected) {
    debugPrint('CoreProvider: Connectivity changed - Connected: $isConnected');
    
    if (isConnected) {
      // Connectivity restored - refresh data if needed
      Timer(const Duration(milliseconds: 500), () async {
        try {
          await refresh(forceRefresh: true);
        } catch (e) {
          debugPrint('Failed to refresh data after connectivity restored: $e');
        }
      });
    } else {
      // Connectivity lost - ensure we have offline data
      _ensureOfflineDataAvailability();
    }
    
    notifyListeners();
  }

  /// Handle offline mode changes
  void _handleOfflineModeChange(bool isOfflineMode) {
    debugPrint('CoreProvider: Offline mode changed - Enabled: $isOfflineMode');
    
    if (isOfflineMode) {
      _ensureOfflineDataAvailability();
    }
    
    notifyListeners();
  }

  /// Ensure offline data is available
  void _ensureOfflineDataAvailability() {
    Timer(const Duration(milliseconds: 100), () async {
      try {
        final cachedCores = await _offlineService.getCachedCores();
        if (cachedCores == null || cachedCores.isEmpty) {
          // No cached data available - this is a problem for offline operation
          await _setError(CoreError(
            type: CoreErrorType.cacheError,
            message: 'No offline data available. Please connect to the internet to sync your data.',
            isRecoverable: true,
            context: {
              'operation': 'offline_data_check',
              'hasConnection': _offlineService.isConnected,
              'offlineModeEnabled': _offlineService.isOfflineModeEnabled,
            },
          ));
        } else {
          debugPrint('CoreProvider: ${cachedCores.length} cores available for offline use');
        }
      } catch (e) {
        debugPrint('Failed to check offline data availability: $e');
      }
    });
  }

  /// Get offline status
  OfflineStatus get offlineStatus => _offlineService.getOfflineStatus();

  /// Enable or disable offline mode
  Future<void> setOfflineMode(bool enabled) async {
    await _offlineService.setOfflineMode(enabled);
  }

  /// Check if currently operating offline
  bool get isOperatingOffline => _offlineService.isOperatingOffline;

  /// Get connectivity status
  bool get isConnected => _offlineService.isConnected;
  
  // Cache management helpers
  Future<List<EmotionalCore>?> _loadCoresFromCache() async {
    try {
      final cachedCores = <EmotionalCore>[];
      
      // Try to load each core from cache
      for (final coreConfig in ['optimism', 'resilience', 'self_awareness', 'creativity', 'social_connection', 'growth_mindset']) {
        final cachedCore = await _cacheManager.getCachedCore(coreConfig);
        if (cachedCore != null) {
          cachedCores.add(cachedCore);
        }
      }
      
      // Return cached cores if we have all of them
      if (cachedCores.length >= 6) {
        debugPrint('CoreProvider: Loaded ${cachedCores.length} cores from cache');
        return cachedCores;
      }
      
      return null;
    } catch (e) {
      debugPrint('CoreProvider: Error loading cores from cache: $e');
      return null;
    }
  }
  
  Future<void> _cacheCores(List<EmotionalCore> cores) async {
    try {
      for (final core in cores) {
        await _cacheManager.cacheCore(core);
      }
      debugPrint('CoreProvider: Cached ${cores.length} cores');
    } catch (e) {
      debugPrint('CoreProvider: Error caching cores: $e');
    }
  }
  
  void _loadFreshCoresInBackground() {
    // Load fresh data in background without blocking UI
    Timer(const Duration(milliseconds: 100), () async {
      try {
        final freshCores = await _coreLibraryService.getAllCores();
        
        // Check if data has changed
        bool hasChanges = false;
        if (freshCores.length != _allCores.length) {
          hasChanges = true;
        } else {
          for (int i = 0; i < freshCores.length; i++) {
            if (freshCores[i].currentLevel != _allCores[i].currentLevel ||
                freshCores[i].trend != _allCores[i].trend) {
              hasChanges = true;
              break;
            }
          }
        }
        
        if (hasChanges) {
          _allCores = freshCores;
          
          // Update cache
          if (_cacheInitialized) {
            await _cacheCores(freshCores);
          }
          
          // Update contexts
          await _updateCoreContexts(freshCores);
          
          // Notify listeners of background update
          notifyListeners();
          
          debugPrint('CoreProvider: Background refresh completed with changes');
        }
      } catch (e) {
        debugPrint('CoreProvider: Background refresh failed: $e');
      }
    });
  }
  
  void _cleanupPreloadCache() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _preloadedCoreIds.removeWhere((timestamp, _) {
      try {
        return DateTime.parse(timestamp).isBefore(cutoff);
      } catch (e) {
        return true; // Remove invalid timestamps
      }
    });
  }
  
  // Core list management helpers
  void _updateCoreInLists(EmotionalCore core) {
    final allIndex = _allCores.indexWhere((c) => c.id == core.id);
    if (allIndex != -1) {
      _allCores[allIndex] = core;
    }
    
    final topIndex = _topCores.indexWhere((c) => c.id == core.id);
    if (topIndex != -1) {
      _topCores[topIndex] = core;
    }
  }
  
  // Core context management
  Future<void> _updateCoreContexts(List<EmotionalCore> cores) async {
    for (final core in cores) {
      await _loadCoreContext(core);
    }
  }
  
  Future<void> _updateSingleCoreContext(EmotionalCore core, JournalEntry? relatedEntry) async {
    final existingContext = _coreContexts[core.id];
    final relatedEntryIds = existingContext?.relatedJournalEntryIds ?? <String>[];
    
    if (relatedEntry != null && !relatedEntryIds.contains(relatedEntry.id)) {
      relatedEntryIds.add(relatedEntry.id);
    }
    
    _coreContexts[core.id] = CoreDetailContext(
      core: core,
      relatedJournalEntryIds: relatedEntryIds,
      recentUpdates: existingContext?.recentUpdates ?? [],
      latestInsight: core.recentInsights.isNotEmpty ? core.recentInsights.first : null,
      upcomingMilestones: core.milestones.where((m) => !m.isAchieved).toList(),
    );
  }
  
  Future<void> _loadCoreContext(EmotionalCore core) async {
    try {
      // Try to load from cache first
      if (_cacheInitialized) {
        final cachedContext = await _cacheManager.getCachedCoreContext(core.id);
        if (cachedContext != null) {
          _coreContexts[core.id] = cachedContext;
          return;
        }
      }
      
      // Load fresh context data
      final context = CoreDetailContext(
        core: core,
        relatedJournalEntryIds: [], // Would be loaded from database
        recentUpdates: [], // Would be loaded from update history
        latestInsight: core.recentInsights.isNotEmpty ? core.recentInsights.first : null,
        upcomingMilestones: core.milestones.where((m) => !m.isAchieved).toList(),
      );
      
      _coreContexts[core.id] = context;
      
      // Cache the context
      if (_cacheInitialized) {
        await _cacheManager.cacheCoreContext(core.id, context);
      }
    } catch (e) {
      debugPrint('Failed to load context for core ${core.id}: $e');
    }
  }
  
  // Real-time synchronization helpers
  void _broadcastUpdateEvent(CoreUpdateEvent event) {
    _updateController?.add(event);
  }
  
  Future<void> _broadcastCoreUpdateEvents(
    EmotionalCore newCore, 
    EmotionalCore? previousCore, 
    JournalEntry? relatedEntry,
  ) async {
    final events = await _createUpdateEvents(newCore, previousCore, relatedEntry);
    
    // Broadcast all events
    for (final event in events) {
      _broadcastUpdateEvent(event);
    }
  }
  
  // Helper method to create update events (used by both single and batch updates)
  Future<List<CoreUpdateEvent>> _createUpdateEvents(
    EmotionalCore newCore,
    EmotionalCore? previousCore,
    JournalEntry? relatedEntry,
  ) async {
    final events = <CoreUpdateEvent>[];
    
    // Level change event
    if (previousCore != null && newCore.currentLevel != previousCore.currentLevel) {
      events.add(CoreUpdateEvent(
        coreId: newCore.id,
        type: CoreUpdateEventType.levelChanged,
        data: {
          'previousLevel': previousCore.currentLevel,
          'newLevel': newCore.currentLevel,
          'change': newCore.currentLevel - previousCore.currentLevel,
        },
        timestamp: DateTime.now(),
        relatedJournalEntryId: relatedEntry?.id,
        updateSource: 'ai_analysis',
      ));
    }
    
    // Trend change event
    if (previousCore != null && newCore.trend != previousCore.trend) {
      events.add(CoreUpdateEvent(
        coreId: newCore.id,
        type: CoreUpdateEventType.trendChanged,
        data: {
          'previousTrend': previousCore.trend,
          'newTrend': newCore.trend,
        },
        timestamp: DateTime.now(),
        relatedJournalEntryId: relatedEntry?.id,
        updateSource: 'ai_analysis',
      ));
    }
    
    // Milestone achievement events
    if (previousCore != null) {
      for (final milestone in newCore.milestones) {
        final previousMilestone = previousCore.milestones
            .where((m) => m.id == milestone.id)
            .firstOrNull;
        
        if (milestone.isAchieved && 
            (previousMilestone == null || !previousMilestone.isAchieved)) {
          events.add(CoreUpdateEvent(
            coreId: newCore.id,
            type: CoreUpdateEventType.milestoneAchieved,
            data: {
              'milestoneId': milestone.id,
              'milestoneTitle': milestone.title,
              'threshold': milestone.threshold,
            },
            timestamp: DateTime.now(),
            relatedJournalEntryId: relatedEntry?.id,
            updateSource: 'ai_analysis',
          ));
        }
      }
    }
    
    return events;
  }
  
  void _handleCoreUpdateEvent(CoreUpdateEvent event) async {
    // Handle internal synchronization and cache invalidation based on update events
    if (_cacheInitialized) {
      await _cacheManager.invalidateByUpdateEvent(event);
    }
    
    switch (event.type) {
      case CoreUpdateEventType.levelChanged:
      case CoreUpdateEventType.trendChanged:
        // Update cached data if needed
        final core = getCoreById(event.coreId);
        if (core != null && _cacheInitialized) {
          await _cacheManager.cacheCore(core);
        }
        break;
      case CoreUpdateEventType.milestoneAchieved:
        // Could trigger celebration animations or notifications
        break;
      case CoreUpdateEventType.batchUpdate:
        // Handle batch updates
        if (_cacheInitialized) {
          await _cacheCores(_allCores);
        }
        break;
      default:
        break;
    }
  }
  
  void _handleSyncEvent(SyncEvent event) {
    switch (event.type) {
      case SyncEventType.syncCompleted:
        debugPrint('CoreProvider: Background sync completed successfully');
        // Refresh data after successful sync
        Timer(const Duration(milliseconds: 500), () async {
          await refresh(forceRefresh: true);
        });
        break;
      case SyncEventType.syncFailed:
        debugPrint('CoreProvider: Background sync failed: ${event.error}');
        // Could show user notification about sync issues
        break;
      case SyncEventType.conflictDetected:
        final coreId = event.data['coreId'] as String?;
        debugPrint('CoreProvider: Conflict detected for core $coreId');
        break;
      case SyncEventType.updateQueued:
        final queueSize = event.data['queueSize'] as int?;
        debugPrint('CoreProvider: Update queued, queue size: $queueSize');
        break;
      default:
        break;
    }
  }
  
  Future<void> _backgroundSync() async {
    if (_isLoading) return; // Skip if already loading
    
    try {
      // Perform lightweight sync check
      final hasUpdates = await _coreLibraryService.hasUpdates();
      if (hasUpdates) {
        await refresh(forceRefresh: true);
      }
    } catch (e) {
      // Background sync failures shouldn't disrupt the user experience
      debugPrint('Background sync failed: $e');
    }
  }
  
  // Get cache statistics for debugging
  CacheStatistics? getCacheStatistics() {
    return _cacheInitialized ? _cacheManager.getCacheStatistics() : null;
  }
  
  // Get sync statistics for debugging
  SyncStatistics? getSyncStatistics() {
    return _syncInitialized ? _backgroundSyncService.getSyncStatistics() : null;
  }
  
  // Get memory statistics for debugging
  MemoryStatistics? getMemoryStatistics() {
    return _memoryOptimizerInitialized ? _memoryOptimizer.getMemoryStatistics() : null;
  }
  
  // Detect memory leaks
  List<MemoryLeak> detectMemoryLeaks() {
    return _memoryOptimizerInitialized ? _memoryOptimizer.detectMemoryLeaks() : [];
  }
  
  // Force memory cleanup
  Future<void> optimizeMemory() async {
    if (_memoryOptimizerInitialized) {
      await _memoryOptimizer.cleanup();
      
      // Force garbage collection in debug mode
      if (kDebugMode) {
        _memoryOptimizer.forceGarbageCollection();
      }
    }
  }
  
  // Force a background sync
  Future<bool> forceSync() async {
    if (_syncInitialized) {
      return await _backgroundSyncService.forceSync();
    }
    return false;
  }
  
  // Check if sync is currently active
  bool get isSyncing => _syncInitialized ? _backgroundSyncService.isSyncing : false;
  
  // Clear cache manually
  Future<void> clearCache() async {
    if (_cacheInitialized) {
      await _cacheManager.clearCache();
    }
  }
  
  // Cleanup resources with proper disposal tracking
  @override
  void dispose() {
    // Dispose subscriptions with memory tracking
    if (_memoryOptimizerInitialized) {
      if (_coreUpdateSubscription != null) {
        _memoryOptimizer.disposeSubscription(_coreUpdateSubscription!, 'core_updates');
      }
      if (_syncEventSubscription != null) {
        _memoryOptimizer.disposeSubscription(_syncEventSubscription!, 'sync_events');
      }
      if (_syncTimer != null) {
        _memoryOptimizer.disposeTimer(_syncTimer!, 'periodic_sync');
      }
    } else {
      _coreUpdateSubscription?.cancel();
      _syncEventSubscription?.cancel();
      _syncTimer?.cancel();
    }
    
    _updateController?.close();
    
    if (_syncInitialized) {
      _backgroundSyncService.dispose();
    }
    
    if (_memoryOptimizerInitialized) {
      _memoryOptimizer.dispose();
    }
    
    // Clear all collections to help with garbage collection
    _allCores.clear();
    _topCores.clear();
    _coreContexts.clear();
    _preloadedCoreIds.clear();
    
    super.dispose();
  }
}
