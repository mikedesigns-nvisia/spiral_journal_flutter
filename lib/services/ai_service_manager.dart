import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import 'providers/enhanced_fallback_provider.dart';
import 'emotional_analyzer.dart';
import 'core_evolution_engine.dart';
import 'offline_queue_service.dart';

/// Manages local analysis operations for journal entries.
/// 
/// This service provides local-only analysis using rule-based algorithms
/// and emotional intelligence processing. No external API calls are made.
/// 
/// ## Key Features
/// - Local emotional analysis using pattern recognition
/// - Core evolution calculations based on journal content
/// - Offline-first architecture with no external dependencies
/// - Built-in emotional intelligence without API requirements
/// 
/// ## Usage Example
/// ```dart
/// final aiManager = AIServiceManager();
/// await aiManager.initialize();
/// 
/// // Analyze a journal entry locally
/// final analysis = await aiManager.analyzeJournalEntry(entry);
/// 
/// // Generate monthly insights from local patterns
/// final insight = await aiManager.generateMonthlyInsight(entries);
/// 
/// // Calculate core updates using local algorithms
/// final coreUpdates = await aiManager.calculateCoreUpdates(entry, cores);
/// ```
class AIServiceManager {
  static final AIServiceManager _instance = AIServiceManager._internal();
  factory AIServiceManager() => _instance;
  AIServiceManager._internal();

  // Local analysis providers
  late final EnhancedFallbackProvider _localAnalyzer;
  
  // Analysis engines
  final EmotionalAnalyzer _emotionalAnalyzer = EmotionalAnalyzer();
  final CoreEvolutionEngine _coreEvolutionEngine = CoreEvolutionEngine();
  
  // Offline queue for analysis operations
  final OfflineQueueService _offlineQueue = OfflineQueueService();
  
  // Network connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];

  bool _isInitialized = false;

  /// Initialize the local analysis service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔧 AIServiceManager: Starting local analysis initialization...');
      
      // Initialize local analyzer with fallback configuration
      _localAnalyzer = EnhancedFallbackProvider(
        LocalAnalysisConfig(),
      );
      
      // Initialize network monitoring for queue management
      await _initializeNetworkMonitoring();
      
      // Initialize offline queue
      await _offlineQueue.initialize();
      
