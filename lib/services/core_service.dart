import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/core.dart';
import '../models/core_error.dart';
import '../models/journal_entry.dart';
import '../database/core_dao.dart';
import 'package:uuid/uuid.dart';

/// Consolidated service for managing emotional cores
/// Replaces multiple fragmented services with a single, focused implementation
class CoreService {
  static final CoreService _instance = CoreService._internal();
  factory CoreService() => _instance;
  CoreService._internal();

  final CoreDao _coreDao = CoreDao();
  
  // Core data cache for performance
  List<EmotionalCore> _cores = [];
  Map<String, EmotionalCore> _coreMap = {};
  
  // Error handling
  CoreError? _lastError;
  final StreamController<CoreError> _errorController = StreamController<CoreError>.broadcast();
  
  // Update events
  final StreamController<CoreUpdateEvent> _updateController = StreamController<CoreUpdateEvent>.broadcast();
  
  // Loading state
  bool _isLoading = false;
  bool _isInitialized = false;

  /// Stream of error events
  Stream<CoreError> get errorStream => _errorController.stream;
  
  /// Stream of core update events  
  Stream<CoreUpdateEvent> get updateStream => _updateController.stream;
  
  /// Current loading state
  bool get isLoading => _isLoading;
  
  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;
  
  /// Last error that occurred
  CoreError? get lastError => _lastError;
  
  /// All emotional cores
  List<EmotionalCore> get cores => List.unmodifiable(_cores);
  
  /// Get top cores by level (default: top 3)
  List<EmotionalCore> getTopCores({int limit = 3}) {
    final sortedCores = List<EmotionalCore>.from(_cores);
    sortedCores.sort((a, b) => b.currentLevel.compareTo(a.currentLevel));
    return sortedCores.take(limit).toList();
  }

  /// Initialize the service with default cores
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      
      // Initialize default cores
      await _coreDao.initializeDefaultCores();
      
      // Load cores from database
      await _loadCores();
      
