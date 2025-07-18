import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';
import 'package:spiral_journal/services/core_evolution_engine.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Emotional Analysis Integration', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });
    late EmotionalAnalyzer analyzer;
    late CoreEvolutionEngine engine;
    late List<EmotionalCore> initialCores;

    setUp(() {
      analyzer = EmotionalAnalyzer();
      engine = CoreEvolutionEngine();
      initialCores = engine.getInitialCores();
    });

    test('should process complete emotional analysis workflow', () async {
      // Create a test journal entry
      final entry = JournalEntry(
        id: 'integration-test-1',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Today was an amazing day! I felt so grateful for my friends and family. I overcame a difficult challenge at work and learned something new about myself. I\'m excited about the creative project I\'m starting.',
        moods: ['happy', 'grateful', 'excited', 'proud'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Simulate AI response
      final aiResponse = {
        'emotional_analysis': {
          'primary_emotions': ['happy', 'grateful', 'excited', 'proud'],
          'emotional_intensity': 0.8,
          'key_themes': ['gratitude', 'achievement', 'creativity', 'learning'],
          'overall_sentiment': 0.7,
          'personalized_insight': 'Your gratitude practice and willingness to face challenges are strengthening your emotional resilience and optimism.',
        },
        'core_updates': [
          {'name': 'Optimism', 'trend': 'rising'},
          {'name': 'Resilience', 'trend': 'rising'},
          {'name': 'Self-Awareness', 'trend': 'rising'},
          {'name': 'Creativity', 'trend': 'rising'},
          {'name': 'Social Connection', 'trend': 'rising'},
          {'name': 'Growth Mindset', 'trend': 'rising'},
        ],
        'growth_indicators': ['gratitude_practice', 'challenge_acceptance', 'creative_exploration', 'self_reflection'],
      };

      // Process analysis
      final analysisResult = analyzer.processAndCacheAnalysis(aiResponse, entry);

      // Verify analysis result
      expect(analysisResult.primaryEmotions, contains('happy'));
      expect(analysisResult.primaryEmotions, contains('grateful'));
      expect(analysisResult.emotionalIntensity, greaterThan(5.0));
      expect(analysisResult.keyThemes, contains('gratitude'));
      expect(analysisResult.overallSentiment, greaterThan(0.0));
      expect(analysisResult.personalizedInsight, isNotEmpty);
      expect(analysisResult.validationScore, greaterThan(0.0));

      // Update cores with analysis
      final updatedCores = engine.updateCoresWithAnalysis(initialCores, analysisResult, entry);

      // Verify core updates
      expect(updatedCores.length, equals(initialCores.length));
      
      final optimismCore = updatedCores.firstWhere((core) => core.name == 'Optimism');
      expect(optimismCore.percentage, greaterThanOrEqualTo(initialCores.firstWhere((core) => core.name == 'Optimism').percentage));
      expect(optimismCore.insight, isNotEmpty);

      // Test caching functionality
      final cachedResult = analyzer.getCachedAnalysisResult(entry.id);
      expect(cachedResult, isNotNull);
      expect(cachedResult!.primaryEmotions, equals(analysisResult.primaryEmotions));

      // Test core progress calculation
      final optimismProgress = engine.calculateCoreProgress(optimismCore, [entry]);
      expect(optimismProgress.milestones, isNotEmpty);
      expect(optimismProgress.achievedMilestones, isNotEmpty);

      // Test core synergies
      final synergies = engine.calculateCoreSynergies(updatedCores);
      expect(synergies, isNotEmpty);
      expect(synergies.values.every((synergy) => synergy >= 0.0), isTrue);

      // Test growth recommendations
      final recommendations = engine.generateGrowthRecommendations(updatedCores, [analysisResult]);
      expect(recommendations, isList);
    });

    test('should handle multiple entries and identify patterns', () async {
      final entries = [
        JournalEntry(
          id: 'pattern-test-1',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(days: 6)),
          content: 'Feeling grateful for my morning routine and the peaceful start to my day.',
          moods: ['grateful', 'peaceful'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now().subtract(Duration(days: 6)),
          updatedAt: DateTime.now().subtract(Duration(days: 6)),
        ),
        JournalEntry(
          id: 'pattern-test-2',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(days: 4)),
          content: 'Had a challenging day but I\'m grateful for the support from my team.',
          moods: ['grateful', 'supported'],
          dayOfWeek: 'Wednesday',
          createdAt: DateTime.now().subtract(Duration(days: 4)),
          updatedAt: DateTime.now().subtract(Duration(days: 4)),
        ),
        JournalEntry(
          id: 'pattern-test-3',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(days: 2)),
          content: 'Grateful for the beautiful weather and time spent in nature.',
          moods: ['grateful', 'content'],
          dayOfWeek: 'Friday',
          createdAt: DateTime.now().subtract(Duration(days: 2)),
          updatedAt: DateTime.now().subtract(Duration(days: 2)),
        ),
        JournalEntry(
          id: 'pattern-test-4',
          userId: 'test-user',
          date: DateTime.now(),
          content: 'Reflecting on the week, I feel grateful for all the growth opportunities.',
          moods: ['grateful', 'reflective'],
          dayOfWeek: 'Sunday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Identify patterns
      final patterns = analyzer.identifyPatterns(entries);
      expect(patterns, isNotEmpty);
      
      // Should identify gratitude as a dominant pattern
      final moodPattern = patterns.firstWhere(
        (pattern) => pattern.category == 'Mood Patterns',
        orElse: () => patterns.first,
      );
      expect(moodPattern.description, contains('grateful'));

      // Analyze emotional trends
      final trends = analyzer.analyzeEmotionalTrends(entries);
      expect(trends, isNotEmpty);
      expect(trends['total_entries'], equals(4));
      expect(trends['date_range'], isNotNull);

      // Test core evolution with multiple entries
      var currentCores = initialCores;
      final analysisResults = <EmotionalAnalysisResult>[];

      for (final entry in entries) {
        final aiResponse = {
          'emotional_analysis': {
            'primary_emotions': entry.moods,
            'emotional_intensity': 0.6,
            'key_themes': ['gratitude', 'reflection'],
            'overall_sentiment': 0.5,
            'personalized_insight': 'Your consistent gratitude practice is building emotional strength.',
          },
          'core_updates': [
            {'name': 'Optimism', 'trend': 'rising'},
            {'name': 'Self-Awareness', 'trend': 'rising'},
          ],
          'growth_indicators': ['gratitude_practice', 'self_reflection'],
        };

        final analysisResult = analyzer.processAnalysis(aiResponse, entry);
        analysisResults.add(analysisResult);
        currentCores = engine.updateCoresWithAnalysis(currentCores, analysisResult, entry);
      }

      // Verify progressive core development
      final finalOptimismCore = currentCores.firstWhere((core) => core.name == 'Optimism');
      final initialOptimismCore = initialCores.firstWhere((core) => core.name == 'Optimism');
      
      expect(finalOptimismCore.percentage, greaterThanOrEqualTo(initialOptimismCore.percentage));

      // Test core combinations
      final combinations = engine.generateCoreCombinations(currentCores);
      expect(combinations, isList);

      // Test milestone achievements
      final milestoneAchievements = engine.calculateMilestoneAchievements(finalOptimismCore, entries);
      expect(milestoneAchievements, isNotEmpty);
      expect(milestoneAchievements.every((milestone) => milestone.isAchieved), isTrue);
    });

    test('should handle error conditions gracefully', () async {
      // Test with empty AI response
      final entry = JournalEntry(
        id: 'error-test-1',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Test entry',
        moods: ['neutral'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final emptyResponse = <String, dynamic>{};
      final analysisResult = analyzer.processAndCacheAnalysis(emptyResponse, entry);

      // Should return fallback analysis
      expect(analysisResult.primaryEmotions, isNotEmpty);
      expect(analysisResult.personalizedInsight, isNotEmpty);
      expect(analysisResult.validationScore, greaterThanOrEqualTo(0.0));

      // Core evolution should handle fallback analysis
      final updatedCores = engine.updateCoresWithAnalysis(initialCores, analysisResult, entry);
      expect(updatedCores.length, equals(initialCores.length));
      expect(updatedCores.every((core) => core.percentage >= 0.0 && core.percentage <= 100.0), isTrue);

      // Test with invalid analysis data
      final invalidAnalysis = EmotionalAnalysisResult(
        primaryEmotions: [],
        emotionalIntensity: -5.0, // Invalid
        keyThemes: [],
        overallSentiment: 5.0, // Invalid
        personalizedInsight: '',
        coreImpacts: {'Invalid': 10.0}, // Invalid
        emotionalPatterns: [],
        growthIndicators: [],
        validationScore: -1.0, // Invalid
      );

      final sanitizedAnalysis = analyzer.sanitizeAnalysisResult(invalidAnalysis);
      expect(sanitizedAnalysis.emotionalIntensity, greaterThanOrEqualTo(0.0));
      expect(sanitizedAnalysis.emotionalIntensity, lessThanOrEqualTo(10.0));
      expect(sanitizedAnalysis.overallSentiment, greaterThanOrEqualTo(-1.0));
      expect(sanitizedAnalysis.overallSentiment, lessThanOrEqualTo(1.0));
      expect(sanitizedAnalysis.validationScore, greaterThanOrEqualTo(0.0));
      expect(sanitizedAnalysis.validationScore, lessThanOrEqualTo(1.0));
    });

    test('should maintain performance with caching', () async {
      final entry = JournalEntry(
        id: 'cache-test-1',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Performance test entry',
        moods: ['happy'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final aiResponse = {
        'emotional_analysis': {
          'primary_emotions': ['happy'],
          'emotional_intensity': 0.7,
          'key_themes': ['performance'],
          'overall_sentiment': 0.6,
          'personalized_insight': 'Performance test insight.',
        },
        'core_updates': [
          {'name': 'Optimism', 'trend': 'stable'},
        ],
        'growth_indicators': ['performance_testing'],
      };

      // First call - should process and cache
      final stopwatch1 = Stopwatch()..start();
      final result1 = analyzer.processAndCacheAnalysis(aiResponse, entry);
      stopwatch1.stop();

      // Second call - should use cache
      final stopwatch2 = Stopwatch()..start();
      final result2 = analyzer.processAndCacheAnalysis(aiResponse, entry);
      stopwatch2.stop();

      // Results should be identical
      expect(result1.primaryEmotions, equals(result2.primaryEmotions));
      expect(result1.personalizedInsight, equals(result2.personalizedInsight));

      // Second call should be faster (cached)
      expect(stopwatch2.elapsedMicroseconds, lessThan(stopwatch1.elapsedMicroseconds));

      // Test cache clearing
      analyzer.clearCache();
      final cachedAfterClear = analyzer.getCachedAnalysisResult(entry.id);
      expect(cachedAfterClear, isNull);
    });
  });
}