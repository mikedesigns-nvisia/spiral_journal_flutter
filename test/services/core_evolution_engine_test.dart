import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/core_evolution_engine.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';

void main() {
  group('CoreEvolutionEngine', () {
    late CoreEvolutionEngine engine;
    late List<EmotionalCore> testCores;
    late EmotionalAnalysisResult testAnalysis;
    late JournalEntry testEntry;

    setUp(() {
      engine = CoreEvolutionEngine();
      
      // Create test cores
      testCores = [
        EmotionalCore(
          id: 'optimism',
          name: 'Optimism',
          description: 'Your ability to maintain hope and positive outlook',
          currentLevel: 0.70,
          previousLevel: 0.70,
          lastUpdated: DateTime.now(),
          trend: 'stable',
          color: '#FF6B35',
          iconPath: 'assets/icons/optimism.png',
          insight: 'Your positive outlook supports your overall well-being.',
          relatedCores: ['resilience', 'growth_mindset'],
        ),
        EmotionalCore(
          id: 'self_awareness',
          name: 'Self-Awareness',
          description: 'Your understanding of your emotions and thoughts',
          currentLevel: 0.75,
          previousLevel: 0.75,
          lastUpdated: DateTime.now(),
          trend: 'stable',
          color: '#45B7D1',
          iconPath: 'assets/icons/self_awareness.png',
          insight: 'Your understanding of yourself deepens through regular reflection.',
          relatedCores: ['resilience', 'growth_mindset'],
        ),
      ];

      // Create test analysis result
      testAnalysis = EmotionalAnalysisResult(
        primaryEmotions: ['happy', 'grateful'],
        emotionalIntensity: 7.5,
        keyThemes: ['gratitude', 'positive_outlook'],
        overallSentiment: 0.6,
        personalizedInsight: 'Your gratitude practice is strengthening your optimism.',
        coreImpacts: {
          'Optimism': 0.3,
          'Self-Awareness': 0.1,
        },
        emotionalPatterns: [
          EmotionalPattern(
            category: 'Growth',
            title: 'Gratitude Practice',
            description: 'Consistent gratitude expressions in journal entries',
            type: 'growth',
          ),
        ],
        growthIndicators: ['gratitude_practice', 'positive_outlook'],
        validationScore: 0.8,
      );

      // Create test journal entry
      testEntry = JournalEntry(
        id: 'test-1',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Today was amazing! I felt so grateful for all the wonderful things in my life.',
        moods: ['happy', 'grateful'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('should calculate core updates based on analysis', () {
      final updates = engine.calculateCoreUpdates(testCores, testAnalysis, testEntry);

      expect(updates, isNotEmpty);
      expect(updates.containsKey('optimism'), isTrue);
      expect(updates['optimism'], greaterThan(70.0)); // Should increase due to positive analysis
    });

    test('should update cores with analysis and maintain data integrity', () {
      final updatedCores = engine.updateCoresWithAnalysis(testCores, testAnalysis, testEntry);

      expect(updatedCores.length, equals(testCores.length));
      
      final optimismCore = updatedCores.firstWhere((core) => core.name == 'Optimism');
      expect(optimismCore.percentage, greaterThanOrEqualTo(0.0));
      expect(optimismCore.percentage, lessThanOrEqualTo(100.0));
      expect(optimismCore.trend, isIn(['rising', 'stable', 'declining']));
      expect(optimismCore.insight, isNotEmpty);
    });

    test('should calculate core progress with milestones', () {
      final optimismCore = testCores.first;
      final recentEntries = [testEntry];
      
      final progressResult = engine.calculateCoreProgress(optimismCore, recentEntries);

      expect(progressResult.core, equals(optimismCore));
      expect(progressResult.milestones, isNotEmpty);
      expect(progressResult.milestones.length, equals(4)); // Foundation, Development, Proficiency, Mastery
      expect(progressResult.achievedMilestones, isNotEmpty);
      expect(progressResult.progressVelocity, greaterThanOrEqualTo(0.0));
    });

    test('should generate personalized core insights', () {
      final recentAnalyses = [testAnalysis];
      final optimismCore = testCores.first;
      
      final insight = engine.generateCoreInsight(optimismCore, recentAnalyses);

      expect(insight, isNotEmpty);
      expect(insight.length, greaterThan(10)); // Should be a meaningful insight
    });

    test('should provide initial cores for new users', () {
      final initialCores = engine.getInitialCores();

      expect(initialCores.length, equals(6)); // All six personality cores
      expect(initialCores.every((core) => core.percentage > 0), isTrue);
      expect(initialCores.every((core) => core.percentage <= 100), isTrue);
      expect(initialCores.every((core) => core.insight.isNotEmpty), isTrue);
      
      final coreNames = initialCores.map((core) => core.name).toList();
      expect(coreNames, contains('Optimism'));
      expect(coreNames, contains('Resilience'));
      expect(coreNames, contains('Self-Awareness'));
      expect(coreNames, contains('Creativity'));
      expect(coreNames, contains('Social Connection'));
      expect(coreNames, contains('Growth Mindset'));
    });

    test('should handle negative emotional analysis appropriately', () {
      final negativeAnalysis = EmotionalAnalysisResult(
        primaryEmotions: ['sad', 'frustrated'],
        emotionalIntensity: 8.0,
        keyThemes: ['difficulty', 'challenge'],
        overallSentiment: -0.4,
        personalizedInsight: 'You are facing some challenges but showing resilience.',
        coreImpacts: {
          'Optimism': -0.2,
          'Resilience': 0.3, // Challenges can build resilience
        },
        emotionalPatterns: [
          EmotionalPattern(
            category: 'Challenge',
            title: 'Difficult Period',
            description: 'Working through challenging emotions',
            type: 'awareness',
          ),
        ],
        growthIndicators: ['emotional_processing'],
        validationScore: 0.7,
      );

      final updatedCores = engine.updateCoresWithAnalysis(testCores, negativeAnalysis, testEntry);
      
      expect(updatedCores, isNotEmpty);
      expect(updatedCores.every((core) => core.percentage >= 0.0), isTrue);
      expect(updatedCores.every((core) => core.percentage <= 100.0), isTrue);
    });

    test('should limit daily core changes to prevent extreme fluctuations', () {
      final extremeAnalysis = EmotionalAnalysisResult(
        primaryEmotions: ['ecstatic', 'overjoyed'],
        emotionalIntensity: 10.0,
        keyThemes: ['extreme_happiness'],
        overallSentiment: 1.0,
        personalizedInsight: 'Extremely positive day!',
        coreImpacts: {
          'Optimism': 10.0, // Extreme impact that should be limited
        },
        emotionalPatterns: [],
        growthIndicators: ['extreme_positivity'],
        validationScore: 0.9,
      );

      final updates = engine.calculateCoreUpdates(testCores, extremeAnalysis, testEntry);
      
      // Should limit the change to reasonable daily limits
      if (updates.containsKey('optimism')) {
        final change = updates['optimism']! - testCores.first.percentage;
        expect(change.abs(), lessThanOrEqualTo(5.0)); // Reasonable daily change limit
      }
    });

    test('should handle empty or invalid analysis gracefully', () {
      final emptyAnalysis = EmotionalAnalysisResult(
        primaryEmotions: [],
        emotionalIntensity: 0.0,
        keyThemes: [],
        overallSentiment: 0.0,
        personalizedInsight: '',
        coreImpacts: {},
        emotionalPatterns: [],
        growthIndicators: [],
        validationScore: 0.0,
      );

      final updatedCores = engine.updateCoresWithAnalysis(testCores, emptyAnalysis, testEntry);
      
      expect(updatedCores.length, equals(testCores.length));
      expect(updatedCores.every((core) => core.percentage >= 0.0), isTrue);
      expect(updatedCores.every((core) => core.percentage <= 100.0), isTrue);
    });

    test('should calculate appropriate trends based on percentage changes', () {
      // Test rising trend
      final risingAnalysis = EmotionalAnalysisResult(
        primaryEmotions: ['happy', 'motivated'],
        emotionalIntensity: 8.0,
        keyThemes: ['growth', 'progress'],
        overallSentiment: 0.7,
        personalizedInsight: 'Great progress!',
        coreImpacts: {'Optimism': 0.8},
        emotionalPatterns: [],
        growthIndicators: ['growth'],
        validationScore: 0.8,
      );

      final updatedCores = engine.updateCoresWithAnalysis(testCores, risingAnalysis, testEntry);
      final optimismCore = updatedCores.firstWhere((core) => core.name == 'Optimism');
      
      if (optimismCore.percentage > testCores.first.percentage + 0.5) {
        expect(optimismCore.trend, equals('rising'));
      }
    });
  });
}