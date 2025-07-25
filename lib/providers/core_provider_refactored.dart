import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/core.dart';
import '../models/core_error.dart';
import '../models/journal_entry.dart';
import '../services/core_service.dart';

/// Refactored CoreProvider focused solely on state management
/// All business logic has been moved to CoreService
class CoreProvider with ChangeNotifier {
  final CoreService _coreService = CoreService();
  
  // State variables
  List<EmotionalCore> _cores = [];
  List<EmotionalCore> _topCores = [];
  bool _isLoading = false;
  CoreError? _error;
  bool _isInitialized = false;
  
  // Subscriptions for reactive updates
  StreamSubscription<CoreUpdateEvent>? _updateSubscription;
  StreamSubscription<CoreError>? _errorSubscription;
  
  // Throttling for performance
  DateTime? _lastNotifyTime;
  static const Duration _notifyThrottleInterval = Duration(milliseconds: 100);

  /// Public getters
  List<EmotionalCore> get cores => List.unmodifiable(_cores);
  List<EmotionalCore> get topCores => List.unmodifiable(_topCores);
  bool get isLoading => _isLoading;
  CoreError? get error => _error;
  bool get isInitialized => _isInitialized;
  
  /// Core update stream for widgets that need real-time updates
  Stream<CoreUpdateEvent> get coreUpdateStream => _coreService.updateStream;

  CoreProvider() {
    _initializeProvider();
  }

  /// Initialize the provider and set up subscriptions
  Future<void> _initializeProvider() async {
    // Subscribe to service streams
    _setupSubscriptions();
    
    // Initialize the service
    await initialize();
  }

  /// Set up reactive subscriptions to service streams
  void _setupSubscriptions() {
    // Listen to core updates
    _updateSubscription = _coreService.updateStream.listen((event) {
      _handleCoreUpdate(event);
    });
    
    // Listen to errors
    _errorSubscription = _coreService.errorStream.listen((error) {
      _setError(error);
    });
  }

  /// Initialize cores
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _executeWithLoadingState(() async {
      await _coreService.initialize();
      await _syncCoresFromService();
      _isInitialized = true;
      _clearError();
    });
  }

  /// Sync local state with service data
  Future<void> _syncCoresFromService() async {
    _cores = _coreService.cores;
    _topCores = _coreService.getTopCores();
  }

  /// Handle core update events from service
  void _handleCoreUpdate(CoreUpdateEvent event) {
    // Update local state
    _syncCoresFromService();
    
    // Notify widgets with throttling
    _throttledNotify();
  }

  /// Get a specific core by ID
  EmotionalCore? getCoreById(String coreId) {
    return _coreService.getCoreById(coreId);
  }

  /// Update a core
  Future<void> updateCore(EmotionalCore core) async {
    await _executeWithLoadingState(() async {
      await _coreService.updateCore(core);
      await _syncCoresFromService();
    });
  }

  /// Analyze journal entry impact on cores
  Future<void> analyzeJournalImpact(JournalEntry entry) async {
    await _executeWithLoadingState(() async {
      await _coreService.analyzeJournalImpact(entry);
      await _syncCoresFromService();
    });
  }

  /// Refresh cores from database
  Future<void> refresh() async {
    await _executeWithLoadingState(() async {
      await _coreService.refresh();
      await _syncCoresFromService();
    });
  }

  /// Clear all cores (for testing/reset)
  Future<void> clearAllCores() async {
    await _executeWithLoadingState(() async {
      await _coreService.clearAllCores();
      _cores.clear();
      _topCores.clear();
      _isInitialized = false;
    });
  }

  /// Execute an operation with loading state management
  Future<void> _executeWithLoadingState(Future<void> Function() operation) async {
    if (_isLoading) return; // Prevent concurrent operations
    
    try {
      _setLoadingState(true);
      await operation();
      _clearError();
    } catch (e) {
      _setError(CoreError(
        type: CoreErrorType.unknown,
        message: 'Operation failed: ${e.toString()}',
        originalError: e,
      ));
    } finally {
      _setLoadingState(false);
    }
  }

  /// Set loading state and notify listeners
  void _setLoadingState(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _throttledNotify();
    }
  }

  /// Set error state and notify listeners
  void _setError(CoreError error) {
    _error = error;
    _throttledNotify();
    
    if (kDebugMode) {
      print('CoreProvider Error: ${error.message}');
    }
  }

  /// Clear error state
  void _clearError() {
    if (_error != null) {
      _error = null;
      _throttledNotify();
    }
  }

  /// Throttled notify to prevent excessive rebuilds
  void _throttledNotify() {
    final now = DateTime.now();
    if (_lastNotifyTime == null || 
        now.difference(_lastNotifyTime!) >= _notifyThrottleInterval) {
      _lastNotifyTime = now;
      notifyListeners();
    }
  }

  /// Get cores by trend
  List<EmotionalCore> getCoresByTrend(String trend) {
    return _cores.where((core) => core.trend == trend).toList();
  }

  /// Get cores above a certain level
  List<EmotionalCore> getCoresAboveLevel(double level) {
    return _cores.where((core) => core.currentLevel >= level).toList();
  }

  /// Get the most recently updated core
  EmotionalCore? getMostRecentlyUpdatedCore() {
    if (_cores.isEmpty) return null;
    
    return _cores.reduce((a, b) => 
        a.lastUpdated.isAfter(b.lastUpdated) ? a : b);
  }

  /// Get cores with recent insights
  List<EmotionalCore> getCoresWithRecentInsights() {
    return _cores.where((core) => core.recentInsights.isNotEmpty).toList();
  }

  /// Check if a specific core has recent changes
  bool hasRecentChanges(String coreId) {
    final core = getCoreById(coreId);
    if (core == null) return false;
    
    final hoursSinceUpdate = DateTime.now().difference(core.lastUpdated).inHours;
    return hoursSinceUpdate < 24;
  }

  /// Get average level across all cores
  double getAverageCoreLevel() {
    if (_cores.isEmpty) return 0.0;
    
    final totalLevel = _cores.fold<double>(0.0, (sum, core) => sum + core.currentLevel);
    return totalLevel / _cores.length;
  }

  /// Get distribution of core trends
  Map<String, int> getTrendDistribution() {
    final distribution = <String, int>{};
    
    for (final core in _cores) {
      distribution[core.trend] = (distribution[core.trend] ?? 0) + 1;
    }
    
    return distribution;
  }

  @override
  void dispose() {
    // Cancel subscriptions
    _updateSubscription?.cancel();
    _errorSubscription?.cancel();
    
    // Dispose service resources
    _coreService.dispose();
    
    super.dispose();
  }
}