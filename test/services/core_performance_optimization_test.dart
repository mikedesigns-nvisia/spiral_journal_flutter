import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/core_cache_manager.dart';
import 'package:spiral_journal/services/core_memory_optimizer.dart';
import 'package:spiral_journal/services/core_background_sync_service.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Core Performance Optimization Tests', () {
    late TestSetupHelper testHelper;

    setUp(() async {
      testHelper = TestSetupHelper();
      await testHelper.setUp();
    });

    tearDown(() async {
      await testHelper.tearDown();
    });

    group('CoreCacheManager Performance', () {
      late CoreCacheManager cacheManager;

      setUp(() async {
        cacheManager = CoreCacheManager();
        await cacheManager.initialize();
      });

      tearDown(() async {
        await cacheManager.dispose();
      });

      test('should cache and retrieve cores efficiently', () async {
        final testCore = _createTestCore('performance_test');
        
        // Measure cache write performance
        final writeStartTime = DateTime.now();
        await cacheManager.cacheCore(testCore);
        final writeDuration = DateTime.now().difference(writeStartTime);
        
        // Cache write should be fast (< 50ms)
        expect(writeDuration.inMilliseconds, lessThan(50));
        
        // Measure cache read performance
        final readStartTime = DateTime.now();
        final cachedCore = await cacheManager.getCachedCore(testCore.id);
        final readDuration = DateTime.now().difference(readStartTime);
        
        // Cache read should be very fast (< 10ms)
        expect(readDuration.inMilliseconds, lessThan(10));
        expect(cachedCore, isNotNull);
        expect(cachedCore!.id, equals(testCore.id));
      });

      test('should handle cache warming efficiently', () async {
        final cores = List.generate(10, (i) => _createTestCore('warm_test_$i'));
        
        final warmingStartTime = DateTime.now();
        await cacheManager.warmCache(cores);
        final warmingDuration = DateTime.now().difference(warmingStartTime);
        
        // Cache warming should be efficient (< 100ms for 10 cores)
        expect(warmingDuration.inMilliseconds, lessThan(100));
        
        // Verify all cores are cached
        for (final core in cores) {
          final cachedCore = await cacheManager.getCachedCore(core.id);
          expect(cachedCore, isNotNull);
        }
      });

      test('should compress cache data for memory efficiency', () async {
        final largeCore = _createTestCore('large_core').copyWith(
          description: 'A' * 1000, // Large description
          insight: 'B' * 1000, // Large insight
        );
        
        await cacheManager.cacheCore(largeCore);
        
        final cacheSize = await cacheManager.getCacheSize();
        final uncompressedSize = largeCore.toJson().toString().length;
        
        // Compressed cache should be smaller than uncompressed data
        expect(cacheSize, lessThan(uncompressedSize));
      });

      test('should invalidate cache efficiently', () async {
        final cores = List.generate(5, (i) => _createTestCore('invalidate_test_$i'));
        
        // Cache all cores
        for (final core in cores) {
          await cacheManager.cacheCore(core);
        }
        
        // Measure invalidation performance
        final invalidateStartTime = DateTime.now();
        await cacheManager.invalidateCore(cores[2].id);
        final invalidateDuration = DateTime.now().difference(invalidateStartTime);
        
        // Invalidation should be fast (< 20ms)
        expect(invalidateDuration.inMilliseconds, lessThan(20));
        
        // Verify specific core is invalidated
        final invalidatedCore = await cacheManager.getCachedCore(cores[2].id);
        expect(invalidatedCore, isNull);
        
        // Verify other cores are still cached
        final stillCachedCore = await cacheManager.getCachedCore(cores[0].id);
        expect(stillCachedCore, isNotNull);
      });

      test('should handle cache eviction under memory pressure', () async {
        // Fill cache with many cores
        final cores = List.generate(100, (i) => _createTestCore('eviction_test_$i'));
        
        for (final core in cores) {
          await cacheManager.cacheCore(core);
        }
        
        // Simulate memory pressure
        await cacheManager.handleMemoryPressure();
        
        final cacheSize = await cacheManager.getCacheSize();
        final cacheCount = await cacheManager.getCachedCoreCount();
        
        // Cache should be reduced under memory pressure
        expect(cacheCount, lessThan(100));
        expect(cacheSize, lessThan(1000000)); // Less than 1MB
      });

      test('should provide cache statistics for monitoring', () async {
        final cores = List.generate(5, (i) => _createTestCore('stats_test_$i'));
        
        // Cache some cores
        for (final core in cores) {
          await cacheManager.cacheCore(core);
        }
        
        // Access some cores to generate hit/miss stats
        await cacheManager.getCachedCore(cores[0].id); // Hit
        await cacheManager.getCachedCore(cores[1].id); // Hit
        await cacheManager.getCachedCore('non_existent'); // Miss
        
        final stats = await cacheManager.getCacheStatistics();
        
        expect(stats['totalCores'], equals(5));
        expect(stats['cacheHits'], equals(2));
        expect(stats['cacheMisses'], equals(1));
        expect(stats['hitRate'], greaterThan(0.5));
        expect(stats['memoryUsage'], isA<int>());
      });
    });

    group('CoreMemoryOptimizer Performance', () {
      late CoreMemoryOptimizer memoryOptimizer;

      setUp(() async {
        memoryOptimizer = CoreMemoryOptimizer();
        await memoryOptimizer.initialize();
      });

      tearDown(() async {
        await memoryOptimizer.dispose();
      });

      test('should optimize core list memory usage', () async {
        final largeCoreList = List.generate(1000, (i) => _createTestCore('memory_test_$i'));
        
        final optimizeStartTime = DateTime.now();
        final optimizedList = memoryOptimizer.optimizeCoreList(largeCoreList);
        final optimizeDuration = DateTime.now().difference(optimizeStartTime);
        
        // Optimization should be fast (< 50ms)
        expect(optimizeDuration.inMilliseconds, lessThan(50));
        
        // Optimized list should be smaller or same size
        expect(optimizedList.length, lessThanOrEqualTo(largeCoreList.length));
        
        // Should maintain essential cores
        expect(optimizedList, isNotEmpty);
      });

      test('should limit core list size for performance', () async {
        final hugeCoreList = List.generate(10000, (i) => _createTestCore('huge_test_$i'));
        
        final optimizedList = memoryOptimizer.optimizeCoreList(hugeCoreList, maxItems: 100);
        
        // Should limit to specified max items
        expect(optimizedList.length, equals(100));
        
        // Should keep most relevant cores (e.g., highest levels)
        final averageLevel = optimizedList
            .map((c) => c.currentLevel)
            .reduce((a, b) => a + b) / optimizedList.length;
        expect(averageLevel, greaterThan(0.5));
      });

      test('should track and manage subscriptions efficiently', () async {
        final subscriptions = <StreamSubscription>[];
        
        // Create multiple subscriptions
        for (int i = 0; i < 10; i++) {
          final controller = StreamController<int>();
          final subscription = controller.stream.listen((_) {});
          subscriptions.add(subscription);
          
          memoryOptimizer.registerSubscription(subscription, 'test_subscription_$i');
        }
        
        final stats = memoryOptimizer.getMemoryStatistics();
        expect(stats['activeSubscriptions'], equals(10));
        
        // Cleanup subscriptions
        await memoryOptimizer.cleanupInactiveSubscriptions();
        
        // Verify cleanup
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      });

      test('should manage timers for memory efficiency', () async {
        final timers = <Timer>[];
        
        // Create multiple timers
        for (int i = 0; i < 5; i++) {
          final timer = Timer.periodic(const Duration(seconds: 1), (_) {});
          timers.add(timer);
          
          memoryOptimizer.registerTimer(timer, 'test_timer_$i');
        }
        
        final stats = memoryOptimizer.getMemoryStatistics();
        expect(stats['activeTimers'], equals(5));
        
        // Cleanup timers
        await memoryOptimizer.cleanupInactiveTimers();
        
        // Cancel timers
        for (final timer in timers) {
          timer.cancel();
        }
      });

      test('should throttle widget rebuilds for performance', () async {
        int rebuildCount = 0;
        
        // Simulate rapid rebuild requests
        for (int i = 0; i < 100; i++) {
          if (!memoryOptimizer.shouldThrottleRebuild('test_widget')) {
            rebuildCount++;
          }
          
          // Small delay to simulate real-world timing
          await Future.delayed(const Duration(microseconds: 100));
        }
        
        // Should throttle excessive rebuilds
        expect(rebuildCount, lessThan(100));
        expect(rebuildCount, greaterThan(0));
      });

      test('should provide memory usage insights', () async {
        // Simulate memory usage
        final largeCoreList = List.generate(500, (i) => _createTestCore('insight_test_$i'));
        memoryOptimizer.optimizeCoreList(largeCoreList);
        
        final insights = memoryOptimizer.getMemoryInsights();
        
        expect(insights['memoryPressure'], isA<String>());
        expect(insights['optimizationSuggestions'], isA<List>());
        expect(insights['performanceMetrics'], isA<Map>());
        expect(insights['resourceUsage'], isA<Map>());
      });

      test('should handle memory pressure gracefully', () async {
        // Fill memory with data
        final largeCoreList = List.generate(2000, (i) => _createTestCore('pressure_test_$i'));
        
        // Simulate memory pressure
        final pressureStartTime = DateTime.now();
        await memoryOptimizer.handleMemoryPressure();
        final pressureDuration = DateTime.now().difference(pressureStartTime);
        
        // Memory pressure handling should be fast (< 100ms)
        expect(pressureDuration.inMilliseconds, lessThan(100));
        
        final stats = memoryOptimizer.getMemoryStatistics();
        expect(stats['memoryOptimized'], isTrue);
      });
    });

    group('CoreBackgroundSyncService Performance', () {
      late CoreBackgroundSyncService syncService;

      setUp(() async {
        syncService = CoreBackgroundSyncService();
        await syncService.initialize();
      });

      tearDown(() async {
        await syncService.dispose();
      });

      test('should queue updates efficiently', () async {
        final updates = List.generate(100, (i) => QueuedUpdate(
          id: 'update_$i',
          coreId: 'test_core_$i',
          type: UpdateType.coreUpdate,
          core: _createTestCore('test_core_$i'),
        ));
        
        final queueStartTime = DateTime.now();
        for (final update in updates) {
          await syncService.queueUpdate(update);
        }
        final queueDuration = DateTime.now().difference(queueStartTime);
        
        // Queuing should be fast (< 200ms for 100 updates)
        expect(queueDuration.inMilliseconds, lessThan(200));
        
        final queueSize = await syncService.getQueueSize();
        expect(queueSize, equals(100));
      });

      test('should process updates in batches for efficiency', () async {
        final updates = List.generate(50, (i) => QueuedUpdate(
          id: 'batch_update_$i',
          coreId: 'batch_core_$i',
          type: UpdateType.coreUpdate,
          core: _createTestCore('batch_core_$i'),
        ));
        
        // Queue all updates
        for (final update in updates) {
          await syncService.queueUpdate(update);
        }
        
        // Process in batches
        final processStartTime = DateTime.now();
        await syncService.processBatch(batchSize: 10);
        final processDuration = DateTime.now().difference(processStartTime);
        
        // Batch processing should be efficient (< 100ms)
        expect(processDuration.inMilliseconds, lessThan(100));
        
        final remainingQueueSize = await syncService.getQueueSize();
        expect(remainingQueueSize, lessThan(50)); // Some updates should be processed
      });

      test('should handle sync conflicts efficiently', () async {
        final conflictingUpdates = [
          QueuedUpdate(
            id: 'conflict_1',
            coreId: 'conflict_core',
            type: UpdateType.coreUpdate,
            core: _createTestCore('conflict_core').copyWith(currentLevel: 0.7),
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
          QueuedUpdate(
            id: 'conflict_2',
            coreId: 'conflict_core',
            type: UpdateType.coreUpdate,
            core: _createTestCore('conflict_core').copyWith(currentLevel: 0.8),
            timestamp: DateTime.now(),
          ),
        ];
        
        for (final update in conflictingUpdates) {
          await syncService.queueUpdate(update);
        }
        
        final conflictStartTime = DateTime.now();
        await syncService.resolveConflicts();
        final conflictDuration = DateTime.now().difference(conflictStartTime);
        
        // Conflict resolution should be fast (< 50ms)
        expect(conflictDuration.inMilliseconds, lessThan(50));
        
        final stats = await syncService.getSyncStatistics();
        expect(stats['conflictsResolved'], greaterThan(0));
      });

      test('should implement exponential backoff for failed syncs', () async {
        final failingUpdate = QueuedUpdate(
          id: 'failing_update',
          coreId: 'failing_core',
          type: UpdateType.coreUpdate,
          core: _createTestCore('failing_core'),
          metadata: {'simulateFailure': true},
        );
        
        await syncService.queueUpdate(failingUpdate);
        
        // First attempt
        final firstAttemptTime = DateTime.now();
        await syncService.processBatch(batchSize: 1);
        
        // Second attempt (should be delayed due to backoff)
        final secondAttemptTime = DateTime.now();
        await syncService.processBatch(batchSize: 1);
        
        final backoffDelay = secondAttemptTime.difference(firstAttemptTime);
        
        // Should implement some delay for failed retries
        expect(backoffDelay.inMilliseconds, greaterThan(10));
        
        final stats = await syncService.getSyncStatistics();
        expect(stats['failedSyncs'], greaterThan(0));
        expect(stats['retryAttempts'], greaterThan(0));
      });

      test('should optimize network requests with batching', () async {
        final updates = List.generate(20, (i) => QueuedUpdate(
          id: 'network_update_$i',
          coreId: 'network_core_$i',
          type: UpdateType.coreUpdate,
          core: _createTestCore('network_core_$i'),
        ));
        
        for (final update in updates) {
          await syncService.queueUpdate(update);
        }
        
        final networkStartTime = DateTime.now();
        await syncService.optimizeNetworkRequests();
        final networkDuration = DateTime.now().difference(networkStartTime);
        
        // Network optimization should be efficient
        expect(networkDuration.inMilliseconds, lessThan(150));
        
        final stats = await syncService.getSyncStatistics();
        expect(stats['batchedRequests'], greaterThan(0));
        expect(stats['networkOptimizations'], greaterThan(0));
      });

      test('should provide sync performance metrics', () async {
        // Generate some sync activity
        final updates = List.generate(10, (i) => QueuedUpdate(
          id: 'metrics_update_$i',
          coreId: 'metrics_core_$i',
          type: UpdateType.coreUpdate,
          core: _createTestCore('metrics_core_$i'),
        ));
        
        for (final update in updates) {
          await syncService.queueUpdate(update);
        }
        
        await syncService.processBatch(batchSize: 5);
        
        final metrics = await syncService.getPerformanceMetrics();
        
        expect(metrics['averageProcessingTime'], isA<double>());
        expect(metrics['throughput'], isA<double>());
        expect(metrics['queueEfficiency'], isA<double>());
        expect(metrics['networkLatency'], isA<double>());
        expect(metrics['successRate'], isA<double>());
      });
    });

    group('Integrated Performance Tests', () {
      test('should handle high-load scenarios efficiently', () async {
        final cacheManager = CoreCacheManager();
        final memoryOptimizer = CoreMemoryOptimizer();
        final syncService = CoreBackgroundSyncService();
        
        await cacheManager.initialize();
        await memoryOptimizer.initialize();
        await syncService.initialize();
        
        try {
          // Simulate high load with many cores and updates
          final cores = List.generate(500, (i) => _createTestCore('load_test_$i'));
          
          final loadTestStartTime = DateTime.now();
          
          // Cache all cores
          for (final core in cores) {
            await cacheManager.cacheCore(core);
          }
          
          // Optimize memory usage
          final optimizedCores = memoryOptimizer.optimizeCoreList(cores, maxItems: 100);
          
          // Queue sync updates
          for (final core in optimizedCores) {
            await syncService.queueUpdate(QueuedUpdate(
              id: 'load_${core.id}',
              coreId: core.id,
              type: UpdateType.coreUpdate,
              core: core,
            ));
          }
          
          // Process updates
          await syncService.processBatch(batchSize: 20);
          
          final loadTestDuration = DateTime.now().difference(loadTestStartTime);
          
          // High load scenario should complete in reasonable time (< 2 seconds)
          expect(loadTestDuration.inSeconds, lessThan(2));
          
          // Verify system stability
          final cacheStats = await cacheManager.getCacheStatistics();
          final memoryStats = memoryOptimizer.getMemoryStatistics();
          final syncStats = await syncService.getSyncStatistics();
          
          expect(cacheStats['totalCores'], greaterThan(0));
          expect(memoryStats['memoryOptimized'], isTrue);
          expect(syncStats['processedUpdates'], greaterThan(0));
          
        } finally {
          await cacheManager.dispose();
          await memoryOptimizer.dispose();
          await syncService.dispose();
        }
      });

      test('should maintain performance under memory pressure', () async {
        final memoryOptimizer = CoreMemoryOptimizer();
        await memoryOptimizer.initialize();
        
        try {
          // Create memory pressure with large datasets
          final largeCoreList = List.generate(5000, (i) => _createTestCore('pressure_$i'));
          
          final pressureStartTime = DateTime.now();
          
          // Perform operations under memory pressure
          final optimizedList1 = memoryOptimizer.optimizeCoreList(largeCoreList, maxItems: 50);
          await memoryOptimizer.handleMemoryPressure();
          final optimizedList2 = memoryOptimizer.optimizeCoreList(largeCoreList, maxItems: 50);
          
          final pressureDuration = DateTime.now().difference(pressureStartTime);
          
          // Should handle memory pressure efficiently (< 500ms)
          expect(pressureDuration.inMilliseconds, lessThan(500));
          
          // Should maintain functionality
          expect(optimizedList1.length, equals(50));
          expect(optimizedList2.length, equals(50));
          
          final stats = memoryOptimizer.getMemoryStatistics();
          expect(stats['memoryOptimized'], isTrue);
          
        } finally {
          await memoryOptimizer.dispose();
        }
      });
    });
  });
}

// Helper function to create test cores
EmotionalCore _createTestCore(String id) {
  return EmotionalCore(
    id: id,
    name: 'Test Core $id',
    description: 'A test core for performance testing',
    currentLevel: 0.5 + (id.hashCode % 100) / 200.0, // Vary levels
    previousLevel: 0.4 + (id.hashCode % 100) / 200.0,
    lastUpdated: DateTime.now(),
    trend: ['rising', 'stable', 'declining'][id.hashCode % 3],
    color: '#${(id.hashCode % 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
    iconPath: 'test_icon_$id.png',
    insight: 'Test insight for $id',
    relatedCores: [],
    milestones: [],
    recentInsights: [],
  );
}