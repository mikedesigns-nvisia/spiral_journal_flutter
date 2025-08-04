import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/journal_entry.dart';
import '../models/core.dart' hide EmotionalPattern;
import '../config/environment.dart';
import 'ai_service_interface.dart';
import 'providers/claude_ai_provider.dart';
import 'providers/fallback_provider.dart';
import 'dev_config_service.dart';
import 'emotional_analyzer.dart';
import 'core_evolution_engine.dart';
// import 'haiku_prompt_optimizer.dart';
import 'offline_queue_service.dart';

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
  // final HaikuPromptOptimizer _promptOptimizer = HaikuPromptOptimizer();
  
  // Token optimization
  final TokenOptimizer _tokenOptimizer = TokenOptimizer();
  final BatchRequestManager _batchManager = BatchRequestManager();
  
  // Metrics tracking
  TokenUsageMetrics _tokenMetrics = TokenUsageMetrics();
  
  // Offline queue for failed operations
  final OfflineQueueService _offlineQueue = OfflineQueueService();
  
  // Network connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final StreamController<NetworkStatus> _networkStatusController = StreamController<NetworkStatus>.broadcast();
  
  // Network-aware processing
  final List<QueuedAnalysisRequest> _deferredRequests = [];
  Timer? _wifiPreFetchTimer;
  DateTime? _lastIdleCheck;
  bool _isPreFetching = false;

  // Built-in Claude API key - loaded from .env file at runtime
  static String get _builtInClaudeApiKey => EnvironmentConfig.claudeApiKey;
  
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
      
      // Initialize network monitoring
      await _initializeNetworkMonitoring();
      
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
      
      // In development mode, check for dev API key (fallback to env if secure storage fails)
      if (DevConfigService.isDevMode) {
        try {
          final devService = DevConfigService();
          final devApiKey = await devService.getDevClaudeApiKey();
          if (devApiKey != null && devApiKey.isNotEmpty) {
            apiKey = devApiKey;
          }
        } catch (e) {
          // If secure storage fails, use environment variable directly
          debugPrint('Dev config failed, using environment API key: $e');
          apiKey = _builtInClaudeApiKey;
        }
      }

      // Debug logging for API key
      if (kDebugMode) {
        debugPrint('AIServiceManager: Using API key: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 20)}..." : "empty"}');
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
        if (kDebugMode) {
          debugPrint('AIServiceManager: Claude API connection test successful');
        }
      } else {
        if (kDebugMode) {
          debugPrint('AIServiceManager: No valid API key found, skipping connection test');
        }
      }

      _currentService = service;
      _currentConfig = config;
      
      if (kDebugMode) {
        debugPrint('AIServiceManager: Initialized with Claude 3 Haiku provider');
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

  // Token-optimized delegate methods to current service with comprehensive error handling
  Future<Map<String, dynamic>> analyzeJournalEntry(JournalEntry entry, {bool isCritical = true}) async {
    try {
      // Check network conditions and defer non-critical analysis on cellular
      if (!isCritical && _isOnCellular()) {
        return await _deferAnalysisRequest(entry);
      }
      
      // If offline, queue for later processing
      if (_isOffline()) {
        await _offlineQueue.queueAIAnalysis(entry);
        return _getBasicFallbackAnalysis();
      }
      
      // Optimize the entry for token efficiency
      final optimizedEntry = await _tokenOptimizer.optimizeEntry(entry);
      
      // Track token usage before request
      final estimatedTokens = _tokenOptimizer.estimateTokens(optimizedEntry.optimizedContent);
      _tokenMetrics.recordRequest(estimatedTokens);
      
      // Enhanced batching on WiFi - batch all requests for efficiency
      if (_isOnWiFi() && _batchManager.shouldBatch(optimizedEntry)) {
        return await _batchManager.addToBatch(optimizedEntry, () => 
            _analyzeOptimizedEntry(optimizedEntry));
      }
      
      return await _analyzeOptimizedEntry(optimizedEntry);
    } on AIServiceException catch (e) {
      debugPrint('AIServiceManager analyzeJournalEntry AIServiceException: $e');
      _tokenMetrics.recordError();
      
      // If the error is not retryable or we're already using fallback, queue for retry
      if (!e.isRetryable || currentService is FallbackProvider) {
        // Queue for offline retry if this appears to be a network-related issue
        if (e.message.toLowerCase().contains('network') || 
            e.message.toLowerCase().contains('connection') ||
            e.message.toLowerCase().contains('timeout')) {
          try {
            await _offlineQueue.queueAIAnalysis(entry);
            debugPrint('AIServiceManager: Queued AI analysis for offline retry');
          } catch (queueError) {
            debugPrint('AIServiceManager: Failed to queue AI analysis: $queueError');
          }
        }
        rethrow;
      }
      
      // Try fallback provider for retryable errors
      return await _tryFallbackAnalysis(entry);
    } catch (e) {
      debugPrint('AIServiceManager analyzeJournalEntry unexpected error: $e');
      _tokenMetrics.recordError();
      
      // For unexpected errors, try fallback if not already using it
      if (currentService is! FallbackProvider) {
        try {
          return await _tryFallbackAnalysis(entry);
        } catch (fallbackError) {
          // If fallback also fails, queue for offline retry
          try {
            await _offlineQueue.queueAIAnalysis(entry);
            debugPrint('AIServiceManager: Queued AI analysis for offline retry after fallback failure');
            // Return a basic fallback result
            return _getBasicFallbackAnalysis();
          } catch (queueError) {
            debugPrint('AIServiceManager: Failed to queue AI analysis: $queueError');
          }
          rethrow;
        }
      }
      
      // Queue for offline retry if all else fails
      try {
        await _offlineQueue.queueAIAnalysis(entry);
        debugPrint('AIServiceManager: Queued AI analysis for offline retry');
        return _getBasicFallbackAnalysis();
      } catch (queueError) {
        debugPrint('AIServiceManager: Failed to queue AI analysis: $queueError');
        rethrow;
      }
    }
  }
  
  /// Internal method to analyze an optimized entry
  Future<Map<String, dynamic>> _analyzeOptimizedEntry(OptimizedJournalEntry optimizedEntry) async {
    final result = await currentService.analyzeJournalEntry(optimizedEntry.toJournalEntry());
    
    // Track successful response tokens
    if (result.containsKey('_token_usage')) {
      final usage = result['_token_usage'] as Map<String, dynamic>;
      _tokenMetrics.recordResponse(
        usage['input_tokens'] ?? 0,
        usage['output_tokens'] ?? 0,
      );
    }
    
    return result;
  }

  Future<String> generateMonthlyInsight(List<JournalEntry> entries, {bool isCritical = false}) async {
    try {
      // Defer non-critical insight generation on cellular
      if (!isCritical && _isOnCellular()) {
        // Queue for WiFi processing
        _deferredRequests.add(QueuedAnalysisRequest(
          entry: entries.first, // Use first entry as representative
          analysisFunction: () async {
            final result = await generateMonthlyInsight(entries, isCritical: true);
            return {'insight': result};
          },
          completer: Completer<Map<String, dynamic>>(),
          timestamp: DateTime.now(),
          type: AnalysisType.monthlyInsight,
        ));
        
        return 'Monthly insight will be generated when on WiFi for better performance.';
      }
      
      // If offline, return basic insight
      if (_isOffline()) {
        return _tryFallbackInsight(entries);
      }
      
      // Optimize entries for token efficiency
      final compressedData = _tokenOptimizer.compressMonthlyData(entries);
      final estimatedTokens = _tokenOptimizer.estimateTokens(compressedData);
      _tokenMetrics.recordRequest(estimatedTokens);
      
      // Create optimized insight request
      final result = await _generateOptimizedInsight(compressedData);
      
      return result;
    } on AIServiceException catch (e) {
      debugPrint('AIServiceManager generateMonthlyInsight AIServiceException: $e');
      _tokenMetrics.recordError();
      
      if (!e.isRetryable || currentService is FallbackProvider) {
        rethrow;
      }
      
      return await _tryFallbackInsight(entries);
    } catch (e) {
      debugPrint('AIServiceManager generateMonthlyInsight unexpected error: $e');
      _tokenMetrics.recordError();
      
      if (currentService is! FallbackProvider) {
        return await _tryFallbackInsight(entries);
      }
      
      rethrow;
    }
  }
  
  /// Generate insight from compressed monthly data
  Future<String> _generateOptimizedInsight(String compressedData) async {
    // This would need to be implemented in the provider
    return await currentService.generateMonthlyInsight([]);
  }

  Future<Map<String, double>> calculateCoreUpdates(
    JournalEntry entry,
    List<EmotionalCore> currentCores, {
    bool isCritical = true,
  }) async {
    try {
      // Defer non-critical core updates on cellular
      if (!isCritical && _isOnCellular()) {
        // Queue for WiFi processing and return minimal update
        _deferredRequests.add(QueuedAnalysisRequest(
          entry: entry,
          analysisFunction: () async {
            final result = await calculateCoreUpdates(entry, currentCores, isCritical: true);
            return {'core_updates': result};
          },
          completer: Completer<Map<String, dynamic>>(),
          timestamp: DateTime.now(),
          type: AnalysisType.coreUpdate,
        ));
        
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
      
      // If offline, use fallback
      if (_isOffline()) {
        return await _tryFallbackCoreUpdates(entry, currentCores);
      }
      
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
  Future<EmotionalAnalysisResult> performEmotionalAnalysis(JournalEntry entry, {bool isCritical = true}) async {
    try {
      // Get raw AI analysis with network awareness
      final rawAnalysis = await analyzeJournalEntry(entry, isCritical: isCritical);
      
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
    JournalEntry entry, {
    bool isCritical = true,
  }) async {
    try {
      // Perform emotional analysis with network awareness
      final analysisResult = await performEmotionalAnalysis(entry, isCritical: isCritical);
      
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
  Future<List<JournalEmotionalPattern>> identifyEmotionalPatterns(
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
    List<JournalEntry> recentEntries, {
    bool isCritical = true,
  }) async {
    try {
      // Perform emotional analysis with network awareness
      final emotionalAnalysis = await performEmotionalAnalysis(entry, isCritical: isCritical);
      
      // Update cores with network awareness
      final updatedCores = await updateEmotionalCores(currentCores, entry, isCritical: isCritical);
      
      // Calculate core updates with network awareness
      final coreUpdates = await calculateCoreUpdates(entry, currentCores, isCritical: isCritical);
      
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

  /// Get token optimization metrics
  TokenUsageMetrics getTokenMetrics() => _tokenMetrics;
  
  /// Reset token metrics
  void resetTokenMetrics() {
    _tokenMetrics = TokenUsageMetrics();
  }
  
  /// Get batch processing status
  BatchStatus getBatchStatus() => _batchManager.getStatus();
  
  /// Force process pending batches
  Future<void> processPendingBatches() async {
    await _batchManager.processPendingBatches();
  }
  
  /// Defer analysis request for WiFi processing
  Future<Map<String, dynamic>> _deferAnalysisRequest(JournalEntry entry) async {
    final completer = Completer<Map<String, dynamic>>();
    
    _deferredRequests.add(QueuedAnalysisRequest(
      entry: entry,
      analysisFunction: () async {
        return await analyzeJournalEntry(entry, isCritical: true);
      },
      completer: completer,
      timestamp: DateTime.now(),
      type: AnalysisType.journalEntry,
    ));
    
    debugPrint('AIServiceManager: Deferred analysis request for entry ${entry.id}');
    
    // Return basic analysis with note about deferral
    final basicAnalysis = _getBasicFallbackAnalysis();
    basicAnalysis['mind_reflection']['summary'] = 
        'Basic analysis complete. Detailed AI analysis will be performed when on WiFi for better performance.';
    
    return basicAnalysis;
  }
  
  /// Get network statistics
  NetworkStatistics getNetworkStatistics() {
    return NetworkStatistics(
      currentStatus: _getNetworkStatus(),
      deferredRequestsCount: _deferredRequests.length,
      isPreFetching: _isPreFetching,
      lastIdleCheck: _lastIdleCheck,
    );
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
      
      // Clean up network monitoring
      await _disposeNetworkMonitoring();
    } catch (e) {
      // Ignore clear errors
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _disposeNetworkMonitoring();
  }

  /// Get a basic fallback analysis when all AI services fail
  Map<String, dynamic> _getBasicFallbackAnalysis() {
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
        "summary": "Thank you for journaling. Your entry has been saved and will be analyzed when connectivity is restored.",
        "insights": ["Self-reflection supports personal growth"],
      },
      "entry_insight": "Thank you for taking time to reflect. Your entry will be fully analyzed when online.",
    };
  }
  
  // =============================================================================
  // NETWORK-AWARE PROCESSING METHODS
  // =============================================================================
  
  /// Initialize network connectivity monitoring
  Future<void> _initializeNetworkMonitoring() async {
    try {
      // Get initial connectivity status
      _connectionStatus = await _connectivity.checkConnectivity();
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint('AIServiceManager connectivity stream error: $error');
        },
      );
      
      // Update batch manager with network status
      _batchManager.setWiFiMode(_isOnWiFi());
      
      // Start WiFi idle monitoring if on WiFi
      if (_isOnWiFi()) {
        _startWiFiIdleMonitoring();
      }
      
      debugPrint('AIServiceManager: Network monitoring initialized. Status: $_connectionStatus');
    } catch (e) {
      debugPrint('AIServiceManager _initializeNetworkMonitoring error: $e');
    }
  }
  
  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final previousStatus = _connectionStatus;
    _connectionStatus = results;
    
    final networkStatus = _getNetworkStatus();
    _networkStatusController.add(networkStatus);
    
    // Update batch manager
    _batchManager.setWiFiMode(_isOnWiFi());
    
    debugPrint('AIServiceManager: Network status changed from $previousStatus to $results');
    
    // Handle network state transitions
    if (_wasOfflineNowOnline(previousStatus, results)) {
      _handleBackOnline();
    } else if (_wasOnWiFiNowCellular(previousStatus, results)) {
      _handleWiFiToCellular();
    } else if (_wasCellularNowWiFi(previousStatus, results)) {
      _handleCellularToWiFi();
    }
  }
  
  /// Check if transitioned from offline to online
  bool _wasOfflineNowOnline(List<ConnectivityResult> previous, List<ConnectivityResult> current) {
    final wasOffline = previous.every((result) => result == ConnectivityResult.none);
    final isOnline = current.any((result) => result != ConnectivityResult.none);
    return wasOffline && isOnline;
  }
  
  /// Check if transitioned from WiFi to cellular
  bool _wasOnWiFiNowCellular(List<ConnectivityResult> previous, List<ConnectivityResult> current) {
    final wasWiFi = previous.contains(ConnectivityResult.wifi);
    final isCellular = current.contains(ConnectivityResult.mobile) && !current.contains(ConnectivityResult.wifi);
    return wasWiFi && isCellular;
  }
  
  /// Check if transitioned from cellular to WiFi
  bool _wasCellularNowWiFi(List<ConnectivityResult> previous, List<ConnectivityResult> current) {
    final wasCellular = previous.contains(ConnectivityResult.mobile) && !previous.contains(ConnectivityResult.wifi);
    final isWiFi = current.contains(ConnectivityResult.wifi);
    return wasCellular && isWiFi;
  }
  
  /// Handle coming back online
  void _handleBackOnline() {
    debugPrint('AIServiceManager: Back online - processing queued requests');
    
    // Process offline queue
    // Note: processQueuedRequests would need to be implemented in OfflineQueueService
    // _offlineQueue.processQueuedRequests();
    
    // Process deferred requests if on WiFi
    if (_isOnWiFi()) {
      _processDeferredRequests();
      _startWiFiIdleMonitoring();
    }
  }
  
  /// Handle WiFi to cellular transition
  void _handleWiFiToCellular() {
    debugPrint('AIServiceManager: Switched to cellular - deferring non-critical analysis');
    _stopWiFiIdleMonitoring();
  }
  
  /// Handle cellular to WiFi transition
  void _handleCellularToWiFi() {
    debugPrint('AIServiceManager: Switched to WiFi - processing deferred requests');
    _processDeferredRequests();
    _startWiFiIdleMonitoring();
  }
  
  /// Check if currently on WiFi
  bool _isOnWiFi() {
    return _connectionStatus.contains(ConnectivityResult.wifi);
  }
  
  /// Check if currently on cellular
  bool _isOnCellular() {
    return _connectionStatus.contains(ConnectivityResult.mobile) && !_connectionStatus.contains(ConnectivityResult.wifi);
  }
  
  /// Check if currently offline
  bool _isOffline() {
    return _connectionStatus.every((result) => result == ConnectivityResult.none);
  }
  
  /// Get current network status
  NetworkStatus _getNetworkStatus() {
    if (_isOffline()) {
      return NetworkStatus.offline;
    } else if (_isOnWiFi()) {
      return NetworkStatus.wifi;
    } else if (_isOnCellular()) {
      return NetworkStatus.cellular;
    } else {
      return NetworkStatus.unknown;
    }
  }
  
  /// Get network status stream
  Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;
  
  /// Get current network status
  NetworkStatus get currentNetworkStatus => _getNetworkStatus();
  
  /// Process deferred requests when on WiFi
  Future<void> _processDeferredRequests() async {
    if (_deferredRequests.isEmpty) return;
    
    debugPrint('AIServiceManager: Processing ${_deferredRequests.length} deferred requests');
    
    final requestsToProcess = List<QueuedAnalysisRequest>.from(_deferredRequests);
    _deferredRequests.clear();
    
    // Process in batches to avoid overwhelming the API
    const batchSize = 3;
    for (int i = 0; i < requestsToProcess.length; i += batchSize) {
      final batch = requestsToProcess.skip(i).take(batchSize);
      
      // Process batch in parallel
      await Future.wait(batch.map((request) async {
        try {
          final result = await request.analysisFunction();
          request.completer.complete(result);
        } catch (e) {
          request.completer.completeError(e);
        }
      }));
      
      // Brief pause between batches
      if (i + batchSize < requestsToProcess.length) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
  }
  
  /// Start WiFi idle monitoring for pre-fetching
  void _startWiFiIdleMonitoring() {
    if (_wifiPreFetchTimer != null) return;
    
    _wifiPreFetchTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      _checkForIdleTimePrefetch();
    });
    
    debugPrint('AIServiceManager: Started WiFi idle monitoring');
  }
  
  /// Stop WiFi idle monitoring
  void _stopWiFiIdleMonitoring() {
    _wifiPreFetchTimer?.cancel();
    _wifiPreFetchTimer = null;
    debugPrint('AIServiceManager: Stopped WiFi idle monitoring');
  }
  
  /// Check for idle time and pre-fetch insights
  void _checkForIdleTimePrefetch() {
    if (!_isOnWiFi() || _isPreFetching) return;
    
    final now = DateTime.now();
    _lastIdleCheck ??= now;
    
    // If no recent analysis requests, consider it idle time
    final timeSinceLastCheck = now.difference(_lastIdleCheck!);
    if (timeSinceLastCheck.inMinutes >= 5) {
      _performIdleTimePrefetch();
    }
    
    _lastIdleCheck = now;
  }
  
  /// Perform pre-fetching during idle time on WiFi
  Future<void> _performIdleTimePrefetch() async {
    if (_isPreFetching || !_isOnWiFi()) return;
    
    _isPreFetching = true;
    debugPrint('AIServiceManager: Starting idle time pre-fetch');
    
    try {
      // Pre-fetch insights for recent entries that haven't been fully analyzed
      // This is a placeholder - would need access to recent entries from database
      // Could be implemented by calling a method on the journal service
      
      // For now, just warm up the connection
      if (_currentService != null && _currentService is! FallbackProvider) {
        try {
          await _currentService!.testConnection();
          debugPrint('AIServiceManager: Connection warmed up during idle time');
        } catch (e) {
          debugPrint('AIServiceManager: Idle connection test failed: $e');
        }
      }
    } catch (e) {
      debugPrint('AIServiceManager: Idle time pre-fetch error: $e');
    } finally {
      _isPreFetching = false;
    }
  }
  
  /// Dispose network monitoring resources
  Future<void> _disposeNetworkMonitoring() async {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    
    _stopWiFiIdleMonitoring();
    
    await _networkStatusController.close();
    
    // Complete any pending deferred requests with error
    for (final request in _deferredRequests) {
      if (!request.completer.isCompleted) {
        request.completer.completeError('Service disposed');
      }
    }
    _deferredRequests.clear();
  }
}

/// Token optimization utility class
class TokenOptimizer {
  // Token counting heuristic: words * 1.3 + overhead
  static const double _tokenMultiplier = 1.3;
  static const int _systemPromptTokens = 800; // Estimated system prompt size
  // static const int _responseTokens = 500; // Max tokens for Haiku responses
  
  /// Estimate token count using simple heuristic
  int estimateTokens(String text) {
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (wordCount * _tokenMultiplier).ceil() + _systemPromptTokens;
  }
  
  /// Optimize journal entry for token efficiency
  Future<OptimizedJournalEntry> optimizeEntry(JournalEntry entry) async {
    // 1. Compress whitespace and remove formatting
    String optimizedContent = _compressWhitespace(entry.content);
    
    // 2. Remove redundant words while preserving meaning
    optimizedContent = _removeRedundantWords(optimizedContent);
    
    // 3. Smart truncation if still too long
    final maxContentTokens = 1500; // Leave room for system prompt and response
    final estimatedTokens = estimateTokens(optimizedContent);
    
    if (estimatedTokens > maxContentTokens) {
      optimizedContent = _smartTruncate(optimizedContent, maxContentTokens);
    }
    
    // 4. Compress mood selection
    final optimizedMoods = _compressMoods(entry.moods);
    
    return OptimizedJournalEntry(
      originalEntry: entry,
      optimizedContent: optimizedContent,
      optimizedMoods: optimizedMoods,
      tokenReduction: estimateTokens(entry.content) - estimateTokens(optimizedContent),
    );
  }
  
  /// Compress whitespace and remove formatting
  String _compressWhitespace(String text) {
    return text
        // Replace multiple whitespace with single space
        .replaceAll(RegExp(r'\s+'), ' ')
        // Remove leading/trailing whitespace
        .trim()
        // Remove common formatting characters that don't add meaning
        .replaceAll(RegExp(r'[\*_~`]{1,2}'), '')
        // Compress multiple punctuation
        .replaceAll(RegExp(r'[!]{2,}'), '!')
        .replaceAll(RegExp(r'[?]{2,}'), '?')
        .replaceAll(RegExp(r'[.]{3,}'), '...');
  }
  
  /// Remove redundant words while preserving meaning
  String _removeRedundantWords(String text) {
    // Common filler words that can be removed in analysis context
    final fillerWords = {
      'really', 'very', 'quite', 'just', 'actually', 'basically', 'literally',
      'totally', 'completely', 'absolutely', 'definitely', 'certainly',
      'obviously', 'clearly', 'honestly', 'frankly', 'truly', 'indeed',
      'perhaps', 'maybe', 'possibly', 'probably', 'presumably',
      'like', 'you know', 'i mean', 'sort of', 'kind of'
    };
    
    final words = text.split(' ');
    final filteredWords = words.where((word) {
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '');
      return !fillerWords.contains(cleanWord);
    }).toList();
    
    return filteredWords.join(' ');
  }
  
  /// Smart truncation that preserves meaning
  String _smartTruncate(String text, int maxTokens) {
    final targetLength = (maxTokens / _tokenMultiplier).floor();
    
    if (text.split(' ').length <= targetLength) {
      return text;
    }
    
    // Try to find natural break points
    final sentences = text.split(RegExp(r'[.!?]+\s*'));
    final importantSentences = <String>[];
    int currentLength = 0;
    
    // Prioritize sentences with emotional content
    final emotionalKeywords = {
      'feel', 'felt', 'emotion', 'happy', 'sad', 'angry', 'excited',
      'worried', 'grateful', 'proud', 'disappointed', 'surprised',
      'love', 'hate', 'fear', 'hope', 'dream', 'wish'
    };
    
    // First pass: include sentences with emotional keywords
    for (final sentence in sentences) {
      final words = sentence.split(' ');
      if (currentLength + words.length > targetLength) break;
      
      final hasEmotionalContent = words.any((word) => 
          emotionalKeywords.contains(word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')));
      
      if (hasEmotionalContent) {
        importantSentences.add(sentence);
        currentLength += words.length;
      }
    }
    
    // Second pass: fill remaining space with other sentences
    for (final sentence in sentences) {
      if (importantSentences.contains(sentence)) continue;
      
      final words = sentence.split(' ');
      if (currentLength + words.length > targetLength) break;
      
      importantSentences.add(sentence);
      currentLength += words.length;
    }
    
    return importantSentences.join('. ').trim() + 
           (importantSentences.length < sentences.length ? '...' : '');
  }
  
  /// Compress mood selection to most relevant ones
  List<String> _compressMoods(List<String> moods) {
    // Limit to top 3 most specific moods to reduce token usage
    final priorityMoods = {
      'grateful': 5, 'excited': 5, 'proud': 5, 'confident': 5,
      'anxious': 4, 'overwhelmed': 4, 'frustrated': 4, 'disappointed': 4,
      'happy': 3, 'sad': 3, 'angry': 3, 'peaceful': 3,
      'content': 2, 'tired': 2, 'energetic': 2,
      'neutral': 1, 'okay': 1
    };
    
    final sortedMoods = moods.toList()
      ..sort((a, b) => (priorityMoods[b] ?? 0).compareTo(priorityMoods[a] ?? 0));
    
    return sortedMoods.take(3).toList();
  }
  
  /// Compress monthly data for insights
  String compressMonthlyData(List<JournalEntry> entries) {
    if (entries.isEmpty) return 'No entries this month.';
    
    // Statistical summary approach
    final totalWords = entries.fold(0, (sum, entry) => sum + entry.content.split(' ').length);
    final avgWords = totalWords / entries.length;
    
    // Mood frequency analysis
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      for (final mood in entry.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }
    
    final topMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Key content themes using simple keyword extraction
    final contentThemes = _extractContentThemes(entries);
    
    // Compressed representation
    return '''${entries.length} entries, avg ${avgWords.round()} words/entry.
Top moods: ${topMoods.take(5).map((e) => '${e.key}(${e.value})').join(', ')}
Themes: ${contentThemes.take(5).join(', ')}
Sample: "${entries.first.content.length > 100 ? '${entries.first.content.substring(0, 100)}...' : entries.first.content}"''';
  }
  
  /// Extract key content themes using simple keyword analysis
  List<String> _extractContentThemes(List<JournalEntry> entries) {
    final wordCounts = <String, int>{};
    
    for (final entry in entries) {
      final words = entry.content.toLowerCase()
          .replaceAll(RegExp(r'[^a-z\s]'), '')
          .split(' ')
          .where((w) => w.length > 4) // Only meaningful words
          .toList();
      
      for (final word in words) {
        wordCounts[word] = (wordCounts[word] ?? 0) + 1;
      }
    }
    
    // Return top themes that appear in multiple entries
    final sortedEntries = wordCounts.entries
        .where((e) => e.value >= 2) // Appears at least twice
        .toList();
    
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .map((e) => e.key)
        .take(5)
        .toList();
  }
}

/// Batch request manager for similar requests
class BatchRequestManager {
  final List<BatchedRequest> _pendingRequests = [];
  Duration _batchWindow = Duration(seconds: 5);
  Timer? _batchTimer;
  bool _isWiFiMode = false;
  
  /// Check if request should be batched
  bool shouldBatch(OptimizedJournalEntry entry) {
    if (_isWiFiMode) {
      // More aggressive batching on WiFi
      return entry.optimizedContent.length < 800 && // Larger entries on WiFi
             _pendingRequests.length < 10; // Larger batch sizes on WiFi
    } else {
      // Conservative batching on cellular
      return entry.optimizedContent.length < 300 && // Smaller entries on cellular
             _pendingRequests.length < 3; // Smaller batch sizes on cellular
    }
  }
  
  /// Update WiFi mode for enhanced batching
  void setWiFiMode(bool isWiFi) {
    _isWiFiMode = isWiFi;
    if (isWiFi) {
      _batchWindow = Duration(seconds: 8); // Longer window on WiFi for better batching
    } else {
      _batchWindow = Duration(seconds: 3); // Shorter window on cellular for responsiveness
    }
  }
  
  /// Add request to batch
  Future<Map<String, dynamic>> addToBatch(
    OptimizedJournalEntry entry,
    Future<Map<String, dynamic>> Function() analyzer,
  ) async {
    final completer = Completer<Map<String, dynamic>>();
    
    _pendingRequests.add(BatchedRequest(
      entry: entry,
      analyzer: analyzer,
      completer: completer,
      timestamp: DateTime.now(),
    ));
    
    // Schedule batch processing if not already scheduled
    _batchTimer ??= Timer(_batchWindow, _processBatch);
    
    return completer.future;
  }
  
  /// Process pending batch
  Future<void> _processBatch() async {
    if (_pendingRequests.isEmpty) return;
    
    final requests = List<BatchedRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    _batchTimer = null;
    
    try {
      // Create combined prompt for batch processing
      // final combinedContent = requests.map((r) => 
      //     'Entry ${requests.indexOf(r) + 1}: "${r.entry.optimizedContent}" [${r.entry.optimizedMoods.join(", ")}]'
      // ).join('\n\n');
      
      // This would need to be implemented in the provider for actual batch processing
      // For now, process individually but with delay between requests
      for (int i = 0; i < requests.length; i++) {
        final request = requests[i];
        try {
          final result = await request.analyzer();
          request.completer.complete(result);
        } catch (e) {
          request.completer.completeError(e);
        }
        
        // Adaptive delay based on network type
        if (i < requests.length - 1) {
          final delay = _isWiFiMode ? Duration(milliseconds: 100) : Duration(milliseconds: 300);
          await Future.delayed(delay);
        }
      }
    } catch (e) {
      // Complete all with error
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }
      }
    }
  }
  
  /// Get batch processing status
  BatchStatus getStatus() {
    return BatchStatus(
      pendingRequests: _pendingRequests.length,
      isProcessing: _batchTimer != null,
      nextProcessTime: _batchTimer != null 
          ? DateTime.now().add(_batchWindow)
          : null,
    );
  }
  
  /// Force process pending batches
  Future<void> processPendingBatches() async {
    _batchTimer?.cancel();
    _batchTimer = null;
    await _processBatch();
  }
}

/// Token usage metrics tracking
class TokenUsageMetrics {
  int totalRequests = 0;
  int totalInputTokens = 0;
  int totalOutputTokens = 0;
  int totalErrors = 0;
  int totalTokensSaved = 0;
  List<TokenUsageSample> recentSamples = [];
  DateTime startTime = DateTime.now();
  
  void recordRequest(int estimatedTokens) {
    totalRequests++;
    totalInputTokens += estimatedTokens;
    
    _addSample(TokenUsageSample(
      timestamp: DateTime.now(),
      inputTokens: estimatedTokens,
      outputTokens: 0,
      isError: false,
    ));
  }
  
  void recordResponse(int actualInputTokens, int outputTokens) {
    totalOutputTokens += outputTokens;
    
    // Update the last sample with actual values
    if (recentSamples.isNotEmpty) {
      final lastSample = recentSamples.last;
      final tokensSaved = lastSample.inputTokens - actualInputTokens;
      totalTokensSaved += tokensSaved.clamp(0, double.infinity).toInt();
      
      recentSamples[recentSamples.length - 1] = TokenUsageSample(
        timestamp: lastSample.timestamp,
        inputTokens: actualInputTokens,
        outputTokens: outputTokens,
        isError: false,
      );
    }
  }
  
  void recordError() {
    totalErrors++;
    
    if (recentSamples.isNotEmpty) {
      final lastSample = recentSamples.last;
      recentSamples[recentSamples.length - 1] = TokenUsageSample(
        timestamp: lastSample.timestamp,
        inputTokens: lastSample.inputTokens,
        outputTokens: 0,
        isError: true,
      );
    }
  }
  
  void _addSample(TokenUsageSample sample) {
    recentSamples.add(sample);
    
    // Keep only recent samples (last 100)
    if (recentSamples.length > 100) {
      recentSamples.removeAt(0);
    }
  }
  
  /// Get optimization statistics
  OptimizationStats getStats() {
    final totalTokens = totalInputTokens + totalOutputTokens;
    final successRate = totalRequests > 0 ? (totalRequests - totalErrors) / totalRequests : 0.0;
    final avgTokensPerRequest = totalRequests > 0 ? totalTokens / totalRequests : 0.0;
    final tokenSavingsRate = totalInputTokens > 0 ? totalTokensSaved / totalInputTokens : 0.0;
    
    return OptimizationStats(
      totalRequests: totalRequests,
      totalTokens: totalTokens,
      totalTokensSaved: totalTokensSaved,
      successRate: successRate,
      averageTokensPerRequest: avgTokensPerRequest,
      tokenSavingsRate: tokenSavingsRate,
      uptime: DateTime.now().difference(startTime),
    );
  }
}

/// Optimized journal entry for token efficiency
class OptimizedJournalEntry {
  final JournalEntry originalEntry;
  final String optimizedContent;
  final List<String> optimizedMoods;
  final int tokenReduction;
  
  OptimizedJournalEntry({
    required this.originalEntry,
    required this.optimizedContent,
    required this.optimizedMoods,
    required this.tokenReduction,
  });
  
  JournalEntry toJournalEntry() {
    return JournalEntry(
      id: originalEntry.id,
      content: optimizedContent,
      date: originalEntry.date,
      moods: optimizedMoods,
      createdAt: originalEntry.createdAt,
      updatedAt: originalEntry.updatedAt,
      userId: originalEntry.userId,
      dayOfWeek: originalEntry.dayOfWeek,
    );
  }
}

/// Batched request container
class BatchedRequest {
  final OptimizedJournalEntry entry;
  final Future<Map<String, dynamic>> Function() analyzer;
  final Completer<Map<String, dynamic>> completer;
  final DateTime timestamp;
  
  BatchedRequest({
    required this.entry,
    required this.analyzer,
    required this.completer,
    required this.timestamp,
  });
}

/// Batch processing status
class BatchStatus {
  final int pendingRequests;
  final bool isProcessing;
  final DateTime? nextProcessTime;
  
  BatchStatus({
    required this.pendingRequests,
    required this.isProcessing,
    this.nextProcessTime,
  });
  
  @override
  String toString() {
    return 'BatchStatus(pending: $pendingRequests, processing: $isProcessing, next: $nextProcessTime)';
  }
}

/// Token usage sample for metrics
class TokenUsageSample {
  final DateTime timestamp;
  final int inputTokens;
  final int outputTokens;
  final bool isError;
  
  TokenUsageSample({
    required this.timestamp,
    required this.inputTokens,
    required this.outputTokens,
    required this.isError,
  });
}

/// Optimization statistics
class OptimizationStats {
  final int totalRequests;
  final int totalTokens;
  final int totalTokensSaved;
  final double successRate;
  final double averageTokensPerRequest;
  final double tokenSavingsRate;
  final Duration uptime;
  
  OptimizationStats({
    required this.totalRequests,
    required this.totalTokens,
    required this.totalTokensSaved,
    required this.successRate,
    required this.averageTokensPerRequest,
    required this.tokenSavingsRate,
    required this.uptime,
  });
  
  @override
  String toString() {
    return 'OptimizationStats(requests: $totalRequests, tokens: $totalTokens, saved: $totalTokensSaved (${(tokenSavingsRate * 100).toStringAsFixed(1)}%), success: ${(successRate * 100).toStringAsFixed(1)}%, avg: ${averageTokensPerRequest.toStringAsFixed(1)} tokens/req)';
  }
}

/// Network status enumeration
enum NetworkStatus {
  offline,
  cellular,
  wifi,
  unknown,
}

/// Analysis type enumeration
enum AnalysisType {
  journalEntry,
  monthlyInsight,
  coreUpdate,
  comprehensive,
}

/// Queued analysis request for deferred processing
class QueuedAnalysisRequest {
  final JournalEntry entry;
  final Future<Map<String, dynamic>> Function() analysisFunction;
  final Completer<Map<String, dynamic>> completer;
  final DateTime timestamp;
  final AnalysisType type;
  
  QueuedAnalysisRequest({
    required this.entry,
    required this.analysisFunction,
    required this.completer,
    required this.timestamp,
    required this.type,
  });
}

/// Network statistics for monitoring
class NetworkStatistics {
  final NetworkStatus currentStatus;
  final int deferredRequestsCount;
  final bool isPreFetching;
  final DateTime? lastIdleCheck;
  
  NetworkStatistics({
    required this.currentStatus,
    required this.deferredRequestsCount,
    required this.isPreFetching,
    this.lastIdleCheck,
  });
  
  @override
  String toString() {
    return 'NetworkStatistics(status: $currentStatus, deferred: $deferredRequestsCount, prefetching: $isPreFetching)';
  }
}

/// Comprehensive analysis result combining all analysis features
class ComprehensiveAnalysisResult {
  final EmotionalAnalysisResult emotionalAnalysis;
  final List<EmotionalCore> updatedCores;
  final Map<String, double> coreUpdates;
  final List<JournalEmotionalPattern> emotionalPatterns;
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