      _isInitialized = true;
      debugPrint('✅ Local analysis service initialized successfully');
      
    } catch (error, stackTrace) {
      debugPrint('❌ AIServiceManager initialization error: $error');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Analyze journal entry using local algorithms
  Future<Map<String, dynamic>> analyzeJournalEntry(JournalEntry entry) async {
    await _ensureInitialized();
    
    try {
      // Use local analysis via the enhanced fallback provider
      final analysis = await _localAnalyzer.analyzeJournalEntry(entry);
      
      return {
        'emotional_analysis': analysis['emotional_analysis'] ?? {'mood': 'neutral', 'confidence': 0.7},
        'insights': analysis['insights'] ?? ['Entry processed with local analysis'],
        'processing_type': 'local',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      debugPrint('❌ Error analyzing journal entry: $error');
      // Return basic analysis on error
      return {
        'emotional_analysis': {'mood': 'neutral', 'confidence': 0.5},
        'insights': ['Entry processed locally'],
        'processing_type': 'basic_local',
        'error': error.toString(),
      };
    }
  }

  /// Generate monthly insights from journal entries
  Future<Map<String, dynamic>> generateMonthlyInsight(List<JournalEntry> entries) async {
    await _ensureInitialized();
    
    try {
      // Generate simple local patterns
      final moodCounts = <String, int>{};
      for (final entry in entries) {
        final moods = entry.moods;
        if (moods.isNotEmpty) {
          final primaryMood = moods.first;
          moodCounts[primaryMood] = (moodCounts[primaryMood] ?? 0) + 1;
        } else {
          moodCounts['neutral'] = (moodCounts['neutral'] ?? 0) + 1;
        }
      }
      
      return {
        'patterns': moodCounts,
        'total_entries': entries.length,
        'processing_type': 'local',
        'period': 'monthly',
        'dominant_mood': moodCounts.isNotEmpty ? 
          moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'neutral',
      };
    } catch (error) {
      debugPrint('❌ Error generating monthly insight: $error');
      return {
        'patterns': {},
        'total_entries': entries.length,
        'processing_type': 'basic_local',
        'error': error.toString(),
      };
    }
  }

  /// Calculate core updates based on journal entry
  Future<List<EmotionalCore>> calculateCoreUpdates(JournalEntry entry, List<EmotionalCore> existingCores) async {
    await _ensureInitialized();
    
    try {
      // Simple local core update logic
      final updatedCores = <EmotionalCore>[];
      for (final core in existingCores) {
        // Simple content-based core resonance calculation
        final contentLower = entry.content.toLowerCase();
        final coreNameLower = core.name.toLowerCase();
        
        double adjustmentFactor = 0.0;
        if (contentLower.contains(coreNameLower)) {
          adjustmentFactor = 0.05; // Small positive adjustment if core name appears in content
        }
        
        final updatedLevel = (core.currentLevel + adjustmentFactor).clamp(0.0, 1.0);
        
        updatedCores.add(EmotionalCore(
          id: core.id,
          name: core.name,
          description: core.description,
          currentLevel: updatedLevel,
          previousLevel: core.currentLevel,
          lastUpdated: DateTime.now(),
          lastTransitionDate: core.lastTransitionDate,
          entriesAtCurrentDepth: core.entriesAtCurrentDepth,
          trend: _calculateTrend(core.currentLevel, updatedLevel),
          color: core.color,
          iconPath: core.iconPath,
          insight: core.insight,
          relatedCores: core.relatedCores,
          milestones: core.milestones,
          recentInsights: core.recentInsights,
          transitionSignals: core.transitionSignals,
          supportingEvidence: core.supportingEvidence,
        ));
      }
      
      return updatedCores;
    } catch (error) {
      debugPrint('❌ Error calculating core updates: $error');
      return existingCores; // Return unchanged cores on error
    }
  }

  /// Calculate trend based on level changes
  String _calculateTrend(double previousLevel, double currentLevel) {
    final difference = currentLevel - previousLevel;
    if (difference > 0.01) return 'rising';
    if (difference < -0.01) return 'declining';
    return 'stable';
  }

  /// Check if service is ready for analysis
  bool get isReady => _isInitialized;

  /// Get current processing type (always local)
  String get processingType => 'local';

  /// Initialize network monitoring for queue management
  Future<void> _initializeNetworkMonitoring() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _connectionStatus = results;
          _processQueuedOperations();
        },
      );
    } catch (error) {
      debugPrint('❌ Network monitoring initialization error: $error');
      // Continue without network monitoring
    }
  }

  /// Process any queued operations when connectivity is restored
  void _processQueuedOperations() {
    if (_connectionStatus.contains(ConnectivityResult.wifi) ||
        _connectionStatus.contains(ConnectivityResult.mobile)) {
      // Process any queued offline operations
      _offlineQueue.processQueue();
    }
  }

  /// Ensure service is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _offlineQueue.dispose();
  }
}

/// Configuration for local analysis operations
class LocalAnalysisConfig {
  final String processingType = 'local';
  final bool enablePatternRecognition = true;
  final bool enableEmotionalAnalysis = true;
  final double confidenceThreshold = 0.6;
}

/// Token usage metrics (placeholder for local processing)
class TokenUsageMetrics {
  int entriesProcessed = 0;
  int patternsIdentified = 0;
  DateTime lastProcessed = DateTime.now();
  
  void recordProcessing() {
    entriesProcessed++;
    lastProcessed = DateTime.now();
  }
}

/// Network status enumeration
enum NetworkStatus { connected, disconnected, limited }

/// Queued analysis request
class QueuedAnalysisRequest {
  final String id;
  final JournalEntry entry;
  final DateTime queuedAt;
  
  QueuedAnalysisRequest({
    required this.id,
    required this.entry,
    required this.queuedAt,
  });
}