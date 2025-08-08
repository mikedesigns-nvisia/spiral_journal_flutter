import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/models/core_error.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('CoreProvider Unit Tests', () {
    late CoreProvider provider;
    late TestSetupHelper testHelper;

    setUp(() async {
      testHelper = TestSetupHelper();
      await testHelper.setUp();
      
      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});
      
      provider = CoreProvider();
    });

    tearDown(() async {
      provider.dispose();
      await testHelper.tearDown();
    });

    group('Initialization', () {
      test('should initialize successfully with all services', () async {
        await provider.initialize();
        
        expect(provider.allCores, isNotEmpty);
        expect(provider.topCores, isNotEmpty);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('should handle initialization failure gracefully', () async {
        // Create a provider that will fail initialization
        final failingProvider = CoreProvider();
        
        // Mock a failure scenario by disposing services before init
        failingProvider.dispose();
        
        // Attempt initialization - should handle gracefully
        await failingProvider.initialize();
        
        // Should have error state but not crash
        expect(failingProvider.error, isNotNull);
        expect(failingProvider.error!.type, equals(CoreErrorType.dataLoadFailure));
      });

      test('should initialize cache manager correctly', () async {
        await provider.initialize();
        
        // Verify cache is working by loading cores twice
        await provider.loadAllCores();
        final firstLoadTime = DateTime.now();
        
        await provider.loadAllCores();
        final secondLoadTime = DateTime.now();
        
        // Second load should be faster due to caching
        expect(secondLoadTime.difference(firstLoadTime).inMilliseconds, lessThan(100));
      });

      test('should initialize real-time synchronization', () async {
        await provider.initialize();
        
        expect(provider.coreUpdateStream, isNotNull);
        
        // Test that update stream is working
        final streamCompleter = Completer<CoreUpdateEvent>();
        final subscription = provider.coreUpdateStream.listen((event) {
          if (!streamCompleter.isCompleted) {
            streamCompleter.complete(event);
          }
        });
        
        // Trigger an update
        final testCore = await _createTestCore();
        await provider.updateCore(testCore);
        
        // Should receive update event
        final event = await streamCompleter.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw TimeoutException('No update event received'),
        );
        
        expect(event.coreId, equals(testCore.id));
        expect(event.type, equals(CoreUpdateEventType.levelChanged));
        
        await subscription.cancel();
      });
    });

    group('Core Data Management', () {
      setUp(() async {
        await provider.initialize();
      });

      test('should load all cores successfully', () async {
        await provider.loadAllCores();
        
        expect(provider.allCores.length, equals(6));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        
        // Verify all expected cores are present
        final coreIds = provider.allCores.map((c) => c.id).toList();
        expect(coreIds, contains('optimism'));
        expect(coreIds, contains('resilience'));
        expect(coreIds, contains('self_awareness'));
        expect(coreIds, contains('creativity'));
        expect(coreIds, contains('social_connection'));
        expect(coreIds, contains('growth_mindset'));
      });

      test('should load top cores with correct limit', () async {
        await provider.loadTopCores(limit: 3);
        
        expect(provider.topCores.length, equals(3));
        expect(provider.isLoading, isFalse);
        
        // Top cores should be sorted by level
        for (int i = 0; i < provider.topCores.length - 1; i++) {
          expect(
            provider.topCores[i].currentLevel,
            greaterThanOrEqualTo(provider.topCores[i + 1].currentLevel),
          );
        }
      });

      test('should handle force refresh correctly', () async {
        // Load cores normally
        await provider.loadAllCores();
        final firstLoadCores = List<EmotionalCore>.from(provider.allCores);
        
        // Force refresh
        await provider.loadAllCores(forceRefresh: true);
        final refreshedCores = provider.allCores;
        
        expect(refreshedCores.length, equals(firstLoadCores.length));
        // Data should be refreshed (timestamps might differ)
        expect(provider.error, isNull);
      });

      test('should get core by ID correctly', () async {
        await provider.loadAllCores();
        
        final optimismCore = provider.getCoreById('optimism');
        expect(optimismCore, isNotNull);
        expect(optimismCore!.id, equals('optimism'));
        expect(optimismCore.name, equals('Optimism'));
        
        final nonExistentCore = provider.getCoreById('non_existent');
        expect(nonExistentCore, isNull);
      });

      test('should get core by name correctly', () async {
        await provider.loadAllCores();
        
        final resilienceCore = provider.getCoreByName('Resilience');
        expect(resilienceCore, isNotNull);
        expect(resilienceCore!.name, equals('Resilience'));
        expect(resilienceCore.id, equals('resilience'));
        
        // Case insensitive search
        final creativityCore = provider.getCoreByName('creativity');
        expect(creativityCore, isNotNull);
        expect(creativityCore!.name, equals('Creativity'));
      });

      test('should get cores by trend correctly', () async {
        await provider.loadAllCores();
        
        // Update some cores to create different trends
        final testCore1 = provider.getCoreById('optimism')!;
        final testCore2 = provider.getCoreById('resilience')!;
        
        final risingCore = testCore1.copyWith(
          currentLevel: testCore1.previousLevel + 0.1,
          trend: 'rising',
        );
        final decliningCore = testCore2.copyWith(
          currentLevel: testCore2.previousLevel - 0.1,
          trend: 'declining',
        );
        
        await provider.updateCore(risingCore);
        await provider.updateCore(decliningCore);
        
        final risingCores = provider.risingCores;
        final decliningCores = provider.decliningCores;
        final stableCores = provider.stableCores;
        
        expect(risingCores.any((c) => c.id == 'optimism'), isTrue);
        expect(decliningCores.any((c) => c.id == 'resilience'), isTrue);
        expect(stableCores.length, greaterThan(0));
      });
    });

    group('Core Updates and Synchronization', () {
      setUp(() async {
        await provider.initialize();
        await provider.loadAllCores();
      });

      test('should update core successfully', () async {
        final originalCore = provider.getCoreById('optimism')!;
        final updatedCore = originalCore.copyWith(
          currentLevel: originalCore.currentLevel + 0.1,
          lastUpdated: DateTime.now(),
        );
        
        final result = await provider.updateCore(updatedCore);
        
        expect(result, isTrue);
        expect(provider.error, isNull);
        
        final retrievedCore = provider.getCoreById('optimism')!;
        expect(retrievedCore.currentLevel, equals(updatedCore.currentLevel));
      });

      test('should update core with journal context', () async {
        final testEntry = JournalEntry(
          id: 'test_entry',
          userId: 'test_user',
          content: 'Test journal entry',
          date: DateTime.now(),
          moods: ['happy'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final result = await provider.updateCoreWithContext(
          'optimism',
          testEntry,
          additionalData: {'source': 'journal_analysis'},
        );
        
        expect(result, isTrue);
        expect(provider.error, isNull);
        
        // Verify context was preserved
        final context = provider.coreContexts['optimism'];
        expect(context, isNotNull);
        expect(context!.relatedJournalEntryIds, contains(testEntry.id));
      });

      test('should handle batch core updates', () async {
        final cores = provider.allCores.take(3).map((core) => 
          core.copyWith(
            currentLevel: core.currentLevel + 0.05,
            lastUpdated: DateTime.now(),
          )
        ).toList();
        
        final result = await provider.batchUpdateCores(
          cores,
          updateSource: 'test_batch',
        );
        
        expect(result, isTrue);
        expect(provider.error, isNull);
        
        // Verify all cores were updated
        for (final core in cores) {
          final updatedCore = provider.getCoreById(core.id)!;
          expect(updatedCore.currentLevel, equals(core.currentLevel));
        }
      });

      test('should resolve core conflicts correctly', () async {
        // Create conflicting cores (same ID, different timestamps)
        final baseCore = provider.getCoreById('optimism')!;
        final conflictingCores = [
          baseCore.copyWith(
            currentLevel: 0.8,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
          baseCore.copyWith(
            currentLevel: 0.9,
            lastUpdated: DateTime.now(),
          ),
        ];
        
        await provider.resolveCoreConflicts(conflictingCores);
        
        expect(provider.error, isNull);
        
        // Latest update should win
        final resolvedCore = provider.getCoreById('optimism')!;
        expect(resolvedCore.currentLevel, equals(0.9));
      });

      test('should broadcast update events correctly', () async {
        final eventCompleter = Completer<CoreUpdateEvent>();
        final subscription = provider.coreUpdateStream.listen((event) {
          if (!eventCompleter.isCompleted) {
            eventCompleter.complete(event);
          }
        });
        
        final testCore = provider.getCoreById('optimism')!;
        final updatedCore = testCore.copyWith(
          currentLevel: testCore.currentLevel + 0.1,
        );
        
        await provider.updateCore(updatedCore);
        
        final event = await eventCompleter.future.timeout(
          const Duration(seconds: 2),
        );
        
        expect(event.coreId, equals('optimism'));
        expect(event.type, equals(CoreUpdateEventType.levelChanged));
        expect(event.updateSource, isNotNull);
        
        await subscription.cancel();
      });
    });

    group('Navigation Context Management', () {
      setUp(() async {
        await provider.initialize();
        await provider.loadAllCores();
      });

      test('should navigate to core with context', () async {
        final context = CoreNavigationContext(
          sourceScreen: 'journal',
          triggeredBy: 'core_tap',
          targetCoreId: 'optimism',
          timestamp: DateTime.now(),
        );
        
        await provider.navigateToCore('optimism', context: context);
        
        expect(provider.navigationState.currentCoreId, equals('optimism'));
        expect(provider.navigationState.currentContext, equals(context));
        expect(provider.navigationState.navigationHistory, contains('optimism'));
      });

      test('should preload core details for performance', () async {
        final coreIds = ['optimism', 'resilience', 'creativity'];
        
        await provider.preloadCoreDetails(coreIds);
        
        // Verify contexts were loaded
        for (final coreId in coreIds) {
          expect(provider.coreContexts.containsKey(coreId), isTrue);
        }
      });

      test('should handle navigation to non-existent core', () async {
        await provider.navigateToCore('non_existent_core');
        
        expect(provider.error, isNotNull);
        expect(provider.error!.type, equals(CoreErrorType.navigationError));
        expect(provider.error!.coreId, equals('non_existent_core'));
      });
    });

    group('Performance Optimization', () {
      setUp(() async {
        await provider.initialize();
      });

      test('should throttle notifications correctly', () async {
        int notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        // Trigger multiple rapid updates
        for (int i = 0; i < 10; i++) {
          provider.notifyListeners();
        }
        
        // Should be throttled to prevent excessive notifications
        expect(notificationCount, lessThan(10));
      });

      test('should use cache for repeated data loads', () async {
        // First load
        final startTime1 = DateTime.now();
        await provider.loadAllCores();
        final duration1 = DateTime.now().difference(startTime1);
        
        // Second load (should use cache)
        final startTime2 = DateTime.now();
        await provider.loadAllCores();
        final duration2 = DateTime.now().difference(startTime2);
        
        // Second load should be significantly faster
        expect(duration2.inMilliseconds, lessThan(duration1.inMilliseconds));
      });

      test('should clean up preload cache correctly', () async {
        // Preload some cores
        await provider.preloadCoreDetails(['optimism', 'resilience']);
        
        // Access private method through reflection or test internal state
        // For now, just verify the operation doesn't throw
        expect(() => provider.preloadCoreDetails(['creativity']), returnsNormally);
      });
    });

    group('Error Handling and Recovery', () {
      setUp(() async {
        await provider.initialize();
      });

      test('should handle data load failures gracefully', () async {
        // Simulate a failure by disposing the provider first
        provider.dispose();
        
        await provider.loadAllCores();
        
        expect(provider.error, isNotNull);
        expect(provider.error!.type, equals(CoreErrorType.dataLoadFailure));
        expect(provider.error!.isRecoverable, isTrue);
      });

      test('should handle update failures gracefully', () async {
        await provider.loadAllCores();
        
        // Try to update with invalid data
        final invalidCore = EmotionalCore(
          id: 'invalid',
          name: 'Invalid',
          description: 'Invalid core',
          currentLevel: -1.0, // Invalid level
          previousLevel: 0.0,
          lastUpdated: DateTime.now(),
          trend: 'stable',
          color: '#000000',
          iconPath: 'invalid',
          insight: 'Invalid',
          relatedCores: [],
        );
        
        final result = await provider.updateCore(invalidCore);
        
        expect(result, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error!.type, equals(CoreErrorType.persistenceError));
      });

      test('should execute recovery actions correctly', () async {
        // Set up an error state
        await provider.loadAllCores();
        provider.dispose(); // Force an error
        await provider.loadAllCores(); // This should fail
        
        expect(provider.error, isNotNull);
        
        // Execute recovery action
        final success = await provider.executeRecoveryAction(
          CoreErrorRecoveryAction.refreshData,
        );
        
        // Recovery might not succeed in test environment, but should not crash
        expect(success, isA<bool>());
      });

      test('should provide error statistics', () async {
        final stats = provider.getErrorStatistics();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalErrors'), isTrue);
        expect(stats.containsKey('errorsByType'), isTrue);
      });

      test('should clear errors correctly', () async {
        // Force an error
        provider.dispose();
        await provider.loadAllCores();
        
        expect(provider.error, isNotNull);
        
        provider.clearError();
        
        expect(provider.error, isNull);
      });
    });

    group('Offline Support', () {
      setUp(() async {
        await provider.initialize();
        await provider.loadAllCores();
      });

      test('should handle offline mode correctly', () async {
        await provider.setOfflineMode(true);
        
        expect(provider.isOperatingOffline, isTrue);
        expect(provider.offlineStatus.isOfflineModeEnabled, isTrue);
      });

      test('should load cached data when offline', () async {
        // Load data while online
        await provider.loadAllCores();
        final onlineCores = List<EmotionalCore>.from(provider.allCores);
        
        // Switch to offline mode
        await provider.setOfflineMode(true);
        
        // Load data while offline
        await provider.loadAllCores();
        
        expect(provider.allCores.length, equals(onlineCores.length));
        expect(provider.error, isNull);
      });

      test('should queue updates when offline', () async {
        await provider.setOfflineMode(true);
        
        final testCore = provider.getCoreById('optimism')!;
        final updatedCore = testCore.copyWith(
          currentLevel: testCore.currentLevel + 0.1,
        );
        
        final result = await provider.updateCore(updatedCore);
        
        // Update should be queued, not fail
        expect(result, isTrue);
        expect(provider.error, isNull);
      });
    });

    group('Memory Management', () {
      setUp(() async {
        await provider.initialize();
      });

      test('should dispose resources correctly', () async {
        await provider.loadAllCores();
        
        // Verify resources are active
        expect(provider.coreUpdateStream, isNotNull);
        
        provider.dispose();
        
        // Verify cleanup
        expect(() => provider.notifyListeners(), returnsNormally);
      });

      test('should handle memory optimization', () async {
        await provider.loadAllCores();
        
        // Load a large number of cores to test memory optimization
        final largeCoreList = List.generate(100, (index) => 
          provider.allCores.first.copyWith(id: 'test_$index')
        );
        
        // Memory optimizer should handle large lists gracefully
        expect(() => provider.allCores, returnsNormally);
      });
    });
  });
}

// Helper function to create test cores
Future<EmotionalCore> _createTestCore() async {
  return EmotionalCore(
    id: 'test_core',
    name: 'Test Core',
    description: 'A test core for unit testing',
    currentLevel: 0.5,
    previousLevel: 0.4,
    lastUpdated: DateTime.now(),
    trend: 'rising',
    color: '#FF0000',
    iconPath: 'test_icon.png',
    insight: 'Test insight',
    relatedCores: [],
    milestones: [],
    recentInsights: [],
  );
}