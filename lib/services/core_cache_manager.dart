import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/core.dart';

/// Intelligent cache manager for core data with compression and invalidation
class CoreCacheManager {
  static final CoreCacheManager _instance = CoreCacheManager._internal();
  factory CoreCacheManager() => _instance;
  CoreCacheManager._internal();

  // Cache configuration
  static const Duration _defaultCacheDuration = Duration(minutes: 15);
  static const Duration _contextCacheDuration = Duration(minutes: 10);
  static const Duration _insightCacheDuration = Duration(minutes: 30);
  static const int _maxCacheSize = 50; // Maximum number of cached items
  static const String _cachePrefix = 'core_cache_';
  static const String _metadataKey = 'cache_metadata';
  
  // Performance optimization settings
  static const int _maxMemoryUsageMB = 25; // Maximum cache memory usage
  static const Duration _performanceCheckInterval = Duration(seconds: 30);

  // In-memory cache for frequently accessed data
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, Timer> _expirationTimers = {};
  
  // Performance monitoring
  Timer? _performanceTimer;
  int _cacheAccessCount = 0;
  DateTime _lastPerformanceCheck = DateTime.now();
  
  // Cache metadata for management
  CacheMetadata? _metadata;
  SharedPreferences? _prefs;

  /// Initialize the cache manager
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCacheMetadata();
      await _cleanupExpiredEntries();
      _startPeriodicCleanup();
      _startPerformanceMonitoring();
    } catch (e) {
      debugPrint('CoreCacheManager initialization error: $e');
    }
  }

  /// Cache core data with intelligent compression
  Future<void> cacheCore(EmotionalCore core, {Duration? ttl}) async {
    try {
      final cacheKey = _getCoreKey(core.id);
      final entry = CacheEntry(
        key: cacheKey,
        data: core.toJson(),
        timestamp: DateTime.now(),
        ttl: ttl ?? _defaultCacheDuration,
        accessCount: 1,
        dataType: CacheDataType.core,
      );

      // Store in memory cache
      _memoryCache[cacheKey] = entry;
      
      // Store in persistent cache with compression
      await _storePersistentEntry(entry);
      
      // Update metadata
      await _updateCacheMetadata(cacheKey, entry);
      
      // Set expiration timer
      _setExpirationTimer(cacheKey, entry.ttl);
      
      debugPrint('CoreCacheManager: Cached core ${core.id}');
    } catch (e) {
      debugPrint('CoreCacheManager cacheCore error: $e');
    }
  }

  /// Cache core context data
  Future<void> cacheCoreContext(String coreId, CoreDetailContext context, {Duration? ttl}) async {
    try {
      final cacheKey = _getContextKey(coreId);
      final entry = CacheEntry(
        key: cacheKey,
        data: context.toJson(),
        timestamp: DateTime.now(),
        ttl: ttl ?? _contextCacheDuration,
        accessCount: 1,
        dataType: CacheDataType.context,
      );

      _memoryCache[cacheKey] = entry;
      await _storePersistentEntry(entry);
      await _updateCacheMetadata(cacheKey, entry);
      _setExpirationTimer(cacheKey, entry.ttl);
      
      debugPrint('CoreCacheManager: Cached context for core $coreId');
    } catch (e) {
      debugPrint('CoreCacheManager cacheCoreContext error: $e');
    }
  }

  /// Cache core insights
  Future<void> cacheCoreInsights(String coreId, List<CoreInsight> insights, {Duration? ttl}) async {
    try {
      final cacheKey = _getInsightsKey(coreId);
      final entry = CacheEntry(
        key: cacheKey,
        data: insights.map((i) => i.toJson()).toList(),
        timestamp: DateTime.now(),
        ttl: ttl ?? _insightCacheDuration,
        accessCount: 1,
        dataType: CacheDataType.insights,
      );

      _memoryCache[cacheKey] = entry;
      await _storePersistentEntry(entry);
      await _updateCacheMetadata(cacheKey, entry);
      _setExpirationTimer(cacheKey, entry.ttl);
      
      debugPrint('CoreCacheManager: Cached ${insights.length} insights for core $coreId');
    } catch (e) {
      debugPrint('CoreCacheManager cacheCoreInsights error: $e');
    }
  }

  /// Retrieve cached core data
  Future<EmotionalCore?> getCachedCore(String coreId) async {
    try {
      final cacheKey = _getCoreKey(coreId);
      final entry = await _getCacheEntry(cacheKey);
      
      if (entry != null && !_isExpired(entry)) {
        // Update access count and timestamp
        entry.accessCount++;
        entry.lastAccessed = DateTime.now();
        
        final coreData = entry.data as Map<String, dynamic>;
        final core = EmotionalCore.fromJson(coreData);
        
        debugPrint('CoreCacheManager: Retrieved cached core $coreId');
        return core;
      }
      
      // Remove expired entry
      if (entry != null) {
        await _removeEntry(cacheKey);
      }
      
      return null;
    } catch (e) {
      debugPrint('CoreCacheManager getCachedCore error: $e');
      return null;
    }
  }

  /// Retrieve cached core context
  Future<CoreDetailContext?> getCachedCoreContext(String coreId) async {
    try {
      final cacheKey = _getContextKey(coreId);
      final entry = await _getCacheEntry(cacheKey);
      
      if (entry != null && !_isExpired(entry)) {
        entry.accessCount++;
        entry.lastAccessed = DateTime.now();
        
        final contextData = entry.data as Map<String, dynamic>;
        final context = CoreDetailContext.fromJson(contextData);
        
        debugPrint('CoreCacheManager: Retrieved cached context for core $coreId');
        return context;
      }
      
      if (entry != null) {
        await _removeEntry(cacheKey);
      }
      
      return null;
    } catch (e) {
      debugPrint('CoreCacheManager getCachedCoreContext error: $e');
      return null;
    }
  }

  /// Retrieve cached core insights
  Future<List<CoreInsight>?> getCachedCoreInsights(String coreId) async {
    try {
      final cacheKey = _getInsightsKey(coreId);
      final entry = await _getCacheEntry(cacheKey);
      
      if (entry != null && !_isExpired(entry)) {
        entry.accessCount++;
        entry.lastAccessed = DateTime.now();
        
        final insightsData = entry.data as List<dynamic>;
        final insights = insightsData
            .map((data) => CoreInsight.fromJson(data as Map<String, dynamic>))
            .toList();
        
        debugPrint('CoreCacheManager: Retrieved ${insights.length} cached insights for core $coreId');
        return insights;
      }
      
      if (entry != null) {
        await _removeEntry(cacheKey);
      }
      
      return null;
    } catch (e) {
      debugPrint('CoreCacheManager getCachedCoreInsights error: $e');
      return null;
    }
  }

  /// Invalidate cache for specific core
  Future<void> invalidateCore(String coreId) async {
    try {
      final keys = [
        _getCoreKey(coreId),
        _getContextKey(coreId),
        _getInsightsKey(coreId),
      ];
      
      for (final key in keys) {
        await _removeEntry(key);
      }
      
      debugPrint('CoreCacheManager: Invalidated cache for core $coreId');
    } catch (e) {
      debugPrint('CoreCacheManager invalidateCore error: $e');
    }
  }

  /// Invalidate cache based on update events
  Future<void> invalidateByUpdateEvent(CoreUpdateEvent event) async {
    try {
      switch (event.type) {
        case CoreUpdateEventType.levelChanged:
        case CoreUpdateEventType.trendChanged:
        case CoreUpdateEventType.milestoneAchieved:
          await invalidateCore(event.coreId);
          break;
        case CoreUpdateEventType.batchUpdate:
          final coreIds = event.data['updatedCoreIds'] as List<String>?;
          if (coreIds != null) {
            for (final coreId in coreIds) {
              await invalidateCore(coreId);
            }
          }
          break;
        case CoreUpdateEventType.analysisCompleted:
          // Invalidate insights cache
          await _removeEntry(_getInsightsKey(event.coreId));
          break;
        case CoreUpdateEventType.insightGenerated:
          await _removeEntry(_getInsightsKey(event.coreId));
          break;
      }
    } catch (e) {
      debugPrint('CoreCacheManager invalidateByUpdateEvent error: $e');
    }
  }

  /// Warm cache for frequently accessed cores
  Future<void> warmCache(List<String> coreIds, List<EmotionalCore> cores) async {
    try {
      for (final coreId in coreIds) {
        final core = cores.firstWhere(
          (c) => c.id == coreId,
          orElse: () => cores.first,
        );
        
        // Cache with longer TTL for warmed data
        await cacheCore(core, ttl: const Duration(minutes: 30));
      }
      
      debugPrint('CoreCacheManager: Warmed cache for ${coreIds.length} cores');
    } catch (e) {
      debugPrint('CoreCacheManager warmCache error: $e');
    }
  }

  /// Get cache statistics
  CacheStatistics getCacheStatistics() {
    final memoryEntries = _memoryCache.length;
    final totalSize = _calculateCacheSize();
    final hitRate = _calculateHitRate();
    
    return CacheStatistics(
      memoryEntries: memoryEntries,
      totalSizeBytes: totalSize,
      hitRate: hitRate,
      lastCleanup: _metadata?.lastCleanup ?? DateTime.now(),
    );
  }

  /// Clear all cache data
  Future<void> clearCache() async {
    try {
      // Clear memory cache
      _memoryCache.clear();
      
      // Cancel all timers
      for (final timer in _expirationTimers.values) {
        timer.cancel();
      }
      _expirationTimers.clear();
      
      // Clear persistent cache
      if (_prefs != null) {
        final keys = _prefs!.getKeys()
            .where((key) => key.startsWith(_cachePrefix))
            .toList();
        
        for (final key in keys) {
          await _prefs!.remove(key);
        }
      }
      
      // Reset metadata
      _metadata = CacheMetadata(
        totalEntries: 0,
        lastCleanup: DateTime.now(),
        hitCount: 0,
        missCount: 0,
      );
      await _saveCacheMetadata();
      
      debugPrint('CoreCacheManager: Cleared all cache data');
    } catch (e) {
      debugPrint('CoreCacheManager clearCache error: $e');
    }
  }

  // Private helper methods

  String _getCoreKey(String coreId) => '${_cachePrefix}core_$coreId';
  String _getContextKey(String coreId) => '${_cachePrefix}context_$coreId';
  String _getInsightsKey(String coreId) => '${_cachePrefix}insights_$coreId';

  Future<CacheEntry?> _getCacheEntry(String key) async {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!_isExpired(entry)) {
        _metadata?.hitCount++;
        return entry;
      } else {
        _memoryCache.remove(key);
      }
    }
    
    // Check persistent cache
    if (_prefs != null) {
      final entryJson = _prefs!.getString(key);
      if (entryJson != null) {
        try {
          final entryData = jsonDecode(entryJson) as Map<String, dynamic>;
          final entry = CacheEntry.fromJson(entryData);
          
          if (!_isExpired(entry)) {
            // Load back into memory cache
            _memoryCache[key] = entry;
            _metadata?.hitCount++;
            return entry;
          } else {
            // Remove expired persistent entry
            await _prefs!.remove(key);
          }
        } catch (e) {
          debugPrint('CoreCacheManager: Error loading persistent entry: $e');
          await _prefs!.remove(key);
        }
      }
    }
    
    _metadata?.missCount++;
    return null;
  }

  Future<void> _storePersistentEntry(CacheEntry entry) async {
    if (_prefs == null) return;
    
    try {
      // Compress data if it's large
      final entryJson = jsonEncode(entry.toJson());
      final compressed = _shouldCompress(entryJson) 
          ? _compressData(entryJson) 
          : entryJson;
      
      await _prefs!.setString(entry.key, compressed);
    } catch (e) {
      debugPrint('CoreCacheManager: Error storing persistent entry: $e');
    }
  }

  Future<void> _removeEntry(String key) async {
    _memoryCache.remove(key);
    _expirationTimers[key]?.cancel();
    _expirationTimers.remove(key);
    
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
    
    await _updateCacheMetadata(key, null, isRemoval: true);
  }

  bool _isExpired(CacheEntry entry) {
    return DateTime.now().difference(entry.timestamp) > entry.ttl;
  }

  void _setExpirationTimer(String key, Duration ttl) {
    _expirationTimers[key]?.cancel();
    _expirationTimers[key] = Timer(ttl, () async {
      await _removeEntry(key);
    });
  }

  bool _shouldCompress(String data) {
    return data.length > 1024; // Compress if larger than 1KB
  }

  String _compressData(String data) {
    // Simple compression - in production, use gzip or similar
    try {
      final bytes = utf8.encode(data);
      final compressed = gzip.encode(bytes);
      return base64Encode(compressed);
    } catch (e) {
      debugPrint('CoreCacheManager: Compression failed: $e');
      return data;
    }
  }

  // Note: Decompression method removed as it's not currently used
  // It would be used if we implement compression detection in cache loading

  Future<void> _loadCacheMetadata() async {
    if (_prefs == null) return;
    
    try {
      final metadataJson = _prefs!.getString(_metadataKey);
      if (metadataJson != null) {
        final metadataData = jsonDecode(metadataJson) as Map<String, dynamic>;
        _metadata = CacheMetadata.fromJson(metadataData);
      } else {
        _metadata = CacheMetadata(
          totalEntries: 0,
          lastCleanup: DateTime.now(),
          hitCount: 0,
          missCount: 0,
        );
      }
    } catch (e) {
      debugPrint('CoreCacheManager: Error loading metadata: $e');
      _metadata = CacheMetadata(
        totalEntries: 0,
        lastCleanup: DateTime.now(),
        hitCount: 0,
        missCount: 0,
      );
    }
  }

  Future<void> _saveCacheMetadata() async {
    if (_prefs == null || _metadata == null) return;
    
    try {
      final metadataJson = jsonEncode(_metadata!.toJson());
      await _prefs!.setString(_metadataKey, metadataJson);
    } catch (e) {
      debugPrint('CoreCacheManager: Error saving metadata: $e');
    }
  }

  Future<void> _updateCacheMetadata(String key, CacheEntry? entry, {bool isRemoval = false}) async {
    if (_metadata == null) return;
    
    if (isRemoval) {
      _metadata!.totalEntries = (_metadata!.totalEntries - 1).clamp(0, double.infinity).toInt();
    } else if (entry != null) {
      _metadata!.totalEntries++;
    }
    
    await _saveCacheMetadata();
  }

  Future<void> _cleanupExpiredEntries() async {
    if (_prefs == null) return;
    
    try {
      final keys = _prefs!.getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();
      
      int removedCount = 0;
      for (final key in keys) {
        final entryJson = _prefs!.getString(key);
        if (entryJson != null) {
          try {
            final entryData = jsonDecode(entryJson) as Map<String, dynamic>;
            final entry = CacheEntry.fromJson(entryData);
            
            if (_isExpired(entry)) {
              await _prefs!.remove(key);
              removedCount++;
            }
          } catch (e) {
            // Remove corrupted entries
            await _prefs!.remove(key);
            removedCount++;
          }
        }
      }
      
      if (removedCount > 0) {
        debugPrint('CoreCacheManager: Cleaned up $removedCount expired entries');
        if (_metadata != null) {
          _metadata!.lastCleanup = DateTime.now();
          await _saveCacheMetadata();
        }
      }
    } catch (e) {
      debugPrint('CoreCacheManager: Error during cleanup: $e');
    }
  }

  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(minutes: 30), (_) async {
      await _cleanupExpiredEntries();
      await _enforceMaxCacheSize();
    });
  }

  /// Start performance monitoring for sub-1-second loading
  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(_performanceCheckInterval, (_) {
      _checkPerformanceMetrics();
    });
  }

  /// Check and optimize performance metrics
  void _checkPerformanceMetrics() {
    final now = DateTime.now();
    final timeSinceLastCheck = now.difference(_lastPerformanceCheck);
    
    // Calculate cache access rate
    final accessRate = _cacheAccessCount / timeSinceLastCheck.inSeconds;
    
    // Check memory usage
    final memoryUsageMB = _calculateMemoryUsageMB();
    
    // Optimize if needed
    if (memoryUsageMB > _maxMemoryUsageMB) {
      _optimizeForMemory();
    }
    
    // Optimize for high access rate
    if (accessRate > 10) { // More than 10 accesses per second
      _optimizeForSpeed();
    }
    
    // Reset counters
    _cacheAccessCount = 0;
    _lastPerformanceCheck = now;
    
    if (kDebugMode && memoryUsageMB > _maxMemoryUsageMB * 0.8) {
      debugPrint('CoreCacheManager: Memory usage: ${memoryUsageMB.toStringAsFixed(1)}MB, Access rate: ${accessRate.toStringAsFixed(1)}/s');
    }
  }

  /// Optimize cache for memory efficiency
  void _optimizeForMemory() {
    // Remove least recently used items
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) {
        final aAccessed = a.value.lastAccessed ?? a.value.timestamp;
        final bAccessed = b.value.lastAccessed ?? b.value.timestamp;
        return aAccessed.compareTo(bAccessed);
      });
    
    // Remove oldest 25% of entries
    final toRemove = (sortedEntries.length * 0.25).round();
    for (int i = 0; i < toRemove && i < sortedEntries.length; i++) {
      final key = sortedEntries[i].key;
      _memoryCache.remove(key);
      _expirationTimers[key]?.cancel();
      _expirationTimers.remove(key);
    }
    
    debugPrint('CoreCacheManager: Optimized for memory - removed $toRemove entries');
  }

  /// Optimize cache for speed
  void _optimizeForSpeed() {
    // Preload frequently accessed data types
    final coreEntries = _memoryCache.entries
        .where((e) => e.key.contains('core_'))
        .length;
    
    // If we have few core entries cached, prioritize them
    if (coreEntries < 10) {
      // Keep core entries longer
      for (final entry in _memoryCache.entries) {
        if (entry.key.contains('core_')) {
          // Extend TTL for core entries
          final extendedEntry = CacheEntry(
            key: entry.value.key,
            data: entry.value.data,
            timestamp: entry.value.timestamp,
            ttl: const Duration(minutes: 30), // Extended TTL
            accessCount: entry.value.accessCount,
            lastAccessed: entry.value.lastAccessed,
            dataType: entry.value.dataType,
          );
          _memoryCache[entry.key] = extendedEntry;
        }
      }
      
      debugPrint('CoreCacheManager: Optimized for speed - extended core cache TTL');
    }
  }

  /// Calculate current memory usage in MB
  double _calculateMemoryUsageMB() {
    int totalBytes = 0;
    
    for (final entry in _memoryCache.values) {
      // Estimate size based on data type
      switch (entry.dataType) {
        case CacheDataType.core:
          totalBytes += 2048; // ~2KB per core
          break;
        case CacheDataType.context:
          totalBytes += 4096; // ~4KB per context
          break;
        case CacheDataType.insights:
          final insights = entry.data as List<dynamic>;
          totalBytes += insights.length * 1024; // ~1KB per insight
          break;
        case CacheDataType.metadata:
          totalBytes += 512; // ~0.5KB per metadata
          break;
      }
    }
    
    return totalBytes / 1024 / 1024; // Convert to MB
  }

  Future<void> _enforceMaxCacheSize() async {
    if (_prefs == null) return;
    
    try {
      final keys = _prefs!.getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();
      
      if (keys.length <= _maxCacheSize) return;
      
      // Load all entries with timestamps
      final entries = <String, DateTime>{};
      for (final key in keys) {
        final entryJson = _prefs!.getString(key);
        if (entryJson != null) {
          try {
            final entryData = jsonDecode(entryJson) as Map<String, dynamic>;
            final entry = CacheEntry.fromJson(entryData);
            entries[key] = entry.lastAccessed ?? entry.timestamp;
          } catch (e) {
            // Remove corrupted entries
            await _prefs!.remove(key);
          }
        }
      }
      
      // Sort by last accessed (oldest first)
      final sortedEntries = entries.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      // Remove oldest entries
      final toRemove = sortedEntries.length - _maxCacheSize;
      for (int i = 0; i < toRemove; i++) {
        await _prefs!.remove(sortedEntries[i].key);
      }
      
      debugPrint('CoreCacheManager: Removed $toRemove old entries to enforce size limit');
    } catch (e) {
      debugPrint('CoreCacheManager: Error enforcing cache size: $e');
    }
  }

  int _calculateCacheSize() {
    if (_prefs == null) return 0;
    
    int totalSize = 0;
    final keys = _prefs!.getKeys()
        .where((key) => key.startsWith(_cachePrefix));
    
    for (final key in keys) {
      final value = _prefs!.getString(key);
      if (value != null) {
        totalSize += value.length;
      }
    }
    
    return totalSize;
  }

  double _calculateHitRate() {
    if (_metadata == null) return 0.0;
    
    final total = _metadata!.hitCount + _metadata!.missCount;
    if (total == 0) return 0.0;
    
    return _metadata!.hitCount / total;
  }
}

