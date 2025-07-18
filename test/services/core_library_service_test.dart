import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/services/core_library_service.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';
import 'package:spiral_journal/models/journal_entry.dart';

void main() {
  group('CoreLibraryService', () {
    late CoreLibraryService service;

    setUp(() async {
      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});
      service = CoreLibraryService();
    });

    test('should create initial cores with all six personality cores', () async {
      final cores = await service.getAllCores();
      
      expect(cores.length, equals(6));
      
      final coreNames = cores.map((c) => c.name).toList();
      expect(coreNames, contains('Optimism'));
      expect(coreNames, contains('Resilience'));
      expect(coreNames, contains('Self-Awareness'));
      expect(coreNames, contains('Creativity'));
      expect(coreNames, contains('Social Connection'));
      expect(coreNames, contains('Growth Mindset'));
    });

    test('should initialize cores with proper baseline levels', () async {
      final cores = await service.getAllCores();
      
      for (final core in cores) {
        expect(core.currentLevel, greaterThan(0.0));
        expect(core.currentLevel, lessThanOrEqualTo(1.0));
        expect(core.previousLevel, equals(core.currentLevel));
        expect(core.trend, equals('stable'));
        expect(core.milestones.length, equals(4));
      }
    });

    test('should get core by ID', () async {
      final core = await service.getCoreById('optimism');
      
      expect(core, isNotNull);
      expect(core!.id, equals('optimism'));
      expect(core.name, equals('Optimism'));
    });

    test('should update core progress', () async {
      const coreId = 'optimism';
      const newLevel = 0.8;
      
      final initialCore = await service.getCoreById(coreId);
      final initialLevel = initialCore!.currentLevel;
      
      await service.updateCoreProgress(coreId, newLevel);
      
      final updatedCore = await service.getCoreById(coreId);
      // Should be limited by maxDailyChange (0.03 for optimism)
      expect(updatedCore!.currentLevel, equals(initialLevel + 0.03));
      expect(updatedCore.trend, equals('rising'));
    });

    test('should generate core milestones', () async {
      final milestones = await service.getCoreMilestones('resilience');
      
      expect(milestones.length, equals(4));
      expect(milestones[0].title, equals('Foundation'));
      expect(milestones[1].title, equals('Development'));
      expect(milestones[2].title, equals('Proficiency'));
      expect(milestones[3].title, equals('Mastery'));
      
      expect(milestones[0].threshold, equals(0.25));
      expect(milestones[1].threshold, equals(0.5));
      expect(milestones[2].threshold, equals(0.75));
      expect(milestones[3].threshold, equals(0.9));
    });

    test('should generate core insight', () async {
      final insight = await service.generateCoreInsight('creativity');
      
      expect(insight.coreId, equals('creativity'));
      expect(insight.title, isNotEmpty);
      expect(insight.description, isNotEmpty);
      expect(insight.type, isIn(['growth', 'pattern', 'recommendation', 'milestone']));
      expect(insight.relevanceScore, greaterThanOrEqualTo(0.0));
      expect(insight.relevanceScore, lessThanOrEqualTo(1.0));
    });

    test('should update cores with journal analysis', () async {
      final now = DateTime.now();
      final journalEntries = [
        JournalEntry(
          id: '1',
          userId: 'test_user',
          content: 'I feel grateful for all the positive things in my life today.',
          date: now,
          moods: ['happy', 'grateful'],
          dayOfWeek: 'Monday',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final analysis = EmotionalAnalysisResult(
        primaryEmotions: ['grateful', 'happy'],
        emotionalIntensity: 7.0,
        keyThemes: ['gratitude', 'positive'],
        overallSentiment: 0.8,
        personalizedInsight: 'You show strong gratitude patterns.',
        coreImpacts: {'Optimism': 0.1, 'Resilience': 0.05},
        emotionalPatterns: [],
        growthIndicators: ['gratitude_practice'],
        validationScore: 0.9,
      );

      final updatedCores = await service.updateCoresWithJournalAnalysis(
        journalEntries,
        analysis,
      );

      expect(updatedCores.length, equals(6));
      
      // Optimism should have increased due to gratitude themes
      final optimismCore = updatedCores.firstWhere((c) => c.id == 'optimism');
      expect(optimismCore.currentLevel, greaterThan(optimismCore.previousLevel));
    });

    test('should generate core combinations for strong cores', () async {
      // Set up cores with high levels
      await service.updateCoreProgress('optimism', 0.8);
      await service.updateCoreProgress('resilience', 0.8);
      
      final combinations = await service.getCoreCombinations();
      
      expect(combinations, isNotEmpty);
      expect(combinations.first.name, equals('Unshakeable Spirit'));
      expect(combinations.first.coreIds, contains('optimism'));
      expect(combinations.first.coreIds, contains('resilience'));
    });

    test('should generate growth recommendations for weak cores', () async {
      // Set up a weak core
      await service.updateCoreProgress('creativity', 0.3);
      
      final recommendations = await service.getGrowthRecommendations();
      
      expect(recommendations, isNotEmpty);
      expect(recommendations.first, contains('creative'));
    });

    test('should handle milestone achievements', () async {
      const coreId = 'self_awareness';
      
      // Update to trigger milestone achievement
      await service.updateCoreProgress(coreId, 0.6);
      
      final milestones = await service.getCoreMilestones(coreId);
      final achievedMilestones = milestones.where((m) => m.isAchieved).toList();
      
      expect(achievedMilestones.length, greaterThanOrEqualTo(2)); // Foundation and Development
      expect(achievedMilestones.first.achievedAt, isNotNull);
    });

    test('should reset cores to initial state', () async {
      // Make some changes
      await service.updateCoreProgress('optimism', 0.9);
      
      // Reset
      await service.resetCores();
      
      // Verify reset
      final cores = await service.getAllCores();
      final optimismCore = cores.firstWhere((c) => c.id == 'optimism');
      expect(optimismCore.currentLevel, equals(0.7)); // Back to baseline
    });

    test('should calculate trend correctly', () async {
      const coreId = 'growth_mindset';
      
      // Test rising trend
      await service.updateCoreProgress(coreId, 0.8);
      final risingCore = await service.getCoreById(coreId);
      expect(risingCore!.trend, equals('rising'));
      
      // Test declining trend
      await service.updateCoreProgress(coreId, 0.6);
      final decliningCore = await service.getCoreById(coreId);
      expect(decliningCore!.trend, equals('declining'));
    });

    test('should limit daily change within bounds', () async {
      const coreId = 'optimism';
      final initialCore = await service.getCoreById(coreId);
      final initialLevel = initialCore!.currentLevel;
      
      // Try to make a huge change
      await service.updateCoreProgress(coreId, 1.0);
      
      final updatedCore = await service.getCoreById(coreId);
      final change = updatedCore!.currentLevel - initialLevel;
      
      // Change should be limited by maxDailyChange (0.03 for optimism)
      // Use a small tolerance for floating point comparison
      expect(change.abs(), lessThanOrEqualTo(0.031));
    });
  });
}