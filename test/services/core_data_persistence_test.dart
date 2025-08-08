import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/services/core_library_service.dart';

void main() {
  late CoreLibraryService coreLibraryService;

  setUp(() {
    // Initialize the service before each test
    coreLibraryService = CoreLibraryService();
    
    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
  });

  group('Core data persistence tests', () {
    test('should create initial cores when no data exists', () async {
      // Get cores (should create initial cores)
      final cores = await coreLibraryService.getAllCores();
      
      // Verify all six cores are created
      expect(cores.length, equals(6));
      
      // Verify core names
      final coreNames = cores.map((c) => c.name).toList();
      expect(coreNames, contains('Optimism'));
      expect(coreNames, contains('Resilience'));
      expect(coreNames, contains('Self-Awareness'));
      expect(coreNames, contains('Creativity'));
      expect(coreNames, contains('Social Connection'));
      expect(coreNames, contains('Growth Mindset'));
    });

    test('should save and retrieve cores correctly', () async {
      // Get initial cores
      final initialCores = await coreLibraryService.getAllCores();
      
      // Update a core
      final optimismCore = initialCores.firstWhere((c) => c.name == 'Optimism');
      final updatedCore = optimismCore.copyWith(
        currentLevel: 0.85,
        trend: 'rising',
      );
      
      // Update the core
      await coreLibraryService.updateCore(updatedCore);
      
      // Get cores again
      final updatedCores = await coreLibraryService.getAllCores();
      
      // Find the updated core
      final retrievedCore = updatedCores.firstWhere((c) => c.name == 'Optimism');
      
      // Verify the update was persisted
      expect(retrievedCore.currentLevel, equals(0.85));
      expect(retrievedCore.trend, equals('rising'));
    });

    test('should handle invalid JSON gracefully', () async {
      // Set invalid JSON in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emotional_cores', 'invalid json');
      
      // Try to get cores
      final cores = await coreLibraryService.getAllCores();
      
      // Should return initial cores
      expect(cores.length, equals(6));
    });

    test('should update cores with journal analysis', () async {
      // Get initial cores
      final initialCores = await coreLibraryService.getAllCores();
      
      // Create a mock analysis result
      final analysis = EmotionalAnalysisResult(
        primaryEmotions: ['happy', 'grateful'],
        emotionalIntensity: 7.0,
        keyThemes: ['gratitude', 'optimism'],
        overallSentiment: 0.8,
        personalizedInsight: 'You are feeling grateful and optimistic.',
        coreImpacts: {
          'Optimism': 0.2,
          'Resilience': 0.1,
        },
        emotionalPatterns: [],
        growthIndicators: ['self-reflection'],
        validationScore: 0.9,
      );
      
      // Update cores with analysis
      final updatedCores = await coreLibraryService.updateCoresWithJournalAnalysis(
        [], // No entries needed for this test
        analysis,
      );
      
      // Find the updated cores
      final optimismCore = updatedCores.firstWhere((c) => c.name == 'Optimism');
      final resilienceCore = updatedCores.firstWhere((c) => c.name == 'Resilience');
      
      // Verify the cores were updated
      expect(optimismCore.currentLevel, greaterThan(initialCores.firstWhere((c) => c.name == 'Optimism').currentLevel));
      expect(resilienceCore.currentLevel, greaterThan(initialCores.firstWhere((c) => c.name == 'Resilience').currentLevel));
    });

    test('should handle color formats correctly', () async {
      // Get initial cores
      final cores = await coreLibraryService.getAllCores();
      
      // Update a core with different color format
      final creativityCore = cores.firstWhere((c) => c.name == 'Creativity');
      
      // Test with # prefix
      final updatedCore1 = creativityCore.copyWith(
        color: '#FF5733',
      );
      await coreLibraryService.updateCore(updatedCore1);
      
      // Test without # prefix
      final updatedCore2 = creativityCore.copyWith(
        color: 'FF5733',
      );
      await coreLibraryService.updateCore(updatedCore2);
      
      // Get cores again
      final updatedCores = await coreLibraryService.getAllCores();
      
      // Find the updated core
      final retrievedCore = updatedCores.firstWhere((c) => c.name == 'Creativity');
      
      // Verify the color was persisted
      expect(retrievedCore.color, equals('FF5733'));
    });
  });
}