import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import 'ai_service_interface.dart';
import 'providers/claude_ai_provider.dart';
import 'providers/fallback_provider.dart';
import 'dev_config_service.dart';
import 'emotional_analyzer.dart';
import 'core_evolution_engine.dart';

/// Manages AI service providers and coordinates AI-powered analysis operations.
/// 
/// This service acts as a facade for different AI providers, handling provider
/// selection, configuration, fallback scenarios, and service health monitoring.
/// It provides a unified interface for AI operations while abstracting the
/// complexity of multiple provider implementations.
/// 
/// ## Key Features
/// - Automatic provider selection based on configuration and availability
/// - Built-in API key management with development mode support
/// - Graceful fallback to rule-based analysis when AI services are unavailable
/// - Service health monitoring and connection testing
/// - Unified interface for all AI operations
/// 
/// ## Usage Example
/// ```dart
/// final aiManager = AIServiceManager();
/// await aiManager.initialize();
/// 
/// // Analyze a journal entry
/// final analysis = await aiManager.analyzeJournalEntry(entry);
/// 
/// // Generate monthly insights
/// final insight = await aiManager.generateMonthlyInsight(entries);
/// 
/// // Calculate core updates
/// final coreUpdates = await aiManager.calculateCoreUpdates(entry, cores);
/// 
/// // Toggle AI analysis
/// await aiManager.setAIEnabled(false); // Use fallback analysis
/// ```
/// 
/// ## Provider Architecture
/// - **ClaudeAIProvider**: Full AI analysis using Claude API
/// - **FallbackProvider**: Rule-based analysis when AI is unavailable
/// - Automatic provider switching based on configuration and health
/// 
/// ## Configuration Management
/// - Built-in API keys for production deployment
/// - Development mode support with custom API keys
/// - Persistent user preferences for AI enablement
/// - Automatic fallback when services are unavailable
class AIServiceManager {
  static final AIServiceManager _instance = AIServiceManager._internal();
  factory AIServiceManager() => _instance;
  AIServiceManager._internal();

  AIServiceInterface? _currentService;
  AIServiceConfig? _currentConfig;
  
  // Analysis engines
  final EmotionalAnalyzer _emotionalAnalyzer = EmotionalAnalyzer();
  final CoreEvolutionEngine _coreEvolutionEngine = CoreEvolutionEngine();

