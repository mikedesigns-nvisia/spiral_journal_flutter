import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/services/core_navigation_context_service.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/screens/journal_screen.dart';
import 'package:spiral_journal/screens/core_library_screen.dart';
import 'package:spiral_journal/widgets/your_cores_card.dart';
import '../utils/test_setup_helper.dart';
import '../utils/integration_test_app.dart';

void main() {
  group('Core Integration Enhancement Integration Tests', () {
    late TestSetupHelper testHelper;
    late CoreProvider coreProvider;
    late CoreNavigationContextService navigationService;
    late JournalService journalService;

    setUp(() async {
      testHelper = TestSetupHelper();
      await testHelper.setUp();
      
      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});
      
      coreProvider = CoreProvider();
      navigationService = CoreNavigationContextService();
      journalService = JournalService();
      
      await coreProvider.initialize();
    });

    tearDown(() async {
      coreProvider.dispose();
      navigationService.dispose();
      await testHelper.tearDown();
    });

    group('End-to-End Journal-to-Core Update Flow', () {
      testWidgets('should update cores after journal entry with AI analysis', (WidgetTester tester) async {
        // Create test app with providers
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: const JournalScreen(),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Get initial core states
        final initialOptimismCore = coreProvider.getCoreById('optimism');
        final initialResilienceCore = coreProvider.getCoreById('resilience');
        
        expect(initialOptimismCore, isNotNull);
        expect(initialResilienceCore, isNotNull);
        
        final initialOptimismLevel = initialOptimismCore!.currentLevel;
        final initialResilienceLevel = initialResilienceCore!.currentLevel;

        // Create a journal entry with positive content
        final journalEntry = JournalEntry(
          id: 'integration_test_entry',
          userId: 'test_user',
          content: 'Today was amazing! I felt so grateful for all the wonderful things in my life. I overcame a challenging situation at work and felt really proud of my resilience.',
          date: DateTime.now(),
          moods: ['grateful', 'proud', 'happy'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Simulate AI analysis
        final analysisResult = EmotionalAnalysisResult(
          primaryEmotions: ['grateful', 'proud', 'happy'],
          emotionalIntensity: 8.0,
          keyThemes: ['gratitude', 'resilience', 'achievement'],
          overallSentiment: 0.9,
          personalizedInsight: 'Your gratitude and resilience are shining through today.',
          coreImpacts: {
            'Optimism': 0.15,
            'Resilience': 0.12,
            'Self-Awareness': 0.08,
          },
          emotionalPatterns: ['positive_reflection', 'growth_mindset'],
          growthIndicators: ['gratitude_practice', 'challenge_overcome'],
          validationScore: 0.95,
        );

        // Process the journal entry and analysis
        await journalService.saveEntry(journalEntry);
        
        // Update cores with analysis results
        await coreProvider.updateCoresWithJournalAnalysis([journalEntry], analysisResult);

        // Wait for updates to propagate
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify cores were updated
        final updatedOptimismCore = coreProvider.getCoreById('optimism')!;
        final updatedResilienceCore = coreProvider.getCoreById('resilience')!;

        expect(updatedOptimismCore.currentLevel, greaterThan(initialOptimismLevel));
        expect(updatedResilienceCore.currentLevel, greaterThan(initialResilienceLevel));
        
        // Verify trends were updated
        expect(updatedOptimismCore.trend, equals('rising'));
        expect(updatedResilienceCore.trend, equals('rising'));

        // Verify core contexts were updated with journal connection
        final optimismContext = coreProvider.coreContexts['optimism'];
        expect(optimismContext, isNotNull);
        expect(optimismContext!.relatedJournalEntryIds, contains(journalEntry.id));
      });

      testWidgets('should handle batch core updates from multiple journal entries', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: const JournalScreen(),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Create multiple journal entries
        final journalEntries = [
          JournalEntry(
            id: 'batch_entry_1',
            userId: 'test_user',
            content: 'I had a creative breakthrough today while working on my art project.',
            date: DateTime.now().subtract(const Duration(days: 2)),
            moods: ['inspired', 'creative'],
            dayOfWeek: 'Saturday',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          JournalEntry(
            id: 'batch_entry_2',
            userId: 'test_user',
            content: 'Connected with old friends today. It reminded me how important relationships are.',
            date: DateTime.now().subtract(const Duration(days: 1)),
            moods: ['connected', 'warm'],
            dayOfWeek: 'Sunday',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          JournalEntry(
            id: 'batch_entry_3',
            userId: 'test_user',
            content: 'Learned something new about myself through meditation and reflection.',
            date: DateTime.now(),
            moods: ['peaceful', 'insightful'],
            dayOfWeek: 'Monday',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Simulate batch analysis
        final batchAnalysis = EmotionalAnalysisResult(
          primaryEmotions: ['inspired', 'connected', 'peaceful'],
          emotionalIntensity: 7.5,
          keyThemes: ['creativity', 'connection', 'self_awareness'],
          overallSentiment: 0.85,
          personalizedInsight: 'You\'re showing growth across multiple areas.',
          coreImpacts: {
            'Creativity': 0.10,
            'Social Connection': 0.12,
            'Self-Awareness': 0.15,
            'Growth Mindset': 0.08,
          },
          emotionalPatterns: ['balanced_growth', 'multi_dimensional_development'],
          growthIndicators: ['creative_expression', 'social_engagement', 'self_reflection'],
          validationScore: 0.92,
        );

        // Get initial core levels
        final initialLevels = <String, double>{};
        for (final coreId in ['creativity', 'social_connection', 'self_awareness', 'growth_mindset']) {
          initialLevels[coreId] = coreProvider.getCoreById(coreId)!.currentLevel;
        }

        // Process batch update
        await coreProvider.updateCoresWithJournalAnalysis(journalEntries, batchAnalysis);

        // Wait for updates
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify all affected cores were updated
        for (final coreId in ['creativity', 'social_connection', 'self_awareness', 'growth_mindset']) {
          final updatedCore = coreProvider.getCoreById(coreId)!;
          expect(updatedCore.currentLevel, greaterThan(initialLevels[coreId]!));
          
          // Verify context includes all related entries
          final context = coreProvider.coreContexts[coreId];
          expect(context, isNotNull);
          
          // Should have connections to relevant journal entries
          final hasRelevantEntries = journalEntries.any((entry) => 
            context!.relatedJournalEntryIds.contains(entry.id));
          expect(hasRelevantEntries, isTrue);
        }
      });

      testWidgets('should handle real-time updates during active journaling session', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: const JournalScreen(),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Set up real-time update listener
        final updateEvents = <CoreUpdateEvent>[];
        final subscription = coreProvider.coreUpdateStream.listen((event) {
          updateEvents.add(event);
        });

        try {
          // Simulate rapid journal updates during active session
          for (int i = 0; i < 5; i++) {
            final entry = JournalEntry(
              id: 'realtime_entry_$i',
              userId: 'test_user',
              content: 'Real-time update $i - feeling more optimistic with each word.',
              date: DateTime.now(),
              moods: ['optimistic', 'motivated'],
              dayOfWeek: 'Tuesday',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            final analysis = EmotionalAnalysisResult(
              primaryEmotions: ['optimistic', 'motivated'],
              emotionalIntensity: 6.0 + i,
              keyThemes: ['optimism', 'motivation'],
              overallSentiment: 0.7 + (i * 0.05),
              personalizedInsight: 'Growing optimism detected.',
              coreImpacts: {'Optimism': 0.02 + (i * 0.01)},
              emotionalPatterns: ['progressive_improvement'],
              growthIndicators: ['positive_momentum'],
              validationScore: 0.9,
            );

            await coreProvider.updateCoresWithJournalAnalysis([entry], analysis);
            
            // Small delay to simulate real-time updates
            await Future.delayed(const Duration(milliseconds: 100));
            await tester.pump();
          }

          await tester.pumpAndSettle();

          // Verify real-time updates were received
          expect(updateEvents.length, greaterThan(0));
          
          // Verify updates contain correct information
          final optimismUpdates = updateEvents.where((e) => e.coreId == 'optimism').toList();
          expect(optimismUpdates.length, greaterThan(0));
          
          // Verify final core state reflects all updates
          final finalOptimismCore = coreProvider.getCoreById('optimism')!;
          expect(finalOptimismCore.trend, equals('rising'));

        } finally {
          await subscription.cancel();
        }
      });
    });

    group('Cross-Screen Data Consistency', () {
      testWidgets('should maintain data consistency between Your Cores widget and Core Library', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: YourCoresCard()),
                Expanded(
                  child: Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CoreLibraryScreen()),
                        );
                      },
                      child: const Text('Go to Core Library'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Get core data from Your Cores widget
        final yourCoresData = coreProvider.topCores;
        expect(yourCoresData, isNotEmpty);

        // Navigate to Core Library
        await tester.tap(find.text('Go to Core Library'));
        await tester.pumpAndSettle();

        // Verify Core Library shows same data
        final coreLibraryData = coreProvider.allCores;
        expect(coreLibraryData, isNotEmpty);

        // Verify consistency - top cores should be subset of all cores
        for (final topCore in yourCoresData) {
          final matchingCore = coreLibraryData.firstWhere(
            (core) => core.id == topCore.id,
            orElse: () => throw Exception('Core not found in library: ${topCore.id}'),
          );
          
          expect(matchingCore.currentLevel, equals(topCore.currentLevel));
          expect(matchingCore.trend, equals(topCore.trend));
          expect(matchingCore.lastUpdated, equals(topCore.lastUpdated));
        }

        // Update a core and verify consistency
        final testCore = yourCoresData.first.copyWith(
          currentLevel: yourCoresData.first.currentLevel + 0.1,
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(testCore);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify both views reflect the update
        final updatedYourCoresData = coreProvider.topCores;
        final updatedCoreLibraryData = coreProvider.allCores;

        final updatedTopCore = updatedYourCoresData.firstWhere((c) => c.id == testCore.id);
        final updatedLibraryCore = updatedCoreLibraryData.firstWhere((c) => c.id == testCore.id);

        expect(updatedTopCore.currentLevel, equals(testCore.currentLevel));
        expect(updatedLibraryCore.currentLevel, equals(testCore.currentLevel));
        expect(updatedTopCore.currentLevel, equals(updatedLibraryCore.currentLevel));
      });

      testWidgets('should synchronize data across multiple screen instances', (WidgetTester tester) async {
        // Create multiple provider instances to simulate different screens
        final provider1 = CoreProvider();
        final provider2 = CoreProvider();
        
        await provider1.initialize();
        await provider2.initialize();

        try {
          // Load data in both providers
          await provider1.loadAllCores();
          await provider2.loadAllCores();

          // Verify initial consistency
          expect(provider1.allCores.length, equals(provider2.allCores.length));

          // Update core in first provider
          final testCore = provider1.getCoreById('optimism')!.copyWith(
            currentLevel: 0.85,
            lastUpdated: DateTime.now(),
          );

          await provider1.updateCore(testCore);

          // Simulate sync between providers (in real app, this would be automatic)
          await provider2.refresh(forceRefresh: true);

          // Verify synchronization
          final core1 = provider1.getCoreById('optimism')!;
          final core2 = provider2.getCoreById('optimism')!;

          expect(core1.currentLevel, equals(core2.currentLevel));
          expect(core1.lastUpdated.millisecondsSinceEpoch, 
                 equals(core2.lastUpdated.millisecondsSinceEpoch));

        } finally {
          provider1.dispose();
          provider2.dispose();
        }
      });

      testWidgets('should handle concurrent updates gracefully', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: const CoreLibraryScreen(),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Simulate concurrent updates to the same core
        final baseCore = coreProvider.getCoreById('resilience')!;
        
        final concurrentUpdates = [
          baseCore.copyWith(
            currentLevel: baseCore.currentLevel + 0.05,
            lastUpdated: DateTime.now(),
          ),
          baseCore.copyWith(
            currentLevel: baseCore.currentLevel + 0.08,
            lastUpdated: DateTime.now().add(const Duration(milliseconds: 10)),
          ),
          baseCore.copyWith(
            currentLevel: baseCore.currentLevel + 0.03,
            lastUpdated: DateTime.now().add(const Duration(milliseconds: 20)),
          ),
        ];

        // Execute concurrent updates
        final futures = concurrentUpdates.map((core) => coreProvider.updateCore(core));
        await Future.wait(futures);

        await tester.pump();
        await tester.pumpAndSettle();

        // Verify system handled concurrent updates without corruption
        final finalCore = coreProvider.getCoreById('resilience')!;
        expect(finalCore.currentLevel, greaterThan(baseCore.currentLevel));
        expect(coreProvider.error, isNull); // No errors should occur
        
        // Verify data consistency
        final allCoresData = coreProvider.allCores;
        final topCoresData = coreProvider.topCores;
        
        final allCoresResilience = allCoresData.firstWhere((c) => c.id == 'resilience');
        final topCoresResilience = topCoresData.firstWhere(
          (c) => c.id == 'resilience',
          orElse: () => allCoresResilience, // Might not be in top cores
        );
        
        expect(allCoresResilience.currentLevel, equals(finalCore.currentLevel));
        if (topCoresData.any((c) => c.id == 'resilience')) {
          expect(topCoresResilience.currentLevel, equals(finalCore.currentLevel));
        }
      });
    });

    group('Real-time Synchronization Across Components', () {
      testWidgets('should synchronize updates across multiple widgets', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(
                  child: YourCoresCard(key: Key('your_cores_widget')),
                ),
                Expanded(
                  child: Consumer<CoreProvider>(
                    builder: (context, provider, child) {
                      return ListView.builder(
                        key: const Key('core_list_widget'),
                        itemCount: provider.allCores.length,
                        itemBuilder: (context, index) {
                          final core = provider.allCores[index];
                          return ListTile(
                            key: Key('core_tile_${core.id}'),
                            title: Text(core.name),
                            subtitle: Text('Level: ${core.currentLevel.toStringAsFixed(2)}'),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Verify both widgets are present
        expect(find.byKey(const Key('your_cores_widget')), findsOneWidget);
        expect(find.byKey(const Key('core_list_widget')), findsOneWidget);

        // Get initial state
        final initialOptimismLevel = coreProvider.getCoreById('optimism')!.currentLevel;

        // Update a core
        final updatedCore = coreProvider.getCoreById('optimism')!.copyWith(
          currentLevel: initialOptimismLevel + 0.15,
          trend: 'rising',
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(updatedCore);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify both widgets reflect the update
        expect(find.text('Level: ${updatedCore.currentLevel.toStringAsFixed(2)}'), findsOneWidget);
        
        // Verify Your Cores widget updated (if optimism is in top cores)
        final topCores = coreProvider.topCores;
        if (topCores.any((c) => c.id == 'optimism')) {
          // Your Cores widget should show updated data
          expect(coreProvider.getCoreById('optimism')!.currentLevel, equals(updatedCore.currentLevel));
        }
      });

      testWidgets('should handle rapid successive updates', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: Consumer<CoreProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                body: Column(
                  children: [
                    Text('Updates: ${provider.allCores.length}'),
                    Text('Loading: ${provider.isLoading}'),
                    Text('Error: ${provider.error?.message ?? 'None'}'),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Perform rapid successive updates
        final baseCore = coreProvider.getCoreById('creativity')!;
        
        for (int i = 0; i < 10; i++) {
          final updatedCore = baseCore.copyWith(
            currentLevel: baseCore.currentLevel + (i * 0.01),
            lastUpdated: DateTime.now().add(Duration(milliseconds: i * 10)),
          );
          
          await coreProvider.updateCore(updatedCore);
          
          // Small delay to simulate rapid updates
          await Future.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Verify system handled rapid updates without errors
        expect(find.text('Error: None'), findsOneWidget);
        expect(coreProvider.error, isNull);
        
        // Verify final state is consistent
        final finalCore = coreProvider.getCoreById('creativity')!;
        expect(finalCore.currentLevel, greaterThan(baseCore.currentLevel));
      });

      testWidgets('should maintain sync during navigation', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Journal Screen'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Core Library'),
                ),
                Expanded(
                  child: Consumer<CoreProvider>(
                    builder: (context, provider, child) {
                      return Text('Cores: ${provider.allCores.length}');
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Update core while on current screen
        final testCore = coreProvider.getCoreById('self_awareness')!.copyWith(
          currentLevel: 0.75,
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(testCore);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify update is reflected
        expect(coreProvider.getCoreById('self_awareness')!.currentLevel, equals(0.75));

        // Simulate navigation (rebuild widget tree)
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Verify data persists after navigation
        expect(coreProvider.getCoreById('self_awareness')!.currentLevel, equals(0.75));
        expect(find.text('Cores: ${coreProvider.allCores.length}'), findsOneWidget);
      });
    });

    group('Navigation Context Preservation', () {
      testWidgets('should preserve context when navigating from journal to core library', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final navContext = navigationService.createJournalToCoreContext(
                        targetCoreId: 'optimism',
                        triggeredBy: 'your_cores_tap',
                      );
                      
                      await navigationService.navigateToAllCores(
                        context,
                        navigationContext: navContext,
                      );
                    },
                    child: const Text('Navigate to Core Library'),
                  ),
                  const Text('Journal Screen'),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Verify initial state
        expect(navigationService.currentContext, isNull);

        // Trigger navigation
        await tester.tap(find.text('Navigate to Core Library'));
        await tester.pumpAndSettle();

        // Verify context was created and preserved
        expect(navigationService.currentContext, isNotNull);
        expect(navigationService.currentContext!.sourceScreen, equals('journal'));
        expect(navigationService.currentContext!.triggeredBy, equals('your_cores_tap'));
        expect(navigationService.currentContext!.targetCoreId, equals('optimism'));
        expect(navigationService.isFromJournal(), isTrue);
      });

      testWidgets('should restore context when navigating back', (WidgetTester tester) async {
        // Create initial context
        final initialContext = navigationService.createContext(
          sourceScreen: 'journal',
          triggeredBy: 'initial_tap',
          targetCoreId: 'resilience',
        );

        // Create second context
        final secondContext = navigationService.createContext(
          sourceScreen: 'core_library',
          triggeredBy: 'library_navigation',
          targetCoreId: 'creativity',
        );

        expect(navigationService.currentContext, equals(secondContext));
        expect(navigationService.canNavigateBack(), isTrue);

        // Restore previous context
        final restoredContext = navigationService.restoreContext();

        expect(restoredContext, equals(initialContext));
        expect(navigationService.currentContext, equals(initialContext));
        expect(navigationService.currentContext!.targetCoreId, equals('resilience'));
      });

      testWidgets('should maintain context across provider updates', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: Consumer<CoreProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                body: Column(
                  children: [
                    Text('Current Core: ${provider.navigationState.currentCoreId ?? 'None'}'),
                    ElevatedButton(
                      onPressed: () async {
                        final navContext = navigationService.createContext(
                          sourceScreen: 'test',
                          triggeredBy: 'test_tap',
                          targetCoreId: 'growth_mindset',
                        );
                        
                        await provider.navigateToCore('growth_mindset', context: navContext);
                      },
                      child: const Text('Navigate to Core'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Initial state
        expect(find.text('Current Core: None'), findsOneWidget);

        // Navigate to core
        await tester.tap(find.text('Navigate to Core'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify navigation state updated
        expect(find.text('Current Core: growth_mindset'), findsOneWidget);
        expect(coreProvider.navigationState.currentCoreId, equals('growth_mindset'));

        // Update core data and verify context is preserved
        final testCore = coreProvider.getCoreById('growth_mindset')!.copyWith(
          currentLevel: 0.9,
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(testCore);
        await tester.pump();
        await tester.pumpAndSettle();

        // Context should still be preserved
        expect(coreProvider.navigationState.currentCoreId, equals('growth_mindset'));
        expect(find.text('Current Core: growth_mindset'), findsOneWidget);
      });
    });

    group('Error Handling and Recovery', () {
      testWidgets('should handle integration errors gracefully', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: Consumer<CoreProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                body: Column(
                  children: [
                    Text('Error: ${provider.error?.message ?? 'None'}'),
                    Text('Loading: ${provider.isLoading}'),
                    ElevatedButton(
                      onPressed: () async {
                        // Try to update non-existent core
                        await provider.updateCoreWithContext('non_existent_core', null);
                      },
                      child: const Text('Trigger Error'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        provider.clearError();
                      },
                      child: const Text('Clear Error'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Initial state - no error
        expect(find.text('Error: None'), findsOneWidget);

        // Trigger error
        await tester.tap(find.text('Trigger Error'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify error is displayed
        expect(find.textContaining('Error:'), findsOneWidget);
        expect(coreProvider.error, isNotNull);

        // Clear error
        await tester.tap(find.text('Clear Error'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify error is cleared
        expect(find.text('Error: None'), findsOneWidget);
        expect(coreProvider.error, isNull);
      });

      testWidgets('should recover from sync failures', (WidgetTester tester) async {
        final app = IntegrationTestApp(
          providers: [
            ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
          ],
          home: Consumer<CoreProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                body: Column(
                  children: [
                    Text('Cores: ${provider.allCores.length}'),
                    ElevatedButton(
                      onPressed: () async {
                        await provider.refresh(forceRefresh: true);
                      },
                      child: const Text('Force Refresh'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Verify initial state
        expect(coreProvider.allCores.length, equals(6));

        // Force refresh to test recovery
        await tester.tap(find.text('Force Refresh'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify system recovered
        expect(coreProvider.allCores.length, equals(6));
        expect(coreProvider.error, isNull);
      });
    });
  });
}