/// Cache entry data structure
class CacheEntry {
  final String key;
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  int accessCount;
  DateTime? lastAccessed;
  final CacheDataType dataType;

  CacheEntry({
    required this.key,
    required this.data,
    required this.timestamp,
    required this.ttl,
    required this.accessCount,
    this.lastAccessed,
    required this.dataType,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'ttl': ttl.inMilliseconds,
    'accessCount': accessCount,
    'lastAccessed': lastAccessed?.toIso8601String(),
    'dataType': dataType.toString(),
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    key: json['key'] as String,
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp'] as String),
    ttl: Duration(milliseconds: json['ttl'] as int),
    accessCount: json['accessCount'] as int,
    lastAccessed: json['lastAccessed'] != null 
        ? DateTime.parse(json['lastAccessed'] as String) 
        : null,
    dataType: CacheDataType.values.firstWhere(
      (e) => e.toString() == json['dataType'],
      orElse: () => CacheDataType.core,
    ),
  );
}

/// Cache data types
enum CacheDataType {
  core,
  context,
  insights,
  metadata,
}

/// Cache metadata for management
class CacheMetadata {
  int totalEntries;
  DateTime lastCleanup;
  int hitCount;
  int missCount;

  CacheMetadata({
    required this.totalEntries,
    required this.lastCleanup,
    required this.hitCount,
    required this.missCount,
  });

  Map<String, dynamic> toJson() => {
    'totalEntries': totalEntries,
    'lastCleanup': lastCleanup.toIso8601String(),
    'hitCount': hitCount,
    'missCount': missCount,
  };

  factory CacheMetadata.fromJson(Map<String, dynamic> json) => CacheMetadata(
    totalEntries: json['totalEntries'] as int,
    lastCleanup: DateTime.parse(json['lastCleanup'] as String),
    hitCount: json['hitCount'] as int,
    missCount: json['missCount'] as int,
  );
}

/// Cache statistics
class CacheStatistics {
  final int memoryEntries;
  final int totalSizeBytes;
  final double hitRate;
  final DateTime lastCleanup;

  CacheStatistics({
    required this.memoryEntries,
    required this.totalSizeBytes,
    required this.hitRate,
    required this.lastCleanup,
  });
}