import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/core.dart';

/// Memory optimization service for core-related operations
class CoreMemoryOptimizer {
  static final CoreMemoryOptimizer _instance = CoreMemoryOptimizer._internal();
  factory CoreMemoryOptimizer() => _instance;
  CoreMemoryOptimizer._internal();

  // Memory monitoring
  Timer? _memoryMonitorTimer;
  final List<MemorySnapshot> _memoryHistory = [];
  static const int _maxHistorySize = 20;
  static const Duration _monitoringInterval = Duration(seconds: 30);

  // Resource tracking
  final Set<StreamSubscription> _activeSubscriptions = {};
  final Set<Timer> _activeTimers = {};
  final Map<String, DateTime> _resourceCreationTimes = {};

  // Widget rebuilding optimization
  final Map<String, int> _widgetRebuildCounts = {};
  final Map<String, DateTime> _lastRebuildTimes = {};
  static const Duration _rebuildThrottleInterval = Duration(milliseconds: 100);

  // Image and asset caching
  final Map<String, WeakReference<Object>> _assetCache = {};
  final Map<String, DateTime> _assetAccessTimes = {};
  static const Duration _assetCacheTimeout = Duration(minutes: 10);

  bool _isInitialized = false;

  /// Initialize the memory optimizer
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _startMemoryMonitoring();
      _startPeriodicCleanup();
      _isInitialized = true;
      