      _isInitialized = true;
      _clearError();
      
    } catch (e) {
      _handleError(CoreError(
        type: CoreErrorType.dataLoadFailure,
        message: 'Failed to initialize cores: ${e.toString()}',
        originalError: e,
      ));
    } finally {
      _isLoading = false;
    }
  }

  /// Load cores from database
  Future<void> _loadCores() async {
    try {
      _cores = await _coreDao.getAllEmotionalCores();
      _coreMap = {for (final core in _cores) core.id: core};
    } catch (e) {
      throw Exception('Failed to load cores: $e');
    }
  }

  /// Get a specific core by ID
  EmotionalCore? getCoreById(String coreId) {
    return _coreMap[coreId];
  }

  /// Update a core with new data
  Future<void> updateCore(EmotionalCore updatedCore) async {
    try {
      _isLoading = true;
      
      // Update in database
      await _coreDao.updateEmotionalCore(updatedCore);
      
      // Update local cache
      final index = _cores.indexWhere((core) => core.id == updatedCore.id);
      if (index != -1) {
        final oldCore = _cores[index];
        _cores[index] = updatedCore;
        _coreMap[updatedCore.id] = updatedCore;
        
        // Emit update event
        _emitUpdateEvent(CoreUpdateEvent(
          coreId: updatedCore.id,
          type: _determineUpdateType(oldCore, updatedCore),
          data: {
            'previousLevel': oldCore.currentLevel,
            'newLevel': updatedCore.currentLevel,
            'previousTrend': oldCore.trend,
            'newTrend': updatedCore.trend,
          },
          timestamp: DateTime.now(),
          updateSource: 'manual',
        ));
      }
      
      _clearError();
      
    } catch (e) {
      _handleError(CoreError(
        type: CoreErrorType.persistenceError,
        message: 'Failed to update core: ${e.toString()}',
        coreId: updatedCore.id,
        originalError: e,
      ));
    } finally {
      _isLoading = false;
    }
  }

  /// Analyze journal entry and update core impacts
  Future<void> analyzeJournalImpact(JournalEntry entry) async {
    try {
      _isLoading = true;
      
      // Simple keyword-based analysis (can be enhanced with AI later)
      final impacts = _calculateCoreImpacts(entry);
      
      // Update cores with calculated impacts
      for (final impact in impacts.entries) {
        final coreId = impact.key;
        final impactData = impact.value;
        
        final core = getCoreById(coreId);
        if (core != null) {
          final updatedCore = _applyImpact(core, impactData, entry);
          await updateCore(updatedCore);
        }
      }
      
      _clearError();
      
    } catch (e) {
      _handleError(CoreError(
        type: CoreErrorType.analysisError,
        message: 'Failed to analyze journal impact: ${e.toString()}',
        originalError: e,
        context: {'entryId': entry.id},
      ));
    } finally {
      _isLoading = false;
    }
  }

  /// Calculate core impacts based on journal content
  Map<String, Map<String, dynamic>> _calculateCoreImpacts(JournalEntry entry) {
    final impacts = <String, Map<String, dynamic>>{};
    final content = entry.content.toLowerCase();
    final moods = entry.moods.map((m) => m.toLowerCase()).toList();
    
    // Optimism core
    if (_containsOptimismKeywords(content, moods)) {
      impacts['optimism'] = {
        'levelChange': 0.02,
        'trend': 'rising',
        'confidence': 0.7,
      };
    }
    
    // Resilience core
    if (_containsResilienceKeywords(content, moods)) {
      impacts['resilience'] = {
        'levelChange': 0.03,
        'trend': 'rising',
        'confidence': 0.8,
      };
    }
    
    // Self-awareness core
    if (_containsSelfAwarenessKeywords(content, moods)) {
      impacts['self-awareness'] = {
        'levelChange': 0.025,
        'trend': 'rising',
        'confidence': 0.75,
      };
    }
    
    // Creativity core
    if (_containsCreativityKeywords(content, moods)) {
      impacts['creativity'] = {
        'levelChange': 0.02,
        'trend': 'rising',
        'confidence': 0.6,
      };
    }
    
    // Social connection core
    if (_containsSocialKeywords(content, moods)) {
      impacts['social-connection'] = {
        'levelChange': 0.025,
        'trend': 'rising',
        'confidence': 0.7,
      };
    }
    
    // Growth mindset core
    if (_containsGrowthKeywords(content, moods)) {
      impacts['growth-mindset'] = {
        'levelChange': 0.03,
        'trend': 'rising',
        'confidence': 0.8,
      };
    }
    
    return impacts;
  }

  /// Apply impact to a core and return updated core
  EmotionalCore _applyImpact(EmotionalCore core, Map<String, dynamic> impactData, JournalEntry entry) {
    final levelChange = impactData['levelChange'] as double;
    final newTrend = impactData['trend'] as String;
    final confidence = impactData['confidence'] as double;
    
    final newLevel = (core.currentLevel + levelChange).clamp(0.0, 1.0);
    
    // Create new insight
    final insight = CoreInsight(
      id: const Uuid().v4(),
      coreId: core.id,
      title: 'Journal Impact Detected',
      description: 'Your recent journal entry shows growth in ${core.name}',
      type: 'growth',
      createdAt: DateTime.now(),
      relevanceScore: confidence,
    );
    
    return EmotionalCore(
      id: core.id,
      name: core.name,
      description: core.description,
      currentLevel: newLevel,
      previousLevel: core.currentLevel,
      lastUpdated: DateTime.now(),
      trend: newLevel > core.currentLevel ? 'rising' : 
             newLevel < core.currentLevel ? 'declining' : 'stable',
      color: core.color,
      iconPath: core.iconPath,
      insight: core.insight,
      relatedCores: core.relatedCores,
      milestones: core.milestones,
      recentInsights: [insight, ...core.recentInsights.take(4)].toList(),
    );
  }

  /// Keyword detection methods
  bool _containsOptimismKeywords(String content, List<String> moods) {
    const keywords = ['hope', 'positive', 'optimistic', 'bright', 'excited', 'grateful', 'blessed'];
    const moodKeywords = ['happy', 'joyful', 'excited', 'grateful', 'hopeful'];
    
    return keywords.any((keyword) => content.contains(keyword)) ||
           moodKeywords.any((mood) => moods.contains(mood));
  }
  
  bool _containsResilienceKeywords(String content, List<String> moods) {
    const keywords = ['overcome', 'persevere', 'strong', 'resilient', 'bounce back', 'challenge', 'endure'];
    const moodKeywords = ['determined', 'strong', 'resilient', 'motivated'];
    
    return keywords.any((keyword) => content.contains(keyword)) ||
           moodKeywords.any((mood) => moods.contains(mood));
  }
  
  bool _containsSelfAwarenessKeywords(String content, List<String> moods) {
    const keywords = ['realize', 'understand', 'aware', 'reflect', 'introspect', 'mindful', 'conscious'];
    const moodKeywords = ['reflective', 'contemplative', 'mindful', 'aware'];
    
    return keywords.any((keyword) => content.contains(keyword)) ||
           moodKeywords.any((mood) => moods.contains(mood));
  }
  
  bool _containsCreativityKeywords(String content, List<String> moods) {
    const keywords = ['create', 'creative', 'imagine', 'artistic', 'inspire', 'innovative', 'original'];
    const moodKeywords = ['creative', 'inspired', 'artistic', 'imaginative'];
    
    return keywords.any((keyword) => content.contains(keyword)) ||
           moodKeywords.any((mood) => moods.contains(mood));
  }
  
  bool _containsSocialKeywords(String content, List<String> moods) {
    const keywords = ['friend', 'family', 'connect', 'share', 'together', 'community', 'relationship'];
    const moodKeywords = ['social', 'connected', 'loved', 'supported'];
    
    return keywords.any((keyword) => content.contains(keyword)) ||
           moodKeywords.any((mood) => moods.contains(mood));
  }
  
  bool _containsGrowthKeywords(String content, List<String> moods) {
    const keywords = ['learn', 'grow', 'improve', 'develop', 'progress', 'better', 'evolve'];
    const moodKeywords = ['motivated', 'ambitious', 'focused', 'determined'];
    
    return keywords.any((keyword) => content.contains(keyword)) ||
           moodKeywords.any((mood) => moods.contains(mood));
  }

  /// Determine the type of update that occurred
  CoreUpdateEventType _determineUpdateType(EmotionalCore oldCore, EmotionalCore newCore) {
    if (newCore.currentLevel != oldCore.currentLevel) {
      return CoreUpdateEventType.levelChanged;
    } else if (newCore.trend != oldCore.trend) {
      return CoreUpdateEventType.trendChanged;
    } else {
      return CoreUpdateEventType.analysisCompleted;
    }
  }

  /// Emit an update event
  void _emitUpdateEvent(CoreUpdateEvent event) {
    if (!_updateController.isClosed) {
      _updateController.add(event);
    }
  }

  /// Handle errors consistently
  void _handleError(CoreError error) {
    _lastError = error;
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
    
    if (kDebugMode) {
      print('CoreService Error: ${error.message}');
    }
  }

  /// Clear the last error
  void _clearError() {
    _lastError = null;
  }

  /// Refresh cores from database
  Future<void> refresh() async {
    try {
      _isLoading = true;
      await _loadCores();
      _clearError();
    } catch (e) {
      _handleError(CoreError(
        type: CoreErrorType.dataLoadFailure,
        message: 'Failed to refresh cores: ${e.toString()}',
        originalError: e,
      ));
    } finally {
      _isLoading = false;
    }
  }

  /// Clear all cores (for testing/reset)
  Future<void> clearAllCores() async {
    try {
      _isLoading = true;
      // Clear cores by reinitializing defaults
      await _coreDao.initializeDefaultCores();
      _cores.clear();
      _coreMap.clear();
      _isInitialized = false;
      _clearError();
    } catch (e) {
      _handleError(CoreError(
        type: CoreErrorType.persistenceError,
        message: 'Failed to clear cores: ${e.toString()}',
        originalError: e,
      ));
    } finally {
      _isLoading = false;
    }
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
    _updateController.close();
  }
}