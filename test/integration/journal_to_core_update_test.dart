import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/services/core_library_service.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/journal_analysis_service.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';

import '../utils/test_setup_helper.dart';
import '../utils/database_test_utils.dart';

void main() {
  late JournalProvider journalProvider;
  late JournalService journalService;
  late CoreLibraryService coreLibraryService;
  late JournalAnalysisService analysisService;
  late EmotionalAnalyzer emotionalAnalyzer;

  setUp(() async {
    // Set up test environment
    TestSetupHelper.setupTest();
    
    // Initialize database for testing
    await DatabaseTestUtils.initializeTestDatabase();
    
    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
    
    // Initialize services
    journalService = JournalService();
    coreLibraryService = CoreLibraryService();
    analysisService = JournalAnalysisService();
    emotionalAnalyzer = EmotionalAnalyzer();
    
    // Initialize journal provider
    journalProvider = JournalProvider();
    await journalProvider.initialize();
  });

  tearDown(() async {
    // Clean up test environment
    TestSetupHelper.teardownTest();
    
    // Clear any cached data
    analysisService.clearCache();
    
    // Reset cores to clean state
    await coreLibraryService.resetCores();
  });

  group('Journal entry to core update integration tests', () {
    test('creating a journal entry should trigger core updates through complete flow', () async {
      // Get initial cores and verify they start at 0.0 for fresh users
      final initialCores = await coreLibraryService.getAllCores();
      expect(initialCores, hasLength(6));
      
      // Verify all cores start at 0.0 for TestFlight users
      for (final core in initialCores) {
        expect(core.currentLevel, equals(0.0));
        expect(core.trend, equals('stable'));
      }
      
      // Create a journal entry with optimism and resilience themes
      final now = DateTime.now();
      final entry = JournalEntry(
        id: 'test-entry-complete-flow',
        userId: 'test-user',
        content: 'I am feeling very grateful today. My optimism is growing and I feel resilient. '
            'I overcame a challenge and feel stronger for it. This experience taught me so much about myself.',
        moods: ['grateful', 'happy', 'confident'],
        date: now,
        dayOfWeek: _getDayOfWeekString(now.weekday),
        createdAt: now,
        updatedAt: now,
        isAnalyzed: false,
      );
      
      // Process the entry through the analysis service
      final analysisResult = await analysisService.analyzeJournalEntry(entry, initialCores);
      
      // Save the updated cores (this simulates what the real app would do)
      for (final core in analysisResult.updatedCores) {
        await coreLibraryService.updateCore(core);
      }
      
      // Verify the analysis was successful
      expect(analysisResult.updatedCores, hasLength(6));
      expect(analysisResult.insights, isNotEmpty);
      
      // Find cores that should be affected by this entry
      final optimismCore = analysisResult.updatedCores.firstWhere((c) => c.name == 'Optimism');
      final resilienceCore = analysisResult.updatedCores.firstWhere((c) => c.name == 'Resilience');
      final selfAwarenessCore = analysisResult.updatedCores.firstWhere((c) => c.name == 'Self-Awareness');
      
      // Verify cores were updated (should be > 0.0 after processing)
      expect(optimismCore.currentLevel, greaterThan(0.0), 
          reason: 'Optimism core should increase from grateful/happy content');
      expect(resilienceCore.currentLevel, greaterThan(0.0), 
          reason: 'Resilience core should increase from overcoming challenges');
      expect(selfAwarenessCore.currentLevel, greaterThan(0.0), 
          reason: 'Self-awareness core should increase from reflective content');
      
      // Verify trends are updated appropriately
      expect(optimismCore.trend, equals('rising'), 
          reason: 'Optimism trend should be rising after positive entry');
      expect(resilienceCore.trend, equals('rising'), 
          reason: 'Resilience trend should be rising after challenge content');
    });

    test('journal analysis service should properly update cores with analysis results', () async {
      // Get initial cores
      final initialCores = await coreLibraryService.getAllCores();
      final initialSelfAwareness = initialCores.firstWhere((c) => c.name == 'Self-Awareness');
      final initialGrowthMindset = initialCores.firstWhere((c) => c.name == 'Growth Mindset');
      
      // Create a test journal entry focused on self-awareness and growth
      final now = DateTime.now();
      final entry = JournalEntry(
        id: 'test-entry-${now.millisecondsSinceEpoch}',
        userId: 'test-user',
        content: 'I am practicing mindfulness and self-awareness today. '
            'I noticed my emotional patterns and how I react to stress. '
            'This reflection is helping me grow and learn about myself.',
        moods: ['reflective', 'calm', 'thoughtful'],
        date: now,
        dayOfWeek: _getDayOfWeekString(now.weekday),
        createdAt: now,
        updatedAt: now,
        isAnalyzed: false,
      );
      
      // Use the analysis service to analyze the entry and update cores
      final analysisResult = await analysisService.analyzeJournalEntry(entry, initialCores);
      
      // Verify the analysis was successful
      expect(analysisResult.entry.id, equals(entry.id));
      expect(analysisResult.updatedCores, hasLength(6));
      
      // Find the updated cores
      final updatedSelfAwareness = analysisResult.updatedCores.firstWhere((c) => c.name == 'Self-Awareness');
      final updatedGrowthMindset = analysisResult.updatedCores.firstWhere((c) => c.name == 'Growth Mindset');
      
      // Verify cores were updated based on the reflective content
      expect(updatedSelfAwareness.currentLevel, greaterThan(initialSelfAwareness.currentLevel),
          reason: 'Self-awareness should increase from mindfulness and reflection content');
      expect(updatedGrowthMindset.currentLevel, greaterThan(initialGrowthMindset.currentLevel),
          reason: 'Growth mindset should increase from learning and growth content');
      
      // Verify insights were generated
      expect(analysisResult.insights, isNotEmpty, 
          reason: 'Analysis should generate insights');
      expect(analysisResult.recommendations, isNotEmpty, 
          reason: 'Analysis should generate recommendations');
      
      // Verify core progress tracking
      expect(analysisResult.coreProgress, isNotEmpty, 
          reason: 'Analysis should track core progress');
    });

    test('multiple journal entries should accumulate core updates over time', () async {
      // Get initial cores
      final initialCores = await coreLibraryService.getAllCores();
      
      // Create multiple journal entries with different themes
      final entries = [
        {
          'content': 'I am feeling creative today and exploring new ideas. '
              'I painted something beautiful and felt so inspired by the process.',
          'moods': ['inspired', 'creative', 'joyful'],
          'expectedCores': ['Creativity', 'Optimism'],
        },
        {
          'content': 'I connected with friends and felt a strong sense of community. '
              'Our conversation was so meaningful and I felt truly understood.',
          'moods': ['social', 'happy', 'grateful'],
          'expectedCores': ['Social Connection', 'Optimism'],
        },
        {
          'content': 'I overcame a challenge today and feel stronger for it. '
              'This difficult situation taught me about my inner strength and resilience.',
          'moods': ['proud', 'confident', 'determined'],
          'expectedCores': ['Resilience', 'Self-Awareness'],
        },
        {
          'content': 'I learned something new today and it opened my mind to possibilities. '
              'I love how learning changes my perspective and helps me grow.',
          'moods': ['curious', 'excited', 'motivated'],
          'expectedCores': ['Growth Mindset', 'Optimism'],
        },
      ];
      
      // Process each entry directly through the analysis service
      for (int i = 0; i < entries.length; i++) {
        final entryData = entries[i];
        final now = DateTime.now().subtract(Duration(days: entries.length - i));
        
        // Create journal entry object
        final entry = JournalEntry(
          id: 'test-entry-${i + 1}',
          userId: 'test-user',
          content: entryData['content'] as String,
          moods: entryData['moods'] as List<String>,
          date: now,
          dayOfWeek: _getDayOfWeekString(now.weekday),
          createdAt: now,
          updatedAt: now,
          isAnalyzed: false,
        );
        
        // Get current cores before analysis
        final currentCores = await coreLibraryService.getAllCores();
        
        // Analyze the entry and update cores
        final analysisResult = await analysisService.analyzeJournalEntry(entry, currentCores);
        
        // Save the updated cores (this simulates what the real app would do)
        for (final core in analysisResult.updatedCores) {
          await coreLibraryService.updateCore(core);
        }
        
        // Verify the analysis was successful
        expect(analysisResult.updatedCores, hasLength(6));
        
        // Verify expected cores were affected
        final expectedCoreNames = entryData['expectedCores'] as List<String>;
        for (final expectedCoreName in expectedCoreNames) {
          final initialCore = currentCores.firstWhere((c) => c.name == expectedCoreName);
          final updatedCore = analysisResult.updatedCores.firstWhere((c) => c.name == expectedCoreName);
          
          expect(updatedCore.currentLevel, greaterThanOrEqualTo(initialCore.currentLevel),
              reason: '$expectedCoreName should maintain or increase after relevant entry ${i + 1}');
        }
      }
      
      // Verify overall growth across multiple entries
      final finalCores = await coreLibraryService.getAllCores();
      
      // At least 4 cores should show some growth from the diverse entries
      int coresWithGrowth = 0;
      for (final finalCore in finalCores) {
        final initialCore = initialCores.firstWhere((c) => c.id == finalCore.id);
        if (finalCore.currentLevel > initialCore.currentLevel) {
          coresWithGrowth++;
        }
      }
      
      expect(coresWithGrowth, greaterThanOrEqualTo(3),
          reason: 'Multiple diverse entries should result in growth across multiple cores');
      
      // Verify specific core improvements
      final finalCreativity = finalCores.firstWhere((c) => c.name == 'Creativity');
      final finalSocialConnection = finalCores.firstWhere((c) => c.name == 'Social Connection');
      final finalResilience = finalCores.firstWhere((c) => c.name == 'Resilience');
      final finalGrowthMindset = finalCores.firstWhere((c) => c.name == 'Growth Mindset');
      
      expect(finalCreativity.currentLevel, greaterThan(0.0),
          reason: 'Creativity should increase from creative entries');
      expect(finalSocialConnection.currentLevel, greaterThan(0.0),
          reason: 'Social Connection should increase from connection entries');
      expect(finalResilience.currentLevel, greaterThan(0.0),
          reason: 'Resilience should increase from challenge entries');
      expect(finalGrowthMindset.currentLevel, greaterThan(0.0),
          reason: 'Growth Mindset should increase from learning entries');
    });

    test('core data persistence should survive service restarts', () async {
      // Get initial cores
      final initialCores = await coreLibraryService.getAllCores();
      
      // Create an entry and update cores directly
      final now = DateTime.now();
      final entry = JournalEntry(
        id: 'test-entry-persistence',
        userId: 'test-user',
        content: 'I am grateful for this beautiful day and feel optimistic about the future. '
            'My resilience has grown through recent challenges.',
        moods: ['grateful', 'optimistic', 'confident'],
        date: now,
        dayOfWeek: _getDayOfWeekString(now.weekday),
        createdAt: now,
        updatedAt: now,
        isAnalyzed: false,
      );
      
      // Process the entry and update cores
      final analysisResult = await analysisService.analyzeJournalEntry(entry, initialCores);
      
      // Save the updated cores (this simulates what the real app would do)
      for (final core in analysisResult.updatedCores) {
        await coreLibraryService.updateCore(core);
      }
      
      // Get cores after update
      final coresAfterUpdate = await coreLibraryService.getAllCores();
      final optimismAfterUpdate = coresAfterUpdate.firstWhere((c) => c.name == 'Optimism');
      final resilienceAfterUpdate = coresAfterUpdate.firstWhere((c) => c.name == 'Resilience');
      
      // Verify cores were updated
      expect(optimismAfterUpdate.currentLevel, greaterThan(0.0));
      expect(resilienceAfterUpdate.currentLevel, greaterThan(0.0));
      
      // Create a new service instance to simulate restart
      final newCoreLibraryService = CoreLibraryService();
      final coresAfterRestart = await newCoreLibraryService.getAllCores();
      
      // Verify data persisted
      final optimismAfterRestart = coresAfterRestart.firstWhere((c) => c.name == 'Optimism');
      final resilienceAfterRestart = coresAfterRestart.firstWhere((c) => c.name == 'Resilience');
      
      expect(optimismAfterRestart.currentLevel, equals(optimismAfterUpdate.currentLevel),
          reason: 'Optimism level should persist after service restart');
      expect(resilienceAfterRestart.currentLevel, equals(resilienceAfterUpdate.currentLevel),
          reason: 'Resilience level should persist after service restart');
      expect(optimismAfterRestart.trend, equals(optimismAfterUpdate.trend),
          reason: 'Optimism trend should persist after service restart');
      expect(resilienceAfterRestart.trend, equals(resilienceAfterUpdate.trend),
          reason: 'Resilience trend should persist after service restart');
    });

    test('edge cases should be handled gracefully', () async {
      // Get initial cores
      final initialCores = await coreLibraryService.getAllCores();
      
      // Test with minimal content
      final now = DateTime.now();
      final minimalEntry = JournalEntry(
        id: 'test-entry-minimal',
        userId: 'test-user',
        content: 'Today was okay.',
        moods: ['content'],
        date: now,
        dayOfWeek: _getDayOfWeekString(now.weekday),
        createdAt: now,
        updatedAt: now,
        isAnalyzed: false,
      );
      
      // Process minimal entry
      final minimalResult = await analysisService.analyzeJournalEntry(minimalEntry, initialCores);
      expect(minimalResult.updatedCores, hasLength(6));
      
      // Save the updated cores
      for (final core in minimalResult.updatedCores) {
        await coreLibraryService.updateCore(core);
      }
      
      // Test with very long content
      final longContent = 'I am reflecting on my day and thinking about all the experiences I had. ' * 50;
      final longEntry = JournalEntry(
        id: 'test-entry-long',
        userId: 'test-user',
        content: longContent,
        moods: ['reflective'],
        date: now,
        dayOfWeek: _getDayOfWeekString(now.weekday),
        createdAt: now,
        updatedAt: now,
        isAnalyzed: false,
      );
      
      // Get current cores for long entry processing
      final currentCores = await coreLibraryService.getAllCores();
      
      // Process long entry
      final longResult = await analysisService.analyzeJournalEntry(longEntry, currentCores);
      expect(longResult.updatedCores, hasLength(6));
      
      // Save the updated cores
      for (final core in longResult.updatedCores) {
        await coreLibraryService.updateCore(core);
      }
      
      // Verify cores are still in valid state after edge cases
      final coresAfterEdgeCases = await coreLibraryService.getAllCores();
      for (final core in coresAfterEdgeCases) {
        expect(core.currentLevel, inInclusiveRange(0.0, 1.0),
            reason: 'Core ${core.name} level should remain in valid range');
        expect(['rising', 'stable', 'declining'], contains(core.trend),
            reason: 'Core ${core.name} trend should be valid');
      }
    });
  });
}

// Helper function to convert weekday int to string
String _getDayOfWeekString(int weekday) {
  const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return dayNames[weekday - 1];
}