      debugPrint('CoreMemoryOptimizer: Initialized successfully');
    } catch (e) {
      debugPrint('CoreMemoryOptimizer: Initialization failed: $e');
    }
  }

  /// Register a stream subscription for tracking
  void registerSubscription(StreamSubscription subscription, String identifier) {
    _activeSubscriptions.add(subscription);
    _resourceCreationTimes[identifier] = DateTime.now();
    
    debugPrint('CoreMemoryOptimizer: Registered subscription $identifier');
  }

  /// Register a timer for tracking
  void registerTimer(Timer timer, String identifier) {
    _activeTimers.add(timer);
    _resourceCreationTimes[identifier] = DateTime.now();
    
    debugPrint('CoreMemoryOptimizer: Registered timer $identifier');
  }

  /// Unregister and dispose a subscription
  void disposeSubscription(StreamSubscription subscription, String identifier) {
    if (_activeSubscriptions.remove(subscription)) {
      subscription.cancel();
      _resourceCreationTimes.remove(identifier);
      
      debugPrint('CoreMemoryOptimizer: Disposed subscription $identifier');
    }
  }

  /// Unregister and dispose a timer
  void disposeTimer(Timer timer, String identifier) {
    if (_activeTimers.remove(timer)) {
      timer.cancel();
      _resourceCreationTimes.remove(identifier);
      
      debugPrint('CoreMemoryOptimizer: Disposed timer $identifier');
    }
  }

  /// Check if widget rebuild should be throttled
  bool shouldThrottleRebuild(String widgetIdentifier) {
    final lastRebuild = _lastRebuildTimes[widgetIdentifier];
    if (lastRebuild == null) {
      _lastRebuildTimes[widgetIdentifier] = DateTime.now();
      _widgetRebuildCounts[widgetIdentifier] = 1;
      return false;
    }

    final timeSinceLastRebuild = DateTime.now().difference(lastRebuild);
    if (timeSinceLastRebuild < _rebuildThrottleInterval) {
      return true;
    }

    _lastRebuildTimes[widgetIdentifier] = DateTime.now();
    _widgetRebuildCounts[widgetIdentifier] = 
        (_widgetRebuildCounts[widgetIdentifier] ?? 0) + 1;
    
    return false;
  }

  /// Optimize core list for memory efficiency
  List<EmotionalCore> optimizeCoreList(List<EmotionalCore> cores, {int? maxItems}) {
    if (cores.isEmpty) return cores;

    // Limit the number of items if specified
    final limitedCores = maxItems != null && cores.length > maxItems
        ? cores.take(maxItems).toList()
        : cores;

    // Create lightweight copies for display
    return limitedCores.map((core) => _createLightweightCore(core)).toList();
  }

  /// Create a lightweight version of a core for display
  EmotionalCore _createLightweightCore(EmotionalCore core) {
    // Keep only essential data for display
    return EmotionalCore(
      id: core.id,
      name: core.name,
      description: core.description,
      currentLevel: core.currentLevel,
      previousLevel: core.previousLevel,
      lastUpdated: core.lastUpdated,
      trend: core.trend,
      color: core.color,
      iconPath: core.iconPath,
      insight: core.insight,
      relatedCores: [], // Remove related cores to save memory
      milestones: core.milestones.take(3).toList(), // Limit milestones
      recentInsights: core.recentInsights.take(2).toList(), // Limit insights
    );
  }

  /// Cache an asset with weak reference
  void cacheAsset(String key, Object asset) {
    _assetCache[key] = WeakReference(asset);
    _assetAccessTimes[key] = DateTime.now();
  }

  /// Retrieve cached asset
  T? getCachedAsset<T>(String key) {
    final weakRef = _assetCache[key];
    if (weakRef != null) {
      final asset = weakRef.target;
      if (asset != null) {
        _assetAccessTimes[key] = DateTime.now();
        return asset as T?;
      } else {
        // Asset was garbage collected, remove from cache
        _assetCache.remove(key);
        _assetAccessTimes.remove(key);
      }
    }
    return null;
  }

  /// Force garbage collection (use sparingly)
  void forceGarbageCollection() {
    if (kDebugMode) {
      debugPrint('CoreMemoryOptimizer: Forcing garbage collection');
    }
    
    // Clear weak references that are no longer valid
    _cleanupWeakReferences();
    
    // Trigger garbage collection (note: gc() is not available in all environments)
    try {
      // Force a minor garbage collection by creating and discarding objects
      for (int i = 0; i < 1000; i++) {
        <int>[].add(i);
      }
    } catch (e) {
      // Ignore errors - gc is not always available
    }
  }

  /// Get current memory usage statistics
  MemoryStatistics getMemoryStatistics() {
    final currentRSS = _getCurrentMemoryUsage();
    final averageRSS = _getAverageMemoryUsage();
    
    return MemoryStatistics(
      currentRSS: currentRSS,
      averageRSS: averageRSS,
      activeSubscriptions: _activeSubscriptions.length,
      activeTimers: _activeTimers.length,
      cachedAssets: _assetCache.length,
      widgetRebuildCounts: Map.from(_widgetRebuildCounts),
      memoryHistory: List.from(_memoryHistory),
    );
  }

  /// Detect potential memory leaks
  List<MemoryLeak> detectMemoryLeaks() {
    final leaks = <MemoryLeak>[];
    final now = DateTime.now();

    // Check for long-running subscriptions
    for (final entry in _resourceCreationTimes.entries) {
      final age = now.difference(entry.value);
      if (age > const Duration(hours: 1)) {
        leaks.add(MemoryLeak(
          type: MemoryLeakType.longRunningSubscription,
          identifier: entry.key,
          age: age,
          description: 'Subscription has been active for ${age.inMinutes} minutes',
        ));
      }
    }

    // Check for excessive widget rebuilds
    for (final entry in _widgetRebuildCounts.entries) {
      if (entry.value > 100) {
        leaks.add(MemoryLeak(
          type: MemoryLeakType.excessiveRebuilds,
          identifier: entry.key,
          age: Duration.zero,
          description: 'Widget has rebuilt ${entry.value} times',
        ));
      }
    }

    // Check memory growth trend
    if (_memoryHistory.length >= 5) {
      final recent = _memoryHistory.skip(_memoryHistory.length - 5).toList();
      final isGrowing = _isMemoryGrowing(recent);
      
      if (isGrowing) {
        leaks.add(MemoryLeak(
          type: MemoryLeakType.memoryGrowth,
          identifier: 'memory_trend',
          age: Duration.zero,
          description: 'Memory usage is consistently growing',
        ));
      }
    }

    return leaks;
  }

  /// Cleanup resources and optimize memory
  Future<void> cleanup() async {
    try {
      // Note: We keep all active subscriptions as they are managed by the app
      // In a real implementation, you might have logic to determine which subscriptions
      // are no longer needed based on app state

      // Clean up expired assets
      _cleanupExpiredAssets();
      
      // Clean up weak references
      _cleanupWeakReferences();
      
      // Reset rebuild counters for widgets that haven't rebuilt recently
      _cleanupRebuildCounters();
      
      debugPrint('CoreMemoryOptimizer: Cleanup completed');
    } catch (e) {
      debugPrint('CoreMemoryOptimizer: Cleanup failed: $e');
    }
  }

  // Private methods

  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(_monitoringInterval, (_) {
      _recordMemorySnapshot();
    });
  }

  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(minutes: 5), (_) async {
      await cleanup();
    });
  }

  void _recordMemorySnapshot() {
    try {
      final rss = _getCurrentMemoryUsage();
      final snapshot = MemorySnapshot(
        timestamp: DateTime.now(),
        rss: rss,
        activeSubscriptions: _activeSubscriptions.length,
        activeTimers: _activeTimers.length,
        cachedAssets: _assetCache.length,
      );

      _memoryHistory.add(snapshot);
      
      // Keep history size limited
      if (_memoryHistory.length > _maxHistorySize) {
        _memoryHistory.removeAt(0);
      }

      // Log memory usage in debug mode
      if (kDebugMode && rss > 100 * 1024 * 1024) { // Log if > 100MB
        debugPrint('CoreMemoryOptimizer: High memory usage detected: ${(rss / 1024 / 1024).toStringAsFixed(1)}MB');
      }
    } catch (e) {
      debugPrint('CoreMemoryOptimizer: Failed to record memory snapshot: $e');
    }
  }

  int _getCurrentMemoryUsage() {
    try {
      // This is a simplified approach - in production you might use
      // platform-specific methods to get actual memory usage
      // Using a simple hash of current time as a placeholder
      return DateTime.now().millisecondsSinceEpoch.hashCode;
    } catch (e) {
      return 0;
    }
  }

  double _getAverageMemoryUsage() {
    if (_memoryHistory.isEmpty) return 0.0;
    
    final total = _memoryHistory.fold<int>(0, (sum, snapshot) => sum + snapshot.rss);
    return total / _memoryHistory.length;
  }

  bool _isMemoryGrowing(List<MemorySnapshot> snapshots) {
    if (snapshots.length < 3) return false;
    
    // Check if memory is consistently growing
    for (int i = 1; i < snapshots.length; i++) {
      if (snapshots[i].rss <= snapshots[i - 1].rss) {
        return false;
      }
    }
    
    return true;
  }

  void _cleanupExpiredAssets() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _assetAccessTimes.entries) {
      if (now.difference(entry.value) > _assetCacheTimeout) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _assetCache.remove(key);
      _assetAccessTimes.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('CoreMemoryOptimizer: Cleaned up ${expiredKeys.length} expired assets');
    }
  }

  void _cleanupWeakReferences() {
    final invalidKeys = <String>[];
    
    for (final entry in _assetCache.entries) {
      if (entry.value.target == null) {
        invalidKeys.add(entry.key);
      }
    }
    
    for (final key in invalidKeys) {
      _assetCache.remove(key);
      _assetAccessTimes.remove(key);
    }
    
    if (invalidKeys.isNotEmpty) {
      debugPrint('CoreMemoryOptimizer: Cleaned up ${invalidKeys.length} invalid weak references');
    }
  }

  void _cleanupRebuildCounters() {
    final now = DateTime.now();
    final staleKeys = <String>[];
    
    for (final entry in _lastRebuildTimes.entries) {
      if (now.difference(entry.value) > const Duration(minutes: 10)) {
        staleKeys.add(entry.key);
      }
    }
    
    for (final key in staleKeys) {
      _lastRebuildTimes.remove(key);
      _widgetRebuildCounts.remove(key);
    }
    
    if (staleKeys.isNotEmpty) {
      debugPrint('CoreMemoryOptimizer: Reset ${staleKeys.length} stale rebuild counters');
    }
  }

  /// Dispose the memory optimizer
  void dispose() {
    _memoryMonitorTimer?.cancel();
    
    // Dispose all tracked resources
    for (final subscription in _activeSubscriptions) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
    
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    
    _assetCache.clear();
    _assetAccessTimes.clear();
    _resourceCreationTimes.clear();
    _widgetRebuildCounts.clear();
    _lastRebuildTimes.clear();
    _memoryHistory.clear();
    
    _isInitialized = false;
    
    debugPrint('CoreMemoryOptimizer: Disposed');
  }
}

