import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/production_environment_loader.dart';
import 'package:spiral_journal/services/ai_service_diagnostic.dart';
import 'package:spiral_journal/config/environment.dart';
import '../utils/test_setup_helper.dart';
import '../utils/claude_integration_tester.dart';

/// Comprehensive integration test suite for Claude AI integration
/// 
/// This test suite validates the complete flow from journal entry creation
/// to AI analysis, ensuring that the Claude API integration works correctly
/// in production builds and handles error scenarios appropriately.
/// 
/// Test Coverage:
/// - Complete journal → AI analysis flow
/// - Real API key validation and usage
/// - Error scenarios and fallback behavior
/// - Production build compatibility
/// - Service initialization and configuration
/// - Network connectivity handling
/// - Offline queue processing
void main() {
  group('Claude AI Integration - Complete Flow Validation', () {
    late ClaudeIntegrationTester tester;
    late AIServiceManager aiManager;
    late JournalService journalService;

    setUpAll(() async {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
      
      // Initialize the integration tester
      tester = ClaudeIntegrationTester();
      await tester.initialize();
      
      // Initialize services
      aiManager = AIServiceManager();
      journalService = JournalService();
    });

    tearDownAll(() async {
      await tester.dispose();
      TestSetupHelper.teardownTestConfiguration();
    });

    setUp(() async {
      // Reset services for each test
      await aiManager.initialize();
      await journalService.initialize();
    });

    group('Environment and Configuration Tests', () {
      test('should load environment variables correctly', () async {
        final result = await tester.testEnvironmentLoading();
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Environment loading should succeed');
        expect(result.data['hasClaudeApiKey'], isTrue, reason: 'Claude API key should be available');
        expect(result.data['environmentLoaded'], isTrue, reason: 'Environment should be loaded');
        
        // Validate API key format if present
        if (result.data['claudeApiKey'] != null) {
          final apiKey = result.data['claudeApiKey'] as String;
          expect(apiKey.startsWith('sk-ant-'), isTrue, reason: 'API key should have correct format');
          expect(apiKey.length, greaterThan(50), reason: 'API key should be sufficiently long');
        }
      });

      test('should initialize AI service manager correctly', () async {
        final result = await tester.testServiceInitialization();
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Service initialization should succeed');
        expect(result.data['aiManagerInitialized'], isTrue, reason: 'AI manager should be initialized');
        expect(result.data['currentProvider'], isNotNull, reason: 'Provider should be selected');
        
        // Verify provider selection logic
        final provider = result.data['currentProvider'] as String;
        expect(['enabled', 'disabled'], contains(provider), reason: 'Provider should be valid');
      });

      test('should validate API key format and connectivity', () async {
        final result = await tester.testApiConnectivity();
        
        if (result.success) {
          expect(result.data['connectionSuccessful'], isTrue, reason: 'API connection should succeed with valid key');
          expect(result.data['responseTime'], lessThan(10000), reason: 'Response time should be reasonable');
        } else {
          // If connection fails, it should be due to network or API issues, not configuration
          expect(result.errorMessage, isNotNull, reason: 'Should provide error message for failed connection');
          print('API connectivity test failed (expected in some environments): ${result.errorMessage}');
        }
      });
    });

    group('Complete Journal-to-Analysis Flow Tests', () {
      test('should complete full journal entry analysis flow', () async {
        // Create a test journal entry
        final testEntry = JournalEntry.create(
          content: 'Today was a wonderful day! I felt really grateful for my friends and family. '
                  'I learned something new at work and overcame a challenging problem. '
                  'I feel like I\'m growing as a person and becoming more resilient.',
          moods: ['happy', 'grateful', 'confident', 'reflective'],
        );

        final result = await tester.testCompleteAnalysisFlow(testEntry);
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Complete analysis flow should succeed');
        
        // Validate analysis results
        final analysis = result.data['analysis'] as Map<String, dynamic>;
        expect(analysis, isNotNull, reason: 'Analysis should be generated');
        expect(analysis['primary_emotions'], isA<List>(), reason: 'Should have primary emotions');
        expect(analysis['emotional_intensity'], isA<num>(), reason: 'Should have emotional intensity');
        expect(analysis['core_adjustments'], isA<Map>(), reason: 'Should have core adjustments');
        
        // Validate core adjustments are reasonable
        final coreAdjustments = analysis['core_adjustments'] as Map<String, dynamic>;
        expect(coreAdjustments.isNotEmpty, isTrue, reason: 'Should have core adjustments');
        
        // Check for expected positive adjustments based on content
        if (coreAdjustments.containsKey('Optimism')) {
          expect(coreAdjustments['Optimism'], greaterThan(0), reason: 'Optimism should increase for positive content');
        }
        if (coreAdjustments.containsKey('Self-Awareness')) {
          expect(coreAdjustments['Self-Awareness'], greaterThan(0), reason: 'Self-awareness should increase for reflective content');
        }
      });

      test('should handle journal entry with mixed emotions', () async {
        final testEntry = JournalEntry.create(
          content: 'Today was challenging. I struggled with a difficult situation at work, '
                  'but I managed to stay calm and find a solution. I felt frustrated at first, '
                  'but then proud of how I handled it. I\'m learning to be more patient with myself.',
          moods: ['frustrated', 'proud', 'reflective', 'determined'],
        );

        final result = await tester.testCompleteAnalysisFlow(testEntry);
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Mixed emotion analysis should succeed');
        
        final analysis = result.data['analysis'] as Map<String, dynamic>;
        final coreAdjustments = analysis['core_adjustments'] as Map<String, dynamic>;
        
        // Should show growth in resilience and self-awareness
        if (coreAdjustments.containsKey('Resilience')) {
          expect(coreAdjustments['Resilience'], greaterThan(0), reason: 'Resilience should increase for overcoming challenges');
        }
      });

      test('should process multiple entries in batch', () async {
        final testEntries = [
          JournalEntry.create(
            content: 'Great day with friends, feeling social and happy.',
            moods: ['happy', 'social'],
          ),
          JournalEntry.create(
            content: 'Learned something new today, feeling accomplished and motivated.',
            moods: ['motivated', 'confident'],
          ),
          JournalEntry.create(
            content: 'Reflecting on my growth this week, feeling grateful and aware.',
            moods: ['reflective', 'grateful'],
          ),
        ];

        final result = await tester.testBatchAnalysis(testEntries);
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Batch analysis should succeed');
        
        final analyses = result.data['analyses'] as List<dynamic>;
        expect(analyses.length, equals(testEntries.length), reason: 'Should analyze all entries');
        
        // Each analysis should be valid
        for (int i = 0; i < analyses.length; i++) {
          final analysis = analyses[i] as Map<String, dynamic>;
          expect(analysis['primary_emotions'], isA<List>(), reason: 'Entry $i should have emotions');
          expect(analysis['core_adjustments'], isA<Map>(), reason: 'Entry $i should have core adjustments');
        }
      });
    });

    group('Core Update Integration Tests', () {
      test('should update emotional cores based on analysis', () async {
        // Get initial cores
        final initialCores = await journalService.getAllCores();
        expect(initialCores.isNotEmpty, isTrue, reason: 'Should have initial cores');

        final testEntry = JournalEntry.create(
          content: 'I had a breakthrough today! I realized something important about myself '
                  'and feel like I\'m becoming more self-aware. This insight will help me grow.',
          moods: ['insightful', 'hopeful', 'reflective'],
        );

        final result = await tester.testCoreUpdateFlow(testEntry, initialCores);
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Core update flow should succeed');
        
        final coreUpdates = result.data['coreUpdates'] as Map<String, double>;
        expect(coreUpdates.isNotEmpty, isTrue, reason: 'Should have core updates');
        
        // Verify updates are applied correctly
        final updatedCores = result.data['updatedCores'] as List<EmotionalCore>;
        expect(updatedCores.length, equals(initialCores.length), reason: 'Should maintain same number of cores');
        
        // Check that at least one core was updated
        bool hasUpdates = false;
        for (int i = 0; i < initialCores.length; i++) {
          if (updatedCores[i].currentLevel != initialCores[i].currentLevel) {
            hasUpdates = true;
            break;
          }
        }
        expect(hasUpdates, isTrue, reason: 'At least one core should be updated');
      });

      test('should generate monthly insights from multiple entries', () async {
        final testEntries = List.generate(5, (index) => JournalEntry.create(
          content: 'Day ${index + 1}: Reflecting on my journey and growth. '
                  'Each day brings new insights and opportunities for development.',
          moods: ['reflective', 'hopeful', 'grateful'],
        ));

        final result = await tester.testMonthlyInsightGeneration(testEntries);
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Monthly insight generation should succeed');
        
        final insight = result.data['insight'] as String;
        expect(insight.isNotEmpty, isTrue, reason: 'Should generate meaningful insight');
        expect(insight.length, greaterThan(20), reason: 'Insight should be substantial');
        
        // Should mention journaling consistency or patterns
        final lowerInsight = insight.toLowerCase();
        expect(
          lowerInsight.contains('reflect') || 
          lowerInsight.contains('growth') || 
          lowerInsight.contains('journey') ||
          lowerInsight.contains('consistent'),
          isTrue,
          reason: 'Insight should reference journaling patterns or growth'
        );
      });
    });

    group('Error Handling and Fallback Tests', () {
      test('should handle invalid API key gracefully', () async {
        final result = await tester.testInvalidApiKeyHandling();
        
        expect(result.success, isTrue, reason: 'Should handle invalid API key gracefully');
        expect(result.data['fallbackUsed'], isTrue, reason: 'Should use fallback provider');
        expect(result.data['errorHandled'], isTrue, reason: 'Should handle error properly');
      });

      test('should handle network connectivity issues', () async {
        final testEntry = JournalEntry.create(
          content: 'Testing network failure scenario.',
          moods: ['neutral'],
        );

        final result = await tester.testNetworkFailureHandling(testEntry);
        
        expect(result.success, isTrue, reason: 'Should handle network failure gracefully');
        
        // Should either succeed with retry or fail gracefully with fallback
        if (result.data['networkFailureSimulated'] == true) {
          expect(result.data['fallbackUsed'], isTrue, reason: 'Should use fallback on network failure');
          expect(result.data['analysisProvided'], isTrue, reason: 'Should still provide analysis');
        }
      });

      test('should handle API rate limiting', () async {
        final result = await tester.testRateLimitHandling();
        
        expect(result.success, isTrue, reason: 'Should handle rate limiting gracefully');
        
        if (result.data['rateLimitEncountered'] == true) {
          expect(result.data['retryScheduled'], isTrue, reason: 'Should schedule retry on rate limit');
          expect(result.data['fallbackUsed'], isTrue, reason: 'Should use fallback during rate limit');
        }
      });

      test('should queue entries for offline processing', () async {
        final testEntry = JournalEntry.create(
          content: 'Testing offline queue functionality.',
          moods: ['neutral'],
        );

        final result = await tester.testOfflineQueueProcessing(testEntry);
        
        expect(result.success, isTrue, reason: 'Should handle offline queuing');
        expect(result.data['entryQueued'], isTrue, reason: 'Entry should be queued for offline processing');
        
        if (result.data['queueProcessed'] == true) {
          expect(result.data['analysisCompleted'], isTrue, reason: 'Queued analysis should complete when online');
        }
      });
    });

    group('Production Build Compatibility Tests', () {
      test('should work with production environment configuration', () async {
        final result = await tester.testProductionEnvironment();
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Should work in production environment');
        expect(result.data['environmentConfigured'], isTrue, reason: 'Production environment should be configured');
        expect(result.data['servicesInitialized'], isTrue, reason: 'Services should initialize in production');
      });

      test('should handle production API key loading', () async {
        final result = await tester.testProductionApiKeyLoading();
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Should load API key in production');
        
        if (result.data['apiKeyLoaded'] == true) {
          expect(result.data['keyValidFormat'], isTrue, reason: 'Loaded API key should have valid format');
          expect(result.data['keySource'], isNotNull, reason: 'Should identify key source');
        }
      });

      test('should provide diagnostic information for troubleshooting', () async {
        final result = await tester.runComprehensiveDiagnostic();
        
        expect(result.success, isTrue, reason: 'Diagnostic should complete successfully');
        
        final diagnostic = result.data['diagnostic'] as Map<String, dynamic>;
        expect(diagnostic.containsKey('environment'), isTrue, reason: 'Should include environment diagnostic');
        expect(diagnostic.containsKey('initialization'), isTrue, reason: 'Should include initialization diagnostic');
        expect(diagnostic.containsKey('connectivity'), isTrue, reason: 'Should include connectivity diagnostic');
        expect(diagnostic.containsKey('endToEnd'), isTrue, reason: 'Should include end-to-end diagnostic');
        
        // Generate diagnostic report
        final report = result.data['report'] as String;
        expect(report.isNotEmpty, isTrue, reason: 'Should generate diagnostic report');
        print('Diagnostic Report:\n$report');
      });
    });

    group('Performance and Resource Management Tests', () {
      test('should handle concurrent analysis requests', () async {
        final testEntries = List.generate(3, (index) => JournalEntry.create(
          content: 'Concurrent test entry $index with different content and moods.',
          moods: ['test_mood_$index'],
        ));

        final result = await tester.testConcurrentAnalysis(testEntries);
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Concurrent analysis should succeed');
        
        final results = result.data['results'] as List<dynamic>;
        expect(results.length, equals(testEntries.length), reason: 'Should handle all concurrent requests');
        
        // All results should be valid
        for (int i = 0; i < results.length; i++) {
          final analysisResult = results[i] as Map<String, dynamic>;
          expect(analysisResult.containsKey('analysis'), isTrue, reason: 'Result $i should contain analysis');
        }
      });

      test('should manage token usage efficiently', () async {
        final testEntry = JournalEntry.create(
          content: 'This is a test entry to validate token usage tracking and optimization.',
          moods: ['neutral'],
        );

        final result = await tester.testTokenUsageTracking(testEntry);
        
        expect(result.success, isTrue, reason: 'Token usage tracking should work');
        
        if (result.data['tokenUsageTracked'] == true) {
          expect(result.data['inputTokens'], greaterThan(0), reason: 'Should track input tokens');
          expect(result.data['outputTokens'], greaterThan(0), reason: 'Should track output tokens');
          expect(result.data['totalTokens'], greaterThan(0), reason: 'Should calculate total tokens');
        }
      });
    });

    group('Integration with Journal Service Tests', () {
      test('should integrate with journal service for complete workflow', () async {
        final result = await tester.testJournalServiceIntegration();
        
        expect(result.success, isTrue, reason: result.errorMessage ?? 'Journal service integration should work');
        
        // Verify that journal entries are created and analyzed
        expect(result.data['entryCreated'], isTrue, reason: 'Journal entry should be created');
        expect(result.data['analysisTriggered'], isTrue, reason: 'Analysis should be triggered');
        expect(result.data['coresUpdated'], isTrue, reason: 'Cores should be updated');
        
        if (result.data['entryId'] != null) {
          final entryId = result.data['entryId'] as String;
          expect(entryId.isNotEmpty, isTrue, reason: 'Entry ID should be valid');
        }
      });

      test('should handle journal service error scenarios', () async {
        final result = await tester.testJournalServiceErrorHandling();
        
        expect(result.success, isTrue, reason: 'Should handle journal service errors gracefully');
        expect(result.data['errorHandled'], isTrue, reason: 'Errors should be handled properly');
        expect(result.data['fallbackProvided'], isTrue, reason: 'Should provide fallback behavior');
      });
    });
  });
}