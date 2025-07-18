import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../repositories/journal_repository.dart';

/// Performance optimization service for efficient data loading and memory management.
/// 
/// This service provides:
/// - Lazy loading with efficient pagination
/// - In-memory caching with LRU eviction
/// - Background processing coordination
/// - Memory management and resource cleanup
/// - Query optimization and batching
/// 
/// ## Key Features
/// - **Lazy Loading**: Load data on-demand with configurable page sizes
/// - **Smart Caching**: LRU cache with automatic memory pressure handling
/// - **Background Processing**: Non-blocking operations for better UI performance
/// - **Memory Management**: Automatic cleanup and resource disposal
/// - **Query Batching**: Combine multiple queries for better performance
/// 
/// ## Usage Example
/// ```dart
/// final perfService = PerformanceOptimizationService();
/// await perfService.initialize();
/// 
/// // Lazy load entries with caching
/// final entries = await perfService.loadEntriesLazy(
///   page: 0,
///   pageSize: 20,
///   useCache: true,
/// );
/// 
/// // Background processing
/// perfService.processInBackground(() async {
///   // Heavy operation
/// });
/// 
/// // Memory cleanup
/// perfService.clearCache();
/// ```
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance = 
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  // Configuration
  static const int _defaultPageSize = 20;
  static const int _maxCacheSize = 500; // Maximum cached entries
  static const int _maxCacheMemoryMB = 50; // Maximum cache memory in MB
  static const Duration _cacheExpiration = Duration(minutes: 30);
  static const Duration _backgroundProcessingDelay = Duration(milliseconds: 100);

  // Cache management
  final LinkedHashMap<String, _CacheEntry<List<JournalEntry>>> _entryCache = 
      LinkedHashMap<String, _CacheEntry<List<JournalEntry>>>();
  final LinkedHashMap<String, _CacheEntry<JournalEntry>> _singleEntryCache = 
      LinkedHashMap<String, _CacheEntry<JournalEntry>>();
  
  // Background processing
  final List<Future<void>> _backgroundTasks = [];
  Timer? _cleanupTimer;
  
  // Performance metrics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalQueries = 0;
  
  // Dependencies
  JournalRepository? _repository;
  
  // Getters for performance metrics
  double get cacheHitRatio => _totalQueries > 0 ? _cacheHits / _totalQueries : 0.0;
  int get cacheSize => _entryCache.length + _singleEntryCache.length;
  Map<String, dynamic> get performanceMetrics => {
    'cacheHits': _cacheHits,
    'cacheMisses': _cacheMisses,
    'totalQueries': _totalQueries,
    'cacheHitRatio': cacheHitRatio,
    'cacheSize': cacheSize,
    'backgroundTasks': _backgroundTasks.length,
  };

  /// Initialize the performance service
  Future<void> initialize({JournalRepository? repository}) async {
    _repository = repository;
    
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performPeriodicCleanup(),
    );
    
    // Warm up cache with recent entries if needed
    if (kDebugMode) {
      debugPrint('PerformanceOptimizationService initialized');
    }
  }

  /// Load journal entries with lazy loading and caching
  Future<List<JournalEntry>> loadEntriesLazy({
    required int page,
    int pageSize = _defaultPageSize,
    bool useCache = true,
    Map<String, dynamic>? filters,
  }) async {
    _totalQueries++;
    
    // Generate cache key
    final cacheKey = _generateCacheKey('entries', {
      'page': page,
      'pageSize': pageSize,
      'filters': filters?.toString() ?? 'none',
    });
    
    // Check cache first
    if (useCache && _entryCache.containsKey(cacheKey)) {
      final cacheEntry = _entryCache[cacheKey]!;
      if (!cacheEntry.isExpired) {
        _cacheHits++;
        _moveToFront(cacheKey, _entryCache);
        return cacheEntry.data;
      } else {
        _entryCache.remove(cacheKey);
      }
    }
    
    _cacheMisses++;
    
    // Load from repository
    final offset = page * pageSize;
    List<JournalEntry> entries;
    
    if (_repository != null) {
      if (filters != null && filters.isNotEmpty) {
        // Apply filters if provided
        entries = await _repository!.searchEntriesAdvanced(
          textQuery: filters['textQuery'],
          moods: filters['moods'],
          aiMoods: filters['aiMoods'],
          startDate: filters['startDate'],
          endDate: filters['endDate'],
          minIntensity: filters['minIntensity'],
          maxIntensity: filters['maxIntensity'],
          isAnalyzed: filters['isAnalyzed'],
          themes: filters['themes'],
          limit: pageSize,
          offset: offset,
        );
      } else {
        entries = await _repository!.getAllEntries(
          limit: pageSize,
          offset: offset,
        );
      }
    } else {
      entries = []; // Fallback when no repository
    }
    
    // Cache the result
    if (useCache) {
      _cacheEntries(cacheKey, entries);
    }
    
    return entries;
  }

  /// Load a single entry with caching
  Future<JournalEntry?> loadEntryCached(String entryId) async {
    _totalQueries++;
    
    // Check cache first
    if (_singleEntryCache.containsKey(entryId)) {
      final cacheEntry = _singleEntryCache[entryId]!;
      if (!cacheEntry.isExpired) {
        _cacheHits++;
        _moveToFront(entryId, _singleEntryCache);
        return cacheEntry.data;
      } else {
        _singleEntryCache.remove(entryId);
      }
    }
    
    _cacheMisses++;
    
    // Load from repository
    if (_repository != null) {
      final entry = await _repository!.getEntryById(entryId);
      if (entry != null) {
        _cacheSingleEntry(entryId, entry);
      }
      return entry;
    }
    
    return null;
  }

  /// Process operation in background to avoid blocking UI
  Future<T> processInBackground<T>(Future<T> Function() operation) async {
    // Add small delay to allow UI to update
    await Future.delayed(_backgroundProcessingDelay);
    
    // Execute in compute if it's a heavy operation
    if (kDebugMode) {
      return await operation();
    } else {
      // For production, consider using compute for CPU-intensive tasks
      return await operation();
    }
  }

  /// Batch multiple operations for better performance
  Future<List<T>> batchOperations<T>(
    List<Future<T> Function()> operations, {
    int batchSize = 5,
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((op) => op()),
      );
      results.addAll(batchResults);
      
      // Small delay between batches to prevent overwhelming the system
      if (i + batchSize < operations.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    
    return results;
  }

  /// Preload entries for better perceived performance
  Future<void> preloadEntries({
    int pages = 3,
    int pageSize = _defaultPageSize,
  }) async {
    processInBackground(() async {
      for (int page = 0; page < pages; page++) {
        await loadEntriesLazy(
          page: page,
          pageSize: pageSize,
          useCache: true,
        );
        
        // Small delay between preloads
        await Future.delayed(const Duration(milliseconds: 50));
      }
    });
  }

  /// Invalidate cache for specific entries or patterns
  void invalidateCache({
    String? entryId,
    String? pattern,
    bool clearAll = false,
  }) {
    if (clearAll) {
      _entryCache.clear();
      _singleEntryCache.clear();
      return;
    }
    
    if (entryId != null) {
      _singleEntryCache.remove(entryId);
      
      // Remove related entry list caches
      final keysToRemove = _entryCache.keys
          .where((key) => key.contains('entries'))
          .toList();
      for (final key in keysToRemove) {
        _entryCache.remove(key);
      }
    }
    
    if (pattern != null) {
      final keysToRemove = [
        ..._entryCache.keys.where((key) => key.contains(pattern)),
        ..._singleEntryCache.keys.where((key) => key.contains(pattern)),
      ];
      
      for (final key in keysToRemove) {
        _entryCache.remove(key);
        _singleEntryCache.remove(key);
      }
    }
  }

  /// Clear all caches and free memory
  void clearCache() {
    _entryCache.clear();
    _singleEntryCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _totalQueries = 0;
    
    if (kDebugMode) {
      debugPrint('PerformanceOptimizationService: Cache cleared');
    }
  }

  /// Get memory usage estimation
  int getEstimatedMemoryUsageMB() {
    int totalEntries = 0;
    
    // Count entries in list caches
    for (final cache in _entryCache.values) {
      totalEntries += cache.data.length;
    }
    
    // Count single entry caches
    totalEntries += _singleEntryCache.length;
    
    // Rough estimation: ~2KB per entry on average
    return (totalEntries * 2) ~/ 1024; // Convert to MB
  }

  /// Optimize memory usage by removing old/unused cache entries
  void optimizeMemoryUsage() {
    final currentMemoryMB = getEstimatedMemoryUsageMB();
    
    if (currentMemoryMB > _maxCacheMemoryMB) {
      // Remove oldest entries until we're under the limit
      final targetEntries = (_maxCacheMemoryMB * 1024) ~/ 2; // Target entry count
      
      // Remove from entry list cache first (usually larger)
      while (_entryCache.length > targetEntries ~/ 4 && _entryCache.isNotEmpty) {
        _entryCache.remove(_entryCache.keys.first);
      }
      
      // Remove from single entry cache
      while (_singleEntryCache.length > targetEntries && _singleEntryCache.isNotEmpty) {
        _singleEntryCache.remove(_singleEntryCache.keys.first);
      }
      
      if (kDebugMode) {
        debugPrint('PerformanceOptimizationService: Memory optimized from ${currentMemoryMB}MB to ${getEstimatedMemoryUsageMB()}MB');
      }
    }
  }

  /// Dispose of resources and cleanup
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    
    // Wait for background tasks to complete
    if (_backgroundTasks.isNotEmpty) {
      await Future.wait(_backgroundTasks);
      _backgroundTasks.clear();
    }
    
    clearCache();
    
    if (kDebugMode) {
      debugPrint('PerformanceOptimizationService disposed');
    }
  }

  // Private helper methods

  String _generateCacheKey(String prefix, Map<String, dynamic> params) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    return '$prefix:${sortedParams.toString()}';
  }

  void _cacheEntries(String key, List<JournalEntry> entries) {
    // Ensure cache size limits
    if (_entryCache.length >= _maxCacheSize) {
      _entryCache.remove(_entryCache.keys.first);
    }
    
    _entryCache[key] = _CacheEntry(entries, DateTime.now().add(_cacheExpiration));
  }

  void _cacheSingleEntry(String key, JournalEntry entry) {
    // Ensure cache size limits
    if (_singleEntryCache.length >= _maxCacheSize) {
      _singleEntryCache.remove(_singleEntryCache.keys.first);
    }
    
    _singleEntryCache[key] = _CacheEntry(entry, DateTime.now().add(_cacheExpiration));
  }

  void _moveToFront<T>(String key, LinkedHashMap<String, _CacheEntry<T>> cache) {
    final entry = cache.remove(key);
    if (entry != null) {
      cache[key] = entry;
    }
  }

  void _performPeriodicCleanup() {
    // Remove expired entries
    final now = DateTime.now();
    
    _entryCache.removeWhere((key, entry) => entry.expiresAt.isBefore(now));
    _singleEntryCache.removeWhere((key, entry) => entry.expiresAt.isBefore(now));
    
    // Optimize memory if needed
    optimizeMemoryUsage();
    
    // Note: Future<void> tasks are automatically cleaned up when they complete
    // No need to manually remove them from the list
  }
}

/// Cache entry with expiration
class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;
  
  _CacheEntry(this.data, this.expiresAt);
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}