  // Built-in Claude API key - securely embedded for production
  static const String _builtInClaudeApiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue: '', // Empty in dev mode - will use fallback analysis
  );
  
  // Available providers - Simplified to enabled/disabled only
  // Note: _providers field removed as we now directly instantiate providers

  // Getters
  AIServiceInterface get currentService => _currentService ?? FallbackProvider(
    AIServiceConfig(provider: AIProvider.disabled, apiKey: ''),
  );
  
  AIProvider get currentProvider => _currentConfig?.provider ?? AIProvider.disabled;
  List<AIProvider> get availableProviders => AIProvider.values;
  bool get isConfigured => _currentService?.isConfigured ?? false;

  // Initialize with saved configuration
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAIEnabled = prefs.getBool('ai_enabled') ?? true; // Default to enabled
      
      if (isAIEnabled) {
        await _enableAIAnalysis();
      } else {
        await _disableAIAnalysis();
      }
    } catch (error) {
      debugPrint('AIServiceManager initialize error: $error');
      // Fallback to disabled if initialization fails
      await _disableAIAnalysis();
    }
  }

  // Enable AI analysis with built-in or development API key
  Future<void> _enableAIAnalysis() async {
    try {
      String apiKey = _builtInClaudeApiKey;
      
      // In development mode, check for dev API key
      if (DevConfigService.isDevMode) {
        final devService = DevConfigService();
        final devApiKey = await devService.getDevClaudeApiKey();
        if (devApiKey != null && devApiKey.isNotEmpty) {
          apiKey = devApiKey;
        }
      }

      final config = AIServiceConfig(
        provider: AIProvider.enabled,
        apiKey: apiKey,
      );

      final service = ClaudeAIProvider(config);
      
      // Only test connection if we have a real API key
      if (apiKey.isNotEmpty && apiKey.startsWith('sk-ant-')) {
        await service.setApiKey(apiKey);
        await service.testConnection();
      }

      _currentService = service;
      _currentConfig = config;
      
      if (kDebugMode) {
        debugPrint('AIServiceManager: Initialized with modern Claude provider (3.7 Sonnet)');
      }
    } catch (error) {
      debugPrint('AIServiceManager _enableAIAnalysis error: $error');
      // If Claude fails, fallback to basic analysis
      await _disableAIAnalysis();
    }
  }

  // Disable AI analysis and use basic mood-based analysis
  Future<void> _disableAIAnalysis() async {
    final config = AIServiceConfig(provider: AIProvider.disabled, apiKey: '');
    _currentService = FallbackProvider(config);
    _currentConfig = config;
  }

  // Toggle AI analysis on/off (user-facing setting)
  Future<void> setAIEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_enabled', enabled);
      
      if (enabled) {
        await _enableAIAnalysis();
      } else {
        await _disableAIAnalysis();
      }
    } catch (e) {
      debugPrint('AIServiceManager setAIEnabled error: $e');
      rethrow;
    }
  }

  // Test current service connection
  Future<void> testCurrentService() async {
    try {
      if (_currentService == null) {
        throw Exception('No service configured');
      }
      
      await _currentService!.testConnection();
    } catch (e) {
      debugPrint('AIServiceManager testCurrentService error: $e');
      rethrow;
    }
  }

  // Delegate methods to current service with comprehensive error handling
  Future<Map<String, dynamic>> analyzeJournalEntry(JournalEntry entry) async {
    try {
      return await currentService.analyzeJournalEntry(entry);
    } on AIServiceException catch (e) {
      debugPrint('AIServiceManager analyzeJournalEntry AIServiceException: $e');
      
      // If the error is not retryable or we're already using fallback, rethrow
      if (!e.isRetryable || currentService is FallbackProvider) {
        rethrow;
      }
      
      // Try fallback provider for retryable errors
      return await _tryFallbackAnalysis(entry);
    } catch (e) {
      debugPrint('AIServiceManager analyzeJournalEntry unexpected error: $e');
      
      // For unexpected errors, try fallback if not already using it
      if (currentService is! FallbackProvider) {
        return await _tryFallbackAnalysis(entry);
      }
      
      rethrow;
    }
  }

  Future<String> generateMonthlyInsight(List<JournalEntry> entries) async {
    try {
      return await currentService.generateMonthlyInsight(entries);
    } on AIServiceException catch (e) {
      debugPrint('AIServiceManager generateMonthlyInsight AIServiceException: $e');
      
      if (!e.isRetryable || currentService is FallbackProvider) {
        rethrow;
      }
      
      return await _tryFallbackInsight(entries);
    } catch (e) {
      debugPrint('AIServiceManager generateMonthlyInsight unexpected error: $e');
      
      if (currentService is! FallbackProvider) {
        return await _tryFallbackInsight(entries);
      }
      
      rethrow;
    }
  }

  Future<Map<String, double>> calculateCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
  ) async {
    try {
      return await currentService.calculateCoreUpdates(entry, currentCores);
    } on AIServiceException catch (e) {
      debugPrint('AIServiceManager calculateCoreUpdates AIServiceException: $e');
      
      if (!e.isRetryable || currentService is FallbackProvider) {
        rethrow;
      }
      
      return await _tryFallbackCoreUpdates(entry, currentCores);
    } catch (e) {
      debugPrint('AIServiceManager calculateCoreUpdates unexpected error: $e');
      
      if (currentService is! FallbackProvider) {
        return await _tryFallbackCoreUpdates(entry, currentCores);
      }
      
      rethrow;
    }
  }

  // Fallback methods
  Future<Map<String, dynamic>> _tryFallbackAnalysis(JournalEntry entry) async {
    try {
      final fallbackService = FallbackProvider(
        AIServiceConfig(provider: AIProvider.disabled, apiKey: ''),
      );
      return await fallbackService.analyzeJournalEntry(entry);
    } catch (e) {
      debugPrint('AIServiceManager fallback analysis failed: $e');
      // Return absolute minimum analysis
      return {
        "primary_emotions": ["neutral"],
        "emotional_intensity": 5.0,
        "growth_indicators": ["self_reflection"],
        "core_adjustments": {
          'Optimism': 0.0,
          'Resilience': 0.0,
          'Self-Awareness': 0.1,
          'Creativity': 0.0,
          'Social Connection': 0.0,
          'Growth Mindset': 0.0,
        },
        "mind_reflection": {
          "title": "Basic Analysis",
          "summary": "Thank you for journaling.",
          "insights": ["Self-reflection supports personal growth"],
        },
        "entry_insight": "Thank you for taking time to reflect.",
      };
    }
  }

  Future<String> _tryFallbackInsight(List<JournalEntry> entries) async {
    try {
      final fallbackService = FallbackProvider(
        AIServiceConfig(provider: AIProvider.disabled, apiKey: ''),
      );
      return await fallbackService.generateMonthlyInsight(entries);
    } catch (e) {
      debugPrint('AIServiceManager fallback insight failed: $e');
      return entries.isEmpty 
          ? "Consider starting a regular journaling practice."
          : "Your journaling practice shows commitment to self-reflection.";
    }
  }

  Future<Map<String, double>> _tryFallbackCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
  ) async {
    try {
      final fallbackService = FallbackProvider(
        AIServiceConfig(provider: AIProvider.disabled, apiKey: ''),
      );
      return await fallbackService.calculateCoreUpdates(entry, currentCores);
    } catch (e) {
      debugPrint('AIServiceManager fallback core updates failed: $e');
      // Return minimal self-awareness boost
      final updates = <String, double>{};
      for (final core in currentCores) {
        if (core.name == 'Self-Awareness') {
          updates[core.id] = (core.percentage + 0.1).clamp(0.0, 100.0);
          break;
        }
      }
      return updates;
    }
  }

  // Get provider info
  String getProviderDescription(AIProvider provider) {
    return provider.description;
  }

  // Enhanced analysis methods using EmotionalAnalyzer and CoreEvolutionEngine

  /// Perform comprehensive emotional analysis with validation and sanitization
  Future<EmotionalAnalysisResult> performEmotionalAnalysis(JournalEntry entry) async {
    try {
      // Get raw AI analysis
      final rawAnalysis = await analyzeJournalEntry(entry);
      
      // Process through emotional analyzer
      final analysisResult = _emotionalAnalyzer.processAnalysis(rawAnalysis, entry);
      
      // Validate and sanitize the result
      if (!_emotionalAnalyzer.validateAnalysisResult(analysisResult)) {
        debugPrint('AIServiceManager: Analysis validation failed, using fallback');
        return _emotionalAnalyzer.processAnalysis({}, entry); // Fallback analysis
      }
      
      return _emotionalAnalyzer.sanitizeAnalysisResult(analysisResult);
    } catch (e) {
      debugPrint('AIServiceManager performEmotionalAnalysis error: $e');
      // Return fallback analysis
      return _emotionalAnalyzer.processAnalysis({}, entry);
    }
  }

  /// Update emotional cores based on analysis with milestone tracking
  Future<List<EmotionalCore>> updateEmotionalCores(
    List<EmotionalCore> currentCores,
    JournalEntry entry,
  ) async {
    try {
      // Perform emotional analysis
      final analysisResult = await performEmotionalAnalysis(entry);
      
      // Update cores using evolution engine
      return _coreEvolutionEngine.updateCoresWithAnalysis(
        currentCores,
        analysisResult,
        entry,
      );
    } catch (e) {
      debugPrint('AIServiceManager updateEmotionalCores error: $e');
      return currentCores; // Return unchanged cores on error
    }
  }

  /// Calculate core progress with milestones and insights
  Future<CoreProgressResult> calculateCoreProgress(
    EmotionalCore core,
    List<JournalEntry> recentEntries,
  ) async {
    try {
      return _coreEvolutionEngine.calculateCoreProgress(core, recentEntries);
    } catch (e) {
      debugPrint('AIServiceManager calculateCoreProgress error: $e');
      return CoreProgressResult(
        core: core,
        milestones: [],
        achievedMilestones: [],
        nextMilestone: null,
        progressVelocity: 0.0,
        estimatedTimeToNextMilestone: null,
      );
    }
  }

  /// Generate personalized core insight based on recent patterns
  Future<String> generateCoreInsight(
    EmotionalCore core,
    List<JournalEntry> recentEntries,
  ) async {
    try {
      // Analyze recent entries
      final recentAnalyses = <EmotionalAnalysisResult>[];
      for (final entry in recentEntries.take(5)) { // Limit to 5 most recent
        final analysis = await performEmotionalAnalysis(entry);
        recentAnalyses.add(analysis);
      }
      
      return _coreEvolutionEngine.generateCoreInsight(core, recentAnalyses);
    } catch (e) {
      debugPrint('AIServiceManager generateCoreInsight error: $e');
      return 'Your ${core.name} continues to develop through self-reflection.';
    }
  }

  /// Identify emotional patterns across multiple entries
  Future<List<EmotionalPattern>> identifyEmotionalPatterns(
    List<JournalEntry> entries,
  ) async {
    try {
      return _emotionalAnalyzer.identifyPatterns(entries);
    } catch (e) {
      debugPrint('AIServiceManager identifyEmotionalPatterns error: $e');
      return [];
    }
  }

  /// Get initial core set for new users
  List<EmotionalCore> getInitialEmotionalCores() {
    return _coreEvolutionEngine.getInitialCores();
  }

  /// Comprehensive analysis combining all features
  Future<ComprehensiveAnalysisResult> performComprehensiveAnalysis(
    JournalEntry entry,
    List<EmotionalCore> currentCores,
    List<JournalEntry> recentEntries,
  ) async {
    try {
      // Perform emotional analysis
      final emotionalAnalysis = await performEmotionalAnalysis(entry);
      
      // Update cores
      final updatedCores = await updateEmotionalCores(currentCores, entry);
      
      // Calculate core updates
      final coreUpdates = _coreEvolutionEngine.calculateCoreUpdates(
        currentCores,
        emotionalAnalysis,
        entry,
      );
      
      // Identify patterns
      final patterns = await identifyEmotionalPatterns([...recentEntries, entry]);
      
      return ComprehensiveAnalysisResult(
        emotionalAnalysis: emotionalAnalysis,
        updatedCores: updatedCores,
        coreUpdates: coreUpdates,
        emotionalPatterns: patterns,
        analysisTimestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('AIServiceManager performComprehensiveAnalysis error: $e');
      // Return minimal result on error
      return ComprehensiveAnalysisResult(
        emotionalAnalysis: _emotionalAnalyzer.processAnalysis({}, entry),
        updatedCores: currentCores,
        coreUpdates: {},
        emotionalPatterns: [],
        analysisTimestamp: DateTime.now(),
      );
    }
  }

  // Clear configuration
  Future<void> clearConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_service_config');
      
      _currentService = FallbackProvider(
        AIServiceConfig(provider: AIProvider.disabled, apiKey: ''),
      );
      _currentConfig = AIServiceConfig(provider: AIProvider.disabled, apiKey: '');
    } catch (e) {
      // Ignore clear errors
    }
  }
}

/// Comprehensive analysis result combining all analysis features
class ComprehensiveAnalysisResult {
  final EmotionalAnalysisResult emotionalAnalysis;
  final List<EmotionalCore> updatedCores;
  final Map<String, double> coreUpdates;
  final List<EmotionalPattern> emotionalPatterns;
  final DateTime analysisTimestamp;

  ComprehensiveAnalysisResult({
    required this.emotionalAnalysis,
    required this.updatedCores,
    required this.coreUpdates,
    required this.emotionalPatterns,
    required this.analysisTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'emotional_analysis': emotionalAnalysis.toJson(),
      'updated_cores': updatedCores.map((core) => core.toJson()).toList(),
      'core_updates': coreUpdates,
      'emotional_patterns': emotionalPatterns.map((pattern) => {
        'category': pattern.category,
        'title': pattern.title,
        'description': pattern.description,
        'type': pattern.type,
      }).toList(),
      'analysis_timestamp': analysisTimestamp.toIso8601String(),
    };
  }
}
