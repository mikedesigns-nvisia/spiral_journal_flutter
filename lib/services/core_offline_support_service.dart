import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/core.dart';
import '../models/core_error.dart';
import '../models/journal_entry.dart';
import 'core_cache_manager.dart';

/// Service for handling offline functionality and graceful degradation
class CoreOfflineSupportService {
  static final CoreOfflineSupportService _instance = CoreOfflineSupportService._internal();
  factory CoreOfflineSupportService() => _instance;
  CoreOfflineSupportService._internal();

  final CoreCacheManager _cacheManager = CoreCacheManager();
  
  /// Stream controller for connectivity status
  final StreamController<bool> _connectivityController = 
      StreamController<bool>.broadcast();
  
  /// Stream controller for offline mode status
  final StreamController<bool> _offlineModeController = 
      StreamController<bool>.broadcast();

  /// Current connectivity status
  bool _isConnected = true;
  
  /// Whether offline mode is explicitly enabled
  bool _isOfflineModeEnabled = false;
  
  /// Queue for operations to perform when connectivity is restored
  final List<OfflineOperation> _operationQueue = [];
  
  /// Maximum number of operations to queue
  static const int _maxQueueSize = 100;
  
  /// Timer for periodic connectivity checks
  Timer? _connectivityTimer;
  
  /// Whether the service has been initialized
  bool _initialized = false;

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// Stream of offline mode status changes
  Stream<bool> get offlineModeStream => _offlineModeController.stream;
  
  /// Current connectivity status
  bool get isConnected => _isConnected;
  
  /// Whether offline mode is enabled
  bool get isOfflineModeEnabled => _isOfflineModeEnabled;
  
  /// Whether the app is currently operating offline
  bool get isOperatingOffline => !_isConnected || _isOfflineModeEnabled;
  
  /// Number of queued operations
  int get queuedOperationsCount => _operationQueue.length;

  /// Initialize the offline support service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize cache manager
      await _cacheManager.initialize();
      
      // Start connectivity monitoring
      _startConnectivityMonitoring();
      
      // Load any previously queued operations
      await _loadQueuedOperations();
      