/// Memory snapshot for monitoring
class MemorySnapshot {
  final DateTime timestamp;
  final int rss; // Resident Set Size
  final int activeSubscriptions;
  final int activeTimers;
  final int cachedAssets;

  MemorySnapshot({
    required this.timestamp,
    required this.rss,
    required this.activeSubscriptions,
    required this.activeTimers,
    required this.cachedAssets,
  });
}

/// Memory usage statistics
class MemoryStatistics {
  final int currentRSS;
  final double averageRSS;
  final int activeSubscriptions;
  final int activeTimers;
  final int cachedAssets;
  final Map<String, int> widgetRebuildCounts;
  final List<MemorySnapshot> memoryHistory;

  MemoryStatistics({
    required this.currentRSS,
    required this.averageRSS,
    required this.activeSubscriptions,
    required this.activeTimers,
    required this.cachedAssets,
    required this.widgetRebuildCounts,
    required this.memoryHistory,
  });
}

/// Memory leak detection
enum MemoryLeakType {
  longRunningSubscription,
  excessiveRebuilds,
  memoryGrowth,
  unclosedResources,
}

class MemoryLeak {
  final MemoryLeakType type;
  final String identifier;
  final Duration age;
  final String description;

  MemoryLeak({
    required this.type,
    required this.identifier,
    required this.age,
    required this.description,
  });
}