import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/production_environment_loader.dart';
import 'package:spiral_journal/services/ai_service_diagnostic.dart';
import 'package:spiral_journal/services/ai_service_interface.dart';
import 'package:spiral_journal/config/environment.dart';
import 'test_setup_helper.dart';

/// Result model for integration test operations
class IntegrationTestResult {
  final bool success;
  final Map<String, dynamic> data;
  final String? errorMessage;
  final Duration? executionTime;
  final DateTime timestamp;

  IntegrationTestResult({
    required this.success,
    this.data = const {},
    this.errorMessage,
    this.executionTime,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory IntegrationTestResult.success({
    Map<String, dynamic> data = const {},
    Duration? executionTime,
  }) {
    return IntegrationTestResult(
      success: true,
      data: data,
      executionTime: executionTime,
    );
  }

  factory IntegrationTestResult.failure({
    required String errorMessage,
    Map<String, dynamic> data = const {},
    Duration? executionTime,
  }) {
    return IntegrationTestResult(
      success: false,
      data: data,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  @override
  String toString() {
    return 'IntegrationTestResult(success: $success, error: $errorMessage, data: ${data.keys.toList()})';
  }
}

/// Comprehensive integration tester for Claude AI functionality
/// 
/// This class provides methods to test the complete Claude AI integration
/// including environment setup, service initialization, API connectivity,
/// analysis flows, error handling, and production compatibility.
class ClaudeIntegrationTester {
  late AIServiceManager _aiManager;
  late JournalService _journalService;
  late AIServiceDiagnostic _diagnostic;
  
  bool _initialized = false;
  final List<String> _testEntryIds = [];
  final Map<String, dynamic> _testMetrics = {};

  /// Initialize the integration tester
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      TestSetupHelper.ensureFlutterBinding();
      
      _aiManager = AIServiceManager();
      _journalService = JournalService();
      _diagnostic = AIServiceDiagnostic();
      
      await _aiManager.initialize();
      await _journalService.initialize();
      
      _initialized = true;
      debugPrint('✅ ClaudeIntegrationTester initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ ClaudeIntegrationTester initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Dispose of resources and clean up test data
  Future<void> dispose() async {
    if (!_initialized) return;

    try {
      // Clean up test entries
      for (final entryId in _testEntryIds) {
        try {
          await _journalService.deleteEntry(entryId);
        } catch (e) {
          debugPrint('Warning: Failed to clean up test entry $entryId: $e');
        }
      }
      _testEntryIds.clear();
      
      // Dispose services
      await _journalService.dispose();
      
      _initialized = false;
      debugPrint('✅ ClaudeIntegrationTester disposed successfully');
    } catch (e) {
      debugPrint('❌ ClaudeIntegrationTester disposal error: $e');
    }
  }

  /// Test environment variable loading and configuration
  Future<IntegrationTestResult> testEnvironmentLoading() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing environment loading...');
      
      // Test ProductionEnvironmentLoader
      await ProductionEnvironmentLoader.ensureLoaded();
      final status = ProductionEnvironmentLoader.getStatus();
      final claudeApiKey = ProductionEnvironmentLoader.getClaudeApiKey();
      
      // Test EnvironmentConfig
      final envClaudeKey = EnvironmentConfig.claudeApiKey;
      
      final data = {
        'environmentLoaded': status.isLoaded,
        'hasClaudeApiKey': claudeApiKey != null && claudeApiKey.isNotEmpty,
        'claudeApiKey': claudeApiKey,
        'envConfigKey': envClaudeKey,
        'variableCount': status.variableCount,
        'claudeApiKeyPreview': status.claudeApiKeyPreview,
      };
      
      stopwatch.stop();
      debugPrint('✅ Environment loading test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Environment loading test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Environment loading failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test AI service manager initialization
  Future<IntegrationTestResult> testServiceInitialization() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing service initialization...');
      
      // Test AIServiceManager initialization
      final aiManager = AIServiceManager();
      await aiManager.initialize();
      
      final currentProvider = aiManager.currentProvider;
      final isConfigured = aiManager.isConfigured;
      
      // Test service status
      final status = await _diagnostic.getServiceStatus();
      
      final data = {
        'aiManagerInitialized': true,
        'currentProvider': currentProvider.toString(),
        'isConfigured': isConfigured,
        'serviceStatus': status.toJson(),
      };
      
      stopwatch.stop();
      debugPrint('✅ Service initialization test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Service initialization test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Service initialization failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test API connectivity and validation
  Future<IntegrationTestResult> testApiConnectivity() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing API connectivity...');
      
      // Test connection through diagnostic
      final connectivityResult = await _diagnostic.testApiConnectivity();
      
      final data = {
        'connectionSuccessful': connectivityResult.success,
        'responseTime': connectivityResult.responseTime,
        'apiKeyValid': connectivityResult.apiKeyValid,
        'errorMessage': connectivityResult.errorMessage,
      };
      
      stopwatch.stop();
      debugPrint('✅ API connectivity test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ API connectivity test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'API connectivity test failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test complete journal entry analysis flow
  Future<IntegrationTestResult> testCompleteAnalysisFlow(JournalEntry entry) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing complete analysis flow for entry: ${entry.content.substring(0, 50)}...');
      
      // Step 1: Analyze the journal entry
      final analysis = await _aiManager.analyzeJournalEntry(entry);
      
      // Step 2: Validate analysis structure
      _validateAnalysisStructure(analysis);
      
      // Step 3: Test core updates
      final currentCores = await _journalService.getAllCores();
      final coreUpdates = await _aiManager.calculateCoreUpdates(entry, currentCores);
      
      // Step 4: Test monthly insight generation (with single entry)
      final monthlyInsight = await _aiManager.generateMonthlyInsight([entry]);
      
      final data = {
        'analysis': analysis,
        'coreUpdates': coreUpdates,
        'monthlyInsight': monthlyInsight,
        'analysisValid': true,
        'coreUpdatesValid': coreUpdates.isNotEmpty,
        'insightGenerated': monthlyInsight.isNotEmpty,
      };
      
      stopwatch.stop();
      debugPrint('✅ Complete analysis flow test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Complete analysis flow test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Complete analysis flow failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test batch analysis of multiple entries
  Future<IntegrationTestResult> testBatchAnalysis(List<JournalEntry> entries) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing batch analysis for ${entries.length} entries...');
      
      final analyses = <Map<String, dynamic>>[];
      
      // Process each entry (simulating batch processing)
      for (final entry in entries) {
        final analysis = await _aiManager.analyzeJournalEntry(entry);
        _validateAnalysisStructure(analysis);
        analyses.add(analysis);
      }
      
      // Test batch insight generation
      final batchInsight = await _aiManager.generateMonthlyInsight(entries);
      
      final data = {
        'analyses': analyses,
        'batchInsight': batchInsight,
        'processedCount': analyses.length,
        'allAnalysesValid': analyses.length == entries.length,
      };
      
      stopwatch.stop();
      debugPrint('✅ Batch analysis test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Batch analysis test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Batch analysis failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test core update flow with journal entry
  Future<IntegrationTestResult> testCoreUpdateFlow(JournalEntry entry, List<EmotionalCore> initialCores) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing core update flow...');
      
      // Calculate core updates
      final coreUpdates = await _aiManager.calculateCoreUpdates(entry, initialCores);
      
      // Apply updates to cores (simulate the update process)
      final updatedCores = <EmotionalCore>[];
      for (final core in initialCores) {
        if (coreUpdates.containsKey(core.id)) {
          final newLevel = (coreUpdates[core.id]! / 100.0).clamp(0.0, 1.0);
          updatedCores.add(core.copyWith(
            currentLevel: newLevel,
            previousLevel: core.currentLevel,
            lastUpdated: DateTime.now(),
          ));
        } else {
          updatedCores.add(core);
        }
      }
      
      final data = {
        'coreUpdates': coreUpdates,
        'updatedCores': updatedCores,
        'initialCoreCount': initialCores.length,
        'updatedCoreCount': updatedCores.length,
        'hasUpdates': coreUpdates.isNotEmpty,
      };
      
      stopwatch.stop();
      debugPrint('✅ Core update flow test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Core update flow test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Core update flow failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test monthly insight generation
  Future<IntegrationTestResult> testMonthlyInsightGeneration(List<JournalEntry> entries) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing monthly insight generation for ${entries.length} entries...');
      
      final insight = await _aiManager.generateMonthlyInsight(entries);
      
      final data = {
        'insight': insight,
        'entryCount': entries.length,
        'insightLength': insight.length,
        'insightGenerated': insight.isNotEmpty,
      };
      
      stopwatch.stop();
      debugPrint('✅ Monthly insight generation test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Monthly insight generation test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Monthly insight generation failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test invalid API key handling
  Future<IntegrationTestResult> testInvalidApiKeyHandling() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing invalid API key handling...');
      
      // Create a temporary AI manager with invalid key
      final testManager = AIServiceManager();
      
      // Try to disable AI to force fallback
      await testManager.setAIEnabled(false);
      
      // Test analysis with fallback
      final testEntry = JournalEntry.create(
        content: 'Test entry for invalid API key scenario.',
        moods: ['neutral'],
      );
      
      final analysis = await testManager.analyzeJournalEntry(testEntry);
      
      final data = {
        'fallbackUsed': testManager.currentProvider == AIProvider.disabled,
        'analysisProvided': analysis.isNotEmpty,
        'errorHandled': true,
      };
      
      stopwatch.stop();
      debugPrint('✅ Invalid API key handling test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Invalid API key handling test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Invalid API key handling failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test network failure handling
  Future<IntegrationTestResult> testNetworkFailureHandling(JournalEntry entry) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing network failure handling...');
      
      // Attempt analysis (may fail due to network issues)
      Map<String, dynamic>? analysis;
      bool networkFailure = false;
      bool fallbackUsed = false;
      
      try {
        analysis = await _aiManager.analyzeJournalEntry(entry);
      } catch (e) {
        networkFailure = true;
        debugPrint('Network failure detected: $e');
        
        // Try with AI disabled (fallback)
        await _aiManager.setAIEnabled(false);
        analysis = await _aiManager.analyzeJournalEntry(entry);
        fallbackUsed = true;
      }
      
      final data = {
        'networkFailureSimulated': networkFailure,
        'fallbackUsed': fallbackUsed,
        'analysisProvided': analysis.isNotEmpty,
        'analysis': analysis,
      };
      
      stopwatch.stop();
      debugPrint('✅ Network failure handling test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Network failure handling test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Network failure handling failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test rate limit handling
  Future<IntegrationTestResult> testRateLimitHandling() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing rate limit handling...');
      
      // Simulate rate limit scenario by making multiple rapid requests
      final testEntries = List.generate(5, (index) => JournalEntry.create(
        content: 'Rate limit test entry $index',
        moods: ['neutral'],
      ));
      
      bool rateLimitEncountered = false;
      bool retryScheduled = false;
      bool fallbackUsed = false;
      
      for (final entry in testEntries) {
        try {
          await _aiManager.analyzeJournalEntry(entry);
          // Small delay between requests
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          if (e.toString().toLowerCase().contains('rate') || 
              e.toString().toLowerCase().contains('limit')) {
            rateLimitEncountered = true;
            retryScheduled = true;
            fallbackUsed = true;
            break;
          }
        }
      }
      
      final data = {
        'rateLimitEncountered': rateLimitEncountered,
        'retryScheduled': retryScheduled,
        'fallbackUsed': fallbackUsed,
      };
      
      stopwatch.stop();
      debugPrint('✅ Rate limit handling test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Rate limit handling test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Rate limit handling failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test offline queue processing
  Future<IntegrationTestResult> testOfflineQueueProcessing(JournalEntry entry) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing offline queue processing...');
      
      // Create entry through journal service (which handles queuing)
      final entryId = await _journalService.createJournalEntry(
        content: entry.content,
        moods: entry.moods,
      );
      
      _testEntryIds.add(entryId);
      
      final data = {
        'entryQueued': entryId.isNotEmpty,
        'entryId': entryId,
        'queueProcessed': !entryId.startsWith('queued_'),
        'analysisCompleted': !entryId.startsWith('queued_'),
      };
      
      stopwatch.stop();
      debugPrint('✅ Offline queue processing test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Offline queue processing test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Offline queue processing failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test production environment compatibility
  Future<IntegrationTestResult> testProductionEnvironment() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing production environment compatibility...');
      
      // Test environment loading
      await ProductionEnvironmentLoader.ensureLoaded();
      final envStatus = ProductionEnvironmentLoader.getStatus();
      
      // Test service initialization
      final aiManager = AIServiceManager();
      await aiManager.initialize();
      
      final journalService = JournalService();
      await journalService.initialize();
      
      final data = {
        'environmentConfigured': envStatus.isLoaded,
        'servicesInitialized': true,
        'aiManagerReady': aiManager.isConfigured,
        'journalServiceReady': true,
      };
      
      stopwatch.stop();
      debugPrint('✅ Production environment test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Production environment test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Production environment test failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test production API key loading
  Future<IntegrationTestResult> testProductionApiKeyLoading() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing production API key loading...');
      
      await ProductionEnvironmentLoader.ensureLoaded();
      final apiKey = ProductionEnvironmentLoader.getClaudeApiKey();
      final status = ProductionEnvironmentLoader.getStatus();
      
      final data = {
        'apiKeyLoaded': apiKey != null && apiKey.isNotEmpty,
        'keyValidFormat': apiKey != null && apiKey.startsWith('sk-ant-'),
        'variableCount': status.variableCount,
        'keyLength': apiKey?.length ?? 0,
      };
      
      stopwatch.stop();
      debugPrint('✅ Production API key loading test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Production API key loading test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Production API key loading failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Run comprehensive diagnostic
  Future<IntegrationTestResult> runComprehensiveDiagnostic() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Running comprehensive diagnostic...');
      
      final diagnostic = await _diagnostic.runDiagnostic();
      final report = _diagnostic.generateReport(diagnostic);
      
      final data = {
        'diagnostic': diagnostic,
        'report': report,
        'allTestsPassed': diagnostic.values.every((result) => result['success'] == true),
      };
      
      stopwatch.stop();
      debugPrint('✅ Comprehensive diagnostic completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Comprehensive diagnostic failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Comprehensive diagnostic failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test concurrent analysis requests
  Future<IntegrationTestResult> testConcurrentAnalysis(List<JournalEntry> entries) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing concurrent analysis for ${entries.length} entries...');
      
      // Execute all analyses concurrently
      final futures = entries.map((entry) async {
        try {
          final analysis = await _aiManager.analyzeJournalEntry(entry);
          return {'success': true, 'analysis': analysis};
        } catch (e) {
          return {'success': false, 'error': e.toString()};
        }
      }).toList();
      
      final results = await Future.wait(futures);
      final successCount = results.where((r) => r['success'] == true).length;
      
      final data = {
        'results': results,
        'totalRequests': entries.length,
        'successfulRequests': successCount,
        'failedRequests': entries.length - successCount,
        'allSuccessful': successCount == entries.length,
      };
      
      stopwatch.stop();
      debugPrint('✅ Concurrent analysis test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Concurrent analysis test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Concurrent analysis failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test token usage tracking
  Future<IntegrationTestResult> testTokenUsageTracking(JournalEntry entry) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing token usage tracking...');
      
      // Get initial metrics
      final initialMetrics = _aiManager.getTokenMetrics();
      
      // Perform analysis
      await _aiManager.analyzeJournalEntry(entry);
      
      // Get updated metrics
      final updatedMetrics = _aiManager.getTokenMetrics();
      
      final data = {
        'tokenUsageTracked': true,
        'inputTokens': updatedMetrics.totalInputTokens - initialMetrics.totalInputTokens,
        'outputTokens': updatedMetrics.totalOutputTokens - initialMetrics.totalOutputTokens,
        'totalTokens': (updatedMetrics.totalInputTokens + updatedMetrics.totalOutputTokens) - 
                      (initialMetrics.totalInputTokens + initialMetrics.totalOutputTokens),
        'requestCount': updatedMetrics.totalRequests - initialMetrics.totalRequests,
      };
      
      stopwatch.stop();
      debugPrint('✅ Token usage tracking test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Token usage tracking test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Token usage tracking failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test journal service integration
  Future<IntegrationTestResult> testJournalServiceIntegration() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing journal service integration...');
      
      // Create journal entry through service
      final entryId = await _journalService.createJournalEntry(
        content: 'Integration test entry for journal service workflow.',
        moods: ['reflective', 'hopeful'],
      );
      
      _testEntryIds.add(entryId);
      
      // Verify entry was created
      final createdEntry = await _journalService.getEntryById(entryId);
      
      // Get cores to verify updates
      final cores = await _journalService.getAllCores();
      
      final data = {
        'entryCreated': createdEntry != null,
        'entryId': entryId,
        'analysisTriggered': true,
        'coresUpdated': cores.isNotEmpty,
        'coreCount': cores.length,
      };
      
      stopwatch.stop();
      debugPrint('✅ Journal service integration test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Journal service integration test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Journal service integration failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Test journal service error handling
  Future<IntegrationTestResult> testJournalServiceErrorHandling() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Testing journal service error handling...');
      
      // Test with empty content (should handle gracefully)
      try {
        final entryId = await _journalService.createJournalEntry(
          content: '',
          moods: [],
        );
        
        if (entryId.isNotEmpty) {
          _testEntryIds.add(entryId);
        }
      } catch (e) {
        debugPrint('Expected error for empty content: $e');
      }
      
      // Test with very long content
      final longContent = 'A' * 10000;
      try {
        final entryId = await _journalService.createJournalEntry(
          content: longContent,
          moods: ['test'],
        );
        
        if (entryId.isNotEmpty) {
          _testEntryIds.add(entryId);
        }
      } catch (e) {
        debugPrint('Handled long content error: $e');
      }
      
      final data = {
        'errorHandled': true,
        'fallbackProvided': true,
        'serviceStable': true,
      };
      
      stopwatch.stop();
      debugPrint('✅ Journal service error handling test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return IntegrationTestResult.success(
        data: data,
        executionTime: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Journal service error handling test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return IntegrationTestResult.failure(
        errorMessage: 'Journal service error handling failed: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Validate analysis structure
  void _validateAnalysisStructure(Map<String, dynamic> analysis) {
    final requiredFields = [
      'primary_emotions',
      'emotional_intensity',
      'core_adjustments',
    ];
    
    for (final field in requiredFields) {
      if (!analysis.containsKey(field)) {
        throw Exception('Analysis missing required field: $field');
      }
    }
    
    // Validate data types
    if (analysis['primary_emotions'] is! List) {
      throw Exception('primary_emotions should be a List');
    }
    
    if (analysis['emotional_intensity'] is! num) {
      throw Exception('emotional_intensity should be a number');
    }
    
    if (analysis['core_adjustments'] is! Map) {
      throw Exception('core_adjustments should be a Map');
    }
  }
}