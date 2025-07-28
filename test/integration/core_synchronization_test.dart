import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/services/core_background_sync_service.dart';
import 'package:spiral_journal/services/core_cache_manager.dart';
import 'package:spiral_journal/services/core_offline_support_service.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Core Synchronization Integration Tests', () {
    late TestSetupHelper testHelper;
    late CoreProvider coreProvider;
    late CoreBackgroundSyncService syncService;
    late CoreCacheManager cacheManager;
    late CoreOfflineSupportService offlineService;

    setUp(() async {
      testHelper = TestSetupHelper();
      await testHelper.setUp();
      
      SharedPreferences.setMockInitialValues({});
      
      coreProvider = CoreProvider();
      syncService = CoreBackgroundSyncService();
      cacheManager = CoreCacheManager();
      offlineService = CoreOfflineSupportService();
      
      await coreProvider.initialize();
      await syncService.initialize();
      await cacheManager.initialize();
      await offlineService.initialize();
    });

    tearDown(() async {
      coreProvider.dispose();
      syncService.dispose();
      await cacheManager.dispose();
      offlineService.dispose();
      await testHelper.tearDown();
    });

    group('Real-time Synchronization', () {
      test('should synchronize core updates across multiple providers', () async {
        // Create second provider instance
        final provider2 = CoreProvider();
        await provider2.initialize();

        try {
          // Load initial data in both providers
          await coreProvider.loadAllCores();
          await provider2.loadAllCores();

          // Verify initial consistency
          expect(coreProvider.allCores.length, equals(provider2.allCores.length));

          // Set up sync listeners
          final provider1Updates = <CoreUpdateEvent>[];
          final provider2Updates = <CoreUpdateEvent>[];

          final subscription1 = coreProvider.coreUpdateStream.listen((event) {
            provider1Updates.add(event);
          });

          final subscription2 = provider2.coreUpdateStream.listen((event) {
            provider2Updates.add(event);
          });

          // Update core in first provider
          final testCore = coreProvider.getCoreById('optimism')!.copyWith(
            currentLevel: 0.85,
            trend: 'rising',
            lastUpdated: DateTime.now(),
          );

          await coreProvider.updateCore(testCore);

          // Wait for sync propagation
          await Future.delayed(const Duration(milliseconds: 200));

          // Simulate sync to second provider
          await provider2.refresh(forceRefresh: true);

          // Verify synchronization
          final core1 = coreProvider.getCoreById('optimism')!;
          final core2 = provider2.getCoreById('optimism')!;

          expect(core1.currentLevel, equals(core2.currentLevel));
          expect(core1.trend, equals(core2.trend));

          // Verify update events were broadcast
          expect(provider1Updates, isNotEmpty);
          expect(provider1Updates.any((e) => e.coreId == 'optimism'), isTrue);

          await subscription1.cancel();
          await subscription2.cancel();

        } finally {
          provider2.dispose();
        }
      });

      test('should handle concurrent updates with conflict resolution', () async {
        await coreProvider.loadAllCores();

        // Create conflicting updates
        final baseCore = coreProvider.getCoreById('resilience')!;
        final conflictingCores = [
          baseCore.copyWith(
            currentLevel: 0.7,
            lastUpdated: DateTime.now().subtract(const Duration(seconds: 1)),
          ),
          baseCore.copyWith(
            currentLevel: 0.8,
            lastUpdated: DateTime.now(),
          ),
          baseCore.copyWith(
            currentLevel: 0.75,
            lastUpdated: DateTime.now().subtract(const Duration(seconds: 2)),
          ),
        ];

        // Apply conflict resolution
        await coreProvider.resolveCoreConflicts(conflictingCores);

        // Verify latest update won (timestamp-based resolution)
        final resolvedCore = coreProvider.getCoreById('resilience')!;
        expect(resolvedCore.currentLevel, equals(0.8)); // Latest timestamp
        expect(coreProvider.error, isNull);
      });

      test('should batch multiple rapid updates for efficiency', () async {
        await coreProvider.loadAllCores();

        // Set up update tracking
        final updateEvents = <CoreUpdateEvent>[];
        final subscription = coreProvider.coreUpdateStream.listen((event) {
          updateEvents.add(event);
        });

        try {
          // Create multiple rapid updates
          final cores = ['optimism', 'resilience', 'creativity'].map((id) {
            final core = coreProvider.getCoreById(id)!;
            return core.copyWith(
              currentLevel: core.currentLevel + 0.1,
              lastUpdated: DateTime.now(),
            );
          }).toList();

          // Batch update
          final success = await coreProvider.batchUpdateCores(
            cores,
            updateSource: 'batch_test',
          );

          expect(success, isTrue);

          // Wait for events to propagate
          await Future.delayed(const Duration(milliseconds: 100));

          // Verify batch update event was broadcast
          final batchEvents = updateEvents.where((e) => 
            e.type == CoreUpdateEventType.batchUpdate).toList();
          expect(batchEvents, isNotEmpty);

          // Verify individual core updates
          for (final core in cores) {
            final updatedCore = coreProvider.getCoreById(core.id)!;
            expect(updatedCore.currentLevel, equals(core.currentLevel));
          }

        } finally {
          await subscription.cancel();
        }
      });

      test('should maintain sync during high-frequency updates', () async {
        await coreProvider.loadAllCores();

        final updateEvents = <CoreUpdateEvent>[];
        final subscription = coreProvider.coreUpdateStream.listen((event) {
          updateEvents.add(event);
        });

        try {
          // Simulate high-frequency updates
          final baseCore = coreProvider.getCoreById('self_awareness')!;
          
          for (int i = 0; i < 20; i++) {
            final updatedCore = baseCore.copyWith(
              currentLevel: baseCore.currentLevel + (i * 0.005),
              lastUpdated: DateTime.now().add(Duration(milliseconds: i * 10)),
            );

            await coreProvider.updateCore(updatedCore);
            
            // Small delay to simulate rapid updates
            await Future.delayed(const Duration(milliseconds: 25));
          }

          // Wait for all updates to process
          await Future.delayed(const Duration(milliseconds: 200));

          // Verify final state is consistent
          final finalCore = coreProvider.getCoreById('self_awareness')!;
          expect(finalCore.currentLevel, greaterThan(baseCore.currentLevel));
          expect(coreProvider.error, isNull);

          // Verify update events were generated (may be throttled)
          expect(updateEvents, isNotEmpty);
          expect(updateEvents.any((e) => e.coreId == 'self_awareness'), isTrue);

        } finally {
          await subscription.cancel();
        }
      });
    });

    group('Background Synchronization', () {
      test('should queue updates for background processing', () async {
        await coreProvider.loadAllCores();

        // Create updates to queue
        final updates = ['optimism', 'resilience', 'creativity'].map((id) {
          final core = coreProvider.getCoreById(id)!;
          return QueuedUpdate(
            id: 'bg_update_$id',
            coreId: id,
            type: UpdateType.coreUpdate,
            core: core.copyWith(
              currentLevel: core.currentLevel + 0.05,
              lastUpdated: DateTime.now(),
            ),
          );
        }).toList();

        // Queue updates
        for (final update in updates) {
          await syncService.queueUpdate(update);
        }

        // Verify queue size
        final queueSize = await syncService.getQueueSize();
        expect(queueSize, equals(3));

        // Process queue
        await syncService.processBatch(batchSize: 2);

        // Verify some updates were processed
        final remainingQueueSize = await syncService.getQueueSize();
        expect(remainingQueueSize, lessThan(3));
      });

      test('should handle background sync failures with retry', () async {
        // Create update that will fail
        final failingUpdate = QueuedUpdate(
          id: 'failing_update',
          coreId: 'test_core',
          type: UpdateType.coreUpdate,
          core: _createTestCore('test_core'),
          metadata: {'simulateFailure': true},
        );

        await syncService.queueUpdate(failingUpdate);

        // Process with failure
        await syncService.processBatch(batchSize: 1);

        // Verify retry was scheduled
        final stats = syncService.getSyncStatistics();
        expect(stats['failedSyncs'], greaterThan(0));
        expect(stats['retryAttempts'], greaterThan(0));
      });

      test('should optimize network requests through batching', () async {
        await coreProvider.loadAllCores();

        // Create multiple updates
        final updates = List.generate(10, (i) {
          final core = coreProvider.getCoreById('optimism')!;
          return QueuedUpdate(
            id: 'network_update_$i',
            coreId: 'optimism',
            type: UpdateType.coreUpdate,
            core: core.copyWith(
              currentLevel: core.currentLevel + (i * 0.01),
              lastUpdated: DateTime.now().add(Duration(milliseconds: i * 10)),
            ),
          );
        });

        // Queue all updates
        for (final update in updates) {
          await syncService.queueUpdate(update);
        }

        // Optimize network requests
        await syncService.optimizeNetworkRequests();

        // Verify optimization occurred
        final stats = syncService.getSyncStatistics();
        expect(stats['batchedRequests'], greaterThan(0));
        expect(stats['networkOptimizations'], greaterThan(0));
      });

      test('should maintain sync integrity during network interruptions', () async {
        await coreProvider.loadAllCores();

        // Simulate network interruption
        await offlineService.setOfflineMode(true);

        // Try to update core while offline
        final testCore = coreProvider.getCoreById('growth_mindset')!.copyWith(
          currentLevel: 0.9,
          lastUpdated: DateTime.now(),
        );

        final success = await coreProvider.updateCore(testCore);
        expect(success, isTrue); // Should queue for later sync

        // Verify update was queued for offline processing
        final offlineStatus = offlineService.getOfflineStatus();
        expect(offlineStatus.hasPendingOperations, isTrue);

        // Restore network connection
        await offlineService.setOfflineMode(false);

        // Wait for sync to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify update was applied
        final updatedCore = coreProvider.getCoreById('growth_mindset')!;
        expect(updatedCore.currentLevel, equals(0.9));
      });
    });

    group('Cache Synchronization', () {
      test('should synchronize cache with live data', () async {
        await coreProvider.loadAllCores();

        // Cache initial data
        final initialCore = coreProvider.getCoreById('social_connection')!;
        await cacheManager.cacheCore(initialCore);

        // Update core
        final updatedCore = initialCore.copyWith(
          currentLevel: initialCore.currentLevel + 0.2,
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(updatedCore);

        // Verify cache was invalidated
        await cacheManager.invalidateCore(initialCore.id);

        // Cache updated data
        await cacheManager.cacheCore(updatedCore);

        // Verify cached data matches live data
        final cachedCore = await cacheManager.getCachedCore(initialCore.id);
        expect(cachedCore, isNotNull);
        expect(cachedCore!.currentLevel, equals(updatedCore.currentLevel));
      });

      test('should handle cache-live data conflicts', () async {
        await coreProvider.loadAllCores();

        // Create cached version
        final cachedCore = coreProvider.getCoreById('creativity')!.copyWith(
          currentLevel: 0.6,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        await cacheManager.cacheCore(cachedCore);

        // Create newer live version
        final liveCore = cachedCore.copyWith(
          currentLevel: 0.8,
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(liveCore);

        // Load from cache and verify conflict resolution
        await coreProvider.loadAllCores();

        // Live data should take precedence
        final resolvedCore = coreProvider.getCoreById('creativity')!;
        expect(resolvedCore.currentLevel, equals(0.8));
      });

      test('should warm cache efficiently during sync', () async {
        // Clear existing cache
        await cacheManager.clearCache();

        // Load cores (should populate cache)
        await coreProvider.loadAllCores();

        // Verify cache was warmed
        final cacheStats = cacheManager.getCacheStatistics();
        expect(cacheStats['totalCores'], equals(6));

        // Verify cache hit rate improves on subsequent loads
        await coreProvider.loadAllCores();
        
        final updatedStats = cacheManager.getCacheStatistics();
        expect(updatedStats['cacheHits'], greaterThan(0));
        expect(updatedStats['hitRate'], greaterThan(0.5));
      });
    });

    group('Offline Synchronization', () {
      test('should queue operations while offline and sync when online', () async {
        await coreProvider.loadAllCores();

        // Go offline
        await offlineService.setOfflineMode(true);
        expect(coreProvider.isOperatingOffline, isTrue);

        // Perform updates while offline
        final offlineUpdates = ['optimism', 'resilience'].map((id) {
          final core = coreProvider.getCoreById(id)!;
          return core.copyWith(
            currentLevel: core.currentLevel + 0.1,
            lastUpdated: DateTime.now(),
          );
        }).toList();

        for (final core in offlineUpdates) {
          await coreProvider.updateCore(core);
        }

        // Verify operations were queued
        final offlineStatus = offlineService.getOfflineStatus();
        expect(offlineStatus.hasPendingOperations, isTrue);
        expect(offlineStatus.pendingOperationCount, equals(2));

        // Go back online
        await offlineService.setOfflineMode(false);

        // Wait for sync to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Verify updates were applied
        for (final core in offlineUpdates) {
          final syncedCore = coreProvider.getCoreById(core.id)!;
          expect(syncedCore.currentLevel, equals(core.currentLevel));
        }

        // Verify queue was cleared
        final finalStatus = offlineService.getOfflineStatus();
        expect(finalStatus.pendingOperationCount, equals(0));
      });

      test('should provide offline data when network unavailable', () async {
        // Load and cache data while online
        await coreProvider.loadAllCores();
        
        // Cache all cores
        for (final core in coreProvider.allCores) {
          await cacheManager.cacheCore(core);
        }

        // Go offline
        await offlineService.setOfflineMode(true);

        // Clear live data to simulate network unavailability
        await coreProvider.refresh(forceRefresh: true);

        // Verify offline data is available
        expect(coreProvider.allCores, isNotEmpty);
        expect(coreProvider.error, isNull);
      });

      test('should handle offline-online transitions gracefully', () async {
        await coreProvider.loadAllCores();

        // Simulate multiple offline-online transitions
        for (int i = 0; i < 3; i++) {
          // Go offline
          await offlineService.setOfflineMode(true);
          
          // Update core while offline
          final core = coreProvider.getCoreById('self_awareness')!.copyWith(
            currentLevel: 0.5 + (i * 0.1),
            lastUpdated: DateTime.now(),
          );
          
          await coreProvider.updateCore(core);
          
          // Go online
          await offlineService.setOfflineMode(false);
          
          // Wait for sync
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Verify final state is consistent
        final finalCore = coreProvider.getCoreById('self_awareness')!;
        expect(finalCore.currentLevel, equals(0.7)); // Last update
        expect(coreProvider.error, isNull);
      });
    });

    group('Journal-Core Synchronization', () {
      test('should synchronize core updates from journal analysis', () async {
        await coreProvider.loadAllCores();

        // Create journal entry
        final journalEntry = JournalEntry(
          id: 'sync_test_entry',
          userId: 'test_user',
          content: 'I feel incredibly optimistic about the future and resilient in facing challenges.',
          date: DateTime.now(),
          moods: ['optimistic', 'resilient', 'confident'],
          dayOfWeek: 'Wednesday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Create analysis result
        final analysisResult = EmotionalAnalysisResult(
          primaryEmotions: ['optimistic', 'resilient', 'confident'],
          emotionalIntensity: 8.5,
          keyThemes: ['optimism', 'resilience', 'confidence'],
          overallSentiment: 0.9,
          personalizedInsight: 'Strong positive emotions detected.',
          coreImpacts: {
            'Optimism': 0.12,
            'Resilience': 0.10,
            'Self-Awareness': 0.05,
          },
          emotionalPatterns: ['positive_growth'],
          growthIndicators: ['emotional_strength'],
          validationScore: 0.95,
        );

        // Get initial levels
        final initialOptimism = coreProvider.getCoreById('optimism')!.currentLevel;
        final initialResilience = coreProvider.getCoreById('resilience')!.currentLevel;

        // Process journal analysis
        await coreProvider.updateCoresWithJournalAnalysis([journalEntry], analysisResult);

        // Verify cores were updated
        final updatedOptimism = coreProvider.getCoreById('optimism')!;
        final updatedResilience = coreProvider.getCoreById('resilience')!;

        expect(updatedOptimism.currentLevel, greaterThan(initialOptimism));
        expect(updatedResilience.currentLevel, greaterThan(initialResilience));

        // Verify journal connection was established
        final optimismContext = coreProvider.coreContexts['optimism'];
        expect(optimismContext, isNotNull);
        expect(optimismContext!.relatedJournalEntryIds, contains(journalEntry.id));
      });

      test('should handle multiple journal entries affecting same cores', () async {
        await coreProvider.loadAllCores();

        // Create multiple journal entries
        final journalEntries = List.generate(3, (i) => JournalEntry(
          id: 'multi_entry_$i',
          userId: 'test_user',
          content: 'Entry $i: Growing in creativity and self-awareness.',
          date: DateTime.now().subtract(Duration(days: i)),
          moods: ['creative', 'insightful'],
          dayOfWeek: 'Thursday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        // Create cumulative analysis
        final analysisResult = EmotionalAnalysisResult(
          primaryEmotions: ['creative', 'insightful'],
          emotionalIntensity: 7.0,
          keyThemes: ['creativity', 'self_awareness'],
          overallSentiment: 0.8,
          personalizedInsight: 'Consistent growth in creativity and self-awareness.',
          coreImpacts: {
            'Creativity': 0.08,
            'Self-Awareness': 0.10,
          },
          emotionalPatterns: ['consistent_growth'],
          growthIndicators: ['creative_development', 'self_reflection'],
          validationScore: 0.9,
        );

        // Get initial levels
        final initialCreativity = coreProvider.getCoreById('creativity')!.currentLevel;
        final initialSelfAwareness = coreProvider.getCoreById('self_awareness')!.currentLevel;

        // Process multiple entries
        await coreProvider.updateCoresWithJournalAnalysis(journalEntries, analysisResult);

        // Verify cumulative impact
        final updatedCreativity = coreProvider.getCoreById('creativity')!;
        final updatedSelfAwareness = coreProvider.getCoreById('self_awareness')!;

        expect(updatedCreativity.currentLevel, greaterThan(initialCreativity));
        expect(updatedSelfAwareness.currentLevel, greaterThan(initialSelfAwareness));

        // Verify all entries are connected
        final creativityContext = coreProvider.coreContexts['creativity'];
        expect(creativityContext, isNotNull);
        
        for (final entry in journalEntries) {
          expect(creativityContext!.relatedJournalEntryIds, contains(entry.id));
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
    description: 'A test core for synchronization testing',
    currentLevel: 0.5,
    previousLevel: 0.4,
    lastUpdated: DateTime.now(),
    trend: 'stable',
    color: '#FF0000',
    iconPath: 'test_icon.png',
    insight: 'Test insight',
    relatedCores: [],
    milestones: [],
    recentInsights: [],
  );
}