      _initialized = true;
      debugPrint('CoreOfflineSupportService: Initialized successfully');
    } catch (e) {
      debugPrint('CoreOfflineSupportService: Initialization failed: $e');
      throw CoreError.fromException(
        Exception('Failed to initialize offline support: $e'),
        type: CoreErrorType.performanceError,
      );
    }
  }

  /// Start monitoring connectivity status
  void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      // In a real implementation, this would check actual network connectivity
      // For now, we'll simulate connectivity checks
      final wasConnected = _isConnected;
      
      // Simulate connectivity check (in real app, use connectivity_plus package)
      _isConnected = await _performConnectivityCheck();
      
      if (wasConnected != _isConnected) {
        _connectivityController.add(_isConnected);
        
        if (_isConnected) {
          await _onConnectivityRestored();
        } else {
          await _onConnectivityLost();
        }
      }
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
  }

  /// Perform actual connectivity check
  Future<bool> _performConnectivityCheck() async {
    // In a real implementation, this would ping a server or check network status
    // For now, simulate that we're usually connected
    return true;
  }

  /// Handle connectivity restoration
  Future<void> _onConnectivityRestored() async {
    debugPrint('CoreOfflineSupportService: Connectivity restored');
    
    // Process queued operations
    await _processQueuedOperations();
    
    // Sync cached data if needed
    await _syncCachedData();
  }

  /// Handle connectivity loss
  Future<void> _onConnectivityLost() async {
    debugPrint('CoreOfflineSupportService: Connectivity lost, switching to offline mode');
    
    // Ensure we have sufficient cached data
    await _ensureCachedDataAvailability();
  }

  /// Enable or disable offline mode manually
  Future<void> setOfflineMode(bool enabled) async {
    if (_isOfflineModeEnabled == enabled) return;
    
    _isOfflineModeEnabled = enabled;
    _offlineModeController.add(enabled);
    
    if (enabled) {
      debugPrint('CoreOfflineSupportService: Offline mode enabled');
      await _ensureCachedDataAvailability();
    } else {
      debugPrint('CoreOfflineSupportService: Offline mode disabled');
      if (_isConnected) {
        await _processQueuedOperations();
      }
    }
  }

  /// Get cached core data for offline viewing
  Future<List<EmotionalCore>?> getCachedCores() async {
    try {
      final cachedCores = <EmotionalCore>[];
      
      // Load all cached cores
      final coreIds = ['optimism', 'resilience', 'self_awareness', 
                      'creativity', 'social_connection', 'growth_mindset'];
      
      for (final coreId in coreIds) {
        final cachedCore = await _cacheManager.getCachedCore(coreId);
        if (cachedCore != null) {
          cachedCores.add(cachedCore);
        }
      }
      
      if (cachedCores.isNotEmpty) {
        debugPrint('CoreOfflineSupportService: Loaded ${cachedCores.length} cached cores');
        return cachedCores;
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to load cached cores: $e');
      return null;
    }
  }

  /// Get cached core by ID
  Future<EmotionalCore?> getCachedCore(String coreId) async {
    try {
      return await _cacheManager.getCachedCore(coreId);
    } catch (e) {
      debugPrint('Failed to load cached core $coreId: $e');
      return null;
    }
  }

  /// Queue an operation for when connectivity is restored
  Future<void> queueOperation(OfflineOperation operation) async {
    if (_operationQueue.length >= _maxQueueSize) {
      // Remove oldest operation to make room
      _operationQueue.removeAt(0);
      debugPrint('CoreOfflineSupportService: Queue full, removed oldest operation');
    }
    
    _operationQueue.add(operation);
    await _saveQueuedOperations();
    
    debugPrint('CoreOfflineSupportService: Queued ${operation.type.name} operation, '
              'queue size: ${_operationQueue.length}');
  }

  /// Process all queued operations
  Future<void> _processQueuedOperations() async {
    if (_operationQueue.isEmpty) return;
    
    debugPrint('CoreOfflineSupportService: Processing ${_operationQueue.length} queued operations');
    
    final operationsToProcess = List<OfflineOperation>.from(_operationQueue);
    _operationQueue.clear();
    
    int successCount = 0;
    int failureCount = 0;
    
    for (final operation in operationsToProcess) {
      try {
        await _processOperation(operation);
        successCount++;
      } catch (e) {
        debugPrint('Failed to process queued operation ${operation.id}: $e');
        failureCount++;
        
        // Re-queue failed operations if they're still valid
        if (operation.isStillValid()) {
          _operationQueue.add(operation);
        }
      }
    }
    
    await _saveQueuedOperations();
    
    debugPrint('CoreOfflineSupportService: Processed operations - '
              'Success: $successCount, Failed: $failureCount, '
              'Remaining: ${_operationQueue.length}');
  }

  /// Process a single queued operation
  Future<void> _processOperation(OfflineOperation operation) async {
    switch (operation.type) {
      case OfflineOperationType.coreUpdate:
        await _processCoreUpdate(operation);
        break;
      case OfflineOperationType.journalEntry:
        await _processJournalEntry(operation);
        break;
      case OfflineOperationType.cacheRefresh:
        await _processCacheRefresh(operation);
        break;
      case OfflineOperationType.dataSync:
        await _processDataSync(operation);
        break;
    }
  }

  /// Process a core update operation
  Future<void> _processCoreUpdate(OfflineOperation operation) async {
    // In a real implementation, this would update the core via the service
    debugPrint('Processing core update: ${operation.data}');
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Process a journal entry operation
  Future<void> _processJournalEntry(OfflineOperation operation) async {
    // In a real implementation, this would save the journal entry
    debugPrint('Processing journal entry: ${operation.data}');
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Process a cache refresh operation
  Future<void> _processCacheRefresh(OfflineOperation operation) async {
    // In a real implementation, this would refresh cached data
    debugPrint('Processing cache refresh: ${operation.data}');
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Process a data sync operation
  Future<void> _processDataSync(OfflineOperation operation) async {
    // In a real implementation, this would sync data with the server
    debugPrint('Processing data sync: ${operation.data}');
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Ensure sufficient cached data is available for offline operation
  Future<void> _ensureCachedDataAvailability() async {
    try {
      // Check if we have recent cached data
      final cachedCores = await getCachedCores();
      
      if (cachedCores == null || cachedCores.isEmpty) {
        debugPrint('CoreOfflineSupportService: No cached data available for offline mode');
        
        // Queue a cache refresh operation for when connectivity is restored
        await queueOperation(OfflineOperation(
          id: 'cache_refresh_${DateTime.now().millisecondsSinceEpoch}',
          type: OfflineOperationType.cacheRefresh,
          data: {'reason': 'insufficient_cached_data'},
          timestamp: DateTime.now(),
        ));
      } else {
        debugPrint('CoreOfflineSupportService: ${cachedCores.length} cores available offline');
      }
    } catch (e) {
      debugPrint('Failed to ensure cached data availability: $e');
    }
  }

  /// Sync cached data with server when connectivity is available
  Future<void> _syncCachedData() async {
    try {
      // In a real implementation, this would compare cached data with server data
      // and update the cache with any changes
      debugPrint('CoreOfflineSupportService: Syncing cached data');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('CoreOfflineSupportService: Cache sync completed');
    } catch (e) {
      debugPrint('Cache sync failed: $e');
    }
  }

  /// Save queued operations to persistent storage
  Future<void> _saveQueuedOperations() async {
    try {
      final operationsJson = _operationQueue.map((op) => op.toJson()).toList();
      // In a real implementation, this would save to secure storage
      debugPrint('Saved ${_operationQueue.length} queued operations');
    } catch (e) {
      debugPrint('Failed to save queued operations: $e');
    }
  }

  /// Load previously queued operations from persistent storage
  Future<void> _loadQueuedOperations() async {
    try {
      // In a real implementation, this would load from secure storage
      // For now, start with empty queue
      debugPrint('Loaded ${_operationQueue.length} queued operations');
    } catch (e) {
      debugPrint('Failed to load queued operations: $e');
    }
  }

  /// Get offline status information
  OfflineStatus getOfflineStatus() {
    return OfflineStatus(
      isConnected: _isConnected,
      isOfflineModeEnabled: _isOfflineModeEnabled,
      queuedOperationsCount: _operationQueue.length,
      lastConnectivityCheck: DateTime.now(),
      hasOfflineData: true, // Would check actual cache status
    );
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    _operationQueue.clear();
    await _saveQueuedOperations();
    debugPrint('CoreOfflineSupportService: Cleared operation queue');
  }

  /// Force a connectivity check
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStatistics() {
    final stats = <String, dynamic>{
      'totalOperations': _operationQueue.length,
      'operationsByType': <String, int>{},
      'oldestOperation': null,
      'newestOperation': null,
    };

    if (_operationQueue.isNotEmpty) {
      // Count by type
      for (final operation in _operationQueue) {
        final typeName = operation.type.name;
        stats['operationsByType'][typeName] = 
            (stats['operationsByType'][typeName] ?? 0) + 1;
      }

      // Find oldest and newest
      _operationQueue.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      stats['oldestOperation'] = _operationQueue.first.timestamp.toIso8601String();
      stats['newestOperation'] = _operationQueue.last.timestamp.toIso8601String();
    }

    return stats;
  }

  /// Dispose of resources
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
    _offlineModeController.close();
    _operationQueue.clear();
  }
}

/// Types of operations that can be queued for offline processing
enum OfflineOperationType {
  coreUpdate,
  journalEntry,
  cacheRefresh,
  dataSync,
}

/// Represents an operation queued for offline processing
class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int maxRetries;
  int retryCount;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.maxRetries = 3,
    this.retryCount = 0,
  });

  /// Check if this operation is still valid (not too old)
  bool isStillValid() {
    final age = DateTime.now().difference(timestamp);
    return age.inHours < 24 && retryCount < maxRetries;
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'maxRetries': maxRetries,
      'retryCount': retryCount,
    };
  }

  /// Create from JSON
  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'],
      type: OfflineOperationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      maxRetries: json['maxRetries'] ?? 3,
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// Current offline status information
class OfflineStatus {
  final bool isConnected;
  final bool isOfflineModeEnabled;
  final int queuedOperationsCount;
  final DateTime lastConnectivityCheck;
  final bool hasOfflineData;

  const OfflineStatus({
    required this.isConnected,
    required this.isOfflineModeEnabled,
    required this.queuedOperationsCount,
    required this.lastConnectivityCheck,
    required this.hasOfflineData,
  });

  bool get isOperatingOffline => !isConnected || isOfflineModeEnabled;

  Map<String, dynamic> toJson() {
    return {
      'isConnected': isConnected,
      'isOfflineModeEnabled': isOfflineModeEnabled,
      'isOperatingOffline': isOperatingOffline,
      'queuedOperationsCount': queuedOperationsCount,
      'lastConnectivityCheck': lastConnectivityCheck.toIso8601String(),
      'hasOfflineData': hasOfflineData,
    };
  